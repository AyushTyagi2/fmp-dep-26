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
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              itemCount: state.drivers.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final d = state.drivers[index] as Driver;

                // build initials for avatar
                final name = (d.fullName ?? '').trim();
                String initials = '';
                if (name.isNotEmpty) {
                  final parts = name.split(' ');
                  initials = parts.map((p) => p.isNotEmpty ? p[0] : '').take(2).join().toUpperCase();
                } else if ((d.phone ?? '').isNotEmpty) {
                  initials = d.phone!.replaceAll(RegExp(r'[^0-9]'), '');
                  if (initials.length > 2) initials = initials.substring(initials.length - 2);
                }

                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FleetDriverDetailsScreen(driverId: d.id))),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 26,
                            backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.12),
                            child: Text(initials.isNotEmpty ? initials : 'DR', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  d.fullName.isNotEmpty ? d.fullName : d.phone,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 6),
                                Text('License: ${d.licenseNumber}', style: TextStyle(color: Colors.grey[700], fontSize: 13)),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 6,
                                  children: [
                                    Chip(label: Text(d.status ?? 'unknown'), backgroundColor: Colors.grey.shade100),
                                    if (d.currentVehicle != null) Chip(label: Text(d.currentVehicle!.vehicleType), backgroundColor: Colors.grey.shade100),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          ConstrainedBox(
                            constraints: const BoxConstraints(minWidth: 72),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.star, size: 16, color: Colors.amber[700]),
                                    const SizedBox(width: 4),
                                    Text((d.averageRating ?? 0).toStringAsFixed(1)),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text('${d.totalTripsCompleted ?? 0} trips', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
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
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          CircleAvatar(radius: 30, child: Text((_driver!.fullName ?? '').isNotEmpty ? _driver!.fullName.split(' ').map((p) => p.isNotEmpty ? p[0] : '').take(2).join().toUpperCase() : 'DR')),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_driver!.fullName, style: Theme.of(context).textTheme.titleLarge),
                                const SizedBox(height: 6),
                                Wrap(spacing: 8, children: [Chip(label: Text(_driver!.status ?? 'unknown'))]),
                              ],
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 16),

                      Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Contact', style: Theme.of(context).textTheme.titleMedium),
                              const SizedBox(height: 8),
                              ListTile(leading: const Icon(Icons.phone), title: Text(_driver!.phone ?? ''), dense: true),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),
                      Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('License', style: Theme.of(context).textTheme.titleMedium),
                              const SizedBox(height: 8),
                              ListTile(leading: const Icon(Icons.badge), title: Text('${_driver!.licenseNumber} (${_driver!.licenseType})'), dense: true),
                              if (_driver!.currentVehicle != null) ...[
                                const Divider(),
                                Text('Vehicle', style: Theme.of(context).textTheme.titleMedium),
                                const SizedBox(height: 8),
                                ListTile(leading: const Icon(Icons.directions_car), title: Text(_driver!.currentVehicle!.registrationNumber), subtitle: Text(_driver!.currentVehicle!.vehicleType), dense: true),
                              ]
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),
                      Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(children: [Icon(Icons.star, color: Colors.amber[700]), const SizedBox(width: 8), Text((_driver!.averageRating ?? 0).toStringAsFixed(1))]),
                              Text('${_driver!.totalTripsCompleted ?? 0} trips', style: const TextStyle(color: Colors.black54)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}