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

class HandlingComplianceSection extends StatefulWidget {
  final ShipmentDraft draft;

  const HandlingComplianceSection({
    super.key,
    required this.draft,
  });

  @override
  State<HandlingComplianceSection> createState() => _HandlingComplianceSectionState();
}

class _HandlingComplianceSectionState extends State<HandlingComplianceSection> {
  late bool isRefrigerated;
  late bool requiresInsurance;

  @override
  void initState() {
    super.initState();
    isRefrigerated = widget.draft.requiresRefrigeration;
    requiresInsurance = widget.draft.requiresInsurance;
  }

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
            '3. Handling & Compliance',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 24),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 24),

          Container(
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE2E8F0)),
              borderRadius: BorderRadius.circular(6)
            ),
            child: Column(
              children: [
                RefrigerationToggle(
                  value: isRefrigerated,
                  onChanged: (value) {
                    setState(() {
                      isRefrigerated = value;
                      widget.draft.requiresRefrigeration = value;
                    });
                  },
                ),
                const Divider(height: 1, color: Color(0xFFE2E8F0)),
                InsuranceToggle(
                  value: requiresInsurance,
                  onChanged: (value) {
                    setState(() {
                      requiresInsurance = value;
                      widget.draft.requiresInsurance = value;
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          SpecialHandlingField(draft: widget.draft),
          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(child: InvoiceNumberField(draft: widget.draft)),
              const SizedBox(width: 16),
              Expanded(child: InvoiceValueField(draft: widget.draft)),
            ],
          ),
          const SizedBox(height: 20),

          EwayBillField(draft: widget.draft),
        ],
      ),
    );
  }
}

class RefrigerationToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const RefrigerationToggle({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      title: const Text('Requires Refrigeration (Cold Chain)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
      value: value,
      activeColor: const Color(0xFF0F172A),
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
    );
  }
}

class InsuranceToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const InsuranceToggle({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      title: const Text('Transit Insurance Required', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
      value: value,
      activeColor: const Color(0xFF0F172A),
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
    );
  }
}

class SpecialHandlingField extends StatelessWidget {
  final ShipmentDraft draft;
  const SpecialHandlingField({super.key, required this.draft});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: draft.specialHandlingInstructions,
      maxLines: 3,
      decoration: _formalInputDecoration('Special Handling Instructions'),
      onChanged: (value) => draft.specialHandlingInstructions = value,
    );
  }
}

class InvoiceNumberField extends StatelessWidget {
  final ShipmentDraft draft;
  const InvoiceNumberField({super.key, required this.draft});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: draft.invoiceNumber,
      decoration: _formalInputDecoration('Commercial Invoice No.'),
      onChanged: (value) => draft.invoiceNumber = value,
    );
  }
}

class InvoiceValueField extends StatelessWidget {
  final ShipmentDraft draft;
  const InvoiceValueField({super.key, required this.draft});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: draft.invoiceValue?.toString(),
      keyboardType: TextInputType.number,
      decoration: _formalInputDecoration('Declared Value (INR)'),
      onChanged: (value) => draft.invoiceValue = double.tryParse(value),
    );
  }
}

class EwayBillField extends StatelessWidget {
  final ShipmentDraft draft;
  const EwayBillField({super.key, required this.draft});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: draft.ewayBillNumber,
      decoration: _formalInputDecoration('E-Way Bill Number'),
      onChanged: (value) => draft.ewayBillNumber = value,
    );
  }
}