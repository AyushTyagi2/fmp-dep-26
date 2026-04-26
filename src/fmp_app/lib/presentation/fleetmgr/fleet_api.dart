import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../../core/models/driver.dart';
import '../../core/models/fleet_dashboard.dart';
import '../../core/models/vehicle.dart';

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

  Future<List<Vehicle>> getVehiclesByFleetOwnerPhone(String phone) async {
    final encoded = Uri.encodeComponent(phone);
    try {
      final res = await _dio.get('/vehicles/fleetowners/phone/$encoded/vehicles');
      final data = res.data as List<dynamic>;
      return data.map((e) => Vehicle.fromJson(Map<String, dynamic>.from(e))).toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return [];
      rethrow;
    }
  }

  Future<Vehicle> addVehicle(String phone, Map<String, dynamic> vehicleData) async {
    final encoded = Uri.encodeComponent(phone);
    final res = await _dio.post('/vehicles/fleetowners/phone/$encoded/vehicles', data: vehicleData);
    return Vehicle.fromJson(Map<String, dynamic>.from(res.data));
  }

  Future<Map<String, dynamic>> addVehiclesBulk(String phone, List<Map<String, dynamic>> vehicles) async {
    final encoded = Uri.encodeComponent(phone);
    final res = await _dio.post('/vehicles/fleetowners/phone/$encoded/vehicles/bulk', data: vehicles);
    return Map<String, dynamic>.from(res.data);
  }

  Future<void> dropVehicles(String phone, List<String> vehicleIds) async {
    final encoded = Uri.encodeComponent(phone);
    await _dio.delete(
      '/vehicles/fleetowners/phone/$encoded/vehicles',
      data: {'vehicleIds': vehicleIds},
    );
  }
}
