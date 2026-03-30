import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_trips.dart';
import '../../../app_session.dart';
import '../../../shared/theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DRIVER HOME SCREEN — Logic unchanged, premium UI applied
// ─────────────────────────────────────────────────────────────────────────────

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
    if (driverId == null) {
      setState(() => _loading = false);
      return;
    }
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
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          if (_loading)
            const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
          else if (_activeTrips.isEmpty)
            SliverFillRemaining(child: _buildEmptyState())
          else
            SliverPadding(
              padding: const EdgeInsets.all(AppSpacing.md),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _TripCard(trip: _activeTrips[i]),
                  ),
                  childCount: _activeTrips.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 140,
      floating: false,
      pinned: true,
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Good ${_greeting()}, Driver 👋',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: Colors.white70,
              ),
            ),
            const Text(
              'My Dashboard',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primaryDark, AppColors.primary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Icon(
                Icons.local_shipping_rounded,
                size: 80,
                color: Colors.white.withOpacity(0.08),
              ),
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: Colors.white),
          onPressed: () {
            setState(() => _loading = true);
            _loadActiveTrips();
          },
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.local_shipping_rounded,
                size: 64,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Active Trips',
              style: AppTextStyles.headingMd,
            ),
            const SizedBox(height: 8),
            const Text(
              'You have no active shipments right now.\nCheck the Queue tab to pick up new jobs.',
              style: AppTextStyles.bodyMd,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 200,
              child: ElevatedButton.icon(
                onPressed: _loadActiveTrips,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Refresh'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'morning';
    if (h < 17) return 'afternoon';
    return 'evening';
  }
}

// ─── Trip Card ────────────────────────────────────────────────────────────────

class _TripCard extends StatelessWidget {
  final TripSummary trip;
  const _TripCard({required this.trip});

  Color get _statusColor => switch (trip.currentStatus) {
    'assigned'   => AppColors.warning,
    'in_transit' => AppColors.primary,
    'delivered'  => AppColors.success,
    _            => AppColors.textSecondary,
  };

  String get _statusLabel => trip.currentStatus
      .replaceAll('_', ' ')
      .split(' ')
      .map((w) => w[0].toUpperCase() + w.substring(1))
      .join(' ');

  IconData get _statusIcon => switch (trip.currentStatus) {
    'assigned'   => Icons.assignment_ind_rounded,
    'in_transit' => Icons.local_shipping_rounded,
    'delivered'  => Icons.check_circle_rounded,
    _            => Icons.help_outline_rounded,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          onTap: () => Navigator.pushNamed(
            context,
            '/active-trip',
            arguments: trip.id,
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Icon(_statusIcon, color: _statusColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Trip #${trip.tripNumber}',
                            style: AppTextStyles.headingSm,
                          ),
                          Text(
                            'Shipment: ${trip.shipmentNumber}',
                            style: AppTextStyles.bodySm,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        border: Border.all(
                          color: _statusColor.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        _statusLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                if (trip.agreedPrice != null) ...[
                  const SizedBox(height: 12),
                  const Divider(height: 1, color: AppColors.divider),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Agreed Price', style: AppTextStyles.bodyMd),
                      Text(
                        '₹${trip.agreedPrice!.toStringAsFixed(0)}',
                        style: AppTextStyles.headingSm.copyWith(
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Active Trip Screen ───────────────────────────────────────────────────────

class ActiveTripScreen extends StatefulWidget {
  final String tripId;
  const ActiveTripScreen({super.key, required this.tripId});

  @override
  State<ActiveTripScreen> createState() => _ActiveTripScreenState();
}

class _ActiveTripScreenState extends State<ActiveTripScreen> {
  late final TripApiService _api;
  TripSummary? _trip;
  bool _loading = true;
  bool _updating = false;
  String? _error;

  static const _steps = ['assigned', 'in_transit', 'delivered'];
  static const _stepLabels = {
    'assigned':   'Start Delivery',
    'in_transit': 'Mark as Delivered',
    'delivered':  'Completed ✓',
  };
  static const _stepDescriptions = {
    'assigned':   'Shipment assigned. Head to the pickup location.',
    'in_transit': 'Cargo picked up. You are currently en route.',
    'delivered':  'Delivery successfully completed!',
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
        const SnackBar(content: Text('Failed to update status. Please retry.')),
      );
    }
    setState(() => _updating = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDone = _trip?.currentStatus == 'delivered';
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Trip Details'),
        backgroundColor: isDone ? AppColors.success : AppColors.primary,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(
          fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white,
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : _buildContent(),
      bottomNavigationBar: (!_loading && _error == null)
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: isDone ? _buildCompletedAction() : _buildActionBtn(),
              ),
            )
          : null,
    );
  }

  Widget _buildError() => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.errorLight,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.error),
      ),
      const SizedBox(height: 20),
      Text(_error!, textAlign: TextAlign.center, style: AppTextStyles.bodyMd),
      const SizedBox(height: 24),
      SizedBox(
        width: 160,
        child: ElevatedButton(onPressed: _loadTrip, child: const Text('Retry')),
      ),
    ]),
  );

