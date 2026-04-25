import 'package:flutter/material.dart';
import 'package:fmp_app/app_session.dart';
import 'package:fmp_app/core/network/api_client.dart';
import 'package:fmp_app/core/network/api_trips.dart';
import 'package:fmp_app/presentation/driver/profile/driver_profile_screen.dart';

// lib/presentation/driver/dashboard/driver_dashboard_screen.dart

enum TripFilter { all, active, completed, assigned, cancelled }
enum TripSort { newestFirst, oldestFirst, highestEarnings, lowestEarnings }

class DriverDashboardScreen extends StatefulWidget {
  const DriverDashboardScreen({super.key});

  @override
  State<DriverDashboardScreen> createState() => _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends State<DriverDashboardScreen> {
  int _tab = 0;
  final _apiClient = ApiClient();
  late final TripApiService _tripApi;

  List<TripSummary> _trips = [];
  bool _loading = true;
  String? _error;

  // ── filter / sort / search state ─────────────────────────────────────────
  TripFilter _filter = TripFilter.all;
  TripSort _sort = TripSort.newestFirst;
  String _search = '';

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
    final pages = [
      _HomeTab(
        loading: _loading,
        error: _error,
        trips: _trips,
        filter: _filter,
        sort: _sort,
        search: _search,
        onRetry: _loadTrips,
        onRefresh: _loadTrips,
        onFilterChanged: (f) => setState(() => _filter = f),
        onSortChanged: (s) => setState(() => _sort = s),
        onSearchChanged: (q) => setState(() => _search = q),
      ),
      const SizedBox.shrink(),
      const DriverProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      body: SafeArea(
        child: Column(
          children: [
            if (_tab != 2) _Header(driverId: AppSession.driverId ?? '—'),
            Expanded(child: IndexedStack(index: _tab, children: pages)),
          ],
        ),
      ),
      bottomNavigationBar: _DriverBottomNav(
        current: _tab,
        onTap: (i) {
          if (i == 1) {
            Navigator.pushNamed(context, '/driver-queue');
          } else if (i == 4) {
            Navigator.pushNamed(context, '/billing');
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
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            )
          : null,
    );
  }
}

// ── Home tab ──────────────────────────────────────────────────────────────────

class _HomeTab extends StatelessWidget {
  final bool loading;
  final String? error;
  final List<TripSummary> trips;
  final TripFilter filter;
  final TripSort sort;
  final String search;
  final VoidCallback onRetry;
  final Future<void> Function() onRefresh;
  final ValueChanged<TripFilter> onFilterChanged;
  final ValueChanged<TripSort> onSortChanged;
  final ValueChanged<String> onSearchChanged;

  const _HomeTab({
    required this.loading,
    required this.error,
    required this.trips,
    required this.filter,
    required this.sort,
    required this.search,
    required this.onRetry,
    required this.onRefresh,
    required this.onFilterChanged,
    required this.onSortChanged,
    required this.onSearchChanged,
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
    return _Body(
      trips: trips,
      filter: filter,
      sort: sort,
      search: search,
      onRefresh: onRefresh,
      onFilterChanged: onFilterChanged,
      onSortChanged: onSortChanged,
      onSearchChanged: onSearchChanged,
    );
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
            width: 42, height: 42,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1A56DB), Color(0xFF0C3997)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.local_shipping_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Good morning 👋', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
              Text('My Dashboard', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
            ]),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: const Color(0xFFDEF7EC), borderRadius: BorderRadius.circular(100)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 7, height: 7, decoration: const BoxDecoration(color: Color(0xFF0E9F6E), shape: BoxShape.circle)),
              const SizedBox(width: 6),
              const Text('Online', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF057A55))),
            ]),
          ),
        ],
      ),
    );
  }
}

// ── Body ──────────────────────────────────────────────────────────────────────

class _Body extends StatelessWidget {
  final List<TripSummary> trips;
  final TripFilter filter;
  final TripSort sort;
  final String search;
  final Future<void> Function() onRefresh;
  final ValueChanged<TripFilter> onFilterChanged;
  final ValueChanged<TripSort> onSortChanged;
  final ValueChanged<String> onSearchChanged;

  const _Body({
    required this.trips,
    required this.filter,
    required this.sort,
    required this.search,
    required this.onRefresh,
    required this.onFilterChanged,
    required this.onSortChanged,
    required this.onSearchChanged,
  });

