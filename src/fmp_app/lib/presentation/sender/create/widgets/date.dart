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

class PickupDeliverySection extends StatelessWidget {
  const PickupDeliverySection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:  [
        SectionTitle(title: 'Pickup & Delivery'),
        SizedBox(height: 16),

        PickupAddressField(),
        SizedBox(height: 12),

        DropAddressField(),
        SizedBox(height: 12),

        PickupDateField(),
        SizedBox(height: 12),

        DeliveryDateField(),
        SizedBox(height: 12),

        UrgentToggle(),
      ],
    );
  }
}



class PickupAddressField extends StatelessWidget {
  const PickupAddressField({super.key});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      readOnly: true,
      decoration: const InputDecoration(
        labelText: 'Pickup Address',
        border: OutlineInputBorder(),
        suffixIcon: Icon(Icons.location_on),
      ),
      onTap: () {
        // open address selector later
      },
    );
  }
}

class DropAddressField extends StatelessWidget {
  const DropAddressField({super.key});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      readOnly: true,
      decoration: const InputDecoration(
        labelText: 'Drop Address',
        border: OutlineInputBorder(),
        suffixIcon: Icon(Icons.location_on_outlined),
      ),
      onTap: () {},
    );
  }
}


class PickupDateField extends StatelessWidget {
  const PickupDateField({super.key});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      readOnly: true,
      decoration: const InputDecoration(
        labelText: 'Preferred Pickup Date',
        border: OutlineInputBorder(),
        suffixIcon: Icon(Icons.calendar_today),
      ),
      onTap: () {},
    );
  }
}

class DeliveryDateField extends StatelessWidget {
  const DeliveryDateField({super.key});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      readOnly: true,
      decoration: const InputDecoration(
        labelText: 'Preferred Delivery Date',
        border: OutlineInputBorder(),
        suffixIcon: Icon(Icons.calendar_today_outlined),
      ),
      onTap: () {},
    );
  }
}



class UrgentToggle extends StatelessWidget {
  const UrgentToggle({super.key});

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: const Text('Mark as Urgent'),
      subtitle: const Text('Higher priority for carriers'),
      value: false,
      onChanged: (_) {},
    );
  }
}