  Widget _buildContent() {
    final trip = _trip!;
    final status = trip.currentStatus;
    final isDone = status == 'delivered';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step indicator
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.border),
              boxShadow: AppShadows.card,
            ),
            child: Column(
              children: [
                Row(
                  children: List.generate(_steps.length * 2 - 1, (i) {
                    if (i.isOdd) {
                      final done = (i ~/ 2) < _steps.indexOf(status);
                      return Expanded(
                        child: Container(
                          height: 3,
                          color: done ? AppColors.success : AppColors.border,
                        ),
                      );
                    }
                    final si = i ~/ 2;
                    final done = si <= _steps.indexOf(status);
                    final isCurr = si == _steps.indexOf(status);
                    return Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: done ? AppColors.success : AppColors.surface,
                        border: Border.all(
                          color: done ? AppColors.success
                              : isCurr ? AppColors.primary : AppColors.border,
                          width: 2,
                        ),
                      ),
                      child: done
                          ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
                          : Center(
                              child: Text('${si + 1}',
                                style: TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w700,
                                  color: isCurr ? AppColors.primary : AppColors.textHint,
                                ),
                              ),
                            ),
                    );
                  }),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: _steps.map((s) => Text(
                    s.replaceAll('_', '\n').split('\n').map((w) =>
                        w[0].toUpperCase() + w.substring(1)).join('\n'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: s == status ? AppColors.primary : AppColors.textHint,
                    ),
                  )).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Status description
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: isDone ? AppColors.successLight : AppColors.primaryLight,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                color: isDone ? AppColors.success.withOpacity(0.3)
                    : AppColors.primary.withOpacity(0.2),
              ),
            ),
            child: Text(
              _stepDescriptions[status] ?? status,
              style: AppTextStyles.bodyLg.copyWith(
                color: isDone ? AppColors.success : AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Trip details
          Text('TRIP DETAILS', style: AppTextStyles.labelSm),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.border),
              boxShadow: AppShadows.card,
            ),
            child: Column(
              children: [
                _InfoRow(label: 'Trip Number', value: trip.tripNumber),
                const Divider(height: 24),
                _InfoRow(label: 'Shipment #', value: trip.shipmentNumber),
                if (trip.agreedPrice != null) ...[
                  const Divider(height: 24),
                  _InfoRow(
                    label: 'Agreed Price',
                    value: '₹${trip.agreedPrice!.toStringAsFixed(0)}',
                    valueColor: AppColors.success,
                    bold: true,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBtn() => ElevatedButton(
    onPressed: _updating ? null : _advanceStatus,
    style: ElevatedButton.styleFrom(
      minimumSize: const Size(double.infinity, 52),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
    ),
    child: _updating
        ? const SizedBox(
            width: 22, height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
          )
        : Text(_stepLabels[_trip!.currentStatus] ?? 'Update Status'),
  );

  Widget _buildCompletedAction() => OutlinedButton(
    onPressed: () => Navigator.pop(context),
    style: OutlinedButton.styleFrom(
      minimumSize: const Size(double.infinity, 52),
    ),
    child: const Text('Back to Dashboard'),
  );
}

class _InfoRow extends StatelessWidget {
  final String label, value;
  final Color? valueColor;
  final bool bold;
  const _InfoRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Text(label, style: AppTextStyles.bodyMd),
      const Spacer(),
      Text(
        value,
        style: AppTextStyles.labelLg.copyWith(
          color: valueColor ?? AppColors.textPrimary,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
          fontSize: bold ? 17 : 14,
        ),
      ),
    ],
  );
}
