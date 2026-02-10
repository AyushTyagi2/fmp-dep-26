import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fmp_app/presentation/auth/auth_controller.dart';

class PhoneInputScreen extends StatefulWidget {
  const PhoneInputScreen({super.key});

  @override
  State<PhoneInputScreen> createState() => _PhoneInputScreenState();
}

class _PhoneInputScreenState extends State<PhoneInputScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneCtrl = TextEditingController();
  //final _vehicleCtrl = TextEditingController();

  @override
  void dispose() {
    _phoneCtrl.dispose();
   // _vehicleCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendOtp(BuildContext context) async {
    final auth = context.read<AuthController>();

    if (!_formKey.currentState!.validate()) return;

    auth.setPhone(_phoneCtrl.text.trim());
    //auth.setVehicle(_vehicleCtrl.text.trim());

    await auth.sendOtp();
    if(!mounted) return;
    if (auth.stage == AuthStage.otpSent) {
      Navigator.pushNamed(context, '/otp');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  prefixText: '+91 ',
                ),
                validator: (v) {
                  final s = v?.trim() ?? '';
                  if (s.length < 10) return 'Enter valid phone number';
                  return null;
                },
              ),
              
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: auth.stage == AuthStage.otpSending
                      ? null
                      : () => _sendOtp(context),
                  child: auth.stage == AuthStage.otpSending
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Send OTP'),
                ),
              ),
              if (auth.stage == AuthStage.error && auth.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    auth.errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
