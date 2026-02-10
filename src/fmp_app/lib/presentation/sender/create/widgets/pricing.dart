import 'package:flutter/material.dart';



class SectionTitle extends StatelessWidget {
  final String title;

  const SectionTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class LoadingChargesField extends StatelessWidget {
  const LoadingChargesField({super.key});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(
        labelText: 'Loading Charges',
        border: OutlineInputBorder(),
      ),
    );
  }
}

class UnloadingChargesField extends StatelessWidget {
  const UnloadingChargesField({super.key});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(
        labelText: 'Unloading Charges',
        border: OutlineInputBorder(),
      ),
    );
  }
}

class PricingSection extends StatelessWidget {
  const PricingSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:  [
        SectionTitle(title: 'Pricing'),
        SizedBox(height: 16),

        AgreedPriceField(),
        SizedBox(height: 12),

        PricePerUnitDropdown(),
        SizedBox(height: 12),

        LoadingChargesField(),
        SizedBox(height: 12),

        UnloadingChargesField(),
        SizedBox(height: 12),

        OtherChargesField(),
      ],
    );
  }
}


class AgreedPriceField extends StatelessWidget {
  const AgreedPriceField({super.key});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(
        labelText: 'Agreed Price (INR)',
        border: OutlineInputBorder(),
      ),
    );
  }
}

class PricePerUnitDropdown extends StatelessWidget {
  const PricePerUnitDropdown({super.key});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      decoration: const InputDecoration(
        labelText: 'Price Per Unit',
        border: OutlineInputBorder(),
      ),
      items: const [
        DropdownMenuItem(value: 'fixed', child: Text('Fixed')),
        DropdownMenuItem(value: 'per_ton', child: Text('Per Ton')),
        DropdownMenuItem(value: 'per_km', child: Text('Per Km')),
      ],
      onChanged: (_) {},
    );
  }
}

class OtherChargesField extends StatelessWidget {
  const OtherChargesField({super.key});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(
        labelText: 'Other Charges',
        border: OutlineInputBorder(),
      ),
    );
  }
}
