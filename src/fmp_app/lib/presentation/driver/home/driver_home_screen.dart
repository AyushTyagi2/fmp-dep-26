import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_trips.dart';
import '../../../app_session.dart';
import '../../../core/theme/app_theme.dart';

/// Full delivery lifecycle screen — navigated to after accepting a shipment
class ActiveTripScreen extends StatefulWidget {
  final String tripId;
  const ActiveTripScreen({super.key, required this.tripId});

  @override
  State<ActiveTripScreen> createState() => _ActiveTripScreenState();
}

class _ActiveTripScreenState extends State<ActiveTripScreen> {
  late final TripApiService _api;
  TripSummary? _trip;
  bool _loading  = true;
  bool _updating = false;
  String? _error;

  static const _steps = ['assigned', 'in_transit', 'delivered'];
  static const _stepLabels = {
    'assigned':   'Start Delivery',
    'in_transit': 'Mark as Delivered',
    'delivered':  'Completed ✓',
  };
  static const _stepDescriptions = {
    'assigned':   'Shipment assigned to you. Head to pickup location.',
    'in_transit': 'Cargo picked up. En route to delivery.',
    'delivered':  'Delivery complete!',
  };

  @override
  void initState() {
    super.initState();
    _api = TripApiService(ApiClient());
    _loadTrip();
  }

  Future<void> _loadTrip() async {
    setState(() { _loading = true; _error = null; });
    try {
      final trip = await _api.getTripById(widget.tripId);
      if (!mounted) return;
      setState(() { _trip = trip; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _advanceStatus() async {
    if (_trip == null) return;
    final idx = _steps.indexOf(_trip!.currentStatus);
    if (idx < 0 || idx >= _steps.length - 1) return;

    final nextStatus = _steps[idx + 1];
    setState(() => _updating = true);

    final ok = await _api.updateStatus(widget.tripId, nextStatus);
    if (!mounted) return;

    if (ok) {
      setState(() {
        _trip = TripSummary(
          id: _trip!.id, tripNumber: _trip!.tripNumber,
          shipmentId: _trip!.shipmentId, shipmentNumber: _trip!.shipmentNumber,
          currentStatus: nextStatus, agreedPrice: _trip!.agreedPrice,
          createdAt: _trip!.createdAt,
        );
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update status. Please retry.'), backgroundColor: Colors.red),
      );
    }
    setState(() => _updating = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Active Trip'),
        automaticallyImplyLeading: false,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null ? _buildError() : _buildContent(),
    );
  }

  Widget _buildError() => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.error_outline, size: 48, color: Colors.red),
      const SizedBox(height: 12),
      Text(_error!, textAlign: TextAlign.center),
      const SizedBox(height: 16),
      ElevatedButton(onPressed: _loadTrip, child: const Text('Retry')),
    ]),
  );

  Widget _buildContent() {
    final trip   = _trip!;
    final status = trip.currentStatus;
    final isDone = status == 'delivered';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _StatusStepper(currentStatus: status, steps: _steps),
        const SizedBox(height: 24),
        Container(
          width: double.infinity, padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDone ? AppTheme.success.withOpacity(0.05) : AppTheme.primary.withOpacity(0.03),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDone ? AppTheme.success.withOpacity(0.3) : AppTheme.primary.withOpacity(0.1)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(trip.tripNumber, style: const TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 4),
            Text(_stepDescriptions[status] ?? status,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ]),
        ),
        const SizedBox(height: 20),
        if (trip.agreedPrice != null)
          _InfoCard(children: [
            _InfoRow(label: 'Shipment #', value: trip.shipmentNumber),
            _InfoRow(label: 'Payout',     value: '₹${trip.agreedPrice!.toStringAsFixed(0)}'),
          ]),
        const SizedBox(height: 32),
        if (!isDone)
          SizedBox(
            width: double.infinity, height: 54,
            child: ElevatedButton(
              onPressed: _updating ? null : _advanceStatus,
              style: Theme.of(context).elevatedButtonTheme.style!.copyWith(
                backgroundColor: WidgetStateProperty.resolveWith(
                  (states) => states.contains(WidgetState.disabled) ? Colors.grey.shade400 : AppTheme.primary,
                ),
              ),
              child: _updating
                  ? const SizedBox(width: 24, height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(_stepLabels[status] ?? 'Update Status',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          )
        else
          Column(children: [
            Container(
              width: double.infinity, padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.success.withOpacity(0.05), borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.success.withOpacity(0.3)),
              ),
              child: const Column(children: [
                Icon(Icons.check_circle, color: AppTheme.success, size: 56),
                SizedBox(height: 12),
                Text('Delivery Complete!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.success)),
                SizedBox(height: 8),
                Text('Great work! Payment will be processed shortly.',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 14), textAlign: TextAlign.center),
              ]),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity, height: 54,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: const Text('Back to Dashboard', style: TextStyle(fontSize: 16)),
              ),
            ),
          ]),
      ]),
    );
  }
}

