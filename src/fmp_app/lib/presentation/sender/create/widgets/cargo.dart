import 'package:flutter/material.dart';
import '../../models/shipment_draft.dart';

// --- Formal Corporate UI Helper ---
InputDecoration _formalInputDecoration(String label) {
  return InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: Color(0xFF475569), fontSize: 14),
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: const BorderSide(color: Color(0xFF0F172A), width: 1.5),
    ),
  );
}

class CargoDetailsSection extends StatelessWidget {
  final ShipmentDraft draft;

  const CargoDetailsSection({
    super.key,
    required this.draft,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFCBD5E1), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '1. Cargo Details',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 24),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 24),

          // Cargo Type
          DropdownButtonFormField<String>(
            initialValue: draft.cargoType,
            icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF475569)),
            decoration: _formalInputDecoration('Cargo Type'),
            items: const [
              DropdownMenuItem(value: 'general', child: Text('General')),
              DropdownMenuItem(value: 'perishable', child: Text('Perishable')),
              DropdownMenuItem(value: 'hazardous', child: Text('Hazardous')),
              DropdownMenuItem(value: 'fragile', child: Text('Fragile')),
            ],
            onChanged: (value) {
              draft.cargoType = value;
            },
          ),
          const SizedBox(height: 20),

          // Cargo Description
          TextFormField(
            initialValue: draft.cargoDescription,
            maxLines: 3,
            decoration: _formalInputDecoration('Cargo Description').copyWith(
              hintText: 'Provide specific details about the cargo contents',
            ),
            onChanged: (value) {
              draft.cargoDescription = value;
            },
          ),
          const SizedBox(height: 20),

          // Weight & Volume Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: draft.cargoWeightKg?.toString(),
                  keyboardType: TextInputType.number,
                  decoration: _formalInputDecoration('Total Weight (kg)'),
                  onChanged: (value) {
                    draft.cargoWeightKg = double.tryParse(value);
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  initialValue: draft.cargoVolumeCubicMeters?.toString(),
                  keyboardType: TextInputType.number,
                  decoration: _formalInputDecoration('Volume (cubic meters)'),
                  onChanged: (value) {
                    draft.cargoVolumeCubicMeters = double.tryParse(value);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Package Count
          TextFormField(
            initialValue: draft.packageCount?.toString(),
            keyboardType: TextInputType.number,
            decoration: _formalInputDecoration('Number of Packages / Units'),
            onChanged: (value) {
              draft.packageCount = int.tryParse(value);
            },
          ),
        ],
      ),
    );
  }
}