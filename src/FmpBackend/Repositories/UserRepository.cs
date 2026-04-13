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

    /// <summary>
    /// Search users by free-text (fullName / phone) and optionally by role name.
    /// Role filtering uses the same raw SQL pattern as GetRolesByUserId because
    /// user_roles / roles are not mapped as EF DbSets.
    /// </summary>
    public async Task<List<User>> SearchAsync(string? q, string? role)
    {
        // If a role filter is provided, get matching user IDs via raw SQL first
        HashSet<Guid>? roleUserIds = null;
        if (!string.IsNullOrWhiteSpace(role))
        {
            var sql = $@"
                SELECT ur.user_id::text as ""Value""
                FROM user_roles ur
                JOIN roles r ON r.id = ur.role_id
                WHERE LOWER(r.name) = LOWER('{role.Replace("'","''")}')
                  AND ur.is_active = true";

            roleUserIds = _db.Database
                .SqlQueryRaw<RoleNameResult>(sql)
                .Select(r => Guid.Parse(r.Value))
                .ToHashSet();

            // If no users have this role, return empty immediately
            if (roleUserIds.Count == 0) return new List<User>();
        }

        var query = _db.Users.AsQueryable();

        // Free-text filter
        if (!string.IsNullOrWhiteSpace(q))
        {
            var lower = q.ToLower();
            query = query.Where(u =>
                u.FullName.ToLower().Contains(lower) ||
                u.Phone.ToLower().Contains(lower));
        }

        // Apply role ID filter if we have one
        if (roleUserIds != null)
            query = query.Where(u => roleUserIds.Contains(u.Id));

        return await query
            .OrderByDescending(u => u.CreatedAt)
            .ToListAsync();
    }
}
