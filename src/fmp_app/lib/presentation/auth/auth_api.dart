import 'package:dio/dio.dart';

class AuthApi {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: "http://localhost:5153",
      headers: {
        "Content-Type": "application/json",
      },
    ),
  );

  // ── Email OTP flow (unchanged) ────────────────────────────────────────────

  Future<void> requestOtp(String email) async {
    await _dio.post(
      "/auth/request-otp",
      data: {
        "email": email,
      },
    );
  }

  Future<Map<String, dynamic>> verifyOtp(String email, String otp) async {
    final res =
        await _dio.post("/auth/verify-otp", data: {"email": email, "otp": otp});
    return Map<String, dynamic>.from(res.data);
  }

  // ── Google Sign-In ────────────────────────────────────────────────────────

  /// Sends the Google ID token to the backend.
  /// Returns { email, token, driverId? }
  Future<Map<String, dynamic>> signInWithGoogle(String idToken) async {
    final res = await _dio.post(
      "/auth/google",
      data: {"idToken": idToken},
    );
    return Map<String, dynamic>.from(res.data);
  }

  // ── Shared ────────────────────────────────────────────────────────────────

  Future<void> submitDriverDetails({
    required String email,
    required String vehicleNumber,
    required String vehicleType,
  }) async {
    await _dio.post(
      "/drivers/driver-details",
      data: {
        "email": email,
        "vehicleNumber": vehicleNumber,
        "vehicleType": vehicleType,
      },
    );
  }

  Future<Map<String, dynamic>> resolveRole(String email, String role) async {
    final res = await _dio.post(
      "/auth/resolve-role",
      data: {
        "email": email,
        "role": role,
      },
    );
    return Map<String, dynamic>.from(res.data);
  }
}