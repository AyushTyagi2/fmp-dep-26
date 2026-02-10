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
  final _formKey = GlobalKey<FormState>();
  String? _vehicleType;

  final _nameCtrl = TextEditingController();
  final _licenseCtrl = TextEditingController();
  final _expCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _licenseCtrl.dispose();
    _expCtrl.dispose();
    super.dispose();
  }

 void _continue() async {
  if (_vehicleType == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Please select vehicle type")),
    );
    return;
  }

  if (_formKey.currentState!.validate()) {
    try {
      await AuthApi().submitDriverDetails(
        phone: AppSession.phone!,
        vehicleNumber: _nameCtrl.text,
        vehicleType: _vehicleType!
      );

      Navigator.pushNamed(context, '/driver-dashboard');
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to save details")),
      );
    }
  }
}



  Widget _vehicleButton(String type) {
    final bool selected = _vehicleType == type;

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: selected ? Colors.blue : Colors.grey[300],
        foregroundColor: selected ? Colors.white : Colors.black,
      ),
      onPressed: () {
        setState(() {
          _vehicleType = type;
        });
      },
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
      controller: _nameCtrl,
      decoration: const InputDecoration(
        labelText: 'Vehicle Number',
      ),
      validator: (v) =>
          v == null || v.trim().isEmpty ? 'Required' : null,
    ),

    const Spacer(),

    SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _continue,
        child: const Text('Continue'),
      ),
    ),
  ],
)

        ),
      ),
    );
  }
}
