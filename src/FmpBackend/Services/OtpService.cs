using FmpBackend.Repositories;
using FmpBackend.Models;
using System.Net;
using System.Net.Mail;

namespace FmpBackend.Services;

/// <summary>
/// OTP flow:
///  1. GenerateOtp(email)  — creates a 6-digit code, stores it in-memory with a 10-min TTL,
///                           and sends it via email (configure SMTP in appsettings.json).
///  2. VerifyOtp(email, otp) — validates code + expiry, creates user if new, returns the User.
///
/// SMTP config required in appsettings.json:
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
/// NOTE: In-memory storage works for a single-instance deployment.
/// For multi-instance / serverless, swap _store for Redis or a DB table.
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

    public void GenerateOtp(string email)
    {
        var otp = Random.Shared.Next(100_000, 999_999).ToString();

        lock (_lock)
        {
            _store[email] = (otp, DateTime.UtcNow.AddMinutes(OtpExpiryMinutes), 0);
        }

        // Log to console for local dev — real email send below
        Console.WriteLine($"[OTP] {email} → {otp}  (valid for {OtpExpiryMinutes} min)");

        SendOtpEmail(email, otp);
    }

    private void SendOtpEmail(string toEmail, string otp)
    {
        var host = _config["Smtp:Host"];
        var port = int.TryParse(_config["Smtp:Port"], out var p) ? p : 587;
        var user = _config["Smtp:User"];
        var pass = _config["Smtp:Pass"];
        var from = _config["Smtp:From"] ?? user;

        // If SMTP is not configured, skip sending (OTP still printed to console)
        if (string.IsNullOrWhiteSpace(host) || string.IsNullOrWhiteSpace(user))
        {
            Console.WriteLine("[OTP] SMTP not configured — skipping email send.");
            return;
        }

        try
        {
            using var client = new SmtpClient(host, port)
            {
                Credentials    = new NetworkCredential(user, pass),
                EnableSsl      = true,
                DeliveryMethod = SmtpDeliveryMethod.Network,
            };

            var body = $@"
<div style='font-family:sans-serif;max-width:480px;margin:auto'>
  <h2 style='color:#1A56DB'>Your FleetOS verification code</h2>
  <p style='font-size:15px;color:#374151'>Use the code below to sign in. It expires in {OtpExpiryMinutes} minutes.</p>
  <div style='background:#EBF0FE;border-radius:12px;padding:24px;text-align:center;margin:24px 0'>
    <span style='font-size:36px;font-weight:800;letter-spacing:8px;color:#1A56DB'>{otp}</span>
  </div>
  <p style='font-size:13px;color:#9CA3AF'>If you did not request this code, you can safely ignore this email.</p>
</div>";

            var msg = new MailMessage
            {
                From       = new MailAddress(from!),
                Subject    = $"{otp} is your FleetOS verification code",
                Body       = body,
                IsBodyHtml = true,
            };
            msg.To.Add(toEmail);

            client.Send(msg);
            Console.WriteLine($"[OTP] Email sent to {toEmail}");
        }
        catch (Exception ex)
        {
            // Don't throw — OTP is still valid, user sees console log in dev
            Console.WriteLine($"[OTP] Email send failed: {ex.Message}");
        }
    }

    /// <summary>
    /// Returns the authenticated User on success.
    /// Throws InvalidOperationException with a human-readable message on failure.
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

            // Success — remove from store so it can't be reused
            _store.Remove(email);
        }

        // Create user if first-time login
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
                FullName     = $"user_{id.ToString()[..8]}"
            };
            _userRepo.Create(user);
        }

        return user;
    }
}