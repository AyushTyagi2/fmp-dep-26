import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fmp_app/app_session.dart';
import 'package:fmp_app/core/network/api_client.dart';
import 'package:fmp_app/core/network/api_shipment_queue.dart';

// lib/presentation/driver/queue/driver_queue_screen.dart
//
// Shows the driver's queue slot + their current offer (if any).
// When the queue is live, every shipment card shows a live countdown.
// When the queue is offline, a "Queue Closed" state is shown.

class DriverQueueScreen extends StatefulWidget {
  const DriverQueueScreen({super.key});

  @override
  State<DriverQueueScreen> createState() => _DriverQueueScreenState();
}

class _DriverQueueScreenState extends State<DriverQueueScreen> {
  final _apiClient = ApiClient();
  late final ShipmentApiService _api;

  QueueSlot?  _slot;
  bool        _loading      = true;
  String?     _error;
  bool        _accepting    = false;
  bool        _passing      = false;
  // Set to true for a brief moment when the driver loses the race on Accept (409).
  // Shows a grey "Taken" card instead of a red snackbar; auto-clears after refresh.
  bool        _takenByOther = false;
  Timer?      _pollTimer;
  Timer?      _countdownTimer;
  Duration    _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _api = ShipmentApiService(_apiClient);
    _refresh();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) => _refresh());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    final driverId = AppSession.driverId;
    if (driverId == null) {
      if (mounted) setState(() { _error = 'No driver session. Please log in again.'; _loading = false; });
      return;
    }
    try {
      final slot = await _api.getMyQueueSlot(driverId);
      if (!mounted) return;
      debugPrint('[Queue] slot=${slot == null ? "null (no event)" : "active, offerStatus=${slot.offerStatus}, hasOffer=${slot.hasActiveOffer}"}');
      setState(() { _slot = slot; _loading = false; _error = null; });
      _startCountdown(slot?.currentOffer?.expiresAt);
    } catch (e, st) {
      debugPrint('[Queue] _refresh error: $e\n$st');
      if (mounted) setState(() { _error = 'Connection error: $e'; _loading = false; });
    }
  }

  void _startCountdown(DateTime? expiresAt) {
    _countdownTimer?.cancel();
    if (expiresAt == null) return;
    // Immediately set the initial value
    final initial = expiresAt.difference(DateTime.now());
    if (mounted) setState(() => _remaining = initial.isNegative ? Duration.zero : initial);

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final rem = expiresAt.difference(DateTime.now());
      if (mounted) setState(() => _remaining = rem.isNegative ? Duration.zero : rem);
      if (rem.isNegative) _countdownTimer?.cancel();
    });
  }

  Future<void> _accept() async {
    final offer    = _slot?.currentOffer;
    final driverId = AppSession.driverId;
    if (offer == null || driverId == null) return;
    setState(() => _accepting = true);
    try {
      final result = await _api.acceptShipment(
        shipmentQueueId: offer.shipmentQueueId,
        driverId: driverId,
      );
      if (!mounted) return;
      setState(() => _accepting = false);

      if (result.success) {
        // Happy path — navigate straight to dashboard/trip.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Shipment accepted! Trip created.'),
            backgroundColor: Color(0xFF0E9F6E),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pushReplacementNamed(context, '/driver-dashboard');

      } else if (result.wasTaken) {
        // Race-loss (409): flip the card to grey "Taken" state inline — no snackbar.
        debugPrint('[Queue] _accept: race lost — flipping to Taken state');
        setState(() => _takenByOther = true);
        await Future.delayed(const Duration(milliseconds: 800));
        if (!mounted) return;
        setState(() => _takenByOther = false);
        _refresh();

      } else {
        // Genuine server error — show snackbar with exact message.
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
      // Network error, 500, timeout, etc. — always reset the button.
      debugPrint('[Queue] _accept: unexpected error: $e\n$st');
      if (!mounted) return;
      setState(() => _accepting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Network error. Please try again.'),
          backgroundColor: const Color(0xFFE02424),
          behavior: SnackBarBehavior.floating,
        ),
      );
      _refresh();
    }
  }

  Future<void> _pass() async {
    final offer    = _slot?.currentOffer;
    final driverId = AppSession.driverId;
    if (offer == null || driverId == null) return;
    setState(() => _passing = true);
    final result = await _api.passShipment(
      shipmentQueueId: offer.shipmentQueueId,
      driverId: driverId,
    );
    if (!mounted) return;

    if (result.nextSlot != null) {
      // Backend returned the updated slot inline — apply it immediately so the
      // UI jumps straight to the next offer without a "Waiting" spinner flash.
      debugPrint('[Queue] _pass: nextSlot inline — applying without spinner');
      setState(() {
        _passing      = false;
        _slot         = result.nextSlot;
        _takenByOther = false;
      });
      _startCountdown(result.nextSlot!.currentOffer?.expiresAt);
      // Still refresh in the background to stay in sync, but don't show loading.
      _refresh();
    } else {
      // No inline slot (older backend or no shipment ready) — regular refresh.
      setState(() => _passing = false);
      _refresh();
    }
  }

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
        title: const Text('Shipment Queue',
            style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111827))),
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
                  valueColor: AlwaysStoppedAnimation(Color(0xFF1A56DB))))
          : _error != null
              ? _ErrorState(message: _error!, onRetry: _refresh)
              : _slot == null
                  ? const _NoEventState()
                  : _QueueBody(
                      slot: _slot!,
                      remaining: _remaining,
                      onAccept: _accept,
                      onPass: _pass,
                      accepting: _accepting,
                      passing: _passing,
                      upcomingShipments: _slot!.upcomingShipments,
                      takenByOther: _takenByOther,
                    ),
    );
  }
}

