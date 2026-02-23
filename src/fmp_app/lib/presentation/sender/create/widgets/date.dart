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

class PickupDeliverySection extends StatefulWidget {
  final ShipmentDraft draft;

  const PickupDeliverySection({
    super.key,
    required this.draft,
  });

  @override
  State<PickupDeliverySection> createState() =>
      _PickupDeliverySectionState();
}

class _PickupDeliverySectionState
    extends State<PickupDeliverySection> {

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(title: 'Pickup & Delivery'),
        SizedBox(height: 16),

        //PickupAddressField(draft: widget.draft),
        //SizedBox(height: 12),

        //DropAddressField(draft: widget.draft),
        //SizedBox(height: 12),
        ReceiverPhoneField(draft: widget.draft),
        SizedBox(height: 12),
        
        PickupDateField(draft: widget.draft),
        SizedBox(height: 12),

        DeliveryDateField(draft: widget.draft),
        SizedBox(height: 12),

        UrgentToggle(
          draft: widget.draft,
          onChanged: (value) {
            setState(() {
              widget.draft.isUrgent = value;
            });
          },
        ),
      ],
    );
  }
}




/*class PickupAddressField extends StatelessWidget {
  final ShipmentDraft draft;
  const PickupAddressField({super.key, required this.draft});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      readOnly: true,
      initialValue: draft.pickupAddressId,
      decoration: const InputDecoration(
        labelText: 'Pickup Address',
        border: OutlineInputBorder(),
        suffixIcon: Icon(Icons.location_on),
      ),
      onTap: () {
        // open address selector later
        draft.pickupAddressId = "ADDRESS_ID_SAMPLE";
      },
    );
  }
}

class DropAddressField extends StatelessWidget {
  final ShipmentDraft draft;
  const DropAddressField({super.key, required this.draft});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      readOnly: true,
      initialValue: draft.dropAddressId,
      decoration: const InputDecoration(
        labelText: 'Drop Address',
        border: OutlineInputBorder(),
        suffixIcon: Icon(Icons.location_on_outlined),
      ),
      onTap: () { draft.dropAddressId = "ADDRESS_ID_SAMPLE";},
    );
  }
}*/


class ReceiverPhoneField extends StatelessWidget {
  final ShipmentDraft draft;

  const ReceiverPhoneField({super.key, required this.draft});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      decoration: const InputDecoration(
        labelText: 'Receiver Phone Number',
        border: OutlineInputBorder(),
      ),
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
      decoration: const InputDecoration(
        labelText: 'Preferred Pickup Date',
        border: OutlineInputBorder(),
        suffixIcon: Icon(Icons.calendar_today),
      ),
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
            _controller.text =
                "${selected.day}/${selected.month}/${selected.year}";
          });
        }
      },
    );
  }
}


class DeliveryDateField extends StatelessWidget {
  final ShipmentDraft draft;

  const DeliveryDateField({
    super.key,
    required this.draft,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      readOnly: true,
      
      decoration: const InputDecoration(
        labelText: 'Preferred Delivery Date',
        border: OutlineInputBorder(),
        suffixIcon: Icon(Icons.calendar_today_outlined),
      ),
      onTap: () async {
        final selected = await showDatePicker(
          context: context,
          firstDate: DateTime.now(),
          lastDate: DateTime(2100),
          initialDate:DateTime.now(),
        );

        if (selected != null) {
          draft.preferredDeliveryDate = selected;
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
      contentPadding: EdgeInsets.zero,
      title: const Text('Mark as Urgent'),
      subtitle: const Text('Higher priority for carriers'),
      value: draft.isUrgent,
      onChanged: onChanged,
    );
  }
}



