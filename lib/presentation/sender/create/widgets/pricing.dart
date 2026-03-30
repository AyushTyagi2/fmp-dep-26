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

class PricingSection extends StatelessWidget {
  final ShipmentDraft draft;

  const PricingSection({
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
            '4. Financial & Pricing',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 24),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 24),

          Row(
            children: [
              Expanded(flex: 2, child: AgreedPriceField(draft: draft)),
              const SizedBox(width: 16),
              Expanded(flex: 1, child: PricePerUnitDropdown(draft: draft)),
            ],
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(child: LoadingChargesField(draft: draft)),
              const SizedBox(width: 16),
              Expanded(child: UnloadingChargesField(draft: draft)),
            ],
          ),
          const SizedBox(height: 20),

          OtherChargesField(draft: draft),
        ],
      ),
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
      decoration: _formalInputDecoration('Agreed Price (INR)'),
    );
  }
}

class PricePerUnitDropdown extends StatelessWidget {
  final ShipmentDraft draft;
  const PricePerUnitDropdown({super.key, required this.draft});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: draft.pricePerUnit,
      icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF475569)),
      decoration: _formalInputDecoration('Pricing Model'),
      items: const [
        DropdownMenuItem(value: 'fixed', child: Text('Fixed Total')),
        DropdownMenuItem(value: 'per_ton', child: Text('Per Ton')),
        DropdownMenuItem(value: 'per_km', child: Text('Per Km')),
      ],
      onChanged: (value) {
        draft.pricePerUnit = value;
      },
    );
  }
}

class LoadingChargesField extends StatelessWidget {
  final ShipmentDraft draft;
  const LoadingChargesField({super.key, required this.draft});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: draft.loadingCharges.toString(),
      keyboardType: TextInputType.number,
      decoration: _formalInputDecoration('Loading Charges'),
      onChanged: (value) => draft.loadingCharges = double.tryParse(value) ?? 0,
    );
  }
}

class UnloadingChargesField extends StatelessWidget {
  final ShipmentDraft draft;
  const UnloadingChargesField({super.key, required this.draft});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: draft.unloadingCharges.toString(),
      keyboardType: TextInputType.number,
      decoration: _formalInputDecoration('Unloading Charges'),
      onChanged: (value) => draft.unloadingCharges = double.tryParse(value) ?? 0,
    );
  }
}

class OtherChargesField extends StatelessWidget {
  final ShipmentDraft draft;
  const OtherChargesField({super.key, required this.draft});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: draft.otherCharges.toString(),
      keyboardType: TextInputType.number,
      decoration: _formalInputDecoration('Additional / Misc Charges'),
      onChanged: (value) => draft.otherCharges = double.tryParse(value) ?? 0,
    );
  }
}