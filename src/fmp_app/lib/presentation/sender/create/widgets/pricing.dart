import 'package:flutter/material.dart';
import '../../models/shipment_draft.dart';


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
  final ShipmentDraft draft;

  const LoadingChargesField({
    super.key,
    required this.draft,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: draft.loadingCharges.toString(),
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(
        labelText: 'Loading Charges',
        border: OutlineInputBorder(),
      ),
      onChanged: (value) {
        draft.loadingCharges = double.tryParse(value) ?? 0;
      },
    );
  }
}


class UnloadingChargesField extends StatelessWidget {
  final ShipmentDraft draft;

  const UnloadingChargesField({
    super.key,
    required this.draft,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: draft.unloadingCharges.toString(),
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(
        labelText: 'Unloading Charges',
        border: OutlineInputBorder(),
      ),
      onChanged: (value) {
        draft.unloadingCharges = double.tryParse(value) ?? 0;
      },
    );
  }
}

class PricingSection extends StatelessWidget {
  final ShipmentDraft draft;

  const PricingSection({
    super.key,
    required this.draft,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(title: 'Pricing'),
        const SizedBox(height: 16),

        AgreedPriceField(draft: draft),
        const SizedBox(height: 12),

        PricePerUnitDropdown(draft: draft),
        const SizedBox(height: 12),

        LoadingChargesField(draft: draft),
        const SizedBox(height: 12),

        UnloadingChargesField(draft: draft),
        const SizedBox(height: 12),

        OtherChargesField(draft: draft),
      ],
    );
  }
}


class AgreedPriceField extends StatelessWidget {
  final ShipmentDraft draft;

  const AgreedPriceField({super.key, required this.draft});

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
  final ShipmentDraft draft;

  const PricePerUnitDropdown({
    super.key,
    required this.draft,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: draft.pricePerUnit,
      decoration: const InputDecoration(
        labelText: 'Price Per Unit',
        border: OutlineInputBorder(),
      ),
      items: const [
        DropdownMenuItem(value: 'fixed', child: Text('Fixed')),
        DropdownMenuItem(value: 'per_ton', child: Text('Per Ton')),
        DropdownMenuItem(value: 'per_km', child: Text('Per Km')),
      ],
      onChanged: (value) {
        draft.pricePerUnit = value;
      },
    );
  }
}


class OtherChargesField extends StatelessWidget {
  final ShipmentDraft draft;

  const OtherChargesField({
    super.key,
    required this.draft,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: draft.otherCharges.toString(),
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(
        labelText: 'Other Charges',
        border: OutlineInputBorder(),
      ),
      onChanged: (value) {
        draft.otherCharges = double.tryParse(value) ?? 0;
      },
    );
  }
}

