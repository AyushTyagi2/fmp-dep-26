import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../models/shipment.dart';
import 'api_client.dart';

// ─── DateTime helper ──────────────────────────────────────────────────────────
//
// Always normalise to local time so countdown arithmetic is correct.
// A bare timestamp with no zone suffix is treated as UTC (backend contract).

DateTime _parseUtc(String raw) {
  final normalized = raw.endsWith('Z') || raw.contains('+') ? raw : '${raw}Z';
  return DateTime.parse(normalized).toLocal();
}

// ─── Result types ─────────────────────────────────────────────────────────────

class AcceptResult {
  final bool    success;
  final bool    wasTaken;   // true on HTTP 409 — race loss
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
  final QueueSlot? nextSlot; // backend returns updated slot inline on pass
  const PassResult({required this.success, this.message, this.nextSlot});
}

// ─── ShipmentSlotItem ─────────────────────────────────────────────────────────
//
// One entry in the driver's ordered shipment list.
//
// Per the queue tuple contract:
//   acceptedByOther = true  → shipment was taken; show struck-out / greyed card
//   isExpired       = true  → driver's primary window closed; still claimable
//   expiresAt       != null → active window is live; countdown until this time
//   expiresAt       == null && !isExpired → locked (up-next, not yet offered)
//
// The backend is the source of truth for isExpired.
// The frontend NEVER derives isExpired from expiresAt reaching zero —
// that would create a race between the countdown timer and the next poll.
// Instead: when the countdown hits zero the UI shows "Expired" optimistically,
// and the next poll confirms the real state.

class ShipmentSlotItem {
  final String    shipmentQueueId;
  final String    shipmentId;
  final String    shipmentNumber;
  final String    pickupLocation;
  final String    dropLocation;
  final String    cargoType;
  final double    cargoWeightKg;
  final double?   agreedPrice;
  final bool      isUrgent;

  /// Backend-authoritative: true when the driver's window for this slot closed.
  /// Must be accompanied by a past (or null) expiresAt.
  final bool      isExpired;

  /// Set by another driver accepting this shipment.
  /// When true the slot is shown as "Taken" and both buttons are hidden.
  final bool      acceptedByOther;

  /// Non-null while the slot is active (claimable and not yet expired).
  /// Null for locked slots and — critically — should NOT be null for expired
  /// slots; the past timestamp must be preserved so the UI can show elapsed time.
  final DateTime? expiresAt;

  const ShipmentSlotItem({
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
    required this.acceptedByOther,
    this.expiresAt,
  });

  factory ShipmentSlotItem.fromJson(Map<String, dynamic> json) {
    // ── Defensive field extraction ──────────────────────────────────────────
    // acceptedByOther may be absent in older backend versions; default false.
    final acceptedByOther = json['acceptedByOther'] as bool? ?? false;

    // isExpired: use backend flag directly.
    // Fallback: if the flag is absent but expiresAt is a past timestamp,
    // treat as expired — this covers backends that omit the field.
    bool isExpired = json['isExpired'] as bool? ?? false;
    DateTime? expiresAt;
    if (json['expiresAt'] != null) {
      expiresAt = _parseUtc(json['expiresAt'] as String);
      if (!isExpired && expiresAt.isBefore(DateTime.now())) {
        // Backend forgot to set isExpired=true despite the window closing.
        isExpired = true;
        debugPrint('[ShipmentSlotItem] corrected isExpired for ${json['shipmentQueueId']}: expiresAt=$expiresAt is in the past');
      }
    }

    return ShipmentSlotItem(
      shipmentQueueId : json['shipmentQueueId'].toString(),
      shipmentId      : json['shipmentId'].toString(),
      shipmentNumber  : json['shipmentNumber']  as String,
      pickupLocation  : json['pickupLocation']  as String,
      dropLocation    : json['dropLocation']    as String,
      cargoType       : json['cargoType']       as String,
      cargoWeightKg   : (json['cargoWeightKg']  as num).toDouble(),
      agreedPrice     : json['agreedPrice'] != null
                          ? (json['agreedPrice'] as num).toDouble()
                          : null,
      isUrgent        : json['isUrgent']       as bool? ?? false,
      isExpired       : isExpired,
      acceptedByOther : acceptedByOther,
      expiresAt       : expiresAt,
    );
  }

  /// True while the driver's claim window is live and the timer is running.
  bool get hasActiveTimer => !isExpired && !acceptedByOther && expiresAt != null;

