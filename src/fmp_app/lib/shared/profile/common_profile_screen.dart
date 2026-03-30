import 'package:flutter/material.dart';
import 'package:fmp_app/app_session.dart';
import 'package:fmp_app/shared/theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// COMMON PROFILE SCREEN
// Used by every dashboard as its Profile tab.
// All existing per-role profile files can simply return this widget,
// or be replaced entirely.
//
// Usage (drop-in for any role's profile screen body):
//
//   class DriverProfileScreen extends StatelessWidget {
//     const DriverProfileScreen({super.key});
//     @override
//     Widget build(BuildContext context) => const CommonProfileScreen();
//   }
// ─────────────────────────────────────────────────────────────────────────────

class CommonProfileScreen extends StatelessWidget {
  const CommonProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final phone    = AppSession.email    ?? '—';
    final role     = AppSession.roleLabel;
    final driverId = AppSession.driverId;

    // Role-specific accent colour and icon
    final (accent, icon) = _roleStyle(AppSession.role);

    // Initials from phone (last 4 digits as fallback)
    final initials = phone.length >= 2
        ? phone.replaceAll(RegExp(r'[^0-9]'), '').substring(
            (phone.replaceAll(RegExp(r'[^0-9]'), '').length - 2)
                .clamp(0, double.maxFinite.toInt()))
        : '??';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── Hero header ─────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _ProfileHero(
              phone: phone,
              role: role,
              initials: initials,
              accent: accent,
              icon: icon,
            ),
          ),

          // ── Info section ─────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md, AppSpacing.md, AppSpacing.md, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionLabel('ACCOUNT INFO'),
                  const SizedBox(height: AppSpacing.sm),
                  _InfoTile(
                    icon: Icons.phone_rounded,
                    label: 'Phone Number',
                    value: phone,
                    accent: accent,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  _InfoTile(
                    icon: icon,
                    label: 'Role',
                    value: role,
                    accent: accent,
                  ),
                  if (driverId != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    _InfoTile(
                      icon: Icons.badge_rounded,
                      label: 'Driver ID',
                      value: driverId,
                      accent: accent,
                    ),
                  ],
                ],
              ),
            ),
          ),

          // ── Settings section ──────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md, AppSpacing.lg, AppSpacing.md, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionLabel('SETTINGS'),
                  const SizedBox(height: AppSpacing.sm),
                  _ActionTile(
                    icon: Icons.notifications_outlined,
                    label: 'Notifications',
                    accent: accent,
                    onTap: () {},
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  _ActionTile(
                    icon: Icons.lock_outline_rounded,
                    label: 'Privacy & Security',
                    accent: accent,
                    onTap: () {},
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  _ActionTile(
                    icon: Icons.help_outline_rounded,
                    label: 'Help & Support',
                    accent: accent,
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ),

          // ── Logout ────────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: _LogoutButton(accent: accent),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
        ],
      ),
    );
  }

  /// Returns (accentColor, roleIcon) based on stored role string.
  (Color, IconData) _roleStyle(String? role) {
    switch (role) {
      case 'driver':
        return (const Color(0xFF1A56DB), Icons.directions_car_rounded);
      case 'sender':
      case 'organization':
        return (const Color(0xFF0E9F6E), Icons.inventory_2_rounded);
      case 'fleet_owner':
        return (const Color(0xFFD97706), Icons.account_balance_rounded);
      case 'admin':
      case 'super_admin':
        return (const Color(0xFF7C3AED), Icons.admin_panel_settings_rounded);
      case 'union_admin':
        return (const Color(0xFF0891B2), Icons.groups_rounded);
      default:
        return (AppColors.primary, Icons.person_rounded);
    }
  }
}

// ─── Hero header ─────────────────────────────────────────────────────────────

class _ProfileHero extends StatelessWidget {
  final String phone;
  final String role;
  final String initials;
  final Color accent;
  final IconData icon;

  const _ProfileHero({
    required this.phone,
    required this.role,
    required this.initials,
    required this.accent,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accent, accent.withOpacity(0.75)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.md, AppSpacing.lg, AppSpacing.md, AppSpacing.xl),
          child: Column(
            children: [
              // Avatar circle
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: Colors.white.withOpacity(0.4), width: 2),
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Phone
              Text(
                phone,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 6),

              // Role badge
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius:
                      BorderRadius.circular(AppRadius.pill),
                  border: Border.all(
                      color: Colors.white.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon,
                        size: 13,
                        color: Colors.white.withOpacity(0.9)),
                    const SizedBox(width: 6),
                    Text(
                      role,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.95),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Section label ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.textHint,
          letterSpacing: 1.1,
        ),
      );
}

// ─── Info tile (read-only) ────────────────────────────────────────────────────

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color accent;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(icon, size: 18, color: accent),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textHint,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Action tile (tappable) ───────────────────────────────────────────────────

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accent;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.border),
          boxShadow: AppShadows.card,
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: accent.withOpacity(0.08),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(icon, size: 18, color: accent),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                size: 20, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }
}

// ─── Logout button ────────────────────────────────────────────────────────────

class _LogoutButton extends StatelessWidget {
  final Color accent;
  const _LogoutButton({required this.accent});

  Future<void> _logout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg)),
        title: const Text(
          'Sign Out',
          style: TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary),
        ),
        content: const Text(
          'Are you sure you want to sign out?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.sm)),
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      await AppSession.clear();
      Navigator.pushNamedAndRemoveUntil(
          context, '/welcome', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _logout(context),
        icon: const Icon(Icons.logout_rounded, size: 18),
        label: const Text('Sign Out'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.error,
          side: const BorderSide(color: AppColors.error),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg)),
          textStyle: const TextStyle(
              fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}