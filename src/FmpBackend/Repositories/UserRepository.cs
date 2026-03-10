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
}
