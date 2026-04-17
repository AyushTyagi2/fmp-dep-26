using FmpBackend.Repositories;
using FmpBackend.Models;
using MailKit.Net.Smtp;
using MailKit.Security;
using MimeKit;

namespace FmpBackend.Services;

/// <summary>
/// OTP flow:
///  1. GenerateOtp(email) — creates a 6-digit code, stores it in-memory with
///     a 10-min TTL, prints it to the console, and sends it via SMTP email.
///  2. VerifyOtp(email, otp) — validates code + expiry, creates user if new.
///
/// SMTP config (appsettings.json):
/// {
///   "Smtp": {
///     "Host": "smtp.gmail.com",
///     "Port": 587,
///     "User": "you@gmail.com",
///     "Pass": "your-app-password",
///     "From": "FleetOS <you@gmail.com>"
///   }
/// }
///
/// NOTE: Console.WriteLine always prints the OTP so you can test locally
/// even when SMTP is not configured.
/// </summary>
public class OtpService
{
    private readonly UserRepository _userRepo;
    private readonly IConfiguration _config;

    // email → (otp, expiry, attemptCount)
    private static readonly Dictionary<string, (string Otp, DateTime Expiry, int Attempts)>
        _store = new();

    private static readonly object _lock = new();

    private const int OtpExpiryMinutes = 10;
    private const int MaxAttempts      = 5;

    public OtpService(UserRepository userRepo, IConfiguration config)
    {
        _userRepo = userRepo;
        _config   = config;
    }

    // ── Generate & send ───────────────────────────────────────────────────────

    public void GenerateOtp(string email)
    {
        var otp = Random.Shared.Next(100_000, 999_999).ToString();

        lock (_lock)
        {
            _store[email] = (otp, DateTime.UtcNow.AddMinutes(OtpExpiryMinutes), 0);
        }

        // ✅ Always log — equivalent to console.log() in Node/nodemailer setups
        Console.WriteLine("╔══════════════════════════════════════╗");
        Console.WriteLine($"║  OTP for {email,-28}║");
        Console.WriteLine($"║  Code : {otp,-31}║");
        Console.WriteLine($"║  Valid: {OtpExpiryMinutes} minutes                        ║");
        Console.WriteLine("╚══════════════════════════════════════╝");

        // Also attempt SMTP delivery (non-blocking — a failure won't throw)
        SendOtpEmail(email, otp);
    }

    // ── SMTP email send ───────────────────────────────────────────────────────

    private void SendOtpEmail(string toEmail, string otp)
{
    var host = _config["Smtp:Host"];
    var port = int.TryParse(_config["Smtp:Port"], out var p) ? p : 587;
    var user = _config["Smtp:User"];
    var pass = _config["Smtp:Pass"];
    var from = _config["Smtp:From"] ?? user;

    if (string.IsNullOrWhiteSpace(host) || string.IsNullOrWhiteSpace(user))
    {
        Console.WriteLine("[OTP] SMTP not configured.");
        return;
    }

    try
    {
        var message = new MimeMessage();
        message.From.Add(MailboxAddress.Parse(from));
        message.To.Add(MailboxAddress.Parse(toEmail));
        message.Subject = $"{otp} is your FleetOS verification code";

        var body = $@"
        <div style='font-family:sans-serif;max-width:480px;margin:auto'>
            <h2>Your FleetOS verification code</h2>
            <p>This OTP is valid for {OtpExpiryMinutes} minutes.</p>

            <div style='background:#EBF0FE;padding:20px;text-align:center'>
                <h1 style='letter-spacing:8px'>{otp}</h1>
            </div>

            <p>If you didn't request this code you can ignore this email.</p>
        </div>";

        message.Body = new TextPart("html")
        {
            Text = body
        };

        using var client = new SmtpClient();

        client.Connect(host, port, SecureSocketOptions.StartTls);
        client.Authenticate(user, pass);
        client.Send(message);
        client.Disconnect(true);

        Console.WriteLine($"[OTP] Email sent to {toEmail}");
    }
    catch (Exception ex)
    {
        Console.WriteLine($"[OTP] Email send failed: {ex.Message}");
    }
}

    // ── Verify ────────────────────────────────────────────────────────────────

    /// <summary>
    /// Returns the authenticated User on success.
    /// Throws InvalidOperationException with a user-readable message on failure.
    /// Creates a new user record on first-time sign-in (same as phone-based onboarding).
    /// </summary>
    public User VerifyOtp(string email, string otp)
    {
        lock (_lock)
        {
            if (!_store.TryGetValue(email, out var entry))
                throw new InvalidOperationException("No OTP was requested for this email.");

            if (entry.Attempts >= MaxAttempts)
                throw new InvalidOperationException("Too many failed attempts. Request a new OTP.");

            if (DateTime.UtcNow > entry.Expiry)
            {
                _store.Remove(email);
                throw new InvalidOperationException("OTP has expired. Please request a new one.");
            }

            if (entry.Otp != otp)
            {
                _store[email] = entry with { Attempts = entry.Attempts + 1 };
                throw new InvalidOperationException("Incorrect OTP.");
            }

            // Consumed — remove so it can't be reused
            _store.Remove(email);
        }

        // ── Upsert user ──────────────────────────────────────────────────────
        // Existing users (e.g. migrated from phone): their email is already in
        // the users table, so GetByEmail finds them and we skip Create.
        // New users: we create a fresh record just like the old phone flow did.
        var user = _userRepo.GetByEmail(email);
        if (user == null)
        {
            var id = Guid.NewGuid();
            user = new User
            {
                Id           = id,
                Email        = email,
                PasswordHash = string.Empty,
                AuthProvider = "email_otp",
                FullName     = $"user_{id.ToString()[..8]}",
                CreatedAt    = DateTime.UtcNow,
            };
            _userRepo.Create(user);
            Console.WriteLine($"[OTP] New user created for {email}");
        }
        else
        {
            Console.WriteLine($"[OTP] Existing user authenticated: {email}");
        }

        return user;
    }
}