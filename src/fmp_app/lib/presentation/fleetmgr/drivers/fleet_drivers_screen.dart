import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../fleetmgr/fleet_api.dart';
import '../../fleetmgr/fleet_state.dart';
import '../../../core/models/driver.dart';
import '../../../app_session.dart';

class FleetDriversScreen extends StatefulWidget {
  const FleetDriversScreen({super.key});

  @override
  State<FleetDriversScreen> createState() => _FleetDriversScreenState();
}

class _FleetDriversScreenState extends State<FleetDriversScreen> {
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadDrivers();
  }

  Future<void> _loadDrivers() async {
    final phone = AppSession.phone;
    if (phone == null) return;
    setState(() => _loading = true);
    try {
      final api = FleetApi();
      final drivers = await api.getDriversByFleetOwnerPhone(phone);
      final state = context.read<FleetState>();
      // replace the list and notify listeners
      state.drivers = drivers;
      state.notifyListeners();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load drivers: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<FleetState>();
    return Scaffold(
      appBar: AppBar(title: const Text('Drivers')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: state.drivers.length,
              itemBuilder: (context, index) {
                final d = state.drivers[index] as Driver;
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    title: Text(d.fullName.isNotEmpty ? d.fullName : d.phone),
                    subtitle: Text('${d.licenseNumber} • ${d.status}'),
                    trailing: d.currentVehicle != null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(d.currentVehicle!.registrationNumber),
                              Text(d.currentVehicle!.vehicleType, style: const TextStyle(fontSize: 12))
                            ],
                          )
                        : null,
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => FleetDriverDetailsScreen(driverId: d.id)));
                    },
                  ),
                );
              },
            ),
    );
  }
}

class FleetDriverDetailsScreen extends StatefulWidget {
  final String driverId;
  const FleetDriverDetailsScreen({required this.driverId, super.key});

  @override
  State<FleetDriverDetailsScreen> createState() => _FleetDriverDetailsScreenState();
}

class _FleetDriverDetailsScreenState extends State<FleetDriverDetailsScreen> {
  Driver? _driver;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final api = FleetApi();
      final d = await api.getDriverById(widget.driverId);
      setState(() => _driver = d);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load driver: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Driver Details')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _driver == null
              ? const Center(child: Text('No details'))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_driver!.fullName, style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 8),
                      Text('Phone: ${_driver!.phone}'),
                      Text('License: ${_driver!.licenseNumber} (${_driver!.licenseType})'),
                      Text('Status: ${_driver!.status}'),
                      const SizedBox(height: 12),
                      if (_driver!.currentVehicle != null) ...[
                        Text('Vehicle', style: Theme.of(context).textTheme.titleMedium),
                        Text('Registration: ${_driver!.currentVehicle!.registrationNumber}'),
                        Text('Type: ${_driver!.currentVehicle!.vehicleType}'),
                      ],
                      const SizedBox(height: 12),
                      Text('Rating: ${_driver!.averageRating} • Trips: ${_driver!.totalTripsCompleted}'),
                    ],
                  ),
                ),
    );
  }
}

