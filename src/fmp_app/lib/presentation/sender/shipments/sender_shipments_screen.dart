import 'package:flutter/material.dart';
import 'package:fmp_app/app_session.dart';
import 'package:fmp_app/core/network/api_client.dart';
import '../../../core/network/api_shipment.dart';
import 'widgets/shipment_list_view.dart';

// --- Formal Corporate UI Constants ---
const _primaryColor = Color(0xFF0F172A); // Deep Slate / Navy
const _backgroundColor = Color(0xFFF1F5F9); // Professional Light Grey
const _accentColor = Color(0xFF3B82F6); // Crisp Blue

class SenderShipmentsScreen extends StatefulWidget {
  const SenderShipmentsScreen({super.key});

  @override
  State<SenderShipmentsScreen> createState() => _SenderShipmentsScreenState();
}

class _SenderShipmentsScreenState extends State<SenderShipmentsScreen>
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
    // Show loading indicator only if the lists are empty (initial load)
    if (sentShipments.isEmpty && receivedShipments.isEmpty) {
      setState(() => isLoading = true);
    }

    final phone = AppSession.phone;

    if (phone == null) {
      if (mounted) setState(() => isLoading = false);
      return;
    }

    try {
      final response = await _api.getShipmentsByPhone(phone);

      if (!mounted) return;
      setState(() {
        sentShipments = response["sent"] ?? [];
        receivedShipments = response["received"] ?? [];
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Failed to refresh shipments. Please try again."),
          backgroundColor: Color(0xFFDC2626), // Formal Red
        ),
      );
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
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: const Text(
          "My Shipments", 
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18, letterSpacing: 0.5)
        ),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 22),
            tooltip: 'Refresh Shipments',
            onPressed: isLoading ? null : _loadShipments,
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFF1E293B), width: 1)),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white, // Crisp white indicator line
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: const Color(0xFF94A3B8), // Muted slate for unselected
              labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, letterSpacing: 0.5),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
              tabs: const [
                Tab(text: "Sent Items"),
                Tab(text: "Received Items"),
              ],
            ),
          ),
        ),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: _primaryColor,
                strokeWidth: 3,
              ),
            )
          : RefreshIndicator(
              color: _primaryColor,
              backgroundColor: Colors.white,
              onRefresh: _loadShipments,
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Wrapping in a subtle padding/layout if ShipmentListView doesn't have it natively
                  _buildTabContent(sentShipments),
                  _buildTabContent(receivedShipments),
                ],
              ),
            ),
    );
  }

  // Optional wrapper in case ShipmentListView needs a clean background constraint
  Widget _buildTabContent(List<dynamic> shipments) {
    if (shipments.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(), // Allows pull-to-refresh even when empty
        padding: const EdgeInsets.only(top: 80),
        children: const [
          Icon(Icons.inventory_2_outlined, size: 64, color: Color(0xFFCBD5E1)),
          SizedBox(height: 16),
          Text(
            "No shipments found",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
          ),
          SizedBox(height: 8),
          Text(
            "Pull down to refresh",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
          ),
        ],
      );
    }

    return ShipmentListView(shipments: shipments);
  }
}