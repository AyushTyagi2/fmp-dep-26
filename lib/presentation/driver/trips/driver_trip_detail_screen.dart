import 'package:flutter/material.dart';
import 'package:fmp_app/core/network/api_client.dart';
import 'package:fmp_app/core/network/api_trips.dart';

// lib/presentation/driver/trips/driver_trip_detail_screen.dart
// Route: '/trip-detail'  (receives tripId as String argument)
//
// Status flow:  assigned → in_transit → delivered
// Each status has exactly one forward action button.

class DriverTripDetailScreen extends StatefulWidget {
  const DriverTripDetailScreen({super.key});

  @override
  State<DriverTripDetailScreen> createState() => _DriverTripDetailScreenState();
}

class _DriverTripDetailScreenState extends State<DriverTripDetailScreen> {
  final _api = TripApiService(ApiClient());

  TripSummary? _trip;
  bool _loading = true;
  bool _updating = false;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final tripId = ModalRoute.of(context)!.settings.arguments as String;
    _load(tripId);
  }

  Future<void> _load(String tripId) async {
    try {
      final trip = await _api.getTripById(tripId);
      if (mounted) setState(() { _trip = trip; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    if (_trip == null) return;
    setState(() => _updating = true);

    final ok = await _api.updateStatus(_trip!.id, newStatus);
    if (!mounted) return;

    if (ok) {
      // Reload to get fresh state
      setState(() { _updating = false; _loading = true; });
      await _load(_trip!.id);

      final label = _statusLabel(newStatus);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Trip marked as $label'),
          backgroundColor: const Color(0xFF0E9F6E),
          behavior: SnackBarBehavior.floating,
        ),
      );

      // If delivered, pop back to dashboard so stats refresh
      if (newStatus == 'delivered' && mounted) {
        Navigator.pop(context, true); // true = refresh needed
      }
    } else {
      setState(() => _updating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update status. Please try again.'),
          backgroundColor: Color(0xFFE02424),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _confirmAction(String newStatus) {
    final label    = _statusLabel(newStatus);
    final message  = _confirmMessage(newStatus);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(color: const Color(0xFFE5E9F0), borderRadius: BorderRadius.circular(2)),
            ),
            Text('Confirm: $label',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
            const SizedBox(height: 8),
            Text(message, style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280), height: 1.5)),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF6B7280),
                    side: const BorderSide(color: Color(0xFFD1D5DB)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _updateStatus(newStatus);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _actionColor(newStatus),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text('Yes, $label',
                      style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white, fontSize: 15)),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
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
        title: Text(
          _trip?.tripNumber ?? 'Trip Details',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Color(0xFF1A56DB))))
          : _error != null
              ? _ErrorView(message: _error!, onRetry: () { setState(() { _loading = true; _error = null; }); _load(_trip!.id); })
              : _trip == null
                  ? const Center(child: Text('Trip not found'))
                  : _TripBody(
                      trip: _trip!,
                      updating: _updating,
                      onAction: _confirmAction,
                    ),
    );
  }
}

// ── Body ──────────────────────────────────────────────────────────────────────

class _TripBody extends StatelessWidget {
  final TripSummary  trip;
  final bool         updating;
  final void Function(String) onAction;

  const _TripBody({required this.trip, required this.updating, required this.onAction});

  @override
  Widget build(BuildContext context) {
    final nextStatus = _nextStatus(trip.currentStatus);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Status banner ────────────────────────────────────────────────
          _StatusBanner(status: trip.currentStatus),
          const SizedBox(height: 16),

          // ── Trip info card ───────────────────────────────────────────────
          _InfoCard(trip: trip),
          const SizedBox(height: 16),

          // ── Progress stepper ─────────────────────────────────────────────
          _ProgressStepper(currentStatus: trip.currentStatus),
          const SizedBox(height: 24),

          // ── Action button ────────────────────────────────────────────────
          if (nextStatus != null)
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: updating ? null : () => onAction(nextStatus),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _actionColor(nextStatus),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: updating
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Icon(_actionIcon(nextStatus), color: Colors.white, size: 20),
                label: Text(
                  updating ? 'Updating…' : _actionLabel(nextStatus),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                ),
              ),
            )
          else if (trip.currentStatus == 'delivered')
            _CompletedBanner(),
        ],
      ),
    );
  }
}

// ── Status banner ─────────────────────────────────────────────────────────────

class _StatusBanner extends StatelessWidget {
  final String status;
  const _StatusBanner({required this.status});

  @override
  Widget build(BuildContext context) {
    final (bg, fg, icon, label) = _bannerStyle(status);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(color: fg.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: fg, size: 22),
        ),
        const SizedBox(width: 14),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Current Status', style: TextStyle(fontSize: 12, color: fg.withOpacity(0.7))),
          Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: fg)),
        ]),
      ]),
    );
  }

  (Color, Color, IconData, String) _bannerStyle(String s) {
    switch (s) {
      case 'assigned':   return (const Color(0xFFEBF0FE), const Color(0xFF1A56DB), Icons.assignment_rounded,      'Assigned');
      case 'in_transit': return (const Color(0xFFFEF3C7), const Color(0xFFD97706), Icons.local_shipping_rounded,  'In Transit');
      case 'delivered':  return (const Color(0xFFDEF7EC), const Color(0xFF057A55), Icons.check_circle_rounded,    'Delivered');
      default:           return (const Color(0xFFF3F4F6), const Color(0xFF6B7280), Icons.info_rounded,            s);
    }
  }
}

