import 'package:dio/dio.dart';

class AuthApi {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: "http://localhost:5153",
      headers: {"Content-Type": "application/json"},
    ),
  );

  Future<void> requestOtp(String phone) async {
    print("[AuthApi] requesting OTP for $phone");
    await _dio.post("/auth/request-otp", data: {"phone": phone});
  }

  /// Verifies OTP.
  /// Returns { success, screen, token, driverId } — Flutter navigates directly to screen.
  Future<Map<String, dynamic>> verifyOtp(String phone, String otp) async {
    final res = await _dio.post(
      "/auth/verify-otp",
      data: {"phone": phone, "otp": otp},
    );
    return Map<String, dynamic>.from(res.data);
  }

  /// Called from role-selection screen (driver / organisation only).
  Future<Map<String, dynamic>> resolveRole(String phone, String role) async {
    final res = await _dio.post(
      "/auth/resolve-role",
      data: {"phone": phone, "role": role},
    );
    return Map<String, dynamic>.from(res.data);
  }

  /// Called from driver onboarding screen to submit vehicle details.
  Future<void> submitDriverDetails({
    required String phone,
    required String vehicleNumber,
    required String vehicleType,
  }) async {
    await _dio.post(
      "/drivers/driver-details",
      data: {
        "phone": phone,
        "vehicleNumber": vehicleNumber,
        "vehicleType": vehicleType,
      },
    );
  }
}