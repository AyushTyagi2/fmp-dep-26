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
    {
        return _db.Users.FirstOrDefault(u => u.Phone == phone);
    }

    public User? GetById(Guid id)
    {
        return _db.Users.FirstOrDefault(u => u.Id == id);
    }
    // Replace GetRolesByUserId with this:
public List<string> GetRolesByUserId(Guid userId)
{
    var sql = $@"
        SELECT r.name as ""Value""
        FROM user_roles ur
        JOIN roles r ON r.id = ur.role_id
        WHERE ur.user_id = '{userId}' AND ur.is_active = true";

    var roles = _db.Database
        .SqlQueryRaw<RoleNameResult>(sql)
        .Select(r => r.Value)
        .ToList();

    Console.WriteLine($"GetRolesByUserId({userId}): [{string.Join(", ", roles)}]");
    return roles;
}
public class RoleNameResult
{
    public string Value { get; set; } = string.Empty;
}
    

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
    {
        return await _db.Users
            .FirstOrDefaultAsync(u => u.Phone == phone);
    }

    public Guid? GetIdByPhone(string phone)
{
    return _db.Users
        .Where(u => u.Phone == phone)
        .Select(u => (Guid?)u.Id)
        .FirstOrDefault();
}
public async Task<List<User>> GetAllAsync()
    {
        return await _db.Users
            .OrderByDescending(u => u.CreatedAt)
            .ToListAsync();
    }
}
