import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fmp_app/app_session.dart';
import 'package:fmp_app/core/network/api_client.dart';
import 'package:fmp_app/core/network/api_shipment_queue.dart';

// lib/presentation/driver/queue/driver_queue_screen.dart
//
// ── Queue contract (matches plan) ────────────────────────────────────────────
//
// Each driver holds a tuple: <List<{shipment, acceptedByOther}>, claimableCount>
//
//   claimableCount == 0          → waiting for first offer
//   claimableCount == 1          → one active window (countdown live)
//   claimableCount == N > 1      → N-1 expired-but-claimable + 1 live window
//                                  driver can accept ANY of the N shipments
//   slot.acceptedByOther == true → that shipment was taken; show greyed card
//
// The UI renders one card per claimable slot, stacked vertically.
// The driver taps Accept on whichever shipment they want.
//
// ── Visibility rules ─────────────────────────────────────────────────────────
//
//   hasActiveOffer  → show offer cards  (claimableCount > 0)
//   isWaiting       → show waiting placeholder
//   hasAlreadyClaimed → show "Shipment accepted" state
//   else            → show "Queue Closed"
//
// Note: the "Queue Closed" state is only reached when _slot == null (no active
// event) OR when eventStatus != 'live' AND none of the above flags are set.
// It must NOT be shown just because claimableCount == 0 while eventStatus == 'live'.

class DriverQueueScreen extends StatefulWidget {
  const DriverQueueScreen({super.key});

  @override
  State<DriverQueueScreen> createState() => _DriverQueueScreenState();
}

class _DriverQueueScreenState extends State<DriverQueueScreen> {
  final _apiClient = ApiClient();
  late final ShipmentApiService _api;

  QueueSlot? _slot;
  bool       _loading   = true;
  String?    _error;
  bool       _accepting = false;
  bool       _passing   = false;
  Timer?     _pollTimer;
  Timer?     _countdownTimer;
  Duration   _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _api = ShipmentApiService(_apiClient);
    _refresh();
    // Poll every 3 s so the list of accepted shipments and claimableCount
    // stay in sync without requiring push notifications.
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) => _refresh());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  // ── Data refresh ──────────────────────────────────────────────────────────

  Future<void> _refresh() async {
    final driverId = AppSession.driverId;
    if (driverId == null) {
      if (mounted) {
        setState(() {
          _error   = 'No driver session. Please log in again.';
          _loading = false;
        });
      }
      return;
    }
    try {
      final slot = await _api.getMyQueueSlot(driverId);
      if (!mounted) return;

      debugPrint('[Queue] refresh: ${slot == null ? "no active event" : slot.toString()}');

      setState(() {
        _slot    = slot;
        _loading = false;
        _error   = null;
      });

      // Start countdown for whichever slot currently has a live window.
      _startCountdown(slot?.activeWindowSlot?.expiresAt);
    } catch (e, st) {
      debugPrint('[Queue] refresh error: $e\n$st');
      if (mounted) {
        setState(() {
          _error   = 'Connection error. Please retry.';
          _loading = false;
        });
      }
    }
  }

  // ── Countdown timer ────────────────────────────────────────────────────────
  //
  // Drives only the visual countdown chip. Authoritative expiry state always
  // comes from the backend via _refresh(); the timer is display-only.

  void _startCountdown(DateTime? expiresAt) {
    _countdownTimer?.cancel();
    if (expiresAt == null) {
      if (mounted) setState(() => _remaining = Duration.zero);
      return;
    }

    void tick() {
      final rem = expiresAt.difference(DateTime.now());
      if (mounted) setState(() => _remaining = rem.isNegative ? Duration.zero : rem);
    }

    tick(); // paint immediately without waiting 1 s
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      tick();
      if (expiresAt.isBefore(DateTime.now())) _countdownTimer?.cancel();
    });
  }

  // ── Accept ────────────────────────────────────────────────────────────────
  //
  // The driver taps Accept on a specific shipment card.
  // shipmentQueueId identifies which shipment they chose.

  Future<void> _acceptSlot(ShipmentSlotItem offer) async {
    final driverId = AppSession.driverId;
    if (driverId == null) return;

    setState(() => _accepting = true);
    try {
      final result = await _api.acceptShipment(
        shipmentQueueId: offer.shipmentQueueId,
        driverId: driverId,
      );
      if (!mounted) return;
      setState(() => _accepting = false);

      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Shipment accepted! Trip created.'),
            backgroundColor: Color(0xFF0E9F6E),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pushReplacementNamed(context, '/driver-dashboard');

      } else if (result.wasTaken) {
        // 409 race loss — mark this slot as takenByOther optimistically
        // then refresh so the backend's updated tuple is applied.
        debugPrint('[Queue] accept: race lost on ${offer.shipmentQueueId}');
        _refresh();

      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message ?? 'Could not accept shipment'),
            backgroundColor: const Color(0xFFE02424),
            behavior: SnackBarBehavior.floating,
          ),
        );
        _refresh();
      }
    } catch (e, st) {
      debugPrint('[Queue] accept unexpected error: $e\n$st');
      if (!mounted) return;
      setState(() => _accepting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Network error. Please try again.'),
          backgroundColor: Color(0xFFE02424),
          behavior: SnackBarBehavior.floating,
        ),
      );
      _refresh();
    }
  }

  // ── Pass ──────────────────────────────────────────────────────────────────
  //
  // Driver passes their CURRENT active window slot.
  // Per the plan: driver2's tuple is then updated to include that shipment
  // and a new window opens for the passing driver.

  Future<void> _passSlot(ShipmentSlotItem offer) async {
    final driverId = AppSession.driverId;
    if (driverId == null) return;

    setState(() => _passing = true);
    try {
      final result = await _api.passShipment(
        shipmentQueueId: offer.shipmentQueueId,
        driverId: driverId,
      );
      if (!mounted) return;

      if (result.nextSlot != null) {
        // Backend returned the updated tuple inline — apply immediately so
        // the UI doesn't flash "Waiting" before the next poll.
        debugPrint('[Queue] pass: nextSlot inline, applying');
        setState(() {
          _passing = false;
          _slot    = result.nextSlot;
        });
        _startCountdown(result.nextSlot!.activeWindowSlot?.expiresAt);
        _refresh(); // background sync
      } else {
        setState(() => _passing = false);
        _refresh();
      }
    } catch (e, st) {
      debugPrint('[Queue] pass unexpected error: $e\n$st');
      if (!mounted) return;
      setState(() => _passing = false);
      _refresh();
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF111827)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Shipment Queue',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF1A56DB)),
            onPressed: _refresh,
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(Color(0xFF1A56DB)),
              ),
            )
          : _error != null
              ? _ErrorState(message: _error!, onRetry: _refresh)
              : _slot == null
                  // null slot = no active event at all
                  ? const _NoEventState()
                  : _QueueBody(
                      slot          : _slot!,
                      remaining     : _remaining,
                      onAccept      : _acceptSlot,
                      onPass        : _passSlot,
                      accepting     : _accepting,
                      passing       : _passing,
                    ),
    );
  }
}

