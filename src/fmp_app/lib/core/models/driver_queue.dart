// lib/core/models/driver_queue.dart
//
// Models for the driver queue screen, matching the backend's ActiveEventDto.
//
// Backend shape (GET /api/queue-events/active?driverId=):
//   {
//     active: bool,
//     eventId, eventStatus, eventEndTime, position, hasClaimed,
//     claimableCount: int,
//     shipmentSlots: [
//       {
//         shipmentQueueId, shipmentId, shipmentNumber,
//         pickupLocation, dropLocation,
//         cargoType, cargoWeightKg, agreedPrice, isUrgent,
//         isExpired: bool,
//         expiresAt: string?   // null = locked (up next) or no active timer
//       }
//     ]
//   }
//
// UI rules (driven by index vs claimableCount):
//   index < claimableCount && !isExpired && expiresAt != null  → active offer, countdown
//   index < claimableCount && isExpired                        → amber "Still Claimable"
//   index >= claimableCount                                    → locked "Up Next"

import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../models/shipment.dart';
import '../network/api_client.dart';

// ─── DateTime helper ─────────────────────────────────────────────────────────

DateTime _parseUtc(String raw) {
  final normalized = raw.endsWith('Z') || raw.contains('+') ? raw : '${raw}Z';
  return DateTime.parse(normalized).toLocal();
}

// ─── Result types ────────────────────────────────────────────────────────────

class AcceptResult {
  final bool    success;
  final bool    wasTaken;
  final String? tripId;
  final String? message;
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
  final QueueSlot? nextSlot;
  const PassResult({required this.success, this.message, this.nextSlot});
}

// ─── ShipmentSlot ─────────────────────────────────────────────────────────────

class ShipmentSlot {
  final String    shipmentQueueId;
  final String    shipmentId;
  final String    shipmentNumber;
  final String    pickupLocation;
  final String    dropLocation;
  final String    cargoType;
  final double    cargoWeightKg;
  final double?   agreedPrice;
  final bool      isUrgent;
  final bool      isExpired;
  final DateTime? expiresAt;

  const ShipmentSlot({
    required this.shipmentQueueId,
    required this.shipmentId,
    required this.shipmentNumber,
    required this.pickupLocation,
    required this.dropLocation,
    required this.cargoType,
    required this.cargoWeightKg,
    this.agreedPrice,
    required this.isUrgent,
    required this.isExpired,
    this.expiresAt,
  });

  factory ShipmentSlot.fromJson(Map<String, dynamic> json) => ShipmentSlot(
    shipmentQueueId : json['shipmentQueueId'].toString(),
    shipmentId      : json['shipmentId'].toString(),
    shipmentNumber  : json['shipmentNumber'] as String,
    pickupLocation  : json['pickupLocation'] as String,
    dropLocation    : json['dropLocation']   as String,
    cargoType       : json['cargoType']      as String,
    cargoWeightKg   : (json['cargoWeightKg'] as num).toDouble(),
    agreedPrice     : json['agreedPrice'] != null
                        ? (json['agreedPrice'] as num).toDouble()
                        : null,
    isUrgent  : json['isUrgent']  as bool,
    isExpired : json['isExpired'] as bool,
    expiresAt : json['expiresAt'] != null
                  ? _parseUtc(json['expiresAt'] as String)
                  : null,
  );

  bool get hasActiveTimer => !isExpired && expiresAt != null;

  Duration get timeRemaining {
    if (expiresAt == null) return Duration.zero;
    final diff = expiresAt!.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }
}

// ─── QueueSlot ────────────────────────────────────────────────────────────────

class QueueSlot {
  final String             eventId;
  final String             eventStatus;
  final DateTime           eventEndTime;
  final int                position;
  final bool               hasClaimed;
  final int                claimableCount;
  final List<ShipmentSlot> shipmentSlots;

  const QueueSlot({
    required this.eventId,
    required this.eventStatus,
    required this.eventEndTime,
    required this.position,
    required this.hasClaimed,
    required this.claimableCount,
    required this.shipmentSlots,
  });

