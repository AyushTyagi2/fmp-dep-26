import 'package:flutter/material.dart';
import 'fleetmgr_api.dart';

// --- Formal Corporate UI Constants ---
const _primaryColor = Color(0xFF0F172A); // Deep Slate / Navy
const _backgroundColor = Color(0xFFF1F5F9); // Professional Light Grey
const _cardColor = Colors.white;
const _borderColor = Color(0xFFCBD5E1); // Crisp border line
const _textColorDark = Color(0xFF1E293B);
const _textColorMuted = Color(0xFF475569);

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
  
  bool _isLoading = false;

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
    
    setState(() => _isLoading = true);

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
      if (mounted) setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit onboarding: $e'), backgroundColor: const Color(0xFFDC2626)),
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

  // --- Formal Input Decoration Helper ---
  InputDecoration _buildInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: _textColorMuted, fontSize: 14),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: _borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: _borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: _primaryColor, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: Color(0xFFDC2626)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: const Text('Fleet Manager Registration', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18, letterSpacing: 0.5)),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800), // Perfect for wide screens
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              children: [
                const Text(
                  "Fleet Onboarding",
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: _textColorDark, letterSpacing: -0.5),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Register your organization and initial fleet assets to get started.",
                  style: TextStyle(fontSize: 15, color: _textColorMuted),
                ),
                const SizedBox(height: 32),

                // --- 1. ORGANIZATION INFO ---
                _buildSectionCard(
                  title: "1. Organization Information",
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _orgNameCtrl,
                            decoration: _buildInputDecoration('Registered Business Name'),
                            validator: (v) => v!.isEmpty ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 1,
                          child: DropdownButtonFormField<String>(
                            initialValue: _orgType,
                            icon: const Icon(Icons.arrow_drop_down, color: _textColorMuted),
                            decoration: _buildInputDecoration("Organization Type"),
                            items: const [
                              DropdownMenuItem(value: "company", child: Text("Company")),
                              DropdownMenuItem(value: "individual", child: Text("Individual")),
                              DropdownMenuItem(value: "partnership", child: Text("Partnership")),
                            ],
                            onChanged: (v) => setState(() => _orgType = v!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _contactNameCtrl,
                      decoration: _buildInputDecoration('Primary Contact Name'),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _phoneCtrl,
                            keyboardType: TextInputType.phone,
                            decoration: _buildInputDecoration('Contact Phone'),
                            validator: (v) => v!.isEmpty ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            decoration: _buildInputDecoration('Contact Email'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // --- 2. ADDRESS ---
                _buildSectionCard(
                  title: "2. Headquarters Address",
                  children: [
                    TextFormField(
                      controller: _addrLineCtrl,
                      decoration: _buildInputDecoration('Street Address'),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _cityCtrl,
                            decoration: _buildInputDecoration('City'),
                            validator: (v) => v!.isEmpty ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 1,
                          child: TextFormField(
                            controller: _stateCtrl,
                            decoration: _buildInputDecoration('State'),
                            validator: (v) => v!.isEmpty ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 1,
                          child: TextFormField(
                            controller: _postalCtrl,
                            keyboardType: TextInputType.number,
                            decoration: _buildInputDecoration('Postal Code'),
                            validator: (v) => v!.isEmpty ? 'Required' : null,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // --- 3. DRIVERS ---
                _buildSectionCard(
                  title: "3. Fleet Drivers",
                  children: [
                    ListView.builder(
                      shrinkWrap: true, // Crucial for nested lists
                      physics: const NeverScrollableScrollPhysics(), // Disables nested scrolling
                      itemCount: _drivers.length,
                      itemBuilder: (_, idx) {
                        final d = _drivers[idx];
                        return _buildDynamicEntryCard(
                          title: 'Driver ${idx + 1}',
                          onRemove: _drivers.length > 1 ? () => _removeDriver(idx) : null,
                          child: Column(
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: d.name,
                                      decoration: _buildInputDecoration('Full Name'),
                                      validator: (v) => v!.isEmpty ? 'Required' : null,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: TextFormField(
                                      controller: d.phone,
                                      keyboardType: TextInputType.phone,
                                      decoration: _buildInputDecoration('Phone Number'),
                                      validator: (v) => v!.isEmpty ? 'Required' : null,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: d.licenseNumber,
                                      decoration: _buildInputDecoration('License Number (Optional)'),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: TextFormField(
                                      controller: d.licenseType,
                                      decoration: _buildInputDecoration('License Type (Optional)'),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: TextFormField(
                                      controller: d.yearsOfExperience,
                                      keyboardType: TextInputType.number,
                                      decoration: _buildInputDecoration('Years Exp. (Optional)'),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: d.emergencyContactName,
                                      decoration: _buildInputDecoration('Emergency Contact Name (Optional)'),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: TextFormField(
                                      controller: d.emergencyContactPhone,
                                      keyboardType: TextInputType.phone,
                                      decoration: _buildInputDecoration('Emergency Phone (Optional)'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: _addDriver,
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Add Another Driver', style: TextStyle(fontWeight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _primaryColor,
                        side: const BorderSide(color: _borderColor),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // --- 4. VEHICLES ---
                _buildSectionCard(
                  title: "4. Fleet Vehicles",
                  children: [
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _vehicles.length,
                      itemBuilder: (_, idx) {
                        final v = _vehicles[idx];
                        return _buildDynamicEntryCard(
                          title: 'Vehicle ${idx + 1}',
                          onRemove: _vehicles.length > 1 ? () => _removeVehicle(idx) : null,
                          child: Column(
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: v.registrationNumber,
                                      decoration: _buildInputDecoration('Registration Number'),
                                      validator: (val) => val!.isEmpty ? 'Required' : null,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: TextFormField(
                                      controller: v.vehicleType,
                                      decoration: _buildInputDecoration('Vehicle Type (e.g. Truck)'),
                                      validator: (val) => val!.isEmpty ? 'Required' : null,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: v.manufacturer,
                                      decoration: _buildInputDecoration('Manufacturer (Optional)'),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: TextFormField(
                                      controller: v.model,
                                      decoration: _buildInputDecoration('Model (Optional)'),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: TextFormField(
                                      controller: v.manufactureYear,
                                      keyboardType: TextInputType.number,
                                      decoration: _buildInputDecoration('Year (Optional)'),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: v.chassisNumber,
                                      decoration: _buildInputDecoration('Chassis Number (Optional)'),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: TextFormField(
                                      controller: v.capacityTons,
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      decoration: _buildInputDecoration('Capacity in Tons (Optional)'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: _addVehicle,
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Add Another Vehicle', style: TextStyle(fontWeight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _primaryColor,
                        side: const BorderSide(color: _borderColor),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),

                // --- SUBMIT BUTTON ---
                Align(
                  alignment: Alignment.centerRight,
                  child: SizedBox(
                    height: 52,
                    width: 240,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                      child: _isLoading
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text("Complete Registration", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Formal Section Container ---
  Widget _buildSectionCard({required String title, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _textColorDark)),
          const SizedBox(height: 24),
          const Divider(height: 1, color: _backgroundColor),
          const SizedBox(height: 24),
          ...children,
        ],
      ),
    );
  }

  // --- Sub-Card for Dynamic Entries (Drivers/Vehicles) ---
  Widget _buildDynamicEntryCard({required String title, VoidCallback? onRemove, required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC), // Slightly tinted background to separate from main card
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 20, right: 8, top: 8, bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, color: _textColorDark)),
                if (onRemove != null)
                  TextButton.icon(
                    onPressed: onRemove,
                    icon: const Icon(Icons.close_rounded, size: 16),
                    label: const Text('Remove'),
                    style: TextButton.styleFrom(foregroundColor: const Color(0xFFDC2626)),
                  )
                else
                  const SizedBox(height: 48), // Spacer to maintain height when no remove button
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          Padding(
            padding: const EdgeInsets.all(20),
            child: child,
          ),
        ],
      ),
    );
  }
}

// --- Data Classes (Unchanged) ---
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