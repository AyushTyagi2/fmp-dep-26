import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_trips.dart';
import '../../../app_session.dart';
import 'package:fmp_app/presentation/driver/home/driver_home_screen.dart';

class DriverTripsScreen extends StatefulWidget {
  const DriverTripsScreen({super.key});

  @override
  State<DriverTripsScreen> createState() => _DriverTripsScreenState();
}

class _DriverTripsScreenState extends State<DriverTripsScreen> {
  late final TripApiService _api;
  List<TripSummary> _trips   = [];
  bool              _loading = true;
  String?           _error;

  @override
  void initState() {
    super.initState();
    _api = TripApiService(ApiClient());
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    final driverId = AppSession.driverId;
    if (driverId == null) {
      setState(() { _error = 'Not logged in'; _loading = false; });
      return;
    }
    try {
      final trips = await _api.getDriverTrips(driverId);
      if (!mounted) return;
      setState(() { _trips = trips; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Trips'),
        backgroundColor: const Color(0xFF1B3A6B),
        foregroundColor: Colors.white,
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _load)],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_error != null) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.error_outline, size: 48, color: Colors.grey),
        const SizedBox(height: 12),
        Text(_error!),
        const SizedBox(height: 16),
        ElevatedButton(onPressed: _load, child: const Text('Retry')),
      ]));
    }

    if (_trips.isEmpty) {
      return const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.history, size: 64, color: Colors.grey),
        SizedBox(height: 12),
        Text('No trips yet', style: TextStyle(fontSize: 16, color: Colors.grey)),
        SizedBox(height: 4),
        Text('Accepted shipments will appear here', style: TextStyle(color: Colors.grey, fontSize: 12)),
      ]));
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _trips.length,
        itemBuilder: (_, i) => _TripCard(
          trip: _trips[i],
          onTap: _trips[i].currentStatus != 'delivered'
              ? () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => ActiveTripScreen(tripId: _trips[i].id)),
                  ).then((_) => _load())
              : null,
        ),
      ),
    );
  }
}

class _TripCard extends StatelessWidget {
  final TripSummary  trip;
  final VoidCallback? onTap;
  const _TripCard({required this.trip, this.onTap});

  Color get _color => switch (trip.currentStatus) {
    'assigned'   => const Color(0xFFFF9800),
    'in_transit' => const Color(0xFF9C27B0),
    'delivered'  => const Color(0xFF4CAF50),
    _            => Colors.grey,
  };

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    elevation: 2,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(shape: BoxShape.circle, color: _color)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(trip.shipmentNumber, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(trip.tripNumber, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            if (trip.agreedPrice != null)
              Text('₹${trip.agreedPrice!.toStringAsFixed(0)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: _color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: Text(trip.currentStatus.replaceAll('_', ' '),
                  style: TextStyle(color: _color, fontSize: 11, fontWeight: FontWeight.w600)),
            ),
          ]),
          if (onTap != null) ...[const SizedBox(width: 8), const Icon(Icons.chevron_right, color: Colors.grey)],
        ]),
      ),
    ),
  );
}