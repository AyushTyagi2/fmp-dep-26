import 'package:flutter/material.dart';
import 'package:fmp_app/app_session.dart';
import 'package:fmp_app/core/network/api_client.dart';
import 'package:fmp_app/core/network/api_trips.dart';
import 'package:fmp_app/presentation/driver/profile/driver_profile_screen.dart';

// lib/presentation/driver/dashboard/driver_dashboard_screen.dart

class DriverBillingScreen extends StatefulWidget {
  const DriverBillingScreen({super.key});

  @override
  State<DriverBillingScreen> createState() => _DriverBillingScreenState();
}

class _DriverBillingScreenState extends State<DriverBillingScreen> {
  int _tab = 0;
  final _apiClient = ApiClient();
  late final TripApiService _tripApi;

  List<TripSummary> _trips = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tripApi = TripApiService(_apiClient);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadTrips());
  }

  Future<void> _loadTrips() async {
    final driverId = AppSession.driverId;
    if (driverId == null) {
      if (mounted) setState(() { _loading = false; _error = 'Session expired'; });
      return;
    }
    try {
      final trips = await _tripApi.getDriverTrips(driverId);
      if (mounted) setState(() { _trips = trips; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    // IndexedStack keeps all tabs alive; Profile is index 2
    final pages = [
      // index 0 — Home (trips)
      _HomeTab(loading: _loading, error: _error, trips: _trips, onRetry: _loadTrips, onRefresh: _loadTrips),
      // index 1 — Queue (navigated via push, not a tab body)
      const SizedBox.shrink(),
      // index 2 — Profile
      const DriverProfileScreen(),
      
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      body: SafeArea(
        child: Column(
          children: [
            if (_tab != 2) _Header(driverId: AppSession.driverId ?? '—'),
            Expanded(
              child: IndexedStack(index: _tab, children: pages),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _DriverBottomNav(
        current: _tab,
        onTap: (i) {
  if (i == 1) {
    Navigator.pushNamed(context, '/driver-queue');
  } else if (i == 3) {
    Navigator.pushNamed(context, '/billing'); // or ignore
  } else {
    setState(() => _tab = i);
  }
},
      ),
      floatingActionButton: _tab == 0
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.pushNamed(context, '/driver-queue'),
              backgroundColor: const Color(0xFF1A56DB),
              elevation: 0,
              icon: const Icon(Icons.queue_rounded, color: Colors.white),
              label: const Text('Join Queue',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600)),
            )
          : null,
    );
  }
}

// ── Home tab content ──────────────────────────────────────────────────────────

class _HomeTab extends StatelessWidget {
  final bool loading;
  final String? error;
  final List<TripSummary> trips;
  final VoidCallback onRetry;
  final Future<void> Function() onRefresh;

  const _HomeTab({
    required this.loading,
    required this.error,
    required this.trips,
    required this.onRetry,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(
          child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(Color(0xFF1A56DB))));
    }
    if (error != null) {
      return _ErrorState(message: error!, onRetry: onRetry);
    }
    return _Body(trips: trips, tab: 0, onRefresh: onRefresh);
  }
}

// ── Header ────────────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  final String driverId;
  const _Header({required this.driverId});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1A56DB), Color(0xFF0C3997)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.local_shipping_rounded,
                color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Good morning 👋',
                    style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                Text('My Dashboard',
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827))),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFDEF7EC),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                      color: Color(0xFF0E9F6E), shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                const Text('Online',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF057A55))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Body (trips list + stats) ─────────────────────────────────────────────────
class _Body extends StatelessWidget {
  final List<TripSummary> trips;
  final int tab;
  final Future<void> Function() onRefresh;
  const _Body({required this.trips, required this.tab, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final active    = trips.where((t) => t.currentStatus == 'in_progress' || t.currentStatus == 'in_transit' || t.currentStatus == 'assigned').toList();
    final completed = trips.where((t) => t.currentStatus == 'completed' || t.currentStatus == 'delivered').toList();
    final totalEarnings = trips
        .where((t) => t.agreedPrice != null)
        .fold<double>(0, (sum, t) => sum + t.agreedPrice!);

    return RefreshIndicator(
      color: const Color(0xFF1A56DB),
      onRefresh: onRefresh,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  Expanded(child: _StatCard(label: 'Active', value: active.length.toString(), icon: Icons.directions_car_rounded, color: const Color(0xFF1A56DB), bg: const Color(0xFFEBF0FE))),
                  const SizedBox(width: 12),
                  Expanded(child: _StatCard(label: 'Completed', value: completed.length.toString(), icon: Icons.check_circle_rounded, color: const Color(0xFF0E9F6E), bg: const Color(0xFFDEF7EC))),
                  const SizedBox(width: 12),
                  Expanded(child: _StatCard(label: 'Earnings', value: '₹${totalEarnings.toStringAsFixed(0)}', icon: Icons.currency_rupee_rounded, color: const Color(0xFFD97706), bg: const Color(0xFFFEF3C7))),
                ],
              ),
            ),
          ),
          if (active.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Active Trip', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
                    const SizedBox(height: 10),
                    _ActiveTripCard(trip: active.first),
                  ],
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Trip History', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
                  Text('${trips.length} total', style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
                ],
              ),
            ),
          ),
          trips.isEmpty
              ? const SliverFillRemaining(child: _EmptyTrips())
              : SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                      child: _TripCard(trip: trips[i], onRefresh: onRefresh),
                    ),
                    childCount: trips.length,
                  ),
                ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color, bg;
  const _StatCard({required this.label, required this.value, required this.icon, required this.color, required this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E9F0)),
        boxShadow: const [BoxShadow(color: Color(0x06000000), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: 32, height: 32, decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)), child: Icon(icon, size: 17, color: color)),
          const SizedBox(height: 10),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF111827))),
          Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
        ],
      ),
    );
  }
}

