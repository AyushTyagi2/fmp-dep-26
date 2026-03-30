namespace FmpBackend.Models;

public class User
{
    public Guid Id { get; set; }
    public string? Phone { get; set; }           // kept for backward compat — nullable now
    public string Email { get; set; } = null!;   // primary identity field
    public string? PasswordHash { get; set; }
    public string FullName { get; set; } = null!;
    public string? AuthProvider { get; set; }
    public DateTime CreatedAt { get; set; }
}