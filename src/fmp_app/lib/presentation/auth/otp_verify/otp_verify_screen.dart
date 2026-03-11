import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth_controller.dart';

class OtpVerifyScreen extends StatefulWidget {
  const OtpVerifyScreen({super.key});

  @override
  State<OtpVerifyScreen> createState() => _OtpVerifyScreenState();
}

class _OtpVerifyScreenState extends State<OtpVerifyScreen> {
  final _otpController = TextEditingController();

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (auth.stage == AuthStage.authenticated) {
        Navigator.pushReplacementNamed(context, '/role-selection');
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Verify OTP')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'OTP'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => auth.verifyOtp(_otpController.text),
              child: const Text('Verify'),
            ),
          ],
        ),
      ),
    );
  }
}