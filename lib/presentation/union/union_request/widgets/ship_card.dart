import 'package:flutter/material.dart';
import '../../.././../core/models/queue.dart';

class ShipmentRequestCard extends StatelessWidget {

  final Shipment shipment;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const ShipmentRequestCard({
    super.key,
    required this.shipment,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Text(
              shipment.shipmentNumber,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Text("Cargo: ${shipment.cargoType}"),
            Text("Weight: ${shipment.cargoWeightKg} kg"),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: onApprove,
                    child: const Text("Approve"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    onPressed: onReject,
                    child: const Text("Reject"),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}