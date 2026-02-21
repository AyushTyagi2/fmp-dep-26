import 'package:flutter/material.dart';

class ShipmentListView extends StatelessWidget {
  final List<dynamic> shipments;

  const ShipmentListView({
    super.key,
    required this.shipments,
  });

  @override
  Widget build(BuildContext context) {
    if (shipments.isEmpty) {
      return const Center(
        child: Text("No shipments found"),
      );
    }

    return ListView.builder(
      itemCount: shipments.length,
      itemBuilder: (context, index) {
        final shipment = shipments[index];

        return Card(
          margin: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 8),
          child: ListTile(
            title: Text(shipment["shipmentNumber"]),
            subtitle: Text(
                "${shipment["cargoType"]} • ${shipment["status"]}"),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              // Navigate to shipment details later
            },
          ),
        );
      },
    );
  }
}