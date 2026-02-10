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

class HandlingComplianceSection extends StatelessWidget {
  const HandlingComplianceSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:  [
        SectionTitle(title: 'Handling & Compliance'),
        SizedBox(height: 16),

        RefrigerationToggle(),
        InsuranceToggle(),
        SizedBox(height: 12),

        SpecialHandlingField(),
        SizedBox(height: 16),

        InvoiceNumberField(),
        SizedBox(height: 12),

        InvoiceValueField(),
        SizedBox(height: 12),

        EwayBillField(),
      ],
    );
  }
}



class RefrigerationToggle extends StatelessWidget {
  const RefrigerationToggle({super.key});

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      contentPadding: EdgeInsets.zero,
      title: const Text('Requires Refrigeration'),
      value: false,
      onChanged: (_) {},
    );
  }
}

class InsuranceToggle extends StatelessWidget {
  const InsuranceToggle({super.key});

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      contentPadding: EdgeInsets.zero,
      title: const Text('Requires Insurance'),
      value: false,
      onChanged: (_) {},
    );
  }
}

class SpecialHandlingField extends StatelessWidget {
  const SpecialHandlingField({super.key});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      maxLines: 3,
      decoration: const InputDecoration(
        labelText: 'Special Handling Instructions',
        border: OutlineInputBorder(),
      ),
    );
  }
}


class InvoiceNumberField extends StatelessWidget {
  const InvoiceNumberField({super.key});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      decoration: const InputDecoration(
        labelText: 'Invoice Number',
        border: OutlineInputBorder(),
      ),
    );
  }
}

class InvoiceValueField extends StatelessWidget {
  const InvoiceValueField({super.key});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(
        labelText: 'Invoice Value',
        border: OutlineInputBorder(),
      ),
    );
  }
}

class EwayBillField extends StatelessWidget {
  const EwayBillField({super.key});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      decoration: const InputDecoration(
        labelText: 'E-Way Bill Number',
        border: OutlineInputBorder(),
      ),
    );
  }
}
