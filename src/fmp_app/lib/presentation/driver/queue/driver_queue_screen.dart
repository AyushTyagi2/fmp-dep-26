import 'package:flutter/material.dart';

class DriverQueueScreen extends StatelessWidget {
  const DriverQueueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Queue'),
      ),
      body: const Center(
        child: Text(
          'Driver Queue Placeholder',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}