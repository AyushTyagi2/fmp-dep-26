import 'package:flutter/material.dart';
import 'sender_api.dart';

// --- Formal Corporate UI Constants ---
const _primaryColor = Color(0xFF0F172A); // Deep Slate / Navy
const _backgroundColor = Color(0xFFF1F5F9); // Professional Light Grey
const _cardColor = Colors.white;
const _borderColor = Color(0xFFCBD5E1); // Crisp border line
const _textColorDark = Color(0xFF1E293B);
const _textColorMuted = Color(0xFF475569);

class SenderOnboardingScreen extends StatefulWidget {
  const SenderOnboardingScreen({super.key});

  @override
  State<SenderOnboardingScreen> createState() => _SenderOnboardingScreenState();
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
  bool _isLoading = false;

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
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
        
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile successfully created.")),
        );
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  // Helper method for clean, formal input fields
  InputDecoration _buildInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: _textColorMuted, fontSize: 14),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6), // Sharper, professional corners
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
        title: const Text("Sender Registration", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18, letterSpacing: 0.5)),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      body: Center( // Centers the form on wide screens
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700), // Prevents stretching on desktop
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              children: [
                // Formal Header (Left Aligned)
                const Text(
                  "Organization Setup",
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: _textColorDark, letterSpacing: -0.5),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Please provide your organization and contact details below to establish your sender profile.",
                  style: TextStyle(fontSize: 15, color: _textColorMuted),
                ),
                const SizedBox(height: 32),

                // --- SECTION 1: ORGANIZATION INFO ---
                _buildSectionCard(
                  title: "1. Organization Details",
                  children: [
                    TextFormField(
                      controller: _orgNameCtrl,
                      decoration: _buildInputDecoration("Registered Business Name"),
                      validator: (v) => v!.isEmpty ? "Required" : null,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _orgType,
                            icon: const Icon(Icons.arrow_drop_down, color: _textColorMuted),
                            decoration: _buildInputDecoration("Entity Type"),
                            items: const [
                              DropdownMenuItem(value: "company", child: Text("Company")),
                              DropdownMenuItem(value: "individual", child: Text("Individual")),
                              DropdownMenuItem(value: "partnership", child: Text("Partnership")),
                            ],
                            onChanged: (v) => setState(() => _orgType = v!),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _industryCtrl,
                            decoration: _buildInputDecoration("Industry / Sector"),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _descCtrl,
                      decoration: _buildInputDecoration("Business Description"),
                      maxLines: 3,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // --- SECTION 2: CONTACT INFO ---
                _buildSectionCard(
                  title: "2. Primary Contact",
                  children: [
                    TextFormField(
                      controller: _contactNameCtrl,
                      decoration: _buildInputDecoration("Full Name"),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _phoneCtrl,
                            keyboardType: TextInputType.phone,
                            decoration: _buildInputDecoration("Direct Phone Number"),
                            validator: (v) => v!.isEmpty ? "Required" : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            decoration: _buildInputDecoration("Corporate Email Address"),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // --- SECTION 3: ADDRESS ---
                _buildSectionCard(
                  title: "3. Headquarters / Default Pickup",
                  children: [
                    TextFormField(
                      controller: _addrLineCtrl,
                      decoration: _buildInputDecoration("Street Address"),
                      validator: (v) => v!.isEmpty ? "Required" : null,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _cityCtrl,
                            decoration: _buildInputDecoration("City"),
                            validator: (v) => v!.isEmpty ? "Required" : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 1,
                          child: TextFormField(
                            controller: _stateCtrl,
                            decoration: _buildInputDecoration("State / Province"),
                            validator: (v) => v!.isEmpty ? "Required" : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 1,
                          child: TextFormField(
                            controller: _postalCtrl,
                            keyboardType: TextInputType.number,
                            decoration: _buildInputDecoration("Postal Code"),
                            validator: (v) => v!.isEmpty ? "Required" : null,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 40),

                // --- SUBMIT BUTTON ---
                Align(
                  alignment: Alignment.centerRight,
                  child: SizedBox(
                    height: 48,
                    width: 200,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                      child: _isLoading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text("Save Profile", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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

  // Formal card container
  Widget _buildSectionCard({required String title, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _borderColor, width: 1), // Crisp, thin border instead of drop shadow
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _textColorDark),
          ),
          const SizedBox(height: 24),
          const Divider(height: 1, color: _backgroundColor),
          const SizedBox(height: 24),
          ...children,
        ],
      ),
    );
  }
}