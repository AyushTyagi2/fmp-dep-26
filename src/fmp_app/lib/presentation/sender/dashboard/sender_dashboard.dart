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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.add_box), label: 'Create'),
          BottomNavigationBarItem(icon: Icon(Icons.local_shipping), label: 'Shipments'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Billing'),
          BottomNavigationBarItem(icon: Icon(Icons.business), label: 'Profile'),
        ],
      ),
    );
  }
}
