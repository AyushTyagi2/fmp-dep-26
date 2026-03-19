import 'package:flutter/material.dart';
import 'package:fmp_app/presentation/fleetmgr/home/fleet_home_screen.dart';
import 'package:fmp_app/presentation/fleetmgr/drivers/fleet_drivers_screen.dart';
import 'package:fmp_app/presentation/fleetmgr/vehicles/fleet_vehicles_screen.dart';
import 'package:fmp_app/presentation/fleetmgr/trips/fleet_trips_screen.dart';
import 'package:fmp_app/presentation/fleetmgr/profile/fleet_profile_screen.dart';
import 'package:fmp_app/core/models/fleet_dashboard.dart';
import 'package:fmp_app/presentation/fleetmgr/fleet_api.dart';
import 'package:fmp_app/app_session.dart';

// ─── Design tokens (mirrors driver-side palette) ────────────────────────────
const _kNavy       = Color(0xFF1B3A6B);
const _kNavyLight  = Color(0xFF254E96);
const _kAmber      = Color(0xFFFFB300);
const _kSurface    = Color(0xFFF4F6FA);
const _kCardRadius = 14.0;
// ────────────────────────────────────────────────────────────────────────────

class FleetDashboardScreen extends StatefulWidget {
  const FleetDashboardScreen({super.key});

  @override
  State<FleetDashboardScreen> createState() => _FleetDashboardScreenState();
}

class _FleetDashboardScreenState extends State<FleetDashboardScreen> {
  int _index = 0;
  FleetDashboard? _dashboard;
  bool _loading = false;

  static const List<Widget> _pages = <Widget>[
    FleetHomeScreen(),
    FleetDriversScreen(),
    FleetVehiclesScreen(),
    FleetTripsScreen(),
    FleetProfileScreen(),
  ];

  void _onItemTapped(int idx) {
    setState(() {
      _index = idx;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    final phone = AppSession.phone;
    if (phone == null) return;
    setState(() {
      _loading = true;
    });
    try {
      final api = FleetApi();
      final dto = await api.getFleetDashboardByPhone(phone);
      setState(() {
        _dashboard = dto;
      });
    } catch (e) {
      // ignore
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kSurface,
      appBar: AppBar(
        backgroundColor: _kNavy,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.local_shipping, size: 18, color: Colors.white),
            ),
            const SizedBox(width: 10),
            const Text(
              'Fleet Dashboard',
              style: TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.3),
            ),
          ],
        ),
      ),
      body: _index == 0 ? _buildDashboard() : _pages[_index],
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: _index,
      onTap: _onItemTapped,
      backgroundColor: Colors.white,
      selectedItemColor: _kNavy,
      unselectedItemColor: Colors.grey[500],
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
      unselectedLabelStyle: const TextStyle(fontSize: 11),
      elevation: 12,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.people_outline), activeIcon: Icon(Icons.people), label: 'Drivers'),
        BottomNavigationBarItem(icon: Icon(Icons.local_shipping_outlined), activeIcon: Icon(Icons.local_shipping), label: 'Vehicles'),
        BottomNavigationBarItem(icon: Icon(Icons.receipt_long_outlined), activeIcon: Icon(Icons.receipt_long), label: 'Trips'),
        BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
      ],
    );
  }

  Widget _buildDashboard() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: _kNavy),
      );
    }
    if (_dashboard == null) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.local_shipping_outlined, size: 56, color: Colors.grey),
            SizedBox(height: 12),
            Text('No fleet owner selected', style: TextStyle(color: Colors.grey, fontSize: 15)),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Fleet owner header ───────────────────────────────────────────
          _buildOwnerHeader(),

          const SizedBox(height: 20),

          // ── Section label ────────────────────────────────────────────────
          const Padding(
            padding: EdgeInsets.only(left: 2, bottom: 10),
            child: Text(
              'OVERVIEW',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.grey,
                letterSpacing: 1.4,
              ),
            ),
          ),

          // ── Stat grid ────────────────────────────────────────────────────
          Row(
            children: [
              _statCard(
                title: 'Active Drivers',
                value: _dashboard!.activeDrivers.toString(),
                icon: Icons.people,
                accent: _kNavyLight,
              ),
              const SizedBox(width: 12),
              _statCard(
                title: 'Active Trips',
                value: _dashboard!.activeTrips.toString(),
                icon: Icons.alt_route,
                accent: const Color(0xFF2E7D32),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _statCard(
                title: 'Vehicle Issues',
                value: _dashboard!.vehicleIssues.toString(),
                icon: Icons.build_circle_outlined,
                accent: const Color(0xFFF57C00),
              ),
              const SizedBox(width: 12),
              _statCard(
                title: 'Trips w/ Issues',
                value: _dashboard!.tripsWithIssues.toString(),
                icon: Icons.warning_amber_rounded,
                accent: const Color(0xFFC62828),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOwnerHeader() {
    final name = _dashboard!.fleetOwnerName;
    final initials = name.trim().isNotEmpty
        ? name.trim().split(' ').map((p) => p.isNotEmpty ? p[0] : '').take(2).join().toUpperCase()
        : 'FM';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_kNavy, _kNavyLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(_kCardRadius),
        boxShadow: [
          BoxShadow(
            color: _kNavy.withOpacity(0.28),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white.withOpacity(0.15),
            child: Text(
              initials,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Fleet Manager',
                    style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _kAmber.withOpacity(0.18),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.local_shipping, color: _kAmber, size: 22),
          ),
        ],
      ),
    );
  }

  Widget _statCard({
    required String title,
    required String value,
    required IconData icon,
    required Color accent,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(_kCardRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
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
                    color: accent.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 18, color: accent),
                ),
                Container(
                  width: 4,
                  height: 28,
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: accent,
                height: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}