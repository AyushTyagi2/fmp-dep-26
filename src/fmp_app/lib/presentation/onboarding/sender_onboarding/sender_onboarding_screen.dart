import 'package:flutter/material.dart';
import 'sender_api.dart';
class SenderOnboardingScreen extends StatefulWidget {
  const SenderOnboardingScreen({super.key});

  @override
  State<SenderOnboardingScreen> createState() =>
      _SenderOnboardingScreenState();
}

class _SenderOnboardingScreenState extends State<SenderOnboardingScreen> {
  final _formKey = GlobalKey<FormState>();

  // Organization
  final _orgNameCtrl = TextEditingController();
  final _contactNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _industryCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  // Address
  final _addrLineCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _postalCtrl = TextEditingController();

  String _orgType = "company";

  void _submit() async {
  if (_formKey.currentState!.validate()) {
    await SenderApi().submitSenderOnboarding(
      orgName: _orgNameCtrl.text,
      orgType: _orgType,
      contactName: _contactNameCtrl.text,
      phone: _phoneCtrl.text,
      email: _emailCtrl.text,
      industry: _industryCtrl.text,
      description: _descCtrl.text,
      addressLine: _addrLineCtrl.text,
      city: _cityCtrl.text,
      state: _stateCtrl.text,
      postalCode: _postalCtrl.text,
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Sender Onboarding")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const Text("Organization Info",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

              TextFormField(
                controller: _orgNameCtrl,
                decoration: const InputDecoration(labelText: "Business Name"),
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),

              DropdownButtonFormField(
                initialValue: _orgType,
                items: const [
                  DropdownMenuItem(value: "company", child: Text("Company")),
                  DropdownMenuItem(value: "individual", child: Text("Individual")),
                  DropdownMenuItem(value: "partnership", child: Text("Partnership")),
                ],
                onChanged: (v) => setState(() => _orgType = v!),
                decoration: const InputDecoration(labelText: "Organization Type"),
              ),

              TextFormField(
                controller: _contactNameCtrl,
                decoration:
                    const InputDecoration(labelText: "Primary Contact Name"),
              ),

              TextFormField(
                controller: _phoneCtrl,
                decoration:
                    const InputDecoration(labelText: "Contact Phone"),
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),

              TextFormField(
                controller: _emailCtrl,
                decoration:
                    const InputDecoration(labelText: "Contact Email"),
              ),

              TextFormField(
                controller: _industryCtrl,
                decoration:
                    const InputDecoration(labelText: "Industry"),
              ),

              TextFormField(
                controller: _descCtrl,
                decoration:
                    const InputDecoration(labelText: "Description"),
                maxLines: 2,
              ),

              const SizedBox(height: 24),
              const Text("Default Pickup Address",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

              TextFormField(
                controller: _addrLineCtrl,
                decoration:
                    const InputDecoration(labelText: "Address Line"),
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),

              TextFormField(
                controller: _cityCtrl,
                decoration: const InputDecoration(labelText: "City"),
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),

              TextFormField(
                controller: _stateCtrl,
                decoration: const InputDecoration(labelText: "State"),
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),

              TextFormField(
                controller: _postalCtrl,
                decoration:
                    const InputDecoration(labelText: "Postal Code"),
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),

              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _submit,
                child: const Text("Complete Onboarding"),
              )
            ],
          ),
        ),
      ),
    );
  }
}
