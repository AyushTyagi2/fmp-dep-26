import 'package:flutter/material.dart';
import '../union_queue/queue.dart';
import '../union_request/request.dart';
import '../union_profile/profile.dart';
import '../union_home/home.dart';
import '../../../shared/theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// UNION DASHBOARD — Logic unchanged, premium UI applied
// ─────────────────────────────────────────────────────────────────────────────

class UnionDashboardScreen extends StatefulWidget {
  final String driverId;

  const UnionDashboardScreen({super.key, required this.driverId});

  @override
  State<UnionDashboardScreen> createState() => _UnionDashboardScreenState();
}

class _UnionDashboardScreenState extends State<UnionDashboardScreen> {
  int _index = 0;

  late final _pages = [
    const UnionHomeScreen(),
    QueueScreen(driverId: widget.driverId),
    const UnionRequestScreen(),
    const UnionProfileScreen(),
  ];

  static const _items = [
    (Icons.home_rounded,    Icons.home_outlined,            'Home'),
    (Icons.inbox_rounded,   Icons.inbox_outlined,           'Queue'),
    (Icons.folder_rounded,  Icons.folder_outlined,          'Requests'),
    (Icons.person_rounded,  Icons.person_outline_rounded,   'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: _BottomNav(
        currentIndex: _index,
        items: _items,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}

// ─── Premium Bottom Nav ───────────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final List<(IconData, IconData, String)> items;
  final ValueChanged<int> onTap;

  const _BottomNav({
    required this.currentIndex,
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(top: BorderSide(color: AppColors.border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: List.generate(items.length, (i) {
              final (activeIcon, icon, label) = items[i];
              final active = i == currentIndex;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 4),
                        decoration: BoxDecoration(
                          color: active
                              ? AppColors.primaryLight
                              : Colors.transparent,
                          borderRadius:
                              BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Icon(
                          active ? activeIcon : icon,
                          size: 22,
                          color: active
                              ? AppColors.primary
                              : AppColors.textHint,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: active
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: active
                              ? AppColors.primary
                              : AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
