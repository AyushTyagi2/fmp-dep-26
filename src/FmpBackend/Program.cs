using Microsoft.EntityFrameworkCore;
using FmpBackend.Data;
using FmpBackend.Repositories;
using FmpBackend.Services;

var builder = WebApplication.CreateBuilder(args);

// 🔹 LOG (correct way)
Console.WriteLine("We're in the ASP.NET API!!");

// 🔹 Controllers
builder.Services.AddControllers();

// 🔹 Database (PostgreSQL)
builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseNpgsql(
        builder.Configuration.GetConnectionString("DefaultConnection")
    )
);

// 🔹 Dependency Injection
builder.Services.AddScoped<OtpService>();
builder.Services.AddScoped<UserRepository>();
builder.Services.AddScoped<DriverService>();
builder.Services.AddScoped<DriverRepository>();
builder.Services.AddScoped<VehicleRepository>();
builder.Services.AddScoped<SenderService>();
builder.Services.AddScoped<OrganizationRepository>();
builder.Services.AddScoped<SenderService>();
builder.Services.AddScoped<RoleService>();

var app = builder.Build();

// 🔹 Map APIs
app.MapControllers();

// 🔹 Start server
app.Run();
