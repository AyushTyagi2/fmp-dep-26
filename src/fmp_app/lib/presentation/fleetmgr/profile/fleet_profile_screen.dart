import 'package:flutter/material.dart';

class FleetProfileScreen extends StatelessWidget {
  const FleetProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: const Center(child: Text('Fleet manager profile and settings')),
    );
  }
}
