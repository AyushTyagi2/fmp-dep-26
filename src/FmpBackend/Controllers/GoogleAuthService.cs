using Google.Apis.Auth;

namespace FmpBackend.Services;

/// <summary>
/// Validates Google ID tokens issued by the Flutter google_sign_in package.
/// The token audience must match the Web Client ID in appsettings.json.
/// </summary>
public class GoogleAuthService
{
    private readonly string _clientId;

    public GoogleAuthService(IConfiguration config)
    {
        _clientId = config["Google:ClientId"]
            ?? throw new InvalidOperationException(
                "Google:ClientId is missing from appsettings.json");
    }

    /// <summary>
    /// Throws GoogleJsonWebSignature.InvalidJwtException if the token is
    /// invalid, expired, or issued for a different audience.
    /// </summary>
    public async Task<GoogleJsonWebSignature.Payload> ValidateAsync(string idToken)
    {
        var settings = new GoogleJsonWebSignature.ValidationSettings
        {
            Audience = new[] { _clientId }
        };

        return await GoogleJsonWebSignature.ValidateAsync(idToken, settings);
    }
}