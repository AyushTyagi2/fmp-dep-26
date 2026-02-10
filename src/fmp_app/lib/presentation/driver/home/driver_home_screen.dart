import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../driver_state.dart';

class DriverHomeScreen extends StatelessWidget {
  const DriverHomeScreen({super.key});

  String _buttonText(TripStatus status) {
    switch (status) {
      case TripStatus.assigned:
        return 'Start Trip';
      case TripStatus.started:
        return 'Reached Pickup';
      case TripStatus.reachedPickup:
        return 'Load Cargo';
      case TripStatus.loaded:
        return 'Start Delivery';
      case TripStatus.inTransit:
        return 'Mark Delivered';
      case TripStatus.delivered:
        return 'Finish';
    }
  }

  @override
  Widget build(BuildContext context) {
    final driverState = context.watch<DriverState>();

    if (!driverState.hasActiveTrip) {
      return const Scaffold(
        body: Center(
          child: Text(
            'No active trip assigned',
            style: TextStyle(fontSize: 18),
          ),
        ),
      );
    }

    final trip = driverState.activeTrip!;

    return Scaffold(
      appBar: AppBar(title: const Text('Active Trip')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  trip.route,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text('Pickup: ${trip.pickupTime}'),
                const SizedBox(height: 8),
                Text('Status: ${trip.status.name}'),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      driverState.advanceStatus();
                    },
                    child: Text(_buttonText(trip.status)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
