import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fmp_app/presentation/auth/auth_controller.dart';

enum UserRole { driver, organization, fleetOwner, systemAdmin }

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthController>();

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Select Your Role",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),

            _RoleButton(
              icon: Icons.local_shipping,
              title: "Driver",
              subtitle: "Accept & deliver shipments",
              onTap: () => auth.chooseRole(context,"driver"),
            ),

            _RoleButton(
              icon: Icons.business,
              title: "Organization",
              subtitle: "Send or receive goods",
              onTap: () => auth.chooseRole(context, "organization"),
            ),

            _RoleButton(
              icon: Icons.directions_bus,
              title: "Fleet Owner",
              subtitle: "Manage vehicles & drivers",
              onTap: () => auth.chooseRole(context,"fleetOwner"),
            ),

            _RoleButton(
              icon: Icons.admin_panel_settings,
              title: "System Admin",
              subtitle: "Platform administration",
              onTap: () {
                Navigator.pushReplacementNamed(context, '/system_admin');
              },
              ),

              _RoleButton(
                icon: Icons.admin_panel_settings,
                title: "Union Admin",
                subtitle: "Union administration",
                onTap: () {
                  Navigator.pushReplacementNamed(context, '/union-dashboard');
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _RoleButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _RoleButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              Icon(icon, size: 32),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(subtitle,
                        style: TextStyle(color: Colors.grey.shade600)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
