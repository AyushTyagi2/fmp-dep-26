import 'package:flutter/material.dart';

class FleetHomeScreen extends StatelessWidget {
  const FleetHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fleet Home')),
      body: const Center(child: Text('Fleet overview and KPIs')),
    );
  }
}