  /// Remaining time in the current window. Zero if expired or no timer.
  Duration get timeRemaining {
    if (expiresAt == null) return Duration.zero;
    final diff = expiresAt!.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  /// True if the slot can still be actioned (claimable but window closed).
  /// These show the amber "Still Claimable" + "Claim Now" UI.
  bool get isStillClaimable => isExpired && !acceptedByOther;

  /// True if the slot is in the offer pool (active or expired-claimable)
  /// but was taken by a competing driver before this driver acted.
  bool get wasTakenByOther => acceptedByOther;
}

// ─── QueueSlot ────────────────────────────────────────────────────────────────
//
// Corresponds to the backend's ActiveEventDto.
//
// The `claimableCount` field is the boundary:
//   slots[0 ..< claimableCount]   → in the offer window (active or expired-claimable)
//   slots[claimableCount ..< end]  → locked / up-next
//
// This matches the tuple semantics in the plan:
//   <json<shipmentN, bool>, claimableCount>
//   where bool = acceptedByOther for each slot.

class QueueSlot {
  final String                 eventId;
  final String                 eventStatus;
  final DateTime               eventEndTime;
  final int                    position;
  final bool                   hasClaimed;
  final int                    claimableCount;
  final List<ShipmentSlotItem> shipmentSlots;

  const QueueSlot({
    required this.eventId,
    required this.eventStatus,
    required this.eventEndTime,
    required this.position,
    required this.hasClaimed,
    required this.claimableCount,
    this.shipmentSlots = const [],
  });

  factory QueueSlot.fromJson(Map<String, dynamic> json) {
    debugPrint('[QueueSlot.fromJson] keys=${json.keys.toList()} '
        'active=${json['active']} claimableCount=${json['claimableCount']}');

    // ── Guard: backend must send active=true for this to be called ──────────
    // If active is missing or false, the API layer returns null before calling
    // fromJson, so this assertion is a safety net only.
    assert(json['active'] == true,
        '[QueueSlot.fromJson] called with active != true — caller should return null');

    return QueueSlot(
      eventId        : json['eventId'].toString(),
      eventStatus    : json['eventStatus']?.toString() ?? 'unknown',
      eventEndTime   : _parseUtc(json['eventEndTime'].toString()),
      position       : (json['position']      as num?)?.toInt() ?? 0,
      hasClaimed     : json['hasClaimed']      as bool? ?? false,
      claimableCount : (json['claimableCount'] as num?)?.toInt() ?? 0,
      shipmentSlots  : (json['shipmentSlots'] as List<dynamic>? ?? [])
          .map((e) => ShipmentSlotItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  // ── Slot partitions ────────────────────────────────────────────────────────

  /// All slots in the offer window (index < claimableCount).
  /// May include both active-timer slots and expired-claimable slots.
  List<ShipmentSlotItem> get claimableSlots =>
      shipmentSlots.take(claimableCount).toList();

  /// The slot whose countdown timer is currently live.
  /// Per the plan this is the LAST claimable slot that is not yet expired
  /// (D1's window is always the most recently opened one).
  ShipmentSlotItem? get activeWindowSlot {
    // Prefer the last non-expired claimable slot (newest window).
    for (int i = claimableSlots.length - 1; i >= 0; i--) {
      final s = claimableSlots[i];
      if (!s.isExpired && !s.acceptedByOther) return s;
    }
    return null;
  }

  /// Slots that had an active window which has now closed but are still
  /// actionable (the amber "Still Claimable" cards).
  List<ShipmentSlotItem> get stillClaimableSlots =>
      claimableSlots.where((s) => s.isStillClaimable).toList();

  /// Slots not yet in any driver's offer window (locked / up-next preview).
  List<ShipmentSlotItem> get upcomingSlots =>
      shipmentSlots.skip(claimableCount).toList();

  // ── State flags ────────────────────────────────────────────────────────────

  /// True if there is at least one slot the driver can act on.
  /// This is the PRIMARY visibility gate — the offer area is shown whenever
  /// this is true, regardless of timer state.
  bool get hasActiveOffer => claimableCount > 0 && claimableSlots.isNotEmpty;

  /// True if the event is live but no offer has arrived yet.
  bool get isWaiting => eventStatus == 'live' && claimableCount == 0 && !hasClaimed;

  /// True if the driver has already claimed a shipment in this event.
  bool get hasAlreadyClaimed => hasClaimed;

  // ── Debug ──────────────────────────────────────────────────────────────────
  @override
  String toString() =>
      'QueueSlot(pos=$position status=$eventStatus claimable=$claimableCount '
      'slots=${shipmentSlots.length} hasClaimed=$hasClaimed)';
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

// ─── API service ──────────────────────────────────────────────────────────────

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

  /// GET /api/queue-events/active?driverId=
  ///
  /// Returns null in two cases:
  ///   1. active=false or missing — no event running
  ///   2. active=true but the response is malformed — logged as error
  ///
  /// Never returns null just because claimableCount=0; that is the
  /// "waiting for offer" state which is perfectly valid.
  Future<QueueSlot?> getMyQueueSlot(String driverId) async {
    final res  = await _dio.get(
      '/api/queue-events/active',
      queryParameters: {'driverId': driverId},
    );
    final data = res.data;

    // ── Defensive: handle non-map responses ──────────────────────────────────
    if (data is! Map<String, dynamic>) {
      debugPrint('[getMyQueueSlot] unexpected response type: ${data.runtimeType}');
      return null;
    }

    final active = data['active'];
    debugPrint('[getMyQueueSlot] active=$active '
        'claimableCount=${data['claimableCount']} '
        'slots=${(data['shipmentSlots'] as List?)?.length ?? 0}');

    // ── active=false → no event → caller shows _NoEventState ────────────────
    if (active != true) return null;

    // ── active=true → parse and return ──────────────────────────────────────
    try {
      return QueueSlot.fromJson(data);
    } catch (e, st) {
      debugPrint('[getMyQueueSlot] parse error: $e\n$st');
      // Return null so the UI shows an error rather than crashing.
      return null;
    }
  }

  /// POST /api/shipment-queue/:id/accept
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
        success : data['success'] as bool? ?? false,
        tripId  : data['tripId']  as String?,
        message : data['message'] as String?,
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        // Race loss — another driver claimed this slot first.
        debugPrint('[acceptShipment] 409 race loss for $shipmentQueueId');
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
    } catch (e, st) {
      debugPrint('[acceptShipment] unexpected: $e\n$st');
      return const AcceptResult(success: false, message: 'Network error. Please try again.');
    }
  }

  /// POST /api/shipment-queue/:id/pass
  ///
  /// The backend may return a nextSlot inline so the UI skips the
  /// "Waiting" flash and goes straight to the next offer.
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
      if (rawSlot is Map<String, dynamic> && rawSlot['active'] == true) {
        debugPrint('[passShipment] nextSlot inline — applying immediately');
        try {
          nextSlot = QueueSlot.fromJson(rawSlot);
        } catch (e) {
          debugPrint('[passShipment] nextSlot parse failed: $e');
        }
      }

      return PassResult(
        success  : data['success'] as bool? ?? true,
        message  : data['message'] as String?,
        nextSlot : nextSlot,
      );
    } on DioException catch (e) {
      debugPrint('[passShipment] DioException ${e.response?.statusCode}');
      return PassResult(
        success : false,
        message : (e.response?.data as Map<String, dynamic>?)?['message'] as String?
            ?? 'Failed to pass.',
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
      debugPrint('[getQueueLiveStatus] eventId=${data['eventId']} isLive=${data['isLive']}');
      return data;
    } on DioException catch (e) {
      debugPrint('[getQueueLiveStatus] ❌ ${e.response?.statusCode}: ${e.message}');
      rethrow;
    }
  }

