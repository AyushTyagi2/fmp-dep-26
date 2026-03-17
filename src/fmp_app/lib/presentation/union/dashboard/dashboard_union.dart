import 'package:flutter/material.dart';
import '../union_queue/queue.dart';
import '../union_request/request.dart';
import '../union_profile/profile.dart';
import '../union_home/home.dart';

class UnionDashboardScreen extends StatefulWidget {
  final String driverId;

  const UnionDashboardScreen({super.key, required this.driverId});

  @override
  State<UnionDashboardScreen> createState() => _UnionDashboardScreenState();
}

class _UnionDashboardScreenState extends State<UnionDashboardScreen> {
  int _index = 0;

  late final _pages = [
    UnionHomeScreen(),
    QueueScreen(driverId: widget.driverId),
    UnionRequestScreen(),
    UnionProfileScreen(),
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
          NavigationDestination(icon: Icon(Icons.queue_play_next_outlined), selectedIcon: Icon(Icons.queue_play_next), label: 'Queue'),
          NavigationDestination(icon: Icon(Icons.request_page_outlined), selectedIcon: Icon(Icons.request_page), label: 'Requests'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}