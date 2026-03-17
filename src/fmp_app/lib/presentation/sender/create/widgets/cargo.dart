import 'package:flutter/material.dart';
import '../../models/shipment_draft.dart';

class CargoDetailsSection extends StatelessWidget {
  final ShipmentDraft draft;

  const CargoDetailsSection({
    super.key,
    required this.draft,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Cargo Details',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        // Cargo Type
        DropdownButtonFormField<String>(
          initialValue: draft.cargoType,
          decoration: const InputDecoration(
            labelText: 'Cargo Type',
            border: OutlineInputBorder(),
          ),
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

        const SizedBox(height: 12),

        // Cargo Description
        TextFormField(
          initialValue: draft.cargoDescription,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Cargo Description',
            border: OutlineInputBorder(),
            hintText: 'Describe the cargo',
          ),
          onChanged: (value) {
            draft.cargoDescription = value;
          },
        ),

        const SizedBox(height: 12),

        // Weight
        TextFormField(
          initialValue: draft.cargoWeightKg?.toString(),
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Weight (kg)',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {
            draft.cargoWeightKg = double.tryParse(value);
          },
        ),

        const SizedBox(height: 12),

        // Volume
        TextFormField(
          initialValue: draft.cargoVolumeCubicMeters?.toString(),
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Volume (cubic meters)',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {
            draft.cargoVolumeCubicMeters = double.tryParse(value);
          },
        ),

        const SizedBox(height: 12),

        // Package Count
        TextFormField(
          initialValue: draft.packageCount?.toString(),
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Number of Packages',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {
            draft.packageCount = int.tryParse(value);
          },
        ),
      ],
    );
  }
}
