import 'package:flutter/material.dart';
import '../../models/shipment_draft.dart';

// --- Formal Corporate UI Helper ---
InputDecoration _formalInputDecoration(String label, {IconData? suffixIcon}) {
  return InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: Color(0xFF475569), fontSize: 14),
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    suffixIcon: suffixIcon != null ? Icon(suffixIcon, color: const Color(0xFF475569), size: 20) : null,
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

class PickupDeliverySection extends StatefulWidget {
  final ShipmentDraft draft;

  const PickupDeliverySection({
    super.key,
    required this.draft,
  });

  @override
  State<PickupDeliverySection> createState() => _PickupDeliverySectionState();
}

class _PickupDeliverySectionState extends State<PickupDeliverySection> {
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
            '2. Pickup & Delivery Scheduling',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 24),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 24),

          ReceiverPhoneField(draft: widget.draft),
          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(child: PickupDateField(draft: widget.draft)),
              const SizedBox(width: 16),
              Expanded(child: DeliveryDateField(draft: widget.draft)),
            ],
          ),
          const SizedBox(height: 20),

          Container(
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE2E8F0)),
              borderRadius: BorderRadius.circular(6)
            ),
            child: UrgentToggle(
              draft: widget.draft,
              onChanged: (value) {
                setState(() {
                  widget.draft.isUrgent = value;
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ReceiverPhoneField extends StatelessWidget {
  final ShipmentDraft draft;

  const ReceiverPhoneField({super.key, required this.draft});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      decoration: _formalInputDecoration('Receiver Phone Number', suffixIcon: Icons.phone_outlined),
      keyboardType: TextInputType.phone,
      onChanged: (value) {
        draft.receiverPhone = value;
      },
    );
  }
}

class PickupDateField extends StatefulWidget {
  final ShipmentDraft draft;

  const PickupDateField({super.key, required this.draft});

  @override
  State<PickupDateField> createState() => _PickupDateFieldState();
}

class _PickupDateFieldState extends State<PickupDateField> {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _controller,
      readOnly: true,
      decoration: _formalInputDecoration('Preferred Pickup Date', suffixIcon: Icons.calendar_today_outlined),
      onTap: () async {
        final selected = await showDatePicker(
          context: context,
          firstDate: DateTime.now(),
          lastDate: DateTime(2100),
          initialDate: DateTime.now(),
        );

        if (selected != null) {
          setState(() {
            widget.draft.preferredPickupDate = selected;
            _controller.text = "${selected.day}/${selected.month}/${selected.year}";
          });
        }
      },
    );
  }
}

class DeliveryDateField extends StatefulWidget {
  final ShipmentDraft draft;

  const DeliveryDateField({super.key, required this.draft});

  @override
  State<DeliveryDateField> createState() => _DeliveryDateFieldState();
}

class _DeliveryDateFieldState extends State<DeliveryDateField> {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _controller,
      readOnly: true,
      decoration: _formalInputDecoration('Preferred Delivery Date', suffixIcon: Icons.event_available_outlined),
      onTap: () async {
        final selected = await showDatePicker(
          context: context,
          firstDate: DateTime.now(),
          lastDate: DateTime(2100),
          initialDate: DateTime.now(),
        );

        if (selected != null) {
          setState(() {
             widget.draft.preferredDeliveryDate = selected;
             _controller.text = "${selected.day}/${selected.month}/${selected.year}";
          });
        }
      },
    );
  }
}

class UrgentToggle extends StatelessWidget {
  final ShipmentDraft draft;
  final ValueChanged<bool> onChanged;

  const UrgentToggle({
    super.key,
    required this.draft,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      title: const Text('Mark as Urgent Dispatch', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF1E293B))),
      subtitle: const Text('Assigns higher priority in the carrier matching queue', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
      value: draft.isUrgent,
      activeColor: const Color(0xFF0F172A),
      onChanged: onChanged,
    );
  }
}