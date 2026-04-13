import 'package:fmp_app/core/network/api_client.dart';

class SysAdminApi {
  final _client = ApiClient();

  // ── Metrics ────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getMetrics() async {
    final res = await _client.dio.get('/sysadmin/metrics');
    return Map<String, dynamic>.from(res.data);
  }

  // ── Logs ───────────────────────────────────────────────────────────────────

  Future<List<dynamic>> getLogs({int limit = 50}) async {
    final res = await _client.dio.get('/sysadmin/logs', queryParameters: {'limit': limit});
    return List<dynamic>.from(res.data['logs'] ?? []);
  }

  // ── Users ──────────────────────────────────────────────────────────────────

  Future<List<dynamic>> getUsers() async {
    final res = await _client.dio.get('/sysadmin/users');
    return List<dynamic>.from(res.data['users'] ?? []);
  }

  /// Search users via backend — GET /sysadmin/users/search?q=&role=
  Future<List<dynamic>> searchUsers({String? q, String? role}) async {
    final params = <String, dynamic>{};
    if (q != null && q.isNotEmpty) params['q'] = q;
    if (role != null && role.isNotEmpty && role != 'All') params['role'] = role;
    final res = await _client.dio.get(
      '/sysadmin/users/search',
      queryParameters: params.isEmpty ? null : params,
    );
    final data = res.data;
    if (data is List) return data;
    return List<dynamic>.from(data['users'] ?? []);
  }

  // ── Shipments ──────────────────────────────────────────────────────────────

  Future<List<dynamic>> getShipments({String? status}) async {
    final res = await _client.dio.get(
      '/sysadmin/shipments',
      queryParameters: status != null ? {'status': status} : null,
    );
    return List<dynamic>.from(res.data['shipments'] ?? []);
  }

  Future<void> approveShipment(String id) async {
    await _client.dio.post('/sysadmin/shipments/$id/approve');
  }

  Future<void> rejectShipment(String id, String reason) async {
    await _client.dio.post('/sysadmin/shipments/$id/reject', data: {'reason': reason});
  }

  Future<void> cancelShipment(String id, String reason) async {
    await _client.dio.post('/sysadmin/shipments/$id/cancel', data: {'reason': reason});
  }

  Future<void> forceAssign(String shipmentId, String driverId, String vehicleId) async {
    await _client.dio.post(
      '/sysadmin/shipments/$shipmentId/force-assign',
      data: {'driverId': driverId, 'vehicleId': vehicleId},
    );
  }
}