import 'package:flutter/material.dart';

class DriverTripsScreen extends StatelessWidget {
  const DriverTripsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          'No trips yet',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
