import 'package:dio/dio.dart';

class FleetmgrApi {
  final Dio _dio;

  FleetmgrApi({Dio? dio})
      : _dio = dio ?? Dio(BaseOptions(baseUrl: 'http://localhost:5153'));

  Future<void> submitFleetOnboarding({
    required String orgName,
    required String orgType,
    required String contactName,
    required String phone,
    required String email,
    required String addressLine,
    required String city,
    required String state,
    required String postalCode,
    required List<Map<String, dynamic>> drivers,
    required List<Map<String, dynamic>> vehicles,
  }) async {
    final payload = {
      'orgName': orgName,
      'orgType': orgType,
      'contactName': contactName,
      'phone': phone,
      'email': email,
      'addressLine': addressLine,
      'city': city,
      'state': state,
      'postalCode': postalCode,
      'drivers': drivers,
      'vehicles': vehicles,
    };

    await _dio.post('/fleet/onboard', data: payload);
  }
}