// ── Info card ─────────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final TripSummary trip;
  const _InfoCard({required this.trip});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E9F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Trip Details', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
          const SizedBox(height: 14),
          _Row(label: 'Trip Number',    value: trip.tripNumber),
          _Row(label: 'Shipment',       value: trip.shipmentNumber),
          if (trip.agreedPrice != null)
            _Row(label: 'Agreed Price', value: '₹${trip.agreedPrice!.toStringAsFixed(0)}'),
          _Row(label: 'Created',        value: _fmtDate(trip.createdAt)),
        ],
      ),
    );
  }

  String _fmtDate(DateTime d) {
    final local = d.toLocal();
    return '${local.day}/${local.month}/${local.year}  ${local.hour.toString().padLeft(2,'0')}:${local.minute.toString().padLeft(2,'0')}';
  }
}

class _Row extends StatelessWidget {
  final String label, value;
  const _Row({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
          Text(value,  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
        ],
      ),
    );
  }
}

// ── Progress stepper ──────────────────────────────────────────────────────────

class _ProgressStepper extends StatelessWidget {
  final String currentStatus;
  const _ProgressStepper({required this.currentStatus});

  static const _steps = ['assigned', 'in_transit', 'delivered'];
  static const _labels = ['Assigned', 'In Transit', 'Delivered'];

  @override
  Widget build(BuildContext context) {
    final currentIdx = _steps.indexOf(currentStatus);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E9F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Progress', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
          const SizedBox(height: 16),
          Row(
            children: List.generate(_steps.length * 2 - 1, (i) {
              if (i.isOdd) {
                // Connector line
                final filled = (i ~/ 2) < currentIdx;
                return Expanded(
                  child: Container(
                    height: 3,
                    color: filled ? const Color(0xFF1A56DB) : const Color(0xFFE5E9F0),
                  ),
                );
              }
              final stepIdx = i ~/ 2;
              final done    = stepIdx <= currentIdx;
              final active  = stepIdx == currentIdx;
              return Column(children: [
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: done ? const Color(0xFF1A56DB) : const Color(0xFFF3F4F6),
                    shape: BoxShape.circle,
                    border: active ? Border.all(color: const Color(0xFF1A56DB), width: 2) : null,
                  ),
                  child: Icon(
                    done ? Icons.check_rounded : Icons.circle,
                    size: done ? 16 : 8,
                    color: done ? Colors.white : const Color(0xFFD1D5DB),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _labels[stepIdx],
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                    color: done ? const Color(0xFF1A56DB) : const Color(0xFF9CA3AF),
                  ),
                ),
              ]);
            }),
          ),
        ],
      ),
    );
  }
}

// ── Completed banner ──────────────────────────────────────────────────────────

class _CompletedBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFDEF7EC),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Column(children: [
        Icon(Icons.check_circle_rounded, color: Color(0xFF057A55), size: 36),
        SizedBox(height: 10),
        Text('Trip Completed', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF057A55))),
        SizedBox(height: 4),
        Text('This trip has been successfully delivered.', style: TextStyle(fontSize: 13, color: Color(0xFF065F46))),
      ]),
    );
  }
}

// ── Error view ────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.error_outline_rounded, size: 48, color: Color(0xFFE02424)),
        const SizedBox(height: 16),
        Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
        const SizedBox(height: 20),
        TextButton(onPressed: onRetry, child: const Text('Retry')),
      ]),
    ));
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

String? _nextStatus(String current) {
  switch (current) {
    case 'assigned':   return 'in_transit';
    case 'in_transit': return 'delivered';
    default:           return null;
  }
}

String _statusLabel(String s) {
  switch (s) {
    case 'in_transit': return 'In Transit';
    case 'delivered':  return 'Delivered';
    default:           return s;
  }
}

String _actionLabel(String nextStatus) {
  switch (nextStatus) {
    case 'in_transit': return 'Start Trip';
    case 'delivered':  return 'Mark as Delivered';
    default:           return 'Update Status';
  }
}

String _confirmMessage(String nextStatus) {
  switch (nextStatus) {
    case 'in_transit':
      return 'Confirm that you have picked up the shipment and are now on the way to the destination.';
    case 'delivered':
      return 'Confirm that the shipment has been successfully delivered to the recipient.';
    default:
      return 'Are you sure you want to update the trip status?';
  }
}

Color _actionColor(String nextStatus) {
  switch (nextStatus) {
    case 'in_transit': return const Color(0xFF1A56DB);
    case 'delivered':  return const Color(0xFF0E9F6E);
    default:           return const Color(0xFF6B7280);
  }
}

IconData _actionIcon(String nextStatus) {
  switch (nextStatus) {
    case 'in_transit': return Icons.play_arrow_rounded;
    case 'delivered':  return Icons.check_rounded;
    default:           return Icons.update_rounded;
  }
}