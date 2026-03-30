import 'package:flutter/material.dart';
import 'package:fmp_app/presentation/sys_admin_dashboard/views/overview_view.dart';
import 'package:fmp_app/presentation/sys_admin_dashboard/views/users_view.dart';
import 'package:fmp_app/presentation/sys_admin_dashboard/views/logs_view.dart';
import 'package:fmp_app/presentation/sys_admin_dashboard/views/queue_view.dart';
import 'package:fmp_app/presentation/sys_admin_dashboard/views/rules_view.dart';
import 'package:fmp_app/shared/profile/common_profile_screen.dart';
import 'package:fmp_app/app_session.dart';
import '../../../shared/theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SYS ADMIN DASHBOARD — added Profile tab (index 5) using CommonProfileScreen
// ─────────────────────────────────────────────────────────────────────────────

class SysAdminDashboardScreen extends StatefulWidget {
  const SysAdminDashboardScreen({super.key});

  @override
  State<SysAdminDashboardScreen> createState() =>
      _SysAdminDashboardScreenState();
}

class _SysAdminDashboardScreenState extends State<SysAdminDashboardScreen> {
  int _selectedIndex = 0;

  static const _views = [
    OverviewView(),
    UsersView(),
    LogsView(),
    QueueView(),
    RulesView(),
    CommonProfileScreen(), // index 5
  ];

  static const _navItems = [
    _NavEntry(Icons.dashboard_rounded,            Icons.dashboard_outlined,          'Overview',     'Platform metrics & recent activity'),
    _NavEntry(Icons.people_rounded,               Icons.people_outline_rounded,      'Users',        'Search and manage all users'),
    _NavEntry(Icons.history_rounded,              Icons.history_outlined,            'System Logs',  'Audit trail and event history'),
    _NavEntry(Icons.inbox_rounded,                Icons.inbox_outlined,              'Queue',        'Shipment approval & management'),
    _NavEntry(Icons.tune_rounded,                 Icons.tune_outlined,               'Rules Engine', 'Business logic configuration'),
    _NavEntry(Icons.person_rounded,               Icons.person_outline_rounded,      'Profile',      'Account & session details'),
  ];

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    Navigator.pop(context); // close drawer
  }

  @override
  Widget build(BuildContext context) {
    final nav = _navItems[_selectedIndex];
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(nav.label),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
          const _AdminAvatar(),
          const SizedBox(width: 8),
        ],
      ),
      drawer: _AdminDrawer(
        selectedIndex: _selectedIndex,
        items: _navItems,
        onTap: _onItemTapped,
      ),
      body: IndexedStack(index: _selectedIndex, children: _views),
    );
  }
}

// ─── Drawer ───────────────────────────────────────────────────────────────────

class _NavEntry {
  final IconData activeIcon, icon;
  final String label, subtitle;
  const _NavEntry(this.activeIcon, this.icon, this.label, this.subtitle);
}

class _AdminDrawer extends StatelessWidget {
  final int selectedIndex;
  final List<_NavEntry> items;
  final ValueChanged<int> onTap;
  const _AdminDrawer({
    required this.selectedIndex,
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final phone = AppSession.email ?? 'Administrator';

    return Drawer(
      backgroundColor: const Color(0xFF0F172A),
      child: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(
                          color: AppColors.primary.withOpacity(0.3)),
                    ),
                    child: const Icon(Icons.admin_panel_settings_rounded,
                        color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          phone,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'System Administrator',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.4),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Divider(color: const Color(0xFF1E293B), height: 1),
          ),
          const SizedBox(height: 8),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'NAVIGATION',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.3),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: items.length,
              itemBuilder: (ctx, i) {
                final item = items[i];
                final active = i == selectedIndex;

                // Visual separator before Profile entry
                return Column(
                  children: [
                    if (i == items.length - 1) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        child: Divider(
                            color: const Color(0xFF1E293B), height: 1),
                      ),
                    ],
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        child: InkWell(
                          borderRadius:
                              BorderRadius.circular(AppRadius.md),
                          onTap: () => onTap(i),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: active
                                  ? AppColors.primary.withOpacity(0.15)
                                  : Colors.transparent,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.md),
                              border: Border.all(
                                color: active
                                    ? AppColors.primary.withOpacity(0.3)
                                    : Colors.transparent,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  active ? item.activeIcon : item.icon,
                                  size: 20,
                                  color: active
                                      ? AppColors.primary
                                      : Colors.white.withOpacity(0.5),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.label,
                                        style: TextStyle(
                                          color: active
                                              ? Colors.white
                                              : Colors.white
                                                  .withOpacity(0.7),
                                          fontSize: 14,
                                          fontWeight: active
                                              ? FontWeight.w600
                                              : FontWeight.w400,
                                        ),
                                      ),
                                      Text(
                                        item.subtitle,
                                        style: TextStyle(
                                          color:
                                              Colors.white.withOpacity(0.3),
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (active)
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: AppColors.primary,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Divider(color: const Color(0xFF1E293B), height: 1),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'FMP Logistics Platform v1.0',
              style: TextStyle(
                color: Colors.white.withOpacity(0.2),
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Admin Avatar ─────────────────────────────────────────────────────────────

class _AdminAvatar extends StatelessWidget {
  const _AdminAvatar();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Tap avatar → jump straight to Profile (index 5)
        final state = context
            .findAncestorStateOfType<_SysAdminDashboardScreenState>();
        state?.setState(() => state._selectedIndex = 5);
      },
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.border, width: 1.5),
        ),
        child: const Center(
          child: Text(
            'SA',
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}