  List<TripSummary> get _processed {
    // 1. search
    var result = search.isEmpty
        ? trips
        : trips.where((t) {
            final q = search.toLowerCase();
            return t.tripNumber.toLowerCase().contains(q) ||
                t.shipmentNumber.toLowerCase().contains(q) ||
                t.senderName.toLowerCase().contains(q) ||
                t.receiverName.toLowerCase().contains(q);
          }).toList();

    // 2. filter
    switch (filter) {
      case TripFilter.active:
        result = result.where((t) =>
            t.currentStatus == 'in_progress' ||
            t.currentStatus == 'in_transit').toList();
        break;
      case TripFilter.completed:
        result = result.where((t) =>
            t.currentStatus == 'completed' ||
            t.currentStatus == 'delivered').toList();
        break;
      case TripFilter.assigned:
        result = result.where((t) => t.currentStatus == 'assigned').toList();
        break;
      case TripFilter.cancelled:
        result = result.where((t) => t.currentStatus == 'cancelled').toList();
        break;
      case TripFilter.all:
        break;
    }

    // 3. sort
    switch (sort) {
      case TripSort.newestFirst:
        result.sort((a, b) => (b.plannedStartTime ?? DateTime(0))
            .compareTo(a.plannedStartTime ?? DateTime(0)));
        break;
      case TripSort.oldestFirst:
        result.sort((a, b) => (a.plannedStartTime ?? DateTime(0))
            .compareTo(b.plannedStartTime ?? DateTime(0)));
        break;
      case TripSort.highestEarnings:
        result.sort((a, b) => (b.agreedPrice ?? 0).compareTo(a.agreedPrice ?? 0));
        break;
      case TripSort.lowestEarnings:
        result.sort((a, b) => (a.agreedPrice ?? 0).compareTo(b.agreedPrice ?? 0));
        break;
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final active    = trips.where((t) => t.currentStatus == 'in_progress' || t.currentStatus == 'in_transit' || t.currentStatus == 'assigned').toList();
    final completed = trips.where((t) => t.currentStatus == 'completed' || t.currentStatus == 'delivered').toList();
    final totalEarnings = trips
        .where((t) => t.agreedPrice != null)
        .fold<double>(0, (sum, t) => sum + t.agreedPrice!);
    final displayed = _processed;

    return RefreshIndicator(
      color: const Color(0xFF1A56DB),
      onRefresh: onRefresh,
      child: CustomScrollView(
        slivers: [
          // ── stat cards ────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(children: [
                Expanded(child: _StatCard(label: 'Active', value: active.length.toString(), icon: Icons.directions_car_rounded, color: const Color(0xFF1A56DB), bg: const Color(0xFFEBF0FE))),
                const SizedBox(width: 12),
                Expanded(child: _StatCard(label: 'Completed', value: completed.length.toString(), icon: Icons.check_circle_rounded, color: const Color(0xFF0E9F6E), bg: const Color(0xFFDEF7EC))),
                const SizedBox(width: 12),
                Expanded(child: _StatCard(label: 'Earnings', value: '₹${totalEarnings.toStringAsFixed(0)}', icon: Icons.currency_rupee_rounded, color: const Color(0xFFD97706), bg: const Color(0xFFFEF3C7))),
              ]),
            ),
          ),

          // ── active trip card ──────────────────────────────────────────────
          if (active.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Active Trip', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
                  const SizedBox(height: 10),
                  _ActiveTripCard(trip: active.first),
                ]),
              ),
            ),

          // ── search + filter + sort ────────────────────────────────────────
          // ── search + filter + sort ────────────────────────────────────────────────────
