import 'package:flutter/material.dart';
import 'package:fmp_app/presentation/sys_admin_dashboard/views/overview_view.dart';
import 'package:fmp_app/presentation/sys_admin_dashboard/views/users_view.dart';
import 'package:fmp_app/presentation/sys_admin_dashboard/views/logs_view.dart';
import 'package:fmp_app/presentation/sys_admin_dashboard/views/queue_view.dart';
import 'package:fmp_app/presentation/sys_admin_dashboard/views/rules_view.dart';

// This is the MAIN container for the Sys Admin module.
class SysAdminDashboardScreen extends StatefulWidget {
  const SysAdminDashboardScreen({super.key});

  @override
  State<SysAdminDashboardScreen> createState() => _SysAdminDashboardScreenState();
}

class _SysAdminDashboardScreenState extends State<SysAdminDashboardScreen> {
  int _selectedIndex = 0;

  // The list of views to switch between based on Drawer selection
  final List<Widget> _views = [
    const OverviewView(),
    const UsersView(),
    const LogsView(),
    const QueueView(),
    const RulesView(),
  ];

  final List<String> _titles = [
    "Dashboard Overview",
    "User Management",
    "System Logs",
    "Queue Management",
    "Rules Engine",
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    Navigator.pop(context); // Close the drawer
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        backgroundColor: Colors.blueGrey,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blueGrey,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(Icons.admin_panel_settings, size: 48, color: Colors.white),
                  SizedBox(height: 12),
                  Text(
                    'Sys Admin Panel',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                    ),
                  ),
                ],
              ),
            ),
            _buildDrawerItem(Icons.dashboard, "Overview", 0),
            _buildDrawerItem(Icons.people, "Users", 1),
            _buildDrawerItem(Icons.history, "System Logs", 2),
            const Divider(),
            _buildDrawerItem(Icons.queue, "Queue Management", 3),
            _buildDrawerItem(Icons.settings, "Rules Engine", 4),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text('Logout', style: TextStyle(color: Colors.redAccent)),
              onTap: () {
                // Return to Role Selection or Login
                Navigator.pop(context); // Close drawer
                Navigator.of(context).pushReplacementNamed('/role-selection');
              },
            ),
          ],
        ),
      ),
      body: _views[_selectedIndex],
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, int index) {
    return ListTile(
      leading: Icon(icon, color: _selectedIndex == index ? Colors.blueGrey : null),
      title: Text(
        title,
        style: TextStyle(
          color: _selectedIndex == index ? Colors.blueGrey : null,
          fontWeight: _selectedIndex == index ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: _selectedIndex == index,
      onTap: () => _onItemTapped(index),
    );
  }
}
