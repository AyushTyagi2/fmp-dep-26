namespace FmpBackend.Models;

public class User
{
    public Guid    Id             { get; set; }
    public string? Phone          { get; set; }           // nullable — existing phone users
    public string? Email          { get; set; }           // primary identity (nullable due to existing DB data)
    public string? PasswordHash   { get; set; }
    public string  FullName       { get; set; } = null!;
    public string? AuthProvider   { get; set; }           // "email_otp" | "google"
    public string? AuthProviderId { get; set; }           // Google "sub" value
    public DateTime CreatedAt     { get; set; }
    public DateTime? DateOfBirth  { get; set; }
}