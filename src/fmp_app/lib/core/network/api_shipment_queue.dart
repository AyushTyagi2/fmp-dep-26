import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../models/shipment.dart';
import 'api_client.dart';

// ─── DateTime helper ─────────────────────────────────────────────────────────

/// ASP.NET Core serializes DateTime without a timezone suffix (e.g.
/// "2026-03-25T05:28:53.412907"). Dart's DateTime.parse treats bare strings
/// as LOCAL time, which is wrong — the server always stores UTC.
/// Appending 'Z' forces correct UTC parsing before converting to local.
DateTime _parseUtc(String raw) {
  final normalized = raw.endsWith('Z') || raw.contains('+') ? raw : '${raw}Z';
  return DateTime.parse(normalized).toLocal();
}

// ─── Result types ────────────────────────────────────────────────────────────

class AcceptResult {
  final bool      success;
  // true when the shipment was taken by another driver (409 race-loss).
  // UI should flip the card to a grey "Taken" state instead of showing a red error.
  final bool      wasTaken;
  final String?   tripId;
  final String?   message;
  const AcceptResult({
    required this.success,
    this.wasTaken = false,
    this.tripId,
    this.message,
  });
}

class PassResult {
  final bool       success;
  final String?    message;
  // The driver's updated queue slot returned inline by the pass endpoint.
  // Applying this immediately avoids the "Waiting for offer" flash that would
  // otherwise appear between the pass response and the next poll.
  final QueueSlot? nextSlot;
  const PassResult({required this.success, this.message, this.nextSlot});
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
                        ? _parseUtc(json['expiresAt'] as String)
                        : null,
  );

  Duration get timeRemaining {
    if (expiresAt == null) return Duration.zero;
    final diff = expiresAt!.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  bool get isExpired => timeRemaining == Duration.zero;
}

// ─── Upcoming shipment preview (read-only, shown below active offer) ─────────

class UpcomingShipment {
  final String  shipmentQueueId;
  final String  shipmentNumber;
  final String  pickupLocation;
  final String  dropLocation;
  final double? agreedPrice;
  final bool    isUrgent;

  const UpcomingShipment({
    required this.shipmentQueueId,
    required this.shipmentNumber,
    required this.pickupLocation,
    required this.dropLocation,
    this.agreedPrice,
    required this.isUrgent,
  });

  factory UpcomingShipment.fromJson(Map<String, dynamic> json) => UpcomingShipment(
    shipmentQueueId : json['shipmentQueueId'].toString(),
    shipmentNumber  : json['shipmentNumber']  as String,
    pickupLocation  : json['pickupLocation']  as String,
    dropLocation    : json['dropLocation']    as String,
    agreedPrice     : json['agreedPrice'] != null
                        ? (json['agreedPrice'] as num).toDouble()
                        : null,
    isUrgent        : json['isUrgent'] as bool,
  );
}

// ─── Queue slot ──────────────────────────────────────────────────────────────

class QueueSlot {
  final String               eventId;
  final String               eventStatus;
  final DateTime             eventEndTime;
  final int                  position;
  final bool                 hasClaimed;
  final String               offerStatus;  // idle | pending | accepted | passed | expired
  final CurrentOffer?        currentOffer;
  final List<UpcomingShipment> upcomingShipments;

  const QueueSlot({
    required this.eventId,
    required this.eventStatus,
    required this.eventEndTime,
    required this.position,
    required this.hasClaimed,
    required this.offerStatus,
    this.currentOffer,
    this.upcomingShipments = const [],
  });

