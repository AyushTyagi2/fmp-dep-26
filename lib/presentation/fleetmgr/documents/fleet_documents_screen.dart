import 'package:flutter/material.dart';

class FleetDocumentsScreen extends StatelessWidget {
  const FleetDocumentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Documents')),
      body: const Center(child: Text('Fleet documents and uploads')),
    );
  }
}
