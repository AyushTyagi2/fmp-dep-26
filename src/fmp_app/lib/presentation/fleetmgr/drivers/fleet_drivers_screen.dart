import 'package:flutter/material.dart';

class FleetDriversScreen extends StatelessWidget {
  const FleetDriversScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Drivers')),
      body: const Center(child: Text('Fleet drivers list and management')),
    );
  }
}