SliverToBoxAdapter(
  child: Padding(
    padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Trip History',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
        const SizedBox(height: 14),

        // ── search bar ──────────────────────────────────────────────────────
        Container(
          height: 46,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E9F0), width: 1.5),
          ),
          child: Row(children: [
            const SizedBox(width: 14),
            const Icon(Icons.search_rounded, size: 18, color: Color(0xFFADB5BD)),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                onChanged: onSearchChanged,
                style: const TextStyle(fontSize: 13, color: Color(0xFF111827)),
                decoration: const InputDecoration(
                  hintText: 'Search trips, shipments, names…',
                  hintStyle: TextStyle(fontSize: 13, color: Color(0xFFADB5BD)),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            if (search.isNotEmpty)
              GestureDetector(
                onTap: () => onSearchChanged(''),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(Icons.close_rounded, size: 16, color: const Color(0xFFADB5BD)),
                ),
              )
            else
              const SizedBox(width: 14),
          ]),
        ),

        const SizedBox(height: 12),

        // ── filter chips ────────────────────────────────────────────────────
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: TripFilter.values.map((f) {
              final label = switch (f) {
                TripFilter.all       => 'All',
                TripFilter.active    => 'Active',
                TripFilter.completed => 'Completed',
                TripFilter.assigned  => 'Assigned',
                TripFilter.cancelled => 'Cancelled',
              };
              final isSelected = filter == f;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => onFilterChanged(f),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF1A56DB) : Colors.white,
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF1A56DB) : const Color(0xFFE5E9F0),
                        width: 1.5,
                      ),
                    ),
                    child: Text(label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : const Color(0xFF6B7280),
                        )),
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 12),

        // ── count + sort row ────────────────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${displayed.length} trip${displayed.length == 1 ? '' : 's'}',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF6B7280)),
            ),
            _SortButton(current: sort, onChanged: onSortChanged),
          ],
        ),

        const SizedBox(height: 10),
      ],
    ),
  ),
),
          // ── trip list ─────────────────────────────────────────────────────
          displayed.isEmpty
              ? const SliverFillRemaining(child: _EmptyTrips())
              : SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                      child: _TripCard(trip: displayed[i], onRefresh: onRefresh),
                    ),
                    childCount: displayed.length,
                  ),
                ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

