import 'package:dio/dio.dart';
import 'api_client.dart';

class TripSummary {
  final String id;
  final String tripNumber;
  final String shipmentId;
  final String shipmentNumber;
  final String currentStatus;
  final double? agreedPrice;
  final DateTime createdAt;
  final String senderName;
  final String receiverName;
  final DateTime? plannedStartTime;
  final DateTime? plannedEndTime;
  final DateTime? actualStartTime;
  final DateTime? deliveredAt;
  final double? driverPaymentAmount;
  final String driverPaymentStatus;
  final bool hasIssues;
  final String? issueDescription;
  final String? deliveredToName;

  const TripSummary({
    required this.id,
    required this.tripNumber,
    required this.shipmentId,
    required this.shipmentNumber,
    required this.currentStatus,
    this.agreedPrice,
    required this.createdAt,
    required this.senderName,
    required this.receiverName,
    this.plannedStartTime,
    this.plannedEndTime,
    this.actualStartTime,
    this.deliveredAt,
    this.driverPaymentAmount,
    required this.driverPaymentStatus,
    required this.hasIssues,
    this.issueDescription,
    this.deliveredToName,
  });

factory TripSummary.fromJson(Map<String, dynamic> json) {
  print('>>> RAW TRIP JSON: $json'); // remove after debugging
  return TripSummary(
    id:                  (json['id']                  as String?) ?? '',
    tripNumber:          (json['tripNumber']           as String?) ?? '',
    shipmentId:          (json['shipmentId']           as String?) ?? '',
    shipmentNumber:      (json['shipmentNumber']       as String?) ?? '',
    currentStatus:       (json['currentStatus']        as String?) ?? 'unknown',
    agreedPrice:         (json['driverPaymentAmount']  as num?)?.toDouble(),
    createdAt:           json['createdAt'] != null
                           ? DateTime.parse(json['createdAt'] as String)
                           : DateTime.now(),
    senderName:          (json['senderName']           as String?) ?? '',
    receiverName:        (json['receiverName']         as String?) ?? '',
    plannedStartTime:    json['plannedStartTime']  != null
                           ? DateTime.parse(json['plannedStartTime'] as String) : null,
    plannedEndTime:      json['plannedEndTime']    != null
                           ? DateTime.parse(json['plannedEndTime']   as String) : null,
    actualStartTime:     json['actualStartTime']   != null
                           ? DateTime.parse(json['actualStartTime']  as String) : null,
    deliveredAt:         json['deliveredAt']       != null
                           ? DateTime.parse(json['deliveredAt']      as String) : null,
    driverPaymentAmount: (json['driverPaymentAmount']  as num?)?.toDouble(),
    driverPaymentStatus: (json['driverPaymentStatus']  as String?) ?? 'pending',
    hasIssues:           (json['hasIssues']            as bool?)  ?? false,
    issueDescription:     json['issueDescription']     as String?,
    deliveredToName:      json['deliveredToName']      as String?,
  );
}
}

class TripApiService {
  final ApiClient _client;
  TripApiService(this._client);
  Dio get _dio => _client.dio;

  Future<List<TripSummary>> getDriverTrips(String driverId) async {
  final url = '/api/trips/driver/$driverId';
  print('>>> CALLING: ${_dio.options.baseUrl}$url');
  print('>>> driverId: "$driverId" (length: ${driverId.length})');
  
  try {
    final res = await _dio.get(url);
    print('>>> STATUS: ${res.statusCode}');
    final list = res.data as List;
    return list.map((e) => TripSummary.fromJson(e as Map<String, dynamic>)).toList();
  } on DioException catch (e) {
    print('>>> 404 URL was: ${e.requestOptions.uri}');
    print('>>> Response body: ${e.response?.data}');
    rethrow;
  }
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