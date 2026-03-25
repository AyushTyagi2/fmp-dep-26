using Microsoft.EntityFrameworkCore;
using FmpBackend.Data;
using FmpBackend.Models;

namespace FmpBackend.Repositories;

public class UserRepository
{
    private readonly AppDbContext _db;

    public UserRepository(AppDbContext db)
    {
        _db = db;
    }

    public User? GetByPhone(string phone)
        => _db.Users.FirstOrDefault(u => u.Phone == phone);

    public User? GetById(Guid id)
        => _db.Users.FirstOrDefault(u => u.Id == id);

    public void Create(User user)
    {
        _db.Users.Add(user);
        _db.SaveChanges();
    }

    public void Update(User user)
    {
        _db.Users.Update(user);
        _db.SaveChanges();
    }

    public async Task<User?> GetByPhoneAsync(string phone)
        => await _db.Users.FirstOrDefaultAsync(u => u.Phone == phone);

    public Guid? GetIdByPhone(string phone)
        => _db.Users
              .Where(u => u.Phone == phone)
              .Select(u => (Guid?)u.Id)
              .FirstOrDefault();

    /// <summary>
    /// Returns active, non-expired role names for a user (e.g. "FLEET_OWNER", "DRIVER").
    /// Checks both is_active = true AND valid_until (null = never expires).
    /// </summary>
    public List<string> GetActiveRoles(Guid userId)
    {
        var now = DateTime.UtcNow;
        return _db.UserRoles
                  .Include(ur => ur.Role)
                  .Where(ur =>
                      ur.UserId   == userId &&
                      ur.IsActive == true   &&
                      (ur.ValidUntil == null || ur.ValidUntil > now))  // ✅ respect expiry
                  .Select(ur => ur.Role!.Name)
                  .ToList();
    }
}