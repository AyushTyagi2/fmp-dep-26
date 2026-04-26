import 'package:flutter/material.dart';

class FleetTripsScreen extends StatelessWidget {
  const FleetTripsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trips'),
      
  automaticallyImplyLeading: false,
  ),
      body: const Center(child: Text('Fleet trips history and management')),
    );
  }
}