// ── Queue body ────────────────────────────────────────────────────────────────

class _QueueBody extends StatelessWidget {
  final QueueSlot              slot;
  final Duration               remaining;
  final VoidCallback           onAccept;
  final VoidCallback           onPass;
  final bool                   accepting, passing;
  final List<UpcomingShipment> upcomingShipments;
  // When true, the current offer card is replaced with a grey "Taken" card,
  // indicating another driver won the race. Cleared after the next refresh.
  final bool                   takenByOther;

  const _QueueBody({
    required this.slot,
    required this.remaining,
    required this.onAccept,
    required this.onPass,
    required this.accepting,
    required this.passing,
    this.upcomingShipments = const [],
    this.takenByOther      = false,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Queue position card
          _QueuePositionCard(slot: slot),
          const SizedBox(height: 16),

          // ── Offer area ──────────────────────────────────────────────────────
          // Priority: takenByOther > hasActiveOffer > isWindowOpen > claimed > closed
          if (takenByOther && slot.currentOffer != null) ...[
            // Race-loss: show grey "Taken" card briefly before next offer loads
            _TakenCard(offer: slot.currentOffer!),
          ] else if (slot.hasActiveOffer && slot.currentOffer != null) ...[
            _OfferCard(
              slot: slot,
              offer: slot.currentOffer!,
              remaining: remaining,
              onAccept: onAccept,
              onPass: onPass,
              accepting: accepting,
              passing: passing,
            ),
          ] else if (slot.isWindowOpen) ...[
            const _WaitingForOffer(),
          ] else if (slot.hasAlreadyClaimed) ...[
            const _AlreadyClaimedState(),
          ] else ...[
            const _QueueClosed(),
          ],

          // Up-next list — shown whenever there are upcoming shipments to preview
          if (upcomingShipments.isNotEmpty) ...[
            const SizedBox(height: 20),
            _UpcomingList(shipments: upcomingShipments),
          ],
        ],
      ),
    );
  }
}

