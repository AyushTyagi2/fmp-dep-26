import 'package:flutter/material.dart';
import 'package:fmp_app/app_session.dart';
import 'package:fmp_app/presentation/auth/auth_api.dart';

// lib/presentation/onboarding/driver_onboarding/driver_basic_screen.dart
// Route: '/driver-basic'
// Uses: AuthApi.submitDriverDetails — UNCHANGED
// Fields match the existing API call exactly

class DriverBasicScreen extends StatefulWidget {
  const DriverBasicScreen({super.key});

  @override
  State<DriverBasicScreen> createState() => _DriverBasicScreenState();
}

class _DriverBasicScreenState extends State<DriverBasicScreen> {
  final _formKey      = GlobalKey<FormState>();
  final _vehicleNum   = TextEditingController();
  String _vehicleType = 'Truck';
  bool   _submitting  = false;
  String? _error;

  final _authApi = AuthApi();

  final _vehicleTypes = [
    ('Truck',           Icons.local_shipping_rounded),
    ('Mini Truck',      Icons.fire_truck_rounded),
    ('Container Truck', Icons.airport_shuttle_rounded),
    ('Tempo',           Icons.airport_shuttle_rounded),
    ('Pickup Van',      Icons.airport_shuttle_rounded),
  ];

  // ── UNCHANGED: calls AuthApi.submitDriverDetails exactly ────────────────
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _submitting = true; _error = null; });

    try {
      await _authApi.submitDriverDetails(
        email: AppSession.email ?? '',
        vehicleNumber: _vehicleNum.text.trim(),
        vehicleType: _vehicleType,
      );
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/approval-pending');
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _submitting = false; });
    }
  }

  @override
  void dispose() {
    _vehicleNum.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      body: SafeArea(
        child: Column(
          children: [
            // ── Progress bar ──────────────────────────────────────────────
            LinearProgressIndicator(
              value: 0.5,
              backgroundColor: const Color(0xFFE5E9F0),
              color: const Color(0xFF1A56DB),
              minHeight: 3,
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),

                      // ── Icon + headline ──────────────────────────────────
                      Container(
                        width: 56, height: 56,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEBF0FE),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.drive_eta_rounded,
                            size: 30, color: Color(0xFF1A56DB)),
                      ),
                      const SizedBox(height: 20),
                      const Text('Driver Details',
                          style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF111827),
                              letterSpacing: -0.4)),
                      const SizedBox(height: 6),
                      const Text(
                          'Tell us about your vehicle so we can match\nyou with the right shipments.',
                          style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF6B7280),
                              height: 1.5)),
                      const SizedBox(height: 32),

                      // ── Vehicle number ───────────────────────────────────
                      const Text('Vehicle Registration Number',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF374151))),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _vehicleNum,
                        textCapitalization: TextCapitalization.characters,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.2,
                            color: Color(0xFF111827)),
                        decoration: InputDecoration(
                          hintText: 'MH 01 AB 1234',
                          hintStyle: const TextStyle(
                              letterSpacing: 0, fontWeight: FontWeight.w400),
                          filled: true,
                          fillColor: Colors.white,
                          prefixIcon: const Icon(Icons.badge_rounded,
                              size: 18, color: Color(0xFF6B7280)),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                  color: Color(0xFFE5E9F0), width: 1.5)),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                  color: Color(0xFFE5E9F0), width: 1.5)),
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                  color: Color(0xFF1A56DB), width: 2)),
                          errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                  color: Color(0xFFE02424), width: 1.5)),
                        ),
                        validator: (v) {
                          final s = v?.trim() ?? '';
                          if (s.length < 6) return 'Enter valid registration number';
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // ── Vehicle type ─────────────────────────────────────
                      const Text('Vehicle Type',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF374151))),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: _vehicleTypes.map((vt) {
                          final selected = _vehicleType == vt.$1;
                          return GestureDetector(
                            onTap: () =>
                                setState(() => _vehicleType = vt.$1),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 160),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: selected
                                    ? const Color(0xFFEBF0FE)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: selected
                                      ? const Color(0xFF1A56DB)
                                      : const Color(0xFFE5E9F0),
                                  width: selected ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(vt.$2,
                                      size: 16,
                                      color: selected
                                          ? const Color(0xFF1A56DB)
                                          : const Color(0xFF6B7280)),
                                  const SizedBox(width: 7),
                                  Text(vt.$1,
                                      style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: selected
                                              ? FontWeight.w600
                                              : FontWeight.w400,
                                          color: selected
                                              ? const Color(0xFF1A56DB)
                                              : const Color(0xFF374151))),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      if (_error != null) ...[
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFDE8E8),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(children: [
                            const Icon(Icons.error_outline_rounded,
                                size: 16, color: Color(0xFFE02424)),
                            const SizedBox(width: 8),
                            Expanded(
                                child: Text(_error!,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFFE02424)))),
                          ]),
                        ),
                      ],

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),

            // ── Bottom CTA ────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
              color: Colors.white,
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A56DB),
                    disabledBackgroundColor:
                        const Color(0xFF1A56DB).withOpacity(0.6),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: Colors.white))
                      : const Text('Submit for Review',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.white)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
