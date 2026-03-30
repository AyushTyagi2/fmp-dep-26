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
  bool        _loading  = true;
  String?     _error;
  bool        _accepting = false;
  bool        _passing   = false;
  Timer?      _pollTimer;
  Timer?      _countdownTimer;
  Duration    _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _api = ShipmentApiService(_apiClient);
    _refresh();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) => _refresh());
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
  }

  Future<void> _pass() async {
    final offer    = _slot?.currentOffer;
    final driverId = AppSession.driverId;
    if (offer == null || driverId == null) return;
    setState(() => _passing = true);
    await _api.passShipment(
      shipmentQueueId: offer.shipmentQueueId,
      driverId: driverId,
    );
    if (!mounted) return;
    setState(() => _passing = false);
    _refresh();
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
                    ),
    );
  }
}

// ── Queue body ────────────────────────────────────────────────────────────────

class _QueueBody extends StatelessWidget {
  final QueueSlot    slot;
  final Duration     remaining;
  final VoidCallback onAccept;
  final VoidCallback onPass;
  final bool         accepting, passing;

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
          // Queue position card
          _QueuePositionCard(slot: slot),
          const SizedBox(height: 16),

          // Active offer card or waiting / claimed / closed states
          if (slot.hasActiveOffer && slot.currentOffer != null) ...[
            _OfferCard(
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
        ],
      ),
    );
  }
}

String _friendlyStatus(String raw) {
  switch (raw) {
    case 'idle':     return 'waiting';
    case 'expired':  return 'waiting';
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

// ── Offer card with countdown ─────────────────────────────────────────────────

class _OfferCard extends StatelessWidget {
  final CurrentOffer offer;
  final Duration     remaining;
  final VoidCallback onAccept;
  final VoidCallback onPass;
  final bool         accepting, passing;

  const _OfferCard({
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
    final isExpired = remaining == Duration.zero && offer.expiresAt != null;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: offer.isUrgent
              ? urgentColor.withOpacity(0.3)
              : const Color(0xFFE5E9F0),
          width: offer.isUrgent ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: offer.isUrgent
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
              color: offer.isUrgent
                  ? const Color(0xFFFDE8E8)
                  : const Color(0xFFEBF0FE),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(17)),
            ),
            child: Row(
              children: [
                Icon(
                  offer.isUrgent
                      ? Icons.flash_on_rounded
                      : Icons.local_shipping_rounded,
                  size: 16,
                  color: offer.isUrgent ? urgentColor : const Color(0xFF1A56DB),
                ),
                const SizedBox(width: 6),
                Text(
                  offer.isUrgent ? 'Urgent Shipment' : 'New Offer',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: offer.isUrgent
                          ? urgentColor
                          : const Color(0xFF1A56DB)),
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
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: OutlinedButton(
                          onPressed: (passing || isExpired) ? null : onPass,
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
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: (accepting || isExpired) ? null : onAccept,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isExpired
                                ? const Color(0xFFD1D5DB)
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
                                          ? Icons.timer_off_rounded
                                          : Icons.check_rounded,
                                      size: 18,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      isExpired ? 'Expired' : 'Accept',
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