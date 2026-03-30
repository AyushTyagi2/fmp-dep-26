import 'package:flutter/material.dart';
import '../../../core/models/queue.dart';//import '../../../core/network/api_client.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_shipment.dart';
import 'widgets/ship_card.dart';
class UnionRequestScreen extends StatefulWidget {
  const UnionRequestScreen({super.key});

  @override
  State<UnionRequestScreen> createState() => _UnionRequestScreenState();
}

class _UnionRequestScreenState extends State<UnionRequestScreen> {
  final ShipmentApi api = ShipmentApi(ApiClient());
  List<Shipment> shipments = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadShipments();
  }

  Future<void> loadShipments() async {
    final data = await api.getPendingShipments();
    print(data);
    setState(() {
      shipments = data;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {

    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Shipment Requests"),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: shipments.length,
        itemBuilder: (context, index) {
          return ShipmentRequestCard(
            shipment: shipments[index],
            onApprove: () async {
              await api.approveShipment(shipments[index].id);
              loadShipments();
            },
            onReject: () async {
              await api.rejectShipment(shipments[index].id);
              loadShipments();
            },
          );
        },
      ),
    );
  }
}