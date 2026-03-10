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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home),   label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.list),   label: 'Queue'),
          BottomNavigationBarItem(icon: Icon(Icons.folder), label: 'Requests'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}