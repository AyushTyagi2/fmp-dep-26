import 'package:flutter/material.dart';
import 'widgets/cargo.dart';
import 'widgets/date.dart';
import 'widgets/insurance.dart';
import 'widgets/pricing.dart';
class SenderCreateShipmentScreen extends StatelessWidget {
  const SenderCreateShipmentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Shipment'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children:  [
    CargoDetailsSection(),
    SizedBox(height: 24),

    PickupDeliverySection(),
    SizedBox(height: 24),

    HandlingComplianceSection(),
    SizedBox(height: 24),

    PricingSection(),
  ],
)
      ),
    );
  }
}
