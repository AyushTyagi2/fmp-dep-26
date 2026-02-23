import 'package:flutter/material.dart';
import 'package:fmp_app/presentation/fleetmgr/home/fleet_home_screen.dart';
import 'package:fmp_app/presentation/fleetmgr/drivers/fleet_drivers_screen.dart';
import 'package:fmp_app/presentation/fleetmgr/vehicles/fleet_vehicles_screen.dart';
import 'package:fmp_app/presentation/fleetmgr/trips/fleet_trips_screen.dart';
import 'package:fmp_app/presentation/fleetmgr/profile/fleet_profile_screen.dart';

class FleetDashboardScreen extends StatefulWidget {
  const FleetDashboardScreen({super.key});

  @override
  State<FleetDashboardScreen> createState() => _FleetDashboardScreenState();
}

class _FleetDashboardScreenState extends State<FleetDashboardScreen> {
  int _index = 0;

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
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_index],
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
}
