import 'package:dio/dio.dart';
import 'api_client.dart';

class TripSummary {
  final String  id;
  final String  tripNumber;
  final String  shipmentId;
  final String  shipmentNumber;
  final String  currentStatus;
  final double? agreedPrice;
  final DateTime createdAt;

  const TripSummary({
    required this.id,
    required this.tripNumber,
    required this.shipmentId,
    required this.shipmentNumber,
    required this.currentStatus,
    this.agreedPrice,
    required this.createdAt,
  });

  factory TripSummary.fromJson(Map<String, dynamic> json) => TripSummary(
    id:             json['id']             as String,
    tripNumber:     json['tripNumber']     as String,
    shipmentId:     json['shipmentId']     as String,
    shipmentNumber: json['shipmentNumber'] as String,
    currentStatus:  json['currentStatus']  as String,
    agreedPrice:    (json['agreedPrice']   as num?)?.toDouble(),
    createdAt:      DateTime.parse(json['createdAt'] as String),
  );
}

class TripApiService {
  final ApiClient _client;
  TripApiService(this._client);
  Dio get _dio => _client.dio;

  Future<List<TripSummary>> getDriverTrips(String driverId) async {
    final res = await _dio.get('/api/trips/driver/$driverId');
    final list = res.data as List;
    return list.map((e) => TripSummary.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<TripSummary?> getTripById(String tripId) async {
    final res = await _dio.get('/api/trips/$tripId');
    return TripSummary.fromJson(res.data as Map<String, dynamic>);
  }

  Future<bool> updateStatus(String tripId, String status) async {
    try {
      await _dio.patch('/api/trips/$tripId/status', data: {'status': status});
      return true;
    } catch (_) {
      return false;
    }
  }
}