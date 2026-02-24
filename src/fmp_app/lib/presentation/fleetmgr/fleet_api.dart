import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../../core/models/driver.dart';
import '../../core/models/fleet_dashboard.dart';

class FleetApi {
  final Dio _dio;

  FleetApi({Dio? dio}) : _dio = dio ?? ApiClient().dio;

  Future<List<Driver>> getDriversByFleetOwnerPhone(String phone) async {
    final encoded = Uri.encodeComponent(phone);
    try {
      final res = await _dio.get('/drivers/fleetowners/phone/$encoded/drivers');
      final data = res.data as List<dynamic>;
      return data.map((e) => Driver.fromJson(Map<String, dynamic>.from(e))).toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return [];
      rethrow;
    }
  }

  Future<Driver> getDriverById(String id) async {
    final res = await _dio.get('/drivers/$id');
    return Driver.fromJson(Map<String, dynamic>.from(res.data));
  }

  Future<FleetDashboard> getFleetDashboardByPhone(String phone) async {
    final encoded = Uri.encodeComponent(phone);
    final res = await _dio.get('/drivers/fleetowners/phone/$encoded/dashboard');
    return FleetDashboard.fromJson(Map<String, dynamic>.from(res.data));
  }
}
