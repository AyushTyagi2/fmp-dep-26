import 'package:flutter/material.dart';


class CargoDetailsSection extends StatelessWidget {
  const CargoDetailsSection({super.key});

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
          onChanged: (value) {},
        ),

        const SizedBox(height: 12),

        // Cargo Description
        TextFormField(
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Cargo Description',
            border: OutlineInputBorder(),
            hintText: 'Describe the cargo',
          ),
        ),

        const SizedBox(height: 12),

        // Weight
        TextFormField(
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Weight (kg)',
            border: OutlineInputBorder(),
          ),
        ),

        const SizedBox(height: 12),

        // Volume
        TextFormField(
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Volume (cubic meters)',
            border: OutlineInputBorder(),
          ),
        ),

        const SizedBox(height: 12),

        // Package Count
        TextFormField(
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Number of Packages',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }
}

