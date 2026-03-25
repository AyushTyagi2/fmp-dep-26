import 'package:flutter/material.dart';
import 'package:fmp_app/presentation/fleetmgr/home/fleet_home_screen.dart';
import 'package:fmp_app/presentation/fleetmgr/drivers/fleet_drivers_screen.dart';
import 'package:fmp_app/presentation/fleetmgr/vehicles/fleet_vehicles_screen.dart';
import 'package:fmp_app/presentation/fleetmgr/trips/fleet_trips_screen.dart';
import 'package:fmp_app/presentation/fleetmgr/profile/fleet_profile_screen.dart';
import 'package:fmp_app/core/models/fleet_dashboard.dart';
import 'package:fmp_app/presentation/fleetmgr/fleet_api.dart';
import 'package:fmp_app/app_session.dart';
import '../../../shared/theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// FLEET DASHBOARD — Logic unchanged, premium UI applied
// ─────────────────────────────────────────────────────────────────────────────

class FleetDashboardScreen extends StatefulWidget {
  const FleetDashboardScreen({super.key});

  @override
  State<FleetDashboardScreen> createState() => _FleetDashboardScreenState();
}

class _FleetDashboardScreenState extends State<FleetDashboardScreen> {
  int _index = 0;
  FleetDashboard? _dashboard;
  bool _loading = false;

  // Sub-pages (index 1-4); index 0 renders _buildDashboard() inline
  static const List<Widget> _subPages = [
    FleetHomeScreen(),
    FleetDriversScreen(),
    FleetVehiclesScreen(),
    FleetTripsScreen(),
    FleetProfileScreen(),
  ];

  void _onItemTapped(int idx) => setState(() => _index = idx);

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    final phone = AppSession.phone;
    if (phone == null) return;
    setState(() => _loading = true);
    try {
      final api = FleetApi();
      final dto = await api.getFleetDashboardByPhone(phone);
      setState(() => _dashboard = dto);
    } catch (_) {
      // ignore — same behaviour as original
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

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
              child: const Icon(Icons.local_shipping_rounded, size: 18, color: Colors.white),
            ),
            const SizedBox(width: 10),
            const Text('Fleet Dashboard'),
          ],
        ),
        actions: [
          if (_index == 0)
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              onPressed: _loadDashboard,
            ),
        ],
      ),
      body: _index == 0 ? _buildDashboardBody() : _subPages[_index],
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    const items = [
      (Icons.dashboard_rounded,        Icons.dashboard_outlined,        'Home'),
      (Icons.people_rounded,           Icons.people_outline_rounded,    'Drivers'),
      (Icons.local_shipping_rounded,   Icons.local_shipping_outlined,   'Vehicles'),
      (Icons.receipt_long_rounded,     Icons.receipt_long_outlined,     'Trips'),
      (Icons.person_rounded,           Icons.person_outline_rounded,    'Profile'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(top: BorderSide(color: AppColors.border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: List.generate(items.length, (i) {
              final (activeIcon, icon, label) = items[i];
              final active = i == _index;
              return Expanded(
                child: GestureDetector(
                  onTap: () => _onItemTapped(i),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        decoration: BoxDecoration(
                          color: active ? AppColors.primaryLight : Colors.transparent,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Icon(
                          active ? activeIcon : icon,
                          size: 22,
                          color: active ? AppColors.primary : AppColors.textHint,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                          color: active ? AppColors.primary : AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  // ── Dashboard home body ─────────────────────────────────────────────────────

  Widget _buildDashboardBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_dashboard == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.local_shipping_outlined, size: 48, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            const Text('No fleet data available', style: AppTextStyles.headingSm),
            const SizedBox(height: 6),
            const Text('Pull down to refresh', style: AppTextStyles.bodyMd),
          ],
        ),
      );
    }

    final d = _dashboard!;
    return RefreshIndicator(
      onRefresh: _loadDashboard,
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOwnerCard(d),
            const SizedBox(height: AppSpacing.md),

            // Alert banner if issues exist
            if (d.vehicleIssues > 0 || d.tripsWithIssues > 0) ...[
              _buildAlertBanner(d),
              const SizedBox(height: AppSpacing.md),
            ],

            Text('OVERVIEW', style: AppTextStyles.labelSm),
            const SizedBox(height: AppSpacing.sm),

            // 2×2 metric grid
            Row(
              children: [
                Expanded(
                  child: _MetricCard(
                    title: 'Active Drivers',
                    value: '${d.activeDrivers}',
                    icon: Icons.people_rounded,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _MetricCard(
                    title: 'Active Trips',
                    value: '${d.activeTrips}',
                    icon: Icons.route_rounded,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: _MetricCard(
                    title: 'Vehicle Issues',
                    value: '${d.vehicleIssues}',
                    icon: Icons.build_circle_rounded,
                    color: d.vehicleIssues > 0 ? AppColors.warning : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _MetricCard(
                    title: 'Trips w/ Issues',
                    value: '${d.tripsWithIssues}',
                    icon: Icons.warning_amber_rounded,
                    color: d.tripsWithIssues > 0 ? AppColors.error : AppColors.textSecondary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.lg),

            // Quick actions
            Text('QUICK ACTIONS', style: AppTextStyles.labelSm),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                _QuickAction(
                  label: 'Drivers',
                  icon: Icons.people_rounded,
                  onTap: () => _onItemTapped(1),
                ),
                const SizedBox(width: AppSpacing.sm),
                _QuickAction(
                  label: 'Vehicles',
                  icon: Icons.local_shipping_rounded,
                  onTap: () => _onItemTapped(2),
                ),
                const SizedBox(width: AppSpacing.sm),
                _QuickAction(
                  label: 'Trips',
                  icon: Icons.route_rounded,
                  onTap: () => _onItemTapped(3),
                ),
                const SizedBox(width: AppSpacing.sm),
                _QuickAction(
                  label: 'Profile',
                  icon: Icons.person_rounded,
                  onTap: () => _onItemTapped(4),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOwnerCard(FleetDashboard d) {
    final name = d.fleetOwnerName;
    final initials = name.trim().isEmpty
        ? 'FM'
        : name.trim().split(' ').map((p) => p.isNotEmpty ? p[0] : '').take(2).join().toUpperCase();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryDark, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.elevated,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: Colors.white.withOpacity(0.2),
            child: Text(
              initials,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 17,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.isEmpty ? 'Fleet Manager' : name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: const Text(
                    'Fleet Manager',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: const Icon(Icons.local_shipping_rounded, color: Colors.white, size: 22),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertBanner(FleetDashboard d) {
    final issues = <String>[];
    if (d.vehicleIssues > 0) issues.add('${d.vehicleIssues} vehicle issue${d.vehicleIssues > 1 ? 's' : ''}');
    if (d.tripsWithIssues > 0) issues.add('${d.tripsWithIssues} trip issue${d.tripsWithIssues > 1 ? 's' : ''}');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.warningLight,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.warning.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Attention needed: ${issues.join(', ')}.',
              style: const TextStyle(
                color: AppColors.warning,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Metric Card ─────────────────────────────────────────────────────────────

class _MetricCard extends StatelessWidget {
  final String title, value;
  final IconData icon;
  final Color color;
  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              Container(
                width: 4,
                height: 28,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: color,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(title, style: AppTextStyles.bodySm),
        ],
      ),
    );
  }
}

// ─── Quick Action ─────────────────────────────────────────────────────────────

class _QuickAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _QuickAction({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              Icon(icon, size: 22, color: AppColors.primary),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
