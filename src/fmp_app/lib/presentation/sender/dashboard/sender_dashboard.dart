import 'package:flutter/material.dart';
import '../home/sender_home_screen.dart';
import '../create/sender_create_shipment_screen.dart';
import '../shipments/sender_shipments_screen.dart';
import '../billing/sender_billing_screen.dart';
import '../profile/sender_profile_screen.dart';

class SenderDashboardScreen extends StatefulWidget {
  const SenderDashboardScreen({super.key});

  @override
  State<SenderDashboardScreen> createState() => _SenderDashboardScreenState();
}

class _SenderDashboardScreenState extends State<SenderDashboardScreen> {
  int _index = 0;

  final _pages = const [
    SenderHomeScreen(),
    SenderCreateShipmentScreen(),
    SenderShipmentsScreen(),
    SenderBillingScreen(),
    SenderProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.add_box_outlined), selectedIcon: Icon(Icons.add_box), label: 'Create'),
          NavigationDestination(icon: Icon(Icons.local_shipping_outlined), selectedIcon: Icon(Icons.local_shipping), label: 'Shipments'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Billing'),
          NavigationDestination(icon: Icon(Icons.business_outlined), selectedIcon: Icon(Icons.business), label: 'Profile'),
        ],
      ),
    );
  }
}
