import 'package:dio/dio.dart';
import '../models/shipment.dart';
import 'api_client.dart';

// ─── Result types ────────────────────────────────────────────────────────────

class AcceptResult {
  final bool    success;
  final String? tripId;
  final String? message;
  const AcceptResult({required this.success, this.tripId, this.message});
}

class PassResult {
  final bool    success;
  final String? message;
  const PassResult({required this.success, this.message});
}

// ─── Current offer handed to this driver ────────────────────────────────────

class CurrentOffer {
  final String   shipmentQueueId;
  final String   shipmentId;
  final String   shipmentNumber;
  final String   pickupLocation;
  final String   dropLocation;
  final String   cargoType;
  final double   cargoWeightKg;
  final double?  agreedPrice;
  final bool     isUrgent;
  final DateTime? expiresAt;

  const CurrentOffer({
    required this.shipmentQueueId,
    required this.shipmentId,
    required this.shipmentNumber,
    required this.pickupLocation,
    required this.dropLocation,
    required this.cargoType,
    required this.cargoWeightKg,
    this.agreedPrice,
    required this.isUrgent,
    this.expiresAt,
  });

  factory CurrentOffer.fromJson(Map<String, dynamic> json) => CurrentOffer(
    shipmentQueueId : json['shipmentQueueId'] as String,
    shipmentId      : json['shipmentId']      as String,
    shipmentNumber  : json['shipmentNumber']  as String,
    pickupLocation  : json['pickupLocation']  as String,
    dropLocation    : json['dropLocation']    as String,
    cargoType       : json['cargoType']       as String,
    cargoWeightKg   : (json['cargoWeightKg']  as num).toDouble(),
    agreedPrice     : json['agreedPrice'] != null
                        ? (json['agreedPrice'] as num).toDouble()
                        : null,
    isUrgent        : json['isUrgent']        as bool,
    expiresAt       : json['expiresAt'] != null
                        ? DateTime.parse(json['expiresAt'] as String).toLocal()
                        : null,
  );

  Duration get timeRemaining {
    if (expiresAt == null) return Duration.zero;
    final diff = expiresAt!.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  bool get isExpired => timeRemaining == Duration.zero;
}

// ─── Queue slot ──────────────────────────────────────────────────────────────

class QueueSlot {
  final String       eventId;
  final String       eventStatus;
  final DateTime     eventEndTime;
  final int          position;
  final bool         hasClaimed;
  final String       offerStatus;  // idle | pending | accepted | passed | expired
  final CurrentOffer? currentOffer;

  const QueueSlot({
    required this.eventId,
    required this.eventStatus,
    required this.eventEndTime,
    required this.position,
    required this.hasClaimed,
    required this.offerStatus,
    this.currentOffer,
  });

  factory QueueSlot.fromJson(Map<String, dynamic> json) => QueueSlot(
    eventId      : json['eventId']      as String,
    eventStatus  : json['eventStatus']  as String,
    eventEndTime : DateTime.parse(json['eventEndTime'] as String),
    position     : json['position']     as int,
    hasClaimed   : json['hasClaimed']   as bool,
    offerStatus  : json['offerStatus']  as String,
    currentOffer : json['currentOffer'] != null
                     ? CurrentOffer.fromJson(json['currentOffer'] as Map<String, dynamic>)
                     : null,
  );

  bool get hasActiveOffer  => offerStatus == 'pending' && currentOffer != null;
  bool get isWindowOpen    => !hasClaimed && eventStatus == 'live';
}

// ─── Paged result (unchanged) ─────────────────────────────────────────────────

class PagedResult<T> {
  final List<T> items;
  final int     page;
  final int     totalPages;
  const PagedResult({required this.items, required this.page, required this.totalPages});

  factory PagedResult.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJson,
  ) => PagedResult(
    items      : (json['items'] as List).map((e) => fromJson(e as Map<String, dynamic>)).toList(),
    page       : json['page']       as int,
    totalPages : json['totalPages'] as int,
  );
}

// ─── API service ─────────────────────────────────────────────────────────────

class ShipmentApiService {
  final ApiClient _client;
  ShipmentApiService(this._client);
  Dio get _dio => _client.dio;

  Future<PagedResult<Shipment>> fetchQueue({int page = 1, int pageSize = 20}) async {
    final res = await _dio.get(
      '/api/shipment-queue',
      queryParameters: {'page': page, 'pageSize': pageSize},
    );
    return PagedResult.fromJson(res.data as Map<String, dynamic>, Shipment.fromJson);
  }

  /// Returns the driver's slot in the active QueueEvent, including their
  /// current highlighted offer (if any), or null if no event is live.
  Future<QueueSlot?> getMyQueueSlot(String driverId) async {
    try {
      final res = await _dio.get(
        '/api/queue-events/active',
        queryParameters: {'driverId': driverId},
      );
      final data = res.data as Map<String, dynamic>;
      if (data['active'] != true) return null;
      return QueueSlot.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  Future<AcceptResult> acceptShipment({
    required String shipmentQueueId,
    required String driverId,
  }) async {
    try {
      final res = await _dio.post(
        '/api/shipment-queue/$shipmentQueueId/accept',
        data: {'driverId': driverId},
      );
      final data = res.data as Map<String, dynamic>;
      return AcceptResult(
        success : data['success'] as bool,
        tripId  : data['tripId']  as String?,
        message : data['message'] as String?,
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        return const AcceptResult(success: false, message: 'Already taken by another driver.');
      }
      rethrow;
    }
  }

  Future<PassResult> passShipment({
    required String shipmentQueueId,
    required String driverId,
  }) async {
    try {
      final res = await _dio.post(
        '/api/shipment-queue/$shipmentQueueId/pass',
        data: {'driverId': driverId},
      );
      final data = res.data as Map<String, dynamic>;
      return PassResult(
        success : data['success'] as bool,
        message : data['message'] as String?,
      );
    } on DioException catch (e) {
      return PassResult(success: false, message: e.response?.data?['message'] as String? ?? 'Failed to pass.');
    }
  }

  Future<Shipment> getQueueItemById(String id) async {
    final res = await _dio.get('/api/shipment-queue/$id');
    return Shipment.fromJson(res.data as Map<String, dynamic>);
  }
}