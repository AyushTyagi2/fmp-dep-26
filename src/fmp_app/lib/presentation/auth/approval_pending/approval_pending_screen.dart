import 'package:flutter/material.dart';

class ApprovalPendingScreen extends StatelessWidget {
  const ApprovalPendingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.hourglass_top, size: 48),
              SizedBox(height: 16),
              Text(
                'Approval Pending',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Your documents are under review.\nYou will be notified once approved.',
                textAlign: TextAlign.center,
              ),
              ElevatedButton(
                onPressed: () {
                    Navigator.pushReplacementNamed(context, '/driver-dashboard');
                },
                child: const Text('Simulate Approval'),
                ),

            ],
          ),
        ),
      ),
    );
  }
}
