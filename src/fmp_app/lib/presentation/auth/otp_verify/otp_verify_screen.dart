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
  bool _navigated = false; // prevents double-navigation on rebuilds

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_navigated) return;
      if (auth.stage == AuthStage.verified) {
        _navigated = true;
        auth.navigateAfterVerify(context);
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
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: 'Enter OTP',
                counterText: '',
              ),
            ),
            const SizedBox(height: 12),

            // Countdown / resend
            if (auth.secondsLeft > 0)
              Text(
                'Resend OTP in ${auth.secondsLeft}s',
                style: const TextStyle(color: Colors.grey),
              )
            else
              TextButton(
                onPressed: () {
                  setState(() => _navigated = false);
                  auth.sendOtp();
                },
                child: const Text('Resend OTP'),
              ),

            const SizedBox(height: 16),

            if (auth.stage == AuthStage.verifyingOtp)
              const CircularProgressIndicator()
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() => _navigated = false);
                    auth.verifyOtp(_otpController.text.trim());
                  },
                  child: const Text('Verify'),
                ),
              ),

            if (auth.stage == AuthStage.error && auth.errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  auth.errorMessage!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }
}