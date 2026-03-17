import 'package:flutter/material.dart';
import 'fleetmgr_api.dart';

class FleetmgrOnboardingScreen extends StatefulWidget {
  const FleetmgrOnboardingScreen({super.key});

  @override
  State<FleetmgrOnboardingScreen> createState() =>
      _FleetmgrOnboardingScreenState();
}

class _FleetmgrOnboardingScreenState extends State<FleetmgrOnboardingScreen> {
  final _formKey = GlobalKey<FormState>();

  // Organization fields
  final _orgNameCtrl = TextEditingController();
  String _orgType = 'company';
  final _contactNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  // Address
  final _addrLineCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _postalCtrl = TextEditingController();

  // Dynamic lists
  final List<_DriverEntry> _drivers = [];
  final List<_VehicleEntry> _vehicles = [];

  @override
  void initState() {
    super.initState();
    _addDriver();
    _addVehicle();
  }

  void _addDriver() {
    setState(() => _drivers.add(_DriverEntry()));
  }

  void _removeDriver(int idx) {
    setState(() {
      _drivers[idx].dispose();
      _drivers.removeAt(idx);
    });
  }

  void _addVehicle() {
    setState(() => _vehicles.add(_VehicleEntry()));
  }

  void _removeVehicle(int idx) {
    setState(() {
      _vehicles[idx].dispose();
      _vehicles.removeAt(idx);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final drivers = _drivers.map((d) {
      return {
        'name': d.name.text,
        'phone': d.phone.text,
        if (d.licenseNumber.text.isNotEmpty) 'license_number': d.licenseNumber.text,
        if (d.licenseType.text.isNotEmpty) 'license_type': d.licenseType.text,
        if (d.yearsOfExperience.text.isNotEmpty)
          'years_of_experience': int.tryParse(d.yearsOfExperience.text),
        if (d.emergencyContactName.text.isNotEmpty)
          'emergency_contact_name': d.emergencyContactName.text,
        if (d.emergencyContactPhone.text.isNotEmpty)
          'emergency_contact_phone': d.emergencyContactPhone.text,
      };
    }).toList();

    final vehicles = _vehicles.map((v) {
      return {
        'registration_number': v.registrationNumber.text,
        'vehicle_type': v.vehicleType.text,
        if (v.chassisNumber.text.isNotEmpty) 'chassis_number': v.chassisNumber.text,
        if (v.manufacturer.text.isNotEmpty) 'manufacturer': v.manufacturer.text,
        if (v.model.text.isNotEmpty) 'model': v.model.text,
        if (v.manufactureYear.text.isNotEmpty)
          'manufacture_year': int.tryParse(v.manufactureYear.text),
        if (v.capacityTons.text.isNotEmpty)
          'capacity_tons': double.tryParse(v.capacityTons.text),
      };
    }).toList();

    try {
      await FleetmgrApi().submitFleetOnboarding(
        orgName: _orgNameCtrl.text,
        orgType: _orgType,
        contactName: _contactNameCtrl.text,
        phone: _phoneCtrl.text,
        email: _emailCtrl.text,
        addressLine: _addrLineCtrl.text,
        city: _cityCtrl.text,
        state: _stateCtrl.text,
        postalCode: _postalCtrl.text,
        drivers: drivers,
        vehicles: vehicles,
      );
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/fleet-dashboard');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit onboarding: $e')),
      );
    }
  }

  @override
  void dispose() {
    _orgNameCtrl.dispose();
    _contactNameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _addrLineCtrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    _postalCtrl.dispose();
    for (final d in _drivers) {
      d.dispose();
    }
    for (final v in _vehicles) {
      v.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(title: const Text('Fleet Onboarding'), bottom: const TabBar(tabs: [
          Tab(text: 'Drivers'),
          Tab(text: 'Vehicles'),
        ])),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Organization Info', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  TextFormField(
                    controller: _orgNameCtrl,
                    decoration: const InputDecoration(labelText: 'Business Name'),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
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
                    decoration: const InputDecoration(labelText: 'Primary Contact Name'),
                  ),
                  TextFormField(
                    controller: _phoneCtrl,
                    decoration: const InputDecoration(labelText: 'Contact Phone'),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  TextFormField(
                    controller: _emailCtrl,
                    decoration: const InputDecoration(labelText: 'Contact Email'),
                  ),
                  const SizedBox(height: 16),
                  const Text('Address', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  TextFormField(
                    controller: _addrLineCtrl,
                    decoration: const InputDecoration(labelText: 'Address Line'),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  TextFormField(
                    controller: _cityCtrl,
                    decoration: const InputDecoration(labelText: 'City'),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  TextFormField(
                    controller: _stateCtrl,
                    decoration: const InputDecoration(labelText: 'State'),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  TextFormField(
                    controller: _postalCtrl,
                    decoration: const InputDecoration(labelText: 'Postal Code'),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 420,
                    child: TabBarView(children: [
                      // Drivers tab
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: ListView.builder(
                              itemCount: _drivers.length,
                              itemBuilder: (_, idx) {
                                final d = _drivers[idx];
                                return Card(
                                  margin: const EdgeInsets.symmetric(vertical: 8),
                                  child: Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Column(
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text('Driver ${idx + 1}'),
                                            IconButton(
                                              icon: const Icon(Icons.delete),
                                              onPressed: () => _removeDriver(idx),
                                            )
                                          ],
                                        ),
                                        TextFormField(
                                          controller: d.name,
                                          decoration: const InputDecoration(labelText: 'Name'),
                                          validator: (v) => v!.isEmpty ? 'Required' : null,
                                        ),
                                        TextFormField(
                                          controller: d.phone,
                                          decoration: const InputDecoration(labelText: 'Phone'),
                                          validator: (v) => v!.isEmpty ? 'Required' : null,
                                        ),
                                        TextFormField(
                                          controller: d.licenseNumber,
                                          decoration: const InputDecoration(labelText: 'License Number (optional)'),
                                        ),
                                        TextFormField(
                                          controller: d.licenseType,
                                          decoration: const InputDecoration(labelText: 'License Type (optional)'),
                                        ),
                                        TextFormField(
                                          controller: d.yearsOfExperience,
                                          decoration: const InputDecoration(labelText: 'Years of Experience (optional)'),
                                          keyboardType: TextInputType.number,
                                        ),
                                        TextFormField(
                                          controller: d.emergencyContactName,
                                          decoration: const InputDecoration(labelText: 'Emergency Contact Name (optional)'),
                                        ),
                                        TextFormField(
                                          controller: d.emergencyContactPhone,
                                          decoration: const InputDecoration(labelText: 'Emergency Contact Phone (optional)'),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          TextButton.icon(
                            onPressed: _addDriver,
                            icon: const Icon(Icons.add),
                            label: const Text('Add one more'),
                          ),
                        ],
                      ),
                      // Vehicles tab
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: ListView.builder(
                              itemCount: _vehicles.length,
                              itemBuilder: (_, idx) {
                                final v = _vehicles[idx];
                                return Card(
                                  margin: const EdgeInsets.symmetric(vertical: 8),
                                  child: Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Column(
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text('Vehicle ${idx + 1}'),
                                            IconButton(
                                              icon: const Icon(Icons.delete),
                                              onPressed: () => _removeVehicle(idx),
                                            )
                                          ],
                                        ),
                                        TextFormField(
                                          controller: v.registrationNumber,
                                          decoration: const InputDecoration(labelText: 'Registration Number'),
                                          validator: (v) => v!.isEmpty ? 'Required' : null,
                                        ),
                                        TextFormField(
                                          controller: v.vehicleType,
                                          decoration: const InputDecoration(labelText: 'Vehicle Type'),
                                          validator: (v) => v!.isEmpty ? 'Required' : null,
                                        ),
                                        TextFormField(
                                          controller: v.chassisNumber,
                                          decoration: const InputDecoration(labelText: 'Chassis Number (optional)'),
                                        ),
                                        TextFormField(
                                          controller: v.manufacturer,
                                          decoration: const InputDecoration(labelText: 'Manufacturer (optional)'),
                                        ),
                                        TextFormField(
                                          controller: v.model,
                                          decoration: const InputDecoration(labelText: 'Model (optional)'),
                                        ),
                                        TextFormField(
                                          controller: v.manufactureYear,
                                          decoration: const InputDecoration(labelText: 'Manufacture Year (optional)'),
                                          keyboardType: TextInputType.number,
                                        ),
                                        TextFormField(
                                          controller: v.capacityTons,
                                          decoration: const InputDecoration(labelText: 'Capacity (tons) (optional)'),
                                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          TextButton.icon(
                            onPressed: _addVehicle,
                            icon: const Icon(Icons.add),
                            label: const Text('Add one more'),
                          ),
                        ],
                      ),
                    ]),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: _submit, child: const Text('Complete Onboarding')),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DriverEntry {
  final TextEditingController name = TextEditingController();
  final TextEditingController phone = TextEditingController();
  final TextEditingController licenseNumber = TextEditingController();
  final TextEditingController licenseType = TextEditingController();
  final TextEditingController yearsOfExperience = TextEditingController();
  final TextEditingController emergencyContactName = TextEditingController();
  final TextEditingController emergencyContactPhone = TextEditingController();

  void dispose() {
    name.dispose();
    phone.dispose();
    licenseNumber.dispose();
    licenseType.dispose();
    yearsOfExperience.dispose();
    emergencyContactName.dispose();
    emergencyContactPhone.dispose();
  }
}

class _VehicleEntry {
  final TextEditingController registrationNumber = TextEditingController();
  final TextEditingController vehicleType = TextEditingController();
  final TextEditingController chassisNumber = TextEditingController();
  final TextEditingController manufacturer = TextEditingController();
  final TextEditingController model = TextEditingController();
  final TextEditingController manufactureYear = TextEditingController();
  final TextEditingController capacityTons = TextEditingController();

  void dispose() {
    registrationNumber.dispose();
    vehicleType.dispose();
    chassisNumber.dispose();
    manufacturer.dispose();
    model.dispose();
    manufactureYear.dispose();
    capacityTons.dispose();
  }
}
