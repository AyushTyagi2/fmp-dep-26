using Microsoft.EntityFrameworkCore;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using System.Text;
using FmpBackend.Data;
using FmpBackend.Repositories;
using FmpBackend.Services;
using FmpBackend.Workers;
using FmpBackend.Middleware;
using System.Text.Json.Serialization;

//AppContext.SetSwitch("Npgsql.EnableLegacyTimestampBehavior", true);

var builder = WebApplication.CreateBuilder(args);

var jwtKey = builder.Configuration["Jwt:Key"]
    ?? throw new InvalidOperationException("Jwt:Key is not configured in appsettings.json");

builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseNpgsql(builder.Configuration.GetConnectionString("DefaultConnection")));

builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuerSigningKey = true,
            IssuerSigningKey         = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtKey)),
            ValidateIssuer           = false,
            ValidateAudience         = false,
            ClockSkew                = TimeSpan.Zero
        };
    });

builder.Services.AddAuthorization();
builder.Services.AddSignalR();

// ── Single AddControllers call with camelCase JSON ────────────────────────────
builder.Services.AddControllers()
    .AddJsonOptions(options =>
        options.JsonSerializerOptions.PropertyNamingPolicy =
            System.Text.Json.JsonNamingPolicy.CamelCase);

// ── CORS ──────────────────────────────────────────────────────────────────────
builder.Services.AddCors(options =>
    options.AddPolicy("AllowFlutter", policy =>
        policy.SetIsOriginAllowed(_ => true)
              .AllowAnyHeader()
              .AllowAnyMethod()
              .AllowCredentials()));

// ── Dependency Injection ──────────────────────────────────────────────────────
builder.Services.AddScoped<OtpService>();
builder.Services.AddScoped<GoogleAuthService>();
builder.Services.AddScoped<UserRepository>();
builder.Services.AddScoped<DriverService>();
builder.Services.AddScoped<DriverRepository>();
builder.Services.AddScoped<VehicleRepository>();
builder.Services.AddScoped<TripRepository>();
builder.Services.AddScoped<SenderService>();
builder.Services.AddScoped<OrganizationRepository>();
builder.Services.AddScoped<FleetOwnerRepository>();
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
builder.Services.AddScoped<SystemLogRepository>();
builder.Services.AddScoped<SystemLogService>();
builder.Services.AddScoped<SysAdminService>();
builder.Services.AddScoped<VehicleService>();
builder.Services.AddSingleton<JwtService>();
builder.Services.AddHostedService<QueueMaintenanceWorker>();

// ── NO second AddControllers() here ──────────────────────────────────────────

var app = builder.Build();

app.UseMiddleware<GlobalExceptionMiddleware>();
app.UseCors("AllowFlutter");
app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();
app.MapHub<ShipmentQueueHub>("/hubs/shipment-queue");

app.Run();