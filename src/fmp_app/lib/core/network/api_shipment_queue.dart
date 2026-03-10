import 'package:dio/dio.dart';
import '../models/shipment.dart';
import 'api_client.dart';

class AcceptResult {
  final bool    success;
  final String? tripId;
  final String? message;
  const AcceptResult({required this.success, this.tripId, this.message});
}

class ShipmentApiService {
  final ApiClient _client;
  ShipmentApiService(this._client);
  Dio get _dio => _client.dio;

  Future<PagedResult<Shipment>> fetchQueue({int page = 1, int pageSize = 20}) async {
    final res = await _dio.get(
      '/api/shipment-queue',
      queryParameters: {'page': page, 'pageSize': pageSize},
    );
    return PagedResult.fromJson(res.data, Shipment.fromJson);
  }

  // ✅ Returns tripId on success so Flutter can navigate directly to the active trip
  Future<AcceptResult> acceptShipment({
    required String shipmentId,
    required String driverId,
  }) async {
    try {
      final res = await _dio.post(
        '/api/shipment-queue/$shipmentId/accept',
        data: {'driverId': driverId},
      );
      final data = res.data as Map<String, dynamic>;
      return AcceptResult(
        success: data['success'] as bool,
        tripId:  data['tripId']  as String?,
        message: data['message'] as String?,
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        return const AcceptResult(success: false, message: 'Already taken by another driver.');
      }
      rethrow;
    }
  }

  Future<Shipment> getQueueItemById(String id) async {
    final res = await _dio.get('/api/shipment-queue/$id');
    return Shipment.fromJson(res.data);
  }
}