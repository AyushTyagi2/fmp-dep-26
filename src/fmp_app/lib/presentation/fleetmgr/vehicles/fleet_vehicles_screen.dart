import 'package:flutter/material.dart';

class FleetVehiclesScreen extends StatelessWidget {
  const FleetVehiclesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vehicles')),
      body: const Center(child: Text('Fleet vehicles list and management')),
    );
  }
}
