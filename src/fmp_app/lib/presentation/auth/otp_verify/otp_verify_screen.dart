import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth_controller.dart';

class OtpVerifyScreen extends StatelessWidget {
  const OtpVerifyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final otpController = TextEditingController();
    final auth = context.read<AuthController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Verify OTP')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: otpController,
              decoration: const InputDecoration(labelText: 'OTP'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
                onPressed: () async {
                    await auth.verifyOtp(otpController.text);
                    if (auth.stage == AuthStage.authenticated) {
                    Navigator.pushReplacementNamed(context, '/role-selection');
                    }
                },
                child: const Text('Verify'),
                ),

          ],
        ),
      ),
    );
  }
}
