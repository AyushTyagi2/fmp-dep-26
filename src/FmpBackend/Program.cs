using Microsoft.EntityFrameworkCore;
using FmpBackend.Data;
using FmpBackend.Repositories;
using FmpBackend.Services;

var builder = WebApplication.CreateBuilder(args);
builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseNpgsql(builder.Configuration.GetConnectionString("DefaultConnection")));
// 🔹 LOG (correct way)
Console.WriteLine("We're in the ASP.NET API!!");

// 🔹 Controllers (use camelCase JSON for compatibility with frontend)
builder.Services.AddControllers()
    .AddJsonOptions(opts =>
    {
        opts.JsonSerializerOptions.PropertyNamingPolicy = System.Text.Json.JsonNamingPolicy.CamelCase;
    });
    AppContext.SetSwitch("Npgsql.EnableLegacyTimestampBehavior", true);

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
builder.Services.AddScoped<TripRepository>();
builder.Services.AddScoped<SenderService>();
builder.Services.AddScoped<OrganizationRepository>();
builder.Services.AddScoped<FleetOwnerRepository>();
builder.Services.AddScoped<SenderService>();
builder.Services.AddScoped<RoleService>();
builder.Services.AddScoped<ShipmentService>();
builder.Services.AddScoped<ShipmentRepository>();
builder.Services.AddScoped<AddressRepository>();
builder.Services.AddScoped<ShipmentQueueRepository>();
builder.Services.AddScoped<ShipmentQueueService>();
builder.Services.AddScoped<TripCrudRepository>();
builder.Services.AddScoped<TripService>();
builder.Services.AddScoped<DriverQueueRepository>();

builder.Services.AddScoped<QueueEventRepository>();
builder.Services.AddScoped<DriverEligibleRepository>();

builder.Services.AddScoped<QueueEventService>();
var app = builder.Build();

// 🔹 Map APIs
app.MapControllers();

// 🔹 Start server
app.Run();