String _friendlyStatus(String raw) {
  switch (raw) {
    case 'idle':     return 'waiting';
    case 'expired':  return 'still claimable';
    case 'passed':   return 'passed';
    case 'pending':  return 'pending offer';
    case 'accepted': return 'accepted';
    default:         return raw;
  }
}

// ── Queue position card ───────────────────────────────────────────────────────

class _QueuePositionCard extends StatelessWidget {
  final QueueSlot slot;
  const _QueuePositionCard({required this.slot});

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
                    color: Colors.white),
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
                  slot.position == 1
                      ? 'You\'re next!'
                      : '${slot.position - 1} drivers ahead',
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827)),
                ),
                const SizedBox(height: 2),
                Text(
                  'Status: ${_friendlyStatus(slot.offerStatus)}',
                  style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF9CA3AF)),
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

// ── Taken card (race-loss inline state) ──────────────────────────────────────
//
// Shown for ~800 ms after a 409 Accept response. Mirrors the offer card's
// layout so the transition is a same-size colour swap, not a jump in height.
// No buttons — both Accept and Pass are absent per the spec state table.

class _TakenCard extends StatelessWidget {
  final CurrentOffer offer;
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
          // Top bar — grey, no timer
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
                // "Taken" badge
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
          // Body — same structure as _OfferCard but muted, no action buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Opacity(
              opacity: 0.45,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(offer.shipmentNumber,
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF6B7280))),
                  const SizedBox(height: 4),
                  if (offer.agreedPrice != null) ...[
                    Text(
                      '₹${offer.agreedPrice!.toStringAsFixed(0)}',
                      style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF111827)),
                    ),
                    const SizedBox(height: 12),
                  ],
                  _RouteDisplay(
                      from: offer.pickupLocation, to: offer.dropLocation),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Offer card with countdown ─────────────────────────────────────────────────

class _OfferCard extends StatelessWidget {
  final QueueSlot    slot;
  final CurrentOffer offer;
  final Duration     remaining;
  final VoidCallback onAccept;
  final VoidCallback onPass;
  final bool         accepting, passing;

  const _OfferCard({
    required this.slot,
    required this.offer,
    required this.remaining,
    required this.onAccept,
    required this.onPass,
    required this.accepting,
    required this.passing,
  });

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    const urgentColor = Color(0xFFE02424);
    final timerColor =
        remaining.inSeconds < 30 ? urgentColor : const Color(0xFF1A56DB);
    // offerStatus == 'expired' means the primary window closed but the shipment
    // is still in the race (cascade not complete).  The spec says:
    //   - Amber "Still Claimable" header
    //   - Accept button: SHOWN and ENABLED
    //   - Pass button: HIDDEN
    final isExpiredStatus = slot.offerStatus == 'expired';
    // Countdown reaches zero before the server sends expired — use both signals.
    final isExpired = isExpiredStatus || (remaining == Duration.zero && offer.expiresAt != null);

    // Colours driven by the expired/urgent/normal state
    final headerBg = isExpired
        ? const Color(0xFFFEF3C7)   // amber tint — "Still Claimable"
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
          // Top bar with countdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: headerBg,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(17)),
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
                      color: headerFg),
                ),
                const Spacer(),
                // ── Countdown timer ────────────────────────────────────
                if (offer.expiresAt != null)
                  _CountdownChip(
                    remaining: remaining,
                    timerColor: timerColor,
                    isExpired: isExpired,
                  ),
              ],
            ),
          ),

          // Body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(offer.shipmentNumber,
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF6B7280))),
                const SizedBox(height: 4),
                if (offer.agreedPrice != null) ...[
                  Text(
                    '₹${offer.agreedPrice!.toStringAsFixed(0)}',
                    style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111827)),
                  ),
                  const SizedBox(height: 12),
                ],
                _RouteDisplay(from: offer.pickupLocation, to: offer.dropLocation),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _InfoChip(icon: Icons.inventory_2_rounded, label: offer.cargoType),
                    _InfoChip(
                        icon: Icons.scale_rounded,
                        label: '${offer.cargoWeightKg.toStringAsFixed(1)} kg'),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    // Pass button: HIDDEN when expired (spec state table)
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
                                        color: Color(0xFF6B7280)))
                                : const Text('Pass',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    // Accept button: always shown.
                    // When expired → amber "Claim Now" (still enabled).
                    // When pending → blue "Accept".
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
                                      strokeWidth: 2.5, color: Colors.white))
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      isExpired
                                          ? Icons.bolt_rounded
                                          : Icons.check_rounded,
                                      size: 18,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      isExpired ? 'Claim Now' : 'Accept',
                                      style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white),
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

