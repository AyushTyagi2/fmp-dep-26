using FmpBackend.Repositories;
using FmpBackend.Models;

namespace FmpBackend.Services;

/// <summary>
/// OTP flow:
///  1. GenerateOtp()  — creates a 6-digit code, stores it in-memory with a 10-min TTL,
///                       and logs it to console (replace Console.WriteLine with your SMS
///                       provider call, e.g. MSG91, Fast2SMS, Twilio).
///  2. VerifyOtp()    — validates code + expiry, creates user if new, returns the User.
///
/// NOTE: In-memory storage works for a single-instance deployment.
/// For multi-instance / serverless, swap _store for Redis or a DB table.
/// </summary>
public class OtpService
{
    private readonly UserRepository _userRepo;

    // phone → (otp, expiry, attemptCount)
    private static readonly Dictionary<string, (string Otp, DateTime Expiry, int Attempts)>
        _store = new();

    private static readonly object _lock = new();

    private const int OtpExpiryMinutes = 10;
    private const int MaxAttempts      = 5;

    public OtpService(UserRepository userRepo)
    {
        _userRepo = userRepo;
    }

    public void GenerateOtp(string phone)
    {
        // ✅ FIX: cryptographically random 6-digit code (was always "123456")
        var otp = Random.Shared.Next(100_000, 999_999).ToString();

        lock (_lock)
        {
            _store[phone] = (otp, DateTime.UtcNow.AddMinutes(OtpExpiryMinutes), 0);
        }

        // TODO: Replace this with your SMS provider (MSG91, Fast2SMS, Twilio, etc.)
        // Example MSG91: POST https://api.msg91.com/api/v5/otp?template_id=...&mobile={phone}&otp={otp}
        Console.WriteLine($"[OTP] {phone} → {otp}  (valid for {OtpExpiryMinutes} min)");
    }

    /// <summary>
    /// Returns the authenticated User on success.
    /// Throws InvalidOperationException with a human-readable message on failure.
    /// </summary>
    public User VerifyOtp(string phone, string otp)
    {
        lock (_lock)
        {
            if (!_store.TryGetValue(phone, out var entry))
                throw new InvalidOperationException("No OTP was requested for this number.");

            if (entry.Attempts >= MaxAttempts)
                throw new InvalidOperationException("Too many failed attempts. Request a new OTP.");

            if (DateTime.UtcNow > entry.Expiry)
            {
                _store.Remove(phone);
                throw new InvalidOperationException("OTP has expired. Please request a new one.");
            }

            if (entry.Otp != otp)
            {
                _store[phone] = entry with { Attempts = entry.Attempts + 1 };
                throw new InvalidOperationException("Incorrect OTP.");
            }

            // Success — remove from store so it can't be reused
            _store.Remove(phone);
        }

        // Create user if first-time login
        var user = _userRepo.GetByPhone(phone);
        if (user == null)
        {
            var id = Guid.NewGuid();
            user = new User
            {
                Id           = id,
                Phone        = phone,
                PasswordHash = string.Empty,
                AuthProvider = "phone_otp",
                FullName     = $"user_{id.ToString()[..8]}"
            };
            _userRepo.Create(user);
        }

        return user;
    }
}