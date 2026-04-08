import 'package:flutter/material.dart';
import 'package:fmp_app/app_session.dart';
import 'package:fmp_app/core/network/api_client.dart';
import 'package:fmp_app/core/network/api_trips.dart';

// lib/presentation/driver/billing/driver_billing_screen.dart

class DriverBillingScreen extends StatefulWidget {
  const DriverBillingScreen({super.key});

  @override
  State<DriverBillingScreen> createState() => _DriverBillingScreenState();
}

class _DriverBillingScreenState extends State<DriverBillingScreen> {
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

  double get _totalEarnings => _trips
      .where((t) => t.agreedPrice != null)
      .fold<double>(0, (sum, t) => sum + t.agreedPrice!);

  List<TripSummary> get _paidTrips => _trips
      .where((t) => t.currentStatus == 'completed' || t.currentStatus == 'delivered')
      .toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF111827)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Billing',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Color(0xFF1A56DB))))
          : _error != null
              ? _ErrorState(message: _error!, onRetry: _loadTrips)
              : RefreshIndicator(
                  color: const Color(0xFF1A56DB),
                  onRefresh: _loadTrips,
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: _EarningsSummaryCard(totalEarnings: _totalEarnings, completedTrips: _paidTrips.length),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                          child: const Text('Trip Payments', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
                        ),
                      ),
                      _paidTrips.isEmpty
                          ? const SliverFillRemaining(child: _EmptyBilling())
                          : SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, i) => Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                                  child: _BillingCard(trip: _paidTrips[i]),
                                ),
                                childCount: _paidTrips.length,
                              ),
                            ),
                      const SliverToBoxAdapter(child: SizedBox(height: 40)),
                    ],
                  ),
                ),
    );
  }
}

class _EarningsSummaryCard extends StatelessWidget {
  final double totalEarnings;
  final int completedTrips;
  const _EarningsSummaryCard({required this.totalEarnings, required this.completedTrips});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF1A56DB), Color(0xFF0C3997)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: const Color(0xFF1A56DB).withOpacity(0.25), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Total Earnings', style: TextStyle(fontSize: 13, color: Colors.white70)),
          const SizedBox(height: 6),
          Text('₹${totalEarnings.toStringAsFixed(0)}', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: Colors.white)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(100)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_rounded, size: 14, color: Colors.white),
                const SizedBox(width: 6),
                Text('$completedTrips Completed', style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BillingCard extends StatelessWidget {
  final TripSummary trip;
  const _BillingCard({required this.trip});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE5E9F0)), boxShadow: const [BoxShadow(color: Color(0x05000000), blurRadius: 8, offset: Offset(0, 2))]),
      child: Row(
        children: [
          Container(width: 42, height: 42, decoration: BoxDecoration(color: const Color(0xFFDEF7EC), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.receipt_long_rounded, size: 20, color: Color(0xFF0E9F6E))),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(trip.tripNumber, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
              Text(trip.shipmentNumber, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
            ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            if (trip.agreedPrice != null)
              Text('₹${trip.agreedPrice!.toStringAsFixed(0)}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: const Color(0xFFDEF7EC), borderRadius: BorderRadius.circular(100)),
              child: const Text('Paid', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF057A55))),
            ),
          ]),
        ],
      ),
    );
  }
}

class _EmptyBilling extends StatelessWidget {
  const _EmptyBilling();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(width: 80, height: 80, decoration: BoxDecoration(color: const Color(0xFFEBF0FE), borderRadius: BorderRadius.circular(20)), child: const Icon(Icons.receipt_long_rounded, size: 40, color: Color(0xFF1A56DB))),
          const SizedBox(height: 20),
          const Text('No payments yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
          const SizedBox(height: 8),
          const Text('Completed trips will appear\nhere with payment details', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Color(0xFF6B7280), height: 1.5)),
        ]),
      ),
    );
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
          const Text('Failed to load billing', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
          const SizedBox(height: 6),
          Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
          const SizedBox(height: 20),
          TextButton(onPressed: onRetry, child: const Text('Try Again', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1A56DB)))),
        ]),
      ),
    );
  }
}