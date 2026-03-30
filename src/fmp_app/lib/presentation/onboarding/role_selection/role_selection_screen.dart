import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fmp_app/presentation/auth/auth_controller.dart';

// lib/presentation/onboarding/role_selection/role_selection_screen.dart
//
// CHANGE: Union Admin and System Admin are no longer shown as selectable cards.
// Instead, if the phone number belongs to a union_admin or admin, the backend
// will return the right screen via resolve-role and chooseRole() will navigate
// directly. The role cards shown here are the 4 normal user roles. Admin roles
// are resolved automatically by the AccountResolverScreen logic OR by the
// user selecting "Admin" below (which the backend then routes to the right
// dashboard based on their actual role in the DB).

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen>
    with SingleTickerProviderStateMixin {
  String? _selectedRole;
  late AnimationController _ctrl;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    if (_selectedRole == null) return;
    final auth = context.read<AuthController>();
    await auth.chooseRole(context, _selectedRole!);
  }

  static const _roles = [
    _RoleOption(
      id: 'driver',
      label: 'Driver',
      subtitle: 'Accept shipments & manage trips',
      icon: Icons.directions_car_rounded,
      color: Color(0xFF1A56DB),
      bg: Color(0xFFEBF0FE),
    ),
    _RoleOption(
      id: 'organization',
      label: 'Sender / Receiver',
      subtitle: 'Create & track your shipments',
      icon: Icons.inventory_2_rounded,
      color: Color(0xFF0E9F6E),
      bg: Color(0xFFDEF7EC),
    ),
    _RoleOption(
      id: 'fleet_owner',
      label: 'Fleet Manager',
      subtitle: 'Manage drivers, vehicles & trips',
      icon: Icons.account_balance_rounded,
      color: Color(0xFFD97706),
      bg: Color(0xFFFEF3C7),
    ),
    
  ];

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final isLoading = auth.stage == AuthStage.verifyingOtp;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fade,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEBF0FE),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.person_outline_rounded,
                      size: 26, color: Color(0xFF1A56DB)),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Who are you?',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Select your role to get the right experience',
                  style: TextStyle(
                      fontSize: 15, color: Color(0xFF6B7280), height: 1.5),
                ),
                const SizedBox(height: 32),
                Expanded(
                  child: ListView.separated(
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _roles.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) {
                      final role = _roles[i];
                      final selected = _selectedRole == role.id;
                      return _RoleCard(
                        option: role,
                        selected: selected,
                        onTap: () => setState(() => _selectedRole = role.id),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                if (auth.stage == AuthStage.error &&
                    auth.errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFDE8E8),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(children: [
                      const Icon(Icons.error_outline_rounded,
                          size: 16, color: Color(0xFFE02424)),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text(auth.errorMessage!,
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFFE02424)))),
                    ]),
                  ),
                  const SizedBox(height: 16),
                ],
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: (_selectedRole == null || isLoading)
                        ? null
                        : _confirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A56DB),
                      disabledBackgroundColor:
                          const Color(0xFF1A56DB).withOpacity(0.4),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white)))
                        : const Text('Continue',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 28),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleOption {
  final String id;
  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color bg;

  const _RoleOption({
    required this.id,
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.bg,
  });
}

class _RoleCard extends StatelessWidget {
  final _RoleOption option;
  final bool selected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? option.color.withOpacity(0.04) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? option.color : const Color(0xFFE5E9F0),
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: option.color.withOpacity(0.12),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  )
                ]
              : [
                  const BoxShadow(
                    color: Color(0x06000000),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  )
                ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: selected ? option.color : option.bg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(option.icon,
                  size: 24,
                  color: selected ? Colors.white : option.color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: selected
                          ? option.color
                          : const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    option.subtitle,
                    style: const TextStyle(
                        fontSize: 13, color: Color(0xFF6B7280)),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: selected ? option.color : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected
                      ? option.color
                      : const Color(0xFFD1D5DB),
                  width: 2,
                ),
              ),
              child: selected
                  ? const Icon(Icons.check_rounded,
                      size: 14, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}