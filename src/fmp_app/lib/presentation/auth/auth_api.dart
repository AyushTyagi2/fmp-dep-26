import 'package:dio/dio.dart';

class AuthApi {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: "http://localhost:5153", // Android emulator
      headers: {
        "Content-Type": "application/json",
      },
    ),
  );

  Future<void> requestOtp(String phone) async {
    print("we reached here!!");
    await _dio.post(
      "/auth/request-otp",
      data: {
        "phone": phone,
      },
    );
  }

  Future<void> verifyOtp(String phone, String otp) async {
    await _dio.post(
      "/auth/verify-otp",
      data: {
        "phone": phone,
        "otp": otp,
      },
    );
  }

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
Future<Map<String, dynamic>> resolveRole(String phone, String role) async {
  final res = await _dio.post(
    "/auth/resolve-role",
    data: {
      "phone": phone,
      "role": role,
    },
  );

  return Map<String, dynamic>.from(res.data);
}

}