// ── Queue body ────────────────────────────────────────────────────────────────

class _QueueBody extends StatelessWidget {
  final QueueSlot                                    slot;
  final Duration                                     remaining;
  final void Function(ShipmentSlotItem offer)        onAccept;
  final void Function(ShipmentSlotItem offer)        onPass;
  final bool                                         accepting;
  final bool                                         passing;

  const _QueueBody({
    required this.slot,
    required this.remaining,
    required this.onAccept,
    required this.onPass,
    required this.accepting,
    required this.passing,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _QueuePositionCard(slot: slot),
          const SizedBox(height: 16),

          // ── Offer area ────────────────────────────────────────────────────
          //
          // Priority ladder:
          //   1. hasActiveOffer  → render one card per claimable slot
          //   2. isWaiting       → waiting placeholder
          //   3. hasAlreadyClaimed → already claimed state
          //   4. else            → queue closed (event not live)
          //
          // "Queue Closed" is NEVER shown while eventStatus=='live'.

          if (slot.hasActiveOffer) ...[
            // ── Per-slot cards (stacked) ─────────────────────────────────
            // Each claimable slot gets its own actionable card.
            // The active-window slot shows a countdown; expired-claimable
            // slots show the amber "Still Claimable" header.
            // If a slot was taken by another driver it shows the grey
            // "Taken" overlay instead of action buttons.
            ...slot.claimableSlots.asMap().entries.map((entry) {
              final idx   = entry.key;
              final offer = entry.value;

              // Is this the slot with the live countdown?
              final isActiveWindow = offer == slot.activeWindowSlot;
              final slotRemaining  = isActiveWindow ? remaining : Duration.zero;

              return Padding(
                padding: EdgeInsets.only(
                  bottom: idx < slot.claimableSlots.length - 1 ? 12 : 0,
                ),
                child: offer.wasTakenByOther
                    ? _TakenCard(offer: offer)
                    : _OfferCard(
                        offer      : offer,
                        remaining  : slotRemaining,
                        onAccept   : () => onAccept(offer),
                        onPass     : () => onPass(offer),
                        accepting  : accepting,
                        passing    : passing,
                      ),
              );
            }),

          ] else if (slot.isWaiting) ...[
            const _WaitingForOffer(),

          ] else if (slot.hasAlreadyClaimed) ...[
            const _AlreadyClaimedState(),

          ] else ...[
            // Only reached when eventStatus != 'live' (e.g. 'closed', 'ended').
            const _QueueClosed(),
          ],

          // ── Up-next preview ───────────────────────────────────────────────
          if (slot.upcomingSlots.isNotEmpty) ...[
            const SizedBox(height: 20),
            _UpcomingList(shipments: slot.upcomingSlots),
          ],
        ],
      ),
    );
  }
}