  Future<void> createQueueEvent({
    required double durationHours,
    required int    windowSeconds,
    required String priorityRule,
    String?         zoneId,
  }) async {
    try {
      await _dio.post(
        '/api/queue-events',
        data: {
          'durationHours' : durationHours,
          'windowSeconds' : windowSeconds,
          'priorityRule'  : priorityRule,
          if (zoneId != null) 'zoneId': zoneId,
        },
      );
    } on DioException catch (e) {
      String msg = 'Failed to create queue event. Please try again.';
      final data = e.response?.data;
      if (data is Map && data['message'] is String) {
        msg = data['message'] as String;
      } else if (e.response?.statusCode == 409) {
        msg = 'A queue event is already active.';
      }
      debugPrint('[createQueueEvent] ❌ ${e.response?.statusCode}: $msg');
      throw Exception(msg);
    } catch (e) {
      final raw = e.toString().replaceFirst('Exception: ', '').trim();
      throw Exception(raw.isEmpty ? 'Unexpected error. Please try again.' : raw);
    }
  }

  Future<Map<String, dynamic>> toggleQueueEvent(String eventId) async {
    final res = await _dio.post('/api/queue-events/$eventId/toggle');
    return res.data as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> getAllQueueEvents() async {
    final res  = await _dio.get('/api/queue-events');
    final data = res.data;
    if (data is List) return data.cast<Map<String, dynamic>>();
    if (data is Map<String, dynamic> && data['items'] is List) {
      return (data['items'] as List).cast<Map<String, dynamic>>();
    }
    return [];
  }
}