class _ActiveTripCard extends StatelessWidget {
  final TripSummary trip;
  const _ActiveTripCard({required this.trip});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF1A56DB), Color(0xFF0C3997)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: const Color(0xFF1A56DB).withOpacity(0.25), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(trip.tripNumber, style: const TextStyle(fontSize: 13, color: Colors.white70, fontWeight: FontWeight.w500)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(100)),
                child: const Text('In Progress', style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(trip.shipmentNumber, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white)),
          if (trip.agreedPrice != null) ...[
            const SizedBox(height: 4),
            Text('₹${trip.agreedPrice!.toStringAsFixed(0)}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.pushNamed(context, '/trip-detail', arguments: trip.id),
              style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white38), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), padding: const EdgeInsets.symmetric(vertical: 11)),
              child: const Text('View Details', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

class _TripCard extends StatelessWidget {
  final TripSummary trip;
  final Future<void> Function()? onRefresh;
  const _TripCard({required this.trip, this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final isCompleted = trip.currentStatus == 'completed' || trip.currentStatus == 'delivered';
    final (statusBg, statusText, statusLabel) = _statusStyle(trip.currentStatus);
    return GestureDetector(
      onTap: () async {
        final needsRefresh = await Navigator.pushNamed(
          context, '/trip-detail', arguments: trip.id,
        );
        if (needsRefresh == true) onRefresh?.call();
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE5E9F0)), boxShadow: const [BoxShadow(color: Color(0x05000000), blurRadius: 8, offset: Offset(0, 2))]),
        child: Row(
          children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(color: isCompleted ? const Color(0xFFDEF7EC) : const Color(0xFFEBF0FE), borderRadius: BorderRadius.circular(10)),
              child: Icon(isCompleted ? Icons.check_circle_rounded : Icons.local_shipping_rounded, size: 20, color: isCompleted ? const Color(0xFF0E9F6E) : const Color(0xFF1A56DB)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(trip.tripNumber, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
                Text(trip.shipmentNumber, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
              ]),
            ),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(100)),
                child: Text(statusLabel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: statusText)),
              ),
              if (trip.agreedPrice != null) ...[
                const SizedBox(height: 4),
                Text('₹${trip.agreedPrice!.toStringAsFixed(0)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
              ],
            ]),
          ],
        ),
      ),
    );
  }

  (Color, Color, String) _statusStyle(String s) {
    switch (s) {
      case 'completed':
      case 'delivered':   return (const Color(0xFFDEF7EC), const Color(0xFF057A55), 'Delivered');
      case 'in_transit':
      case 'in_progress': return (const Color(0xFFEBF0FE), const Color(0xFF1A56DB), 'In Transit');
      case 'assigned':    return (const Color(0xFFF3F4F6), const Color(0xFF374151), 'Assigned');
      case 'cancelled':   return (const Color(0xFFFDE8E8), const Color(0xFFE02424), 'Cancelled');
      default:            return (const Color(0xFFF3F4F6), const Color(0xFF6B7280), s);
    }
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(width: 64, height: 64, decoration: BoxDecoration(color: const Color(0xFFFDE8E8), borderRadius: BorderRadius.circular(16)), child: const Icon(Icons.error_outline_rounded, size: 32, color: Color(0xFFE02424))),
          const SizedBox(height: 16),
          const Text('Failed to load trips', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
          const SizedBox(height: 6),
          Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
          const SizedBox(height: 20),
          TextButton(onPressed: onRetry, child: const Text('Try Again', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1A56DB)))),
        ]),
      ),
    );
  }
}

class _EmptyTrips extends StatelessWidget {
  const _EmptyTrips();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(width: 80, height: 80, decoration: BoxDecoration(color: const Color(0xFFEBF0FE), borderRadius: BorderRadius.circular(20)), child: const Icon(Icons.route_rounded, size: 40, color: Color(0xFF1A56DB))),
          const SizedBox(height: 20),
          const Text('No trips yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
          const SizedBox(height: 8),
          const Text('Join the queue to receive your\nfirst shipment offer', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Color(0xFF6B7280), height: 1.5)),
        ]),
      ),
    );
  }
}

class _DriverBottomNav extends StatelessWidget {
  final int current;
  final ValueChanged<int> onTap;
  const _DriverBottomNav({required this.current, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE5E9F0), width: 1)),
      ),
      child: BottomNavigationBar(
        currentIndex: current == 1 ? 0 : current, // queue never "selected"
        onTap: onTap,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF1A56DB),
        unselectedItemColor: const Color(0xFFADB5BD),
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.queue_rounded), label: 'Queue'),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profile'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long_rounded), label: 'Billing'),
        ],
      ),
    );
  }
}