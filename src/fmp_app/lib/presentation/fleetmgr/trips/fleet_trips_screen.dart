// lib/presentation/fleetmgr/trips/fleet_trips_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fmp_app/app_session.dart';
import 'package:fmp_app/core/models/trip.dart';
import 'package:fmp_app/presentation/fleetmgr/fleet_state.dart';
import '../../../shared/theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// FLEET TRIPS SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class FleetTripsScreen extends StatefulWidget {
  const FleetTripsScreen({super.key});

  @override
  State<FleetTripsScreen> createState() => _FleetTripsScreenState();
}

class _FleetTripsScreenState extends State<FleetTripsScreen> {
  final FleetState _state = FleetState();
  String _activeFilter = 'All';

  static const _filters = ['All', 'Active', 'Completed', 'Issues'];

  // Which DB statuses each filter bucket maps to
  static const _statusMap = {
    'Active': {'created', 'assigned', 'started', 'reached_pickup', 'loaded', 'in_transit', 'reached_drop', 'unloaded'},
    'Completed': {'delivered', 'completed'},
    'Issues': {'cancelled'},
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final phone = AppSession.email;
    if (phone == null) return;
    await _state.loadTrips(phone);
    if (mounted) setState(() {});
  }

  List<Trip> get _filtered {
    if (_activeFilter == 'All') return _state.trips;
    final bucket = _statusMap[_activeFilter];
    if (bucket == null) return _state.trips;
    return _state.trips.where((t) => bucket.contains(t.currentStatus)).toList();
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          fontFamily: AppTextStyles.fontFamily,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: const Icon(Icons.receipt_long_rounded, size: 18, color: Colors.white),
            ),
            const SizedBox(width: 10),
            const Text('Trips'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _load,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.primary,
      child: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: _filtered.isEmpty ? _buildEmptyState() : _buildList(),
          ),
        ],
      ),
    );
  }

  // ── Filter Bar ─────────────────────────────────────────────────────────────

  Widget _buildFilterBar() {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.sm),
      child: Row(
        children: _filters.map((f) {
          final active = f == _activeFilter;

          // Badge counts
          int count = 0;
          if (f == 'All') {
            count = _state.trips.length;
          } else {
            final bucket = _statusMap[f];
            if (bucket != null) {
              count = _state.trips.where((t) => bucket.contains(t.currentStatus)).length;
            }
          }

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _activeFilter = f),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: active ? AppColors.primary : AppColors.background,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(
                    color: active ? AppColors.primary : AppColors.border,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      f,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: active ? Colors.white : AppColors.textSecondary,
                      ),
                    ),
                    if (count > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: active
                              ? Colors.white.withOpacity(0.25)
                              : AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Text(
                          '$count',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: active ? Colors.white : AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── List ───────────────────────────────────────────────────────────────────

  Widget _buildList() {
    final trips = _filtered;
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: trips.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (_, i) => _TripCard(trip: trips[i]),
    );
  }

  // ── Empty State ────────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    final isFiltered = _activeFilter != 'All';
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.route_outlined,
                    size: 48, color: AppColors.primary),
              ),
              const SizedBox(height: 16),
              Text(
                isFiltered
                    ? 'No $_activeFilter trips'
                    : 'No trips yet',
                style: AppTextStyles.headingSm,
              ),
              const SizedBox(height: 6),
              Text(
                isFiltered
                    ? 'Try a different filter above'
                    : 'Trips assigned to your fleet will appear here',
                style: AppTextStyles.bodyMd,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TRIP CARD
// ─────────────────────────────────────────────────────────────────────────────

class _TripCard extends StatelessWidget {
  final Trip trip;
  const _TripCard({required this.trip});

  // ── Status config ──────────────────────────────────────────────────────────

  static const _statusLabels = {
    'created': 'Created',
    'assigned': 'Assigned',
    'started': 'Started',
    'reached_pickup': 'At Pickup',
    'loaded': 'Loaded',
    'in_transit': 'In Transit',
    'reached_drop': 'At Drop',
    'unloaded': 'Unloaded',
    'delivered': 'Delivered',
    'completed': 'Completed',
    'cancelled': 'Cancelled',
  };

  Color _pillBg(String status) {
    switch (status) {
      case 'delivered':
      case 'completed':
        return AppColors.success.withOpacity(0.12);
      case 'in_transit':
      case 'started':
      case 'loaded':
      case 'reached_pickup':
      case 'reached_drop':
      case 'unloaded':
        return AppColors.primaryLight;
      case 'cancelled':
        return AppColors.error.withOpacity(0.12);
      default: // created, assigned
        return AppColors.warningLight;
    }
  }

  Color _pillFg(String status) {
    switch (status) {
      case 'delivered':
      case 'completed':
        return AppColors.success;
      case 'in_transit':
      case 'started':
      case 'loaded':
      case 'reached_pickup':
      case 'reached_drop':
      case 'unloaded':
        return AppColors.primary;
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = _statusLabels[trip.currentStatus] ?? trip.currentStatus;
    final pillBg = _pillBg(trip.currentStatus);
    final pillFg = _pillFg(trip.currentStatus);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.md, AppSpacing.md, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(trip.tripNumber, style: AppTextStyles.headingSm),
                      if (trip.plannedStartTime != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          DateFormat('d MMM y • HH:mm')
                              .format(trip.plannedStartTime!),
                          style: AppTextStyles.bodySm,
                        ),
                      ],
                    ],
                  ),
                ),
                // Status pill
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: pillBg,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: pillFg,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // ── Route timeline ─────────────────────────────────────────────────
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: _RouteTimeline(
              pickup: trip.pickupCity,
              drop: trip.dropCity,
              distanceKm: trip.estimatedDistanceKm,
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // ── Cargo info row ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              children: [
                _InfoChip(
                  icon: Icons.inventory_2_outlined,
                  label: trip.cargoType,
                ),
                if (trip.cargoWeightKg != null) ...[
                  const SizedBox(width: 8),
                  _InfoChip(
                    icon: Icons.scale_outlined,
                    label: '${trip.cargoWeightKg!.toStringAsFixed(0)} kg',
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // ── Footer: vehicle + driver ───────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(AppRadius.lg),
                bottomRight: Radius.circular(AppRadius.lg),
              ),
              border: Border(
                top: BorderSide(color: AppColors.border),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.local_shipping_outlined,
                    size: 14, color: AppColors.textHint),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    trip.vehicleRegistrationNumber,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                const Icon(Icons.person_outline_rounded,
                    size: 14, color: AppColors.textHint),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    trip.driverName,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ROUTE TIMELINE  (pickup → drop with a dashed connector)
// ─────────────────────────────────────────────────────────────────────────────

class _RouteTimeline extends StatelessWidget {
  final String pickup;
  final String drop;
  final double? distanceKm;

  const _RouteTimeline({
    required this.pickup,
    required this.drop,
    this.distanceKm,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Pickup
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'FROM',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textHint,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                pickup,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),

        // Connector
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(
            children: [
              if (distanceKm != null)
                Text(
                  '${distanceKm!.toStringAsFixed(0)} km',
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textHint,
                  ),
                ),
              const SizedBox(height: 2),
              _DashedLine(),
              const SizedBox(height: 2),
              const Icon(Icons.arrow_forward_rounded,
                  size: 14, color: AppColors.primary),
            ],
          ),
        ),

        // Drop
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'TO',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textHint,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                drop,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Dashed line painted widget ─────────────────────────────────────────────

class _DashedLine extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(48, 2),
      painter: _DashPainter(),
    );
  }
}

class _DashPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    double x = 0;
    const dashLen = 5.0;
    const gap = 3.0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + dashLen, 0), paint);
      x += dashLen + gap;
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// SMALL INFO CHIP
// ─────────────────────────────────────────────────────────────────────────────

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.textHint),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}