import 'package:flutter/material.dart';
import 'package:fmp_app/presentation/sys_admin_dashboard/views/overview_view.dart';
import 'package:fmp_app/presentation/sys_admin_dashboard/views/users_view.dart';
import 'package:fmp_app/presentation/sys_admin_dashboard/views/logs_view.dart';
import 'package:fmp_app/presentation/sys_admin_dashboard/views/queue_view.dart';
import 'package:fmp_app/presentation/sys_admin_dashboard/views/rules_view.dart';
import 'package:fmp_app/core/theme/app_theme.dart';

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
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(_titles[_selectedIndex], style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 20)),
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.primary,
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: CircleAvatar(
              backgroundColor: AppTheme.primary,
              child: Text('SA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: Drawer(
        backgroundColor: AppTheme.primary, // using primary instead of slate for drawer mapping
        child: Column(
          children: [
            const UserAccountsDrawerHeader(
              decoration: BoxDecoration(
                color: Color(0xFF10284f), // darker primary
              ),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.admin_panel_settings, size: 40, color: AppTheme.primary),
              ),
              accountName: const Text(
                'System Administrator',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              accountEmail: const Text('admin@fmp.app', style: TextStyle(color: Colors.white70)),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildDrawerItem(Icons.dashboard, "Overview", 0),
                  _buildDrawerItem(Icons.people_alt, "Users", 1),
                  _buildDrawerItem(Icons.receipt_long, "System Logs", 2),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Text("SYSTEM", style: TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                  ),
                  _buildDrawerItem(Icons.queue_play_next, "Queue Management", 3),
                  _buildDrawerItem(Icons.rule, "Rules Engine", 4),
                ],
              ),
            ),
            const Divider(color: Colors.white24),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text('Logout', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w500)),
              onTap: () {
                Navigator.pop(context); 
                Navigator.of(context).pushReplacementNamed('/role-selection');
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      body: _views[_selectedIndex],
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, int index) {
    final isSelected = _selectedIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        tileColor: isSelected ? Colors.white.withOpacity(0.15) : Colors.transparent,
        leading: Icon(icon, color: isSelected ? Colors.white : Colors.white70),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
        selected: isSelected,
        onTap: () => _onItemTapped(index),
      ),
    );
  }
}