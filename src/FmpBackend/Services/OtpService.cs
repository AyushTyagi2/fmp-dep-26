using FmpBackend.Repositories;
using FmpBackend.Models;

namespace FmpBackend.Services;

public class OtpService
{
    private readonly UserRepository _userRepo;

    public OtpService(UserRepository userRepo)
    {
        _userRepo = userRepo;
    }

    public void GenerateOtp(string phone)
    {
        var otp = "123456"; // later random + SMS
        Console.WriteLine($"OTP for {phone}: {otp}");
    }

   public void VerifyOtp(string phone, string otp)
{
    var user = _userRepo.GetByPhone(phone);

    if (user == null)
    {
        var id = Guid.NewGuid();

        user = new User
        {
            Id = id,
            Phone = phone,
            PasswordHash = "dummy",
            AuthProvider = "phone_otp",
            FullName = $"driver_{id}"
        };

        _userRepo.Create(user);
    }
   
}

}