/// Home tab — shows active trip or empty state
class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  late final TripApiService _api;
  List<TripSummary> _activeTrips = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _api = TripApiService(ApiClient());
    _loadActiveTrips();
  }

  Future<void> _loadActiveTrips() async {
    final driverId = AppSession.driverId;
    if (driverId == null) { setState(() => _loading = false); return; }
    try {
      final all = await _api.getDriverTrips(driverId);
      if (!mounted) return;
      setState(() {
        _activeTrips = all.where((t) => t.currentStatus != 'delivered').toList();
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    if (_activeTrips.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Dashboard')),
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.05), shape: BoxShape.circle),
              child: const Icon(Icons.local_shipping_outlined, size: 72, color: AppTheme.primary),
            ),
            const SizedBox(height: 24),
            const Text('No active trips', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
            const SizedBox(height: 8),
            const Text('Browse the Queue tab to accept a shipment', style: TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _loadActiveTrips,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ]),
        ),
      );
    }

    final trip = _activeTrips.first;
    return Scaffold(
    return Scaffold(
      appBar: AppBar(title: const Text('My Dashboard')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('ACTIVE TRIP', style: TextStyle(fontSize: 12, color: AppTheme.primary, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.surface, AppTheme.surface.withOpacity(0.9)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(color: AppTheme.primary.withOpacity(0.08), blurRadius: 24, offset: const Offset(0, 8)),
              ],
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade100, width: 1.5),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(trip.tripNumber, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
                    _StatusChip(status: trip.currentStatus),
                  ],
                ),
                const SizedBox(height: 16),
                Text(trip.shipmentNumber, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ActiveTripScreen(tripId: trip.id)),
                    ).then((_) => _loadActiveTrips()),
                    child: const Text('Manage Trip'),
                  ),
                ),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}

// ── Supporting widgets ────────────────────────────────────────────────────────

class _StatusStepper extends StatelessWidget {
  final String currentStatus;
  final List<String> steps;
  const _StatusStepper({required this.currentStatus, required this.steps});

  @override
  Widget build(BuildContext context) {
    final idx = steps.indexOf(currentStatus);
    return Row(
      children: List.generate(steps.length * 2 - 1, (i) {
        if (i.isOdd) {
          final done = (i ~/ 2) < idx;
          return Expanded(child: Container(height: 3, color: done ? AppTheme.success : Colors.grey.shade200));
        }
        final stepIdx = i ~/ 2;
        final done    = stepIdx <= idx;
        return Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle, 
            color: done ? AppTheme.success : AppTheme.surface,
            border: Border.all(color: done ? AppTheme.success : Colors.grey.shade300, width: 2),
            boxShadow: done ? [BoxShadow(color: AppTheme.success.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))] : null,
          ),
          child: done
              ? const Icon(Icons.check, color: Colors.white, size: 18)
              : Center(child: Text('${stepIdx + 1}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w600))),
        );
      }),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  Color get _color => switch (status) {
    'assigned'   => AppTheme.secondary,
    'in_transit' => AppTheme.primary,
    'delivered'  => AppTheme.success,
    _            => AppTheme.textSecondary,
  };

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(color: _color.withOpacity(0.12), borderRadius: BorderRadius.circular(24), border: Border.all(color: _color.withOpacity(0.2))),
    child: Text(status.replaceAll('_', ' ').toUpperCase(), style: TextStyle(color: _color, fontWeight: FontWeight.w700, fontSize: 11, letterSpacing: 0.5)),
  );
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity, padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white, borderRadius: BorderRadius.circular(12),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))],
    ),
    child: Column(children: children),
  );
}

class _InfoRow extends StatelessWidget {
  final String label; final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(children: [
      SizedBox(width: 100, child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13))),
      Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
    ]),
  );
}