  factory QueueSlot.fromJson(Map<String, dynamic> json) {
    debugPrint('[QueueSlot.fromJson] raw: $json');
    return QueueSlot(
      eventId        : json['eventId'].toString(),
      eventStatus    : json['eventStatus'].toString(),
      eventEndTime   : _parseUtc(json['eventEndTime'].toString()),
      position       : (json['position']       as num).toInt(),
      hasClaimed     : json['hasClaimed']       as bool,
      claimableCount : (json['claimableCount']  as num).toInt(),
      shipmentSlots  : (json['shipmentSlots']   as List<dynamic>? ?? [])
          .map((e) => ShipmentSlot.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  ShipmentSlot? get activeOffer {
    if (claimableCount <= 0) return null;
    final claimable = shipmentSlots.take(claimableCount).toList();
    final active = claimable.where((s) => s.hasActiveTimer).toList();
    if (active.isNotEmpty) return active.first;
    final expired = claimable.where((s) => s.isExpired).toList();
    return expired.isNotEmpty ? expired.first : claimable.firstOrNull;
  }

  List<ShipmentSlot> get upcomingSlots =>
      claimableCount < shipmentSlots.length
          ? shipmentSlots.sublist(claimableCount)
          : [];

  String get offerStatus {
    if (hasClaimed) return 'accepted';
    if (claimableCount == 0) return 'idle';
    final offer = activeOffer;
    if (offer == null) return 'idle';
    if (offer.isExpired) return 'expired';
    return 'pending';
  }

  bool get hasActiveOffer    => activeOffer != null;
  bool get isWindowOpen      => eventStatus == 'live' && !hasClaimed && claimableCount == 0;
  bool get hasAlreadyClaimed => hasClaimed;
}

// ─── Paged result ─────────────────────────────────────────────────────────────

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
    final res  = await _dio.get(
      '/api/queue-events/active',
      queryParameters: {'driverId': driverId},
    );
    final data = res.data as Map<String, dynamic>;
    if (data['active'] != true) return null;
    return QueueSlot.fromJson(data);
  }

  Future<AcceptResult> acceptShipment({
    required String shipmentQueueId,
    required String driverId,
  }) async {
    try {
      final res  = await _dio.post(
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

      QueueSlot? nextSlot;
      final rawSlot = data['nextSlot'];
      if (rawSlot != null && rawSlot is Map<String, dynamic> && rawSlot['active'] == true) {
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

  Future<Map<String, dynamic>> getQueueLiveStatus() async {
    debugPrint('[getQueueLiveStatus] → GET /api/queue-events/live-status');
    try {
      final res  = await _dio.get('/api/queue-events/live-status');
      final data = res.data as Map<String, dynamic>;
      debugPrint('[getQueueLiveStatus] eventId=${data['eventId']}  isLive=${data['isLive']}');
      return data;
    } on DioException catch (e) {
      debugPrint('[getQueueLiveStatus] ❌ ${e.response?.statusCode}: ${e.message}');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> toggleQueueEvent(String eventId) async {
    final res = await _dio.post('/api/queue-events/$eventId/toggle');
    return res.data as Map<String, dynamic>;
  }

  /// POST /api/queue-events — seeds a brand-new queue event in the DB.
  /// [durationHours]  how long the event runs (e.g. 2.0)
  /// [windowSeconds]  per-driver claim window (e.g. 120)
  /// [zoneId]         optional zone restriction
  Future<Map<String, dynamic>> createQueueEvent({
    required double durationHours,
    required int    windowSeconds,
    String?         zoneId,
  }) async {
    debugPrint('[createQueueEvent] durationHours=$durationHours windowSeconds=$windowSeconds zoneId=$zoneId');
    try {
      final res = await _dio.post(
        '/api/queue-events',
        data: {
          'durationHours' : durationHours,
          'windowSeconds' : windowSeconds,
          if (zoneId != null) 'zoneId': zoneId,
        },
      );
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      debugPrint('[createQueueEvent] ❌ ${e.response?.statusCode}: ${e.message}');
      rethrow;
    }
  }
}