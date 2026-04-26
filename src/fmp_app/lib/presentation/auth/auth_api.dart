import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

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
    debugPrint('📤 [API] POST /auth/request-otp with email: $email');
    await _dio.post(
      "/auth/request-otp",
      data: {
        "email": email,
      },
    );
    debugPrint('✓ [API] /auth/request-otp completed');
  }

  Future<Map<String, dynamic>> verifyOtp(String email, String otp) async {
    debugPrint('📤 [API] POST /auth/verify-otp with email: $email, otp: $otp');
    final res =
        await _dio.post("/auth/verify-otp", data: {"email": email, "otp": otp});
    final data = Map<String, dynamic>.from(res.data);
    debugPrint('✓ [API] /auth/verify-otp response: $data');
    return data;
  }

  // ── Google Sign-In ────────────────────────────────────────────────────────

  /// Sends the Google ID token to the backend.
  /// Returns { email, token, driverId? }
  Future<Map<String, dynamic>> signInWithGoogle(String idToken) async {
    debugPrint('📤 [API] POST /auth/google with idToken');
    final res = await _dio.post(
      "/auth/google",
      data: {"idToken": idToken},
    );
    final data = Map<String, dynamic>.from(res.data);
    debugPrint('✓ [API] /auth/google response: $data');
    return data;
  }

  // ── Shared ────────────────────────────────────────────────────────────────

  Future<void> submitDriverDetails({
    required String email,
    required String vehicleNumber,
    required String vehicleType,
    required String licenseNumber,
  }) async {
    await _dio.post(
      "/drivers/driver-details",
      data: {
        "Phone": email,
        "vehicleNumber": vehicleNumber,
        "vehicleType": vehicleType,
        "licenseNumber": licenseNumber,
      },
    );
  }

  Future<Map<String, dynamic>> resolveRole(String email, String role) async {
    debugPrint('📤 [API] POST /auth/resolve-role with email: $email, role: $role');
    final res = await _dio.post(
      "/auth/resolve-role",
      data: {
        "email": email,
        "role": role,
      },
    );
    final data = Map<String, dynamic>.from(res.data);
    debugPrint('✓ [API] /auth/resolve-role response: $data');
    debugPrint('   screen: ${data['screen']}, token: ${data['token']?.substring(0, 20)}..., driverId: ${data['driverId']}');
    return data;
  }
}