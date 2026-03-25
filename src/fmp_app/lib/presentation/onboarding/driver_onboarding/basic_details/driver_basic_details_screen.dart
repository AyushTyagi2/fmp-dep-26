import 'package:flutter/material.dart';
import 'package:fmp_app/app_session.dart';
import 'package:fmp_app/presentation/auth/auth_api.dart';

class DriverBasicDetailsScreen extends StatefulWidget {
  const DriverBasicDetailsScreen({super.key});

  @override
  State<DriverBasicDetailsScreen> createState() =>
      _DriverBasicDetailsScreenState();
}

class _DriverBasicDetailsScreenState extends State<DriverBasicDetailsScreen> {
  final _formKey    = GlobalKey<FormState>();
  final _authApi    = AuthApi();
  String? _vehicleType;
  final _vehicleNumberCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _vehicleNumberCtrl.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    if (_vehicleType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a vehicle type")),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      await _authApi.submitDriverDetails(
        phone:         AppSession.phone!,
        vehicleNumber: _vehicleNumberCtrl.text.trim(),
        vehicleType:   _vehicleType!,
      );
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/driver-dashboard');
    } catch (e) {
      print("[DriverBasicDetails] error: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to save details. Please try again.")),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _vehicleButton(String type) {
    final selected = _vehicleType == type;
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: selected ? Colors.blue : Colors.grey[300],
        foregroundColor: selected ? Colors.white : Colors.black,
      ),
      onPressed: () => setState(() => _vehicleType = type),
      child: Text(type),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Driver Details')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const Text(
                "Select Vehicle Type",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                children: [
                  _vehicleButton("Truck"),
                  _vehicleButton("Lorry"),
                  _vehicleButton("Tanker"),
                  _vehicleButton("Car"),
                ],
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _vehicleNumberCtrl,
                decoration: const InputDecoration(labelText: 'Vehicle Number'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _continue,
                  child: _loading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Continue'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}