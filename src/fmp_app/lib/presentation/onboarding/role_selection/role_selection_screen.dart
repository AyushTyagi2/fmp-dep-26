import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fmp_app/presentation/auth/auth_controller.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Choose Role')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => auth.chooseRole(context, "driver"),
              child: const Text('I am a Driver'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => auth.chooseRole(context, "organization"),
              child: const Text('I want to Send / Receive Goods'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => auth.chooseRole(context, "fleet_owner"),
              child: const Text('I am a Fleet Owner'),
            ),
          ],
        ),
      ),
    );
  }
}
