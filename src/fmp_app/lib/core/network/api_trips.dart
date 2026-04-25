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

  factory TripSummary.fromJson(Map<String, dynamic> json) => TripSummary(
    id:                   json['id']             as String,
    tripNumber:           json['tripNumber']     as String,
    shipmentId:           json['shipmentId']     as String,
    shipmentNumber:       json['shipmentNumber'] as String,
    currentStatus:        json['currentStatus']  as String,
    agreedPrice:          (json['agreedPrice']   as num?)?.toDouble(),
    createdAt:            DateTime.parse(json['createdAt'] as String),
    senderName:           json['senderName']     ?? '',
    receiverName:         json['receiverName']   ?? '',
    plannedStartTime:     json['plannedStartTime']  != null ? DateTime.parse(json['plannedStartTime']) : null,
    plannedEndTime:       json['plannedEndTime']    != null ? DateTime.parse(json['plannedEndTime'])   : null,
    actualStartTime:      json['actualStartTime']   != null ? DateTime.parse(json['actualStartTime'])  : null,
    deliveredAt:          json['deliveredAt']       != null ? DateTime.parse(json['deliveredAt'])       : null,
    driverPaymentAmount:  (json['driverPaymentAmount'] as num?)?.toDouble(),
    driverPaymentStatus:  json['driverPaymentStatus'] ?? 'pending',
    hasIssues:            json['hasIssues']      ?? false,
    issueDescription:     json['issueDescription'] as String?,
    deliveredToName:      json['deliveredToName']   as String?,
  );
}

class TripApiService {
  final ApiClient _client;
  TripApiService(this._client);
  Dio get _dio => _client.dio;

  Future<List<TripSummary>> getDriverTrips(String driverId) async {
  final res = await _dio.get('/api/trips/driver/$driverId');
  final list = res.data as List;
  // TEMP DEBUG
  if (list.isNotEmpty) {
    print('TRIP JSON KEYS: ${(list.first as Map<String, dynamic>).keys.toList()}');
    print('senderName: ${(list.first as Map<String, dynamic>)['senderName']}');
    print('receiverName: ${(list.first as Map<String, dynamic>)['receiverName']}');
  }
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