// ── everything below is unchanged ────────────────────────────────────────────

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
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 32, height: 32, decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)), child: Icon(icon, size: 17, color: color)),
        const SizedBox(height: 10),
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF111827))),
        Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
      ]),
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
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(trip.tripNumber, style: const TextStyle(fontSize: 13, color: Colors.white70, fontWeight: FontWeight.w500)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(100)),
            child: const Text('In Progress', style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ]),
        const SizedBox(height: 12),
        Text(trip.shipmentNumber, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white)),
        const SizedBox(height: 6),
        Row(children: [
          const Icon(Icons.circle, size: 8, color: Colors.white54),
          const SizedBox(width: 6),
          Expanded(child: Text(trip.senderName, style: const TextStyle(fontSize: 12, color: Colors.white70), overflow: TextOverflow.ellipsis)),
          const Icon(Icons.arrow_forward_rounded, size: 13, color: Colors.white54),
          const SizedBox(width: 6),
          Expanded(child: Text(trip.receiverName, style: const TextStyle(fontSize: 12, color: Colors.white70), overflow: TextOverflow.ellipsis)),
          const Icon(Icons.circle, size: 8, color: Colors.white54),
        ]),
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
      ]),
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
        final needsRefresh = await Navigator.pushNamed(context, '/trip-detail', arguments: trip.id);
        if (needsRefresh == true) onRefresh?.call();
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: trip.hasIssues ? const Color(0xFFFBD5D5) : const Color(0xFFE5E9F0)),
          boxShadow: const [BoxShadow(color: Color(0x05000000), blurRadius: 8, offset: Offset(0, 2))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: isCompleted ? const Color(0xFFDEF7EC) : const Color(0xFFEBF0FE),
                borderRadius: BorderRadius.circular(10),
              ),
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
          ]),
          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0xFFF3F4F6)),
          const SizedBox(height: 10),
          Row(children: [
            const Icon(Icons.circle, size: 7, color: Color(0xFF1A56DB)),
            const SizedBox(width: 5),
            Flexible(child: Text(trip.senderName, style: const TextStyle(fontSize: 12, color: Color(0xFF374151), fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
            const Padding(padding: EdgeInsets.symmetric(horizontal: 6), child: Icon(Icons.arrow_forward_rounded, size: 12, color: Color(0xFFADB5BD))),
            Flexible(child: Text(trip.receiverName, style: const TextStyle(fontSize: 12, color: Color(0xFF374151), fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
            const SizedBox(width: 5),
            const Icon(Icons.circle, size: 7, color: Color(0xFF0E9F6E)),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            if (trip.plannedStartTime != null) ...[
              const Icon(Icons.calendar_today_rounded, size: 11, color: Color(0xFF9CA3AF)),
              const SizedBox(width: 4),
              Text(_formatDate(trip.plannedStartTime!), style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
              const SizedBox(width: 12),
            ],
            if (trip.deliveredAt != null) ...[
              const Icon(Icons.flag_rounded, size: 11, color: Color(0xFF0E9F6E)),
              const SizedBox(width: 4),
              Text(_formatDate(trip.deliveredAt!), style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
              const SizedBox(width: 12),
            ],
            if (trip.driverPaymentAmount != null) ...[
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: trip.driverPaymentStatus == 'paid' ? const Color(0xFFDEF7EC) : const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(trip.driverPaymentStatus == 'paid' ? Icons.check_rounded : Icons.schedule_rounded, size: 10, color: trip.driverPaymentStatus == 'paid' ? const Color(0xFF057A55) : const Color(0xFFD97706)),
                  const SizedBox(width: 3),
                  Text('₹${trip.driverPaymentAmount!.toStringAsFixed(0)}',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: trip.driverPaymentStatus == 'paid' ? const Color(0xFF057A55) : const Color(0xFFD97706))),
                ]),
              ),
            ],
          ]),
          if (trip.hasIssues) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: const Color(0xFFFDE8E8), borderRadius: BorderRadius.circular(8)),
              child: Row(children: [
                const Icon(Icons.warning_amber_rounded, size: 13, color: Color(0xFFE02424)),
                const SizedBox(width: 6),
                Flexible(child: Text(trip.issueDescription ?? 'Issue reported', style: const TextStyle(fontSize: 11, color: Color(0xFFE02424)), overflow: TextOverflow.ellipsis)),
              ]),
            ),
          ],
          if (trip.deliveredToName != null && trip.deliveredToName!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(children: [
              const Icon(Icons.person_outline_rounded, size: 12, color: Color(0xFF9CA3AF)),
              const SizedBox(width: 4),
              Text('Delivered to ${trip.deliveredToName}', style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280), fontStyle: FontStyle.italic)),
            ]),
          ],
        ]),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${dt.day} ${months[dt.month - 1]}';
  }

  (Color, Color, String) _statusStyle(String s) {
    return switch (s) {
      'completed' || 'delivered'          => (const Color(0xFFDEF7EC), const Color(0xFF057A55), 'Delivered'),
      'in_transit' || 'in_progress'       => (const Color(0xFFEBF0FE), const Color(0xFF1A56DB), 'In Transit'),
      'assigned'                          => (const Color(0xFFF3F4F6), const Color(0xFF374151), 'Assigned'),
      'cancelled'                         => (const Color(0xFFFDE8E8), const Color(0xFFE02424), 'Cancelled'),
      _                                   => (const Color(0xFFF3F4F6), const Color(0xFF6B7280), s),
    };
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
        currentIndex: current == 1 ? 0 : current,
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

class _SortButton extends StatelessWidget {
  final TripSort current;
  final ValueChanged<TripSort> onChanged;
  const _SortButton({required this.current, required this.onChanged});

  String get _label => switch (current) {
    TripSort.newestFirst     => 'Newest first',
    TripSort.oldestFirst     => 'Oldest first',
    TripSort.highestEarnings => 'Highest earnings',
    TripSort.lowestEarnings  => 'Lowest earnings',
  };

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<TripSort>(
      onSelected: onChanged,
      color: Colors.white,
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE5E9F0)),
      ),
      offset: const Offset(0, 40),
      itemBuilder: (_) => [
        _sortItem(TripSort.newestFirst,     'Newest first',     Icons.arrow_downward_rounded),
        _sortItem(TripSort.oldestFirst,     'Oldest first',     Icons.arrow_upward_rounded),
        _sortItem(TripSort.highestEarnings, 'Highest earnings', Icons.trending_up_rounded),
        _sortItem(TripSort.lowestEarnings,  'Lowest earnings',  Icons.trending_down_rounded),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE5E9F0), width: 1.5),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.swap_vert_rounded, size: 15, color: Color(0xFF6B7280)),
          const SizedBox(width: 6),
          Text(_label,
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
          const SizedBox(width: 4),
          const Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: Color(0xFFADB5BD)),
        ]),
      ),
    );
  }

  PopupMenuItem<TripSort> _sortItem(TripSort value, String label, IconData icon) {
    final isSelected = current == value;
    return PopupMenuItem(
      value: value,
      child: Row(children: [
        Icon(icon, size: 15,
            color: isSelected ? const Color(0xFF1A56DB) : const Color(0xFF9CA3AF)),
        const SizedBox(width: 10),
        Text(label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected ? const Color(0xFF1A56DB) : const Color(0xFF374151),
            )),
        if (isSelected) ...[
          const Spacer(),
          const Icon(Icons.check_rounded, size: 14, color: Color(0xFF1A56DB)),
        ],
      ]),
    );
  }
}