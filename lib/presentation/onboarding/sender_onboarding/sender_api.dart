import 'package:dio/dio.dart';

class SenderApi {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: "http://localhost:5153",
      headers: {
        "Content-Type": "application/json",
      },
    ),
  );

  Future<void> submitSenderOnboarding({
    required String orgName,
    required String orgType,
    required String contactName,
    required String phone,
    required String email,
    required String industry,
    required String description,
    required String addressLine,
    required String city,
    required String state,
    required String postalCode,
  }) async {
    await _dio.post(
      "/senders/onboard",
      data: {
        "orgName": orgName,
        "orgType": orgType,
        "contactName": contactName,
        "phone": phone,
        "email": email,
        "industry": industry,
        "description": description,
        "addressLine": addressLine,
        "city": city,
        "state": state,
        "postalCode": postalCode,
      },
    );
  }
}
