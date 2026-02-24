import 'package:flutter/material.dart';
import 'package:fmp_app/presentation/fleetmgr/home/fleet_home_screen.dart';
import 'package:fmp_app/presentation/fleetmgr/drivers/fleet_drivers_screen.dart';
import 'package:fmp_app/presentation/fleetmgr/vehicles/fleet_vehicles_screen.dart';
import 'package:fmp_app/presentation/fleetmgr/trips/fleet_trips_screen.dart';
import 'package:fmp_app/presentation/fleetmgr/profile/fleet_profile_screen.dart';
import 'package:fmp_app/core/models/fleet_dashboard.dart';
import 'package:fmp_app/presentation/fleetmgr/fleet_api.dart';
import 'package:fmp_app/app_session.dart';

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
      appBar: AppBar(title: const Text('Fleet Dashboard')),
      body: _index == 0 ? _buildDashboard() : _pages[_index],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _index,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Drivers'),
          BottomNavigationBarItem(icon: Icon(Icons.directions_car), label: 'Vehicles'),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Trips'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildDashboard() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_dashboard == null) return const Center(child: Text('No fleet owner selected'));

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _dashboard!.fleetOwnerName,
            style: Theme.of(context).textTheme.titleLarge ?? const TextStyle(fontSize: 20),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _statCard('Active Drivers', _dashboard!.activeDrivers.toString()),
              const SizedBox(width: 12),
              _statCard('Active Trips', _dashboard!.activeTrips.toString()),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _statCard('Vehicle Issues', _dashboard!.vehicleIssues.toString()),
              const SizedBox(width: 12),
              _statCard('Trips With Issues', _dashboard!.tripsWithIssues.toString()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statCard(String title, String value) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 8),
              Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}