// ── Countdown chip widget ─────────────────────────────────────────────────────

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
        color: isExpired
            ? const Color(0xFFF3F4F6)
            : timerColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isExpired
              ? const Color(0xFFD1D5DB)
              : timerColor.withOpacity(0.3),
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
                  color: Color(0xFF0E9F6E), shape: BoxShape.circle),
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

// Animated pulsing hourglass for the waiting state
class _PulsingHourglass extends StatefulWidget {
  const _PulsingHourglass();

  @override
  State<_PulsingHourglass> createState() => _PulsingHourglassState();
}

class _PulsingHourglassState extends State<_PulsingHourglass>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.92, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

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
          const Text('No active queue event right now.\nCheck back later.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13, color: Color(0xFF6B7280), height: 1.5)),
        ],
      ),
    );
  }
}

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
            const Icon(Icons.wifi_off_rounded,
                size: 48, color: Color(0xFF6B7280)),
            const SizedBox(height: 16),
            const Text('Connection error',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827))),
            const SizedBox(height: 6),
            Text(message,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
            const SizedBox(height: 20),
            TextButton(
                onPressed: onRetry,
                child: const Text('Retry',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A56DB)))),
          ],
        ),
      ),
    );
  }
}

class _NoEventState extends StatelessWidget {
  const _NoEventState();

  @override
  Widget build(BuildContext context) => const _QueueClosed();
}

// ── Already claimed state ─────────────────────────────────────────────────────

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
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Upcoming shipments list ───────────────────────────────────────────────────
//
// Read-only preview of the next shipments waiting in the pool.
// Shown below the active offer card (or the waiting placeholder).
// Drivers cannot interact with these — they are informational only.

class _UpcomingList extends StatelessWidget {
  final List<UpcomingShipment> shipments;
  const _UpcomingList({required this.shipments});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
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
            const Text(
              'Up Next',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF374151),
                letterSpacing: 0.2,
              ),
            ),
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
                  color: Color(0xFF1A56DB),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Cards
        ...shipments.asMap().entries.map((entry) {
          final index    = entry.key;
          final shipment = entry.value;
          return Padding(
            padding: EdgeInsets.only(bottom: index < shipments.length - 1 ? 8 : 0),
            child: _UpcomingShipmentCard(shipment: shipment, index: index),
          );
        }),
      ],
    );
  }
}

class _UpcomingShipmentCard extends StatelessWidget {
  final UpcomingShipment shipment;
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
          // Position badge
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFF4F6FA),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '${index + 2}',   // +2 because 1 is the active offer
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF6B7280),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Route
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  shipment.shipmentNumber,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF9CA3AF),
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(Icons.radio_button_checked,
                        size: 10, color: Color(0xFF0E9F6E)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        shipment.pickupLocation,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF111827),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
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
                      child: Text(
                        shipment.dropLocation,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF111827),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Right side: price + urgent badge
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (shipment.agreedPrice != null)
                Text(
                  '₹${shipment.agreedPrice!.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                  ),
                ),
              if (shipment.isUrgent) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDE8E8),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Urgent',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFE02424),
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
              // Lock icon signals read-only
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