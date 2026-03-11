using System.Net;
using System.Text.Json;

namespace FmpBackend.Middleware;

/// <summary>
/// ✅ NEW: Catches all unhandled exceptions and returns consistent JSON error shapes.
/// Before: unhandled exceptions returned HTML error pages or raw exception text.
/// After:  always { "error": "...", "code": 400/404/409/500 }
/// </summary>
public class GlobalExceptionMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger<GlobalExceptionMiddleware> _logger;

    public GlobalExceptionMiddleware(RequestDelegate next, ILogger<GlobalExceptionMiddleware> logger)
    {
        _next   = next;
        _logger = logger;
    }

    public async Task InvokeAsync(HttpContext ctx)
    {
        try
        {
            await _next(ctx);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Unhandled exception: {Message}", ex.Message);
            await WriteErrorAsync(ctx, ex);
        }
    }

    private static async Task WriteErrorAsync(HttpContext ctx, Exception ex)
    {
        ctx.Response.ContentType = "application/json";

        (int statusCode, string message) = ex switch
        {
            KeyNotFoundException     e => (404, e.Message),
            InvalidOperationException e => (409, e.Message),
            UnauthorizedAccessException e => (403, e.Message),
            ArgumentException        e => (400, e.Message),
            _                          => (500, "An unexpected error occurred.")
        };

        ctx.Response.StatusCode = statusCode;

        var body = JsonSerializer.Serialize(
            new { error = message, code = statusCode },
            new JsonSerializerOptions { PropertyNamingPolicy = JsonNamingPolicy.CamelCase });

        await ctx.Response.WriteAsync(body);
    }
}