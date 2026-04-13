import 'package:dio/dio.dart';
import 'api_client.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SEARCH API SERVICE
// All search queries are sent to the backend with query parameters.
// Each method corresponds to a stakeholder's search scope.
// ─────────────────────────────────────────────────────────────────────────────

class SearchApi {
  final ApiClient _client;
  SearchApi(this._client);
  Dio get _dio => _client.dio;

  // ── Sender: shipment search ───────────────────────────────────────────────
  /// GET /api/shipments/search?q=&status=&cargoType=&urgent=&phone=
  Future<Map<String, dynamic>> searchShipments({
    required String phone,
    String? q,
    String? status,
    String? cargoType,
    bool? urgent,
  }) async {
    final params = <String, dynamic>{'phone': phone};
    if (q != null && q.isNotEmpty) params['q'] = q;
    if (status != null && status.isNotEmpty) params['status'] = status;
    if (cargoType != null && cargoType.isNotEmpty) params['cargoType'] = cargoType;
    if (urgent == true) params['urgent'] = 'true';
    try {
      final res = await _dio.get('/api/shipments/search', queryParameters: params);
      return Map<String, dynamic>.from(res.data as Map);
    } on DioException catch (e) {
      throw Exception(
          e.response?.data?['message'] ?? 'Shipment search failed');
    }
  }

  // ── Driver: trip search ───────────────────────────────────────────────────
  /// GET /api/trips/search?q=&status=&driverId=
  Future<List<dynamic>> searchTrips({
    required String driverId,
    String? q,
    String? status,
  }) async {
    final params = <String, dynamic>{'driverId': driverId};
    if (q != null && q.isNotEmpty) params['q'] = q;
    if (status != null && status.isNotEmpty) params['status'] = status;
    try {
      final res = await _dio.get('/api/trips/search', queryParameters: params);
      final data = res.data;
      if (data is List) return data;
      if (data is Map && data['trips'] != null) return data['trips'] as List;
      return [];
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'Trip search failed');
    }
  }

  // ── Union: shipment queue search ──────────────────────────────────────────
  /// GET /api/shipments/queue/search?q=&status=&cargoType=&urgent=
  Future<List<dynamic>> searchQueueShipments({
    String? q,
    String? status,
    String? cargoType,
    bool? urgent,
  }) async {
    final params = <String, dynamic>{};
    if (q != null && q.isNotEmpty) params['q'] = q;
    if (status != null && status.isNotEmpty) params['status'] = status;
    if (cargoType != null && cargoType.isNotEmpty) params['cargoType'] = cargoType;
    if (urgent == true) params['urgent'] = 'true';
    try {
      final res = await _dio.get('/api/shipments/queue/search', queryParameters: params.isEmpty ? null : params);
      final data = res.data;
      if (data is List) return data;
      if (data is Map && data['shipments'] != null) return data['shipments'] as List;
      return [];
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'Queue search failed');
    }
  }

  // ── FleetMgr: driver search ───────────────────────────────────────────────
  /// GET /drivers/fleetowners/phone/{phone}/drivers/search?q=&status=
  Future<List<dynamic>> searchFleetDrivers({
    required String phone,
    String? q,
    String? status,
  }) async {
    final encoded = Uri.encodeComponent(phone);
    final params = <String, dynamic>{};
    if (q != null && q.isNotEmpty) params['q'] = q;
    if (status != null && status.isNotEmpty) params['status'] = status;
    try {
      final res = await _dio.get(
        '/drivers/fleetowners/phone/$encoded/drivers/search',
        queryParameters: params.isEmpty ? null : params,
      );
      final data = res.data;
      if (data is List) return data;
      if (data is Map && data['drivers'] != null) return data['drivers'] as List;
      return [];
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'Driver search failed');
    }
  }

  // ── SysAdmin: user search ─────────────────────────────────────────────────
  /// GET /sysadmin/users/search?q=&role=
  Future<List<dynamic>> searchUsers({String? q, String? role}) async {
    final params = <String, dynamic>{};
    if (q != null && q.isNotEmpty) params['q'] = q;
    if (role != null && role.isNotEmpty && role != 'All') params['role'] = role;
    try {
      final res = await _dio.get(
        '/sysadmin/users/search',
        queryParameters: params.isEmpty ? null : params,
      );
      final data = res.data;
      if (data is List) return data;
      if (data is Map && data['users'] != null) return data['users'] as List;
      return [];
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'User search failed');
    }
  }
}