  factory QueueSlot.fromJson(Map<String, dynamic> json) {
    debugPrint('[QueueSlot.fromJson] raw: $json');
    return QueueSlot(
      eventId      : json['eventId'].toString(),
      eventStatus  : json['eventStatus'].toString(),
      eventEndTime : _parseUtc(json['eventEndTime'].toString()),
      position     : (json['position'] as num).toInt(),
      hasClaimed   : json['hasClaimed'] as bool,
      offerStatus  : json['offerStatus'].toString(),
      currentOffer : json['currentOffer'] != null
                       ? CurrentOffer.fromJson(json['currentOffer'] as Map<String, dynamic>)
                       : null,
      upcomingShipments: (json['upcomingShipments'] as List<dynamic>? ?? [])
          .map((e) => UpcomingShipment.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  // True when the driver has an offer card to display — either an active pending
  // offer or an expired-but-still-claimable one (currentOffer must be present).
  bool get hasActiveOffer    => (offerStatus == 'pending' || offerStatus == 'expired')
                                 && currentOffer != null;
  // Open when the event is live and driver is waiting for their next offer.
  // Includes expired-with-no-offer: their window closed but no new shipment has
  // been matched yet — show the waiting placeholder, not "Queue is closed".
  bool get isWindowOpen      => eventStatus == 'live' &&
      (offerStatus == 'idle' ||
       offerStatus == 'passed' ||
       (offerStatus == 'expired' && currentOffer == null));
  // True if the driver has already accepted a shipment in this event
  bool get hasAlreadyClaimed => hasClaimed || offerStatus == 'accepted';
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

  Future<QueueSlot?> getMyQueueSlot(String driverId) async {
    final res = await _dio.get(
      '/api/queue-events/active',
      queryParameters: {'driverId': driverId},
    );
    final data = res.data as Map<String, dynamic>;
    // Backend returns { active: false } when no live event exists
    if (data['active'] != true) return null;
    return QueueSlot.fromJson(data);
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
        return const AcceptResult(
          success  : false,
          wasTaken : true,
          message  : 'Already taken by another driver.',
        );
      }
      // For any other HTTP error (400, 500, timeout, etc.) return a clean
      // AcceptResult so the caller always reaches setState(() => _accepting = false).
      final msg = (e.response?.data as Map<String, dynamic>?)?['message'] as String?
          ?? e.message
          ?? 'Could not accept shipment. Please try again.';
      debugPrint('[acceptShipment] DioException ${e.response?.statusCode}: $msg');
      return AcceptResult(success: false, message: msg);
    } catch (e) {
      debugPrint('[acceptShipment] unexpected error: $e');
      return const AcceptResult(success: false, message: 'Network error. Please try again.');
    }
  }

  Future<PassResult> passShipment({
    required String shipmentQueueId,
    required String driverId,
  }) async {
    try {
      final res  = await _dio.post(
        '/api/shipment-queue/$shipmentQueueId/pass',
        data: {'driverId': driverId},
      );
      final data = res.data as Map<String, dynamic>;

      // The backend returns { success, message, nextSlot? }.
      // nextSlot is the driver's updated queue slot after the pass; applying it
      // immediately lets Flutter skip the "Waiting for offer" spinner entirely.
      QueueSlot? nextSlot;
      final rawSlot = data['nextSlot'];
      if (rawSlot != null && rawSlot is Map<String, dynamic> && rawSlot['active'] == true) {
        debugPrint('[passShipment] nextSlot present — applying inline');
        nextSlot = QueueSlot.fromJson(rawSlot);
      }

      return PassResult(
        success  : data['success'] as bool,
        message  : data['message'] as String?,
        nextSlot : nextSlot,
      );
    } on DioException catch (e) {
      return PassResult(
        success : false,
        message : e.response?.data?['message'] as String? ?? 'Failed to pass.',
      );
    }
  }

  Future<Shipment> getQueueItemById(String id) async {
    final res = await _dio.get('/api/shipment-queue/$id');
    return Shipment.fromJson(res.data as Map<String, dynamic>);
  }

  // ── Queue live-status (union toggle) ───────────────────────────────────────

  /// Returns { isLive: bool, eventId: String?, endTime: String? }
  Future<Map<String, dynamic>> getQueueLiveStatus() async {
  debugPrint('[getQueueLiveStatus] → GET /api/queue-events/live-status');
  try {
    final res = await _dio.get('/api/queue-events/live-status');
    debugPrint('[getQueueLiveStatus] ← status: ${res.statusCode}');
    debugPrint('[getQueueLiveStatus] ← body: ${res.data}');
    final data = res.data as Map<String, dynamic>;
    debugPrint('[getQueueLiveStatus] eventId=${data['eventId']}  isLive=${data['isLive']}');
    return data;
  } on DioException catch (e) {
    debugPrint('[getQueueLiveStatus] ❌ DioException — '
        'status: ${e.response?.statusCode}  body: ${e.response?.data}  msg: ${e.message}');
    rethrow;
  } catch (e) {
    debugPrint('[getQueueLiveStatus] ❌ Unexpected error: $e');
    rethrow;
  }
}

  /// Toggles the given queue event live ↔ closed.
  /// Returns the updated status map.
  Future<Map<String, dynamic>> toggleQueueEvent(String eventId) async {
    final res = await _dio.post('/api/queue-events/$eventId/toggle');
    return res.data as Map<String, dynamic>;
  }
}