// ── Queue position card ────────────────────────────────────────────────────────

class _QueuePositionCard extends StatelessWidget {
  final QueueSlot slot;
  const _QueuePositionCard({required this.slot});

  String get _statusLabel {
    if (slot.hasClaimed)         return 'Accepted';
    if (slot.hasActiveOffer) {
      final n = slot.claimableCount;
      return n == 1 ? '1 offer' : '$n offers';
    }
    if (slot.isWaiting)          return 'Waiting';
    return slot.eventStatus;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E9F0)),
      ),
      child: Row(
        children: [
          // Position badge
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1A56DB), Color(0xFF0C3997)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                '#${slot.position}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Your Queue Position',
                    style: TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
                const SizedBox(height: 2),
                Text(
                  slot.position == 1 ? 'You\'re next!' : '${slot.position - 1} drivers ahead',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Status: $_statusLabel',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
                ),
              ],
            ),
          ),
          _StatusPill(status: slot.eventStatus),
        ],
      ),
    );
  }
}

// ── Taken card ────────────────────────────────────────────────────────────────
//
// Shown when acceptedByOther=true on a claimable slot.
// Mirrors the offer card layout so the height doesn't jump.
// No action buttons — per spec the driver can't interact with a taken slot.

class _TakenCard extends StatelessWidget {
  final ShipmentSlotItem offer;
  const _TakenCard({required this.offer});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD1D5DB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFF3F4F6),
              borderRadius: BorderRadius.vertical(top: Radius.circular(17)),
            ),
            child: Row(
              children: [
                const Icon(Icons.do_not_disturb_on_rounded,
                    size: 16, color: Color(0xFF9CA3AF)),
                const SizedBox(width: 6),
                const Text(
                  'Taken by another driver',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'TAKEN',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF6B7280),
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Body — muted, no actions
          Padding(
            padding: const EdgeInsets.all(16),
            child: Opacity(
              opacity: 0.45,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(offer.shipmentNumber,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                  const SizedBox(height: 4),
                  if (offer.agreedPrice != null) ...[
                    Text(
                      '₹${offer.agreedPrice!.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  _RouteDisplay(from: offer.pickupLocation, to: offer.dropLocation),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Offer card ────────────────────────────────────────────────────────────────
//
// Renders for every claimable slot (index < claimableCount).
//
// Visual state:
//   isExpired=false, expiresAt!=null  → blue header, live countdown, Accept + Pass
//   isExpired=true                    → amber header, "Expired" chip, Accept only (Claim Now)
//   (acceptedByOther is handled by _TakenCard before this widget is reached)

class _OfferCard extends StatelessWidget {
  final ShipmentSlotItem offer;
  final Duration         remaining;
  final VoidCallback     onAccept;
  final VoidCallback     onPass;
  final bool             accepting;
  final bool             passing;

  const _OfferCard({
    required this.offer,
    required this.remaining,
    required this.onAccept,
    required this.onPass,
    required this.accepting,
    required this.passing,
  });

  @override
  Widget build(BuildContext context) {
    const urgentColor = Color(0xFFE02424);

    // isExpired is authoritative from the model — no derived logic here.
    final isExpired = offer.isExpired;

    final timerColor =
        (!isExpired && remaining.inSeconds < 30) ? urgentColor : const Color(0xFF1A56DB);

    final headerBg = isExpired
        ? const Color(0xFFFEF3C7)
        : offer.isUrgent
            ? const Color(0xFFFDE8E8)
            : const Color(0xFFEBF0FE);

    final headerFg = isExpired
        ? const Color(0xFF92400E)
        : offer.isUrgent
            ? urgentColor
            : const Color(0xFF1A56DB);

    final borderColor = isExpired
        ? const Color(0xFFF59E0B).withOpacity(0.5)
        : offer.isUrgent
            ? urgentColor.withOpacity(0.3)
            : const Color(0xFFE5E9F0);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: borderColor,
          width: (offer.isUrgent || isExpired) ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isExpired
                ? const Color(0xFFF59E0B).withOpacity(0.08)
                : offer.isUrgent
                    ? urgentColor.withOpacity(0.08)
                    : Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header bar ──────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: headerBg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(17)),
            ),
            child: Row(
              children: [
                Icon(
                  isExpired
                      ? Icons.hourglass_bottom_rounded
                      : offer.isUrgent
                          ? Icons.flash_on_rounded
                          : Icons.local_shipping_rounded,
                  size: 16,
                  color: headerFg,
                ),
                const SizedBox(width: 6),
                Text(
                  isExpired
                      ? 'Still Claimable'
                      : offer.isUrgent
                          ? 'Urgent Shipment'
                          : 'New Offer',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: headerFg,
                  ),
                ),
                const Spacer(),
                if (offer.expiresAt != null)
                  _CountdownChip(
                    remaining  : remaining,
                    timerColor : timerColor,
                    isExpired  : isExpired,
                  ),
              ],
            ),
          ),

          // ── Body ─────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(offer.shipmentNumber,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                const SizedBox(height: 4),
                if (offer.agreedPrice != null) ...[
                  Text(
                    '₹${offer.agreedPrice!.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                _RouteDisplay(from: offer.pickupLocation, to: offer.dropLocation),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _InfoChip(icon: Icons.inventory_2_rounded,  label: offer.cargoType),
                    _InfoChip(
                      icon  : Icons.scale_rounded,
                      label : '${offer.cargoWeightKg.toStringAsFixed(1)} kg',
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Action buttons ──────────────────────────────────────────
                Row(
                  children: [
                    // Pass button: hidden when expired (only active window can be passed).
                    if (!isExpired) ...[
                      Expanded(
                        child: SizedBox(
                          height: 50,
                          child: OutlinedButton(
                            onPressed: passing ? null : onPass,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF6B7280),
                              side: const BorderSide(
                                  color: Color(0xFFD1D5DB), width: 1.5),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            child: passing
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Color(0xFF6B7280),
                                    ),
                                  )
                                : const Text('Pass',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600, fontSize: 15)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],

                    // Accept button: always shown; amber when expired.
                    Expanded(
                      flex: isExpired ? 1 : 2,
                      child: SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: accepting ? null : onAccept,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isExpired
                                ? const Color(0xFFF59E0B)
                                : const Color(0xFF1A56DB),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: accepting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2.5, color: Colors.white),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      isExpired ? Icons.bolt_rounded : Icons.check_rounded,
                                      size: 18,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      isExpired ? 'Claim Now' : 'Accept',
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Countdown chip ─────────────────────────────────────────────────────────────

class _CountdownChip extends StatelessWidget {
  final Duration remaining;
  final Color    timerColor;
  final bool     isExpired;

  const _CountdownChip({
    required this.remaining,
    required this.timerColor,
    required this.isExpired,
  });

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isExpired ? const Color(0xFFF3F4F6) : timerColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isExpired ? const Color(0xFFD1D5DB) : timerColor.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isExpired ? Icons.timer_off_rounded : Icons.timer_outlined,
            size: 13,
            color: isExpired ? const Color(0xFF9CA3AF) : timerColor,
          ),
          const SizedBox(width: 4),
          Text(
            isExpired ? 'Expired' : _fmt(remaining),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isExpired ? const Color(0xFF9CA3AF) : timerColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Route display ─────────────────────────────────────────────────────────────

class _RouteDisplay extends StatelessWidget {
  final String from, to;
  const _RouteDisplay({required this.from, required this.to});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6FA),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Column(
            children: [
              const Icon(Icons.radio_button_checked,
                  size: 14, color: Color(0xFF0E9F6E)),
              Container(width: 1.5, height: 26, color: const Color(0xFFD1D5DB)),
              const Icon(Icons.location_on_rounded,
                  size: 14, color: Color(0xFFE02424)),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(from,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827)),
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 14),
                Text(to,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827)),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String   label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6FA),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E9F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: const Color(0xFF6B7280)),
          const SizedBox(width: 5),
          Text(label,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF374151))),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String status;
  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final isLive = status == 'live';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isLive ? const Color(0xFFDEF7EC) : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLive)
            Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.only(right: 5),
              decoration: const BoxDecoration(
                color: Color(0xFF0E9F6E),
                shape: BoxShape.circle,
              ),
            ),
          Text(
            isLive ? 'Live' : status,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isLive ? const Color(0xFF057A55) : const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Waiting state ─────────────────────────────────────────────────────────────

class _WaitingForOffer extends StatelessWidget {
  const _WaitingForOffer();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E9F0)),
      ),
      child: const Column(
        children: [
          _PulsingHourglass(),
          SizedBox(height: 16),
          Text('Waiting for a shipment offer',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827))),
          SizedBox(height: 8),
          Text(
            'Stay online. You\'ll be notified\nwhen a shipment matches your position.',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 13, color: Color(0xFF6B7280), height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _PulsingHourglass extends StatefulWidget {
  const _PulsingHourglass();
  @override
  State<_PulsingHourglass> createState() => _PulsingHourglassState();
}

class _PulsingHourglassState extends State<_PulsingHourglass>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.92, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => ScaleTransition(
        scale: _scale,
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: const Color(0xFFEBF0FE),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.hourglass_top_rounded,
              size: 32, color: Color(0xFF1A56DB)),
        ),
      );
}

// ── Queue closed ───────────────────────────────────────────────────────────────
//
// Only shown when eventStatus != 'live' (i.e. event has ended or not started).
// NEVER shown while the event is live, even with claimableCount == 0.

class _QueueClosed extends StatelessWidget {
  const _QueueClosed();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E9F0)),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.event_busy_rounded,
                size: 32, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 16),
          const Text('Queue is closed',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827))),
          const SizedBox(height: 8),
          const Text(
            'No active queue event right now.\nCheck back later.',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 13, color: Color(0xFF6B7280), height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _NoEventState extends StatelessWidget {
  const _NoEventState();
  @override
  Widget build(BuildContext context) => const _QueueClosed();
}

// ── Already claimed ────────────────────────────────────────────────────────────

class _AlreadyClaimedState extends StatelessWidget {
  const _AlreadyClaimedState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E9F0)),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFDEF7EC),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.check_circle_rounded,
                size: 32, color: Color(0xFF057A55)),
          ),
          const SizedBox(height: 16),
          const Text('Shipment accepted',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827))),
          const SizedBox(height: 8),
          const Text(
            'You have already claimed a shipment\nin this queue event.',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 13, color: Color(0xFF6B7280), height: 1.5),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () =>
                Navigator.pushReplacementNamed(context, '/driver-dashboard'),
            icon: const Icon(Icons.directions_car_rounded, size: 16),
            label: const Text('Go to My Trip'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A56DB),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Error state ────────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  final String       message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 48, color: Color(0xFF6B7280)),
            const SizedBox(height: 16),
            const Text('Connection error',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827))),
            const SizedBox(height: 6),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
            const SizedBox(height: 20),
            TextButton(
              onPressed: onRetry,
              child: const Text('Retry',
                  style: TextStyle(
                      fontWeight: FontWeight.w600, color: Color(0xFF1A56DB))),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Upcoming list ──────────────────────────────────────────────────────────────

class _UpcomingList extends StatelessWidget {
  final List<ShipmentSlotItem> shipments;
  const _UpcomingList({required this.shipments});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 3,
              height: 14,
              decoration: BoxDecoration(
                color: const Color(0xFF1A56DB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            const Text('Up Next',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF374151),
                    letterSpacing: 0.2)),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFEBF0FE),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${shipments.length}',
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A56DB)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...shipments.asMap().entries.map((entry) => Padding(
              padding: EdgeInsets.only(
                  bottom: entry.key < shipments.length - 1 ? 8 : 0),
              child: _UpcomingShipmentCard(
                  shipment: entry.value, index: entry.key),
            )),
      ],
    );
  }
}

class _UpcomingShipmentCard extends StatelessWidget {
  final ShipmentSlotItem shipment;
  final int              index;
  const _UpcomingShipmentCard({required this.shipment, required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E9F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFF4F6FA),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '${index + 2}',
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF6B7280)),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(shipment.shipmentNumber,
                    style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF9CA3AF),
                        letterSpacing: 0.3)),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(Icons.radio_button_checked,
                        size: 10, color: Color(0xFF0E9F6E)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(shipment.pickupLocation,
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF111827)),
                          overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded,
                        size: 10, color: Color(0xFFE02424)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(shipment.dropLocation,
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF111827)),
                          overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (shipment.agreedPrice != null)
                Text(
                  '₹${shipment.agreedPrice!.toStringAsFixed(0)}',
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF111827)),
                ),
              if (shipment.isUrgent) ...[
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDE8E8),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('Urgent',
                      style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFE02424),
                          letterSpacing: 0.3)),
                ),
              ],
              const SizedBox(height: 4),
              const Icon(Icons.lock_outline_rounded,
                  size: 12, color: Color(0xFFD1D5DB)),
            ],
          ),
        ],
      ),
    );
  }
}