import 'package:flutter/material.dart';
import 'package:fmp_app/app_session.dart';
import 'package:fmp_app/core/network/api_client.dart';
import '../../../core/network/api_shipment.dart';
import 'widgets/shipment_list_view.dart';

class SenderShipmentsScreen extends StatefulWidget {
  const SenderShipmentsScreen({super.key});

  @override
  State<SenderShipmentsScreen> createState() =>
      _SenderShipmentsScreenState();
}

class _SenderShipmentsScreenState
    extends State<SenderShipmentsScreen>
    with SingleTickerProviderStateMixin {

  late TabController _tabController;
  late ShipmentApi _api;
  late ApiClient _client;

  List<dynamic> sentShipments = [];
  List<dynamic> receivedShipments = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 2, vsync: this);

    _client = ApiClient();
    _api = ShipmentApi(_client);

    _loadShipments();
  }

  Future<void> _loadShipments() async {
    final phone = AppSession.phone;

    if (phone == null) {
      setState(() => isLoading = false);
      return;
    }

    try {
      final response = await _api.getShipmentsByPhone(phone);

      setState(() {
        sentShipments = response["sent"] ?? [];
        receivedShipments = response["received"] ?? [];
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Shipments"),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Sent"),
            Tab(text: "Received"),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                ShipmentListView(shipments: sentShipments),
                ShipmentListView(shipments: receivedShipments),
              ],
            ),
    );
  }
}