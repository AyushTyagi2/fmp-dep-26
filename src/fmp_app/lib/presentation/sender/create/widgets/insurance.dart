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

class HandlingComplianceSection extends StatefulWidget {
  final ShipmentDraft draft;

  const HandlingComplianceSection({
    super.key,
    required this.draft,
  });

  @override
  State<HandlingComplianceSection> createState() =>
      _HandlingComplianceSectionState();
}

class _HandlingComplianceSectionState
    extends State<HandlingComplianceSection> {

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(title: 'Handling & Compliance'),
        const SizedBox(height: 16),

        RefrigerationToggle(
          value: isRefrigerated,
          onChanged: (value) {
            setState(() {
              isRefrigerated = value;
              widget.draft.requiresRefrigeration = value;
            });
          },
        ),

        InsuranceToggle(
          value: requiresInsurance,
          onChanged: (value) {
            setState(() {
              requiresInsurance = value;
              widget.draft.requiresInsurance = value;
            });
          },
        ),

        const SizedBox(height: 12),

        SpecialHandlingField(draft: widget.draft),
        const SizedBox(height: 16),

        InvoiceNumberField(draft: widget.draft),
        const SizedBox(height: 12),

        InvoiceValueField(draft: widget.draft),
        const SizedBox(height: 12),

        EwayBillField(draft: widget.draft),
      ],
    );
  }
}




class RefrigerationToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const RefrigerationToggle({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      contentPadding: EdgeInsets.zero,
      title: const Text('Requires Refrigeration'),
      value: value,
      onChanged: (value) {
        if (value != null) {
          onChanged(value);
        }
      },
    );
  }
}


class InsuranceToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const InsuranceToggle({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      contentPadding: EdgeInsets.zero,
      title: const Text('Requires Insurance'),
      value: value,
      onChanged: (value) {
        if (value != null) {
          onChanged(value);
        }
      },
    );
  }
}


class SpecialHandlingField extends StatelessWidget {
  final ShipmentDraft draft;

  const SpecialHandlingField({
    super.key,
    required this.draft,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: draft.specialHandlingInstructions,
      maxLines: 3,
      decoration: const InputDecoration(
        labelText: 'Special Handling Instructions',
        border: OutlineInputBorder(),
      ),
      onChanged: (value) {
        draft.specialHandlingInstructions = value;
      },
    );
  }
}


class InvoiceNumberField extends StatelessWidget {
  final ShipmentDraft draft;

  const InvoiceNumberField({
    super.key,
    required this.draft,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: draft.invoiceNumber,
      decoration: const InputDecoration(
        labelText: 'Invoice Number',
        border: OutlineInputBorder(),
      ),
      onChanged: (value) {
        draft.invoiceNumber = value;
      },
    );
  }
}


class InvoiceValueField extends StatelessWidget {
  final ShipmentDraft draft;

  const InvoiceValueField({
    super.key,
    required this.draft,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: draft.invoiceValue?.toString(),
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(
        labelText: 'Invoice Value',
        border: OutlineInputBorder(),
      ),
      onChanged: (value) {
        draft.invoiceValue = double.tryParse(value);
      },
    );
  }
}


class EwayBillField extends StatelessWidget {
  final ShipmentDraft draft;

  const EwayBillField({
    super.key,
    required this.draft,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: draft.ewayBillNumber,
      decoration: const InputDecoration(
        labelText: 'E-Way Bill Number',
        border: OutlineInputBorder(),
      ),
      onChanged: (value) {
        draft.ewayBillNumber = value;
      },
    );
  }
}

