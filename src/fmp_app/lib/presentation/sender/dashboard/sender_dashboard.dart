import 'package:flutter/material.dart';
import '../home/sender_home_screen.dart';
import '../create/sender_create_shipment_screen.dart';
import '../shipments/sender_shipments_screen.dart';
import '../billing/sender_billing_screen.dart';
import '../profile/sender_profile_screen.dart';
import '../search/sender_search_screen.dart';
import '../../../shared/theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SENDER DASHBOARD — Bottom-nav shell (logic unchanged, UI upgraded)
// ─────────────────────────────────────────────────────────────────────────────

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
    SenderSearchScreen(),
  ];

  static const _items = [
    _NavItem(Icons.dashboard_rounded,     Icons.dashboard_outlined,    'Home'),
    _NavItem(Icons.add_box_rounded,       Icons.add_box_outlined,      'Create'),
    _NavItem(Icons.local_shipping_rounded,Icons.local_shipping_outlined,'Shipments'),
    _NavItem(Icons.receipt_long_rounded,  Icons.receipt_long_outlined, 'Billing'),
    _NavItem(Icons.business_rounded,      Icons.business_outlined,     'Profile'),
    _NavItem(Icons.search_rounded,        Icons.search_outlined,       'Search'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: _AppBottomNav(
        currentIndex: _index,
        items: _items,
        onTap: (i) => setState(() => _index = i),
        accentColor: AppColors.primary,
      ),
    );
  }
}

// ─── Premium pill-style bottom nav ───────────────────────────────────────────

class _NavItem {
  final IconData activeIcon, icon;
  final String label;
  const _NavItem(this.activeIcon, this.icon, this.label);
}

class _AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final List<_NavItem> items;
  final ValueChanged<int> onTap;
  final Color accentColor;
  const _AppBottomNav({
    required this.currentIndex,
    required this.items,
    required this.onTap,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(top: BorderSide(color: AppColors.border, width: 1)),
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
              final item = items[i];
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
                          horizontal: 14,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: active
                              ? accentColor.withOpacity(0.1)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Icon(
                          active ? item.activeIcon : item.icon,
                          size: 22,
                          color: active ? accentColor : AppColors.textHint,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight:
                              active ? FontWeight.w600 : FontWeight.w400,
                          color: active ? accentColor : AppColors.textHint,
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
