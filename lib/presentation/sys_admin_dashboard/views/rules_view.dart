import 'package:flutter/material.dart';
import '../../../../shared/theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// RULES VIEW — Logic unchanged, premium UI applied
// ─────────────────────────────────────────────────────────────────────────────

class RulesView extends StatelessWidget {
  const RulesView({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.primary.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: const Icon(Icons.tune_rounded, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Rules Engine', style: AppTextStyles.headingSm),
                    Text(
                      'Configure global business logic and feature toggles.',
                      style: AppTextStyles.bodySm,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        _RuleSection(
          title: 'Driver Matching',
          icon: Icons.local_taxi_rounded,
          rules: const [
            _RuleData(
              title: 'Auto-assign nearest driver',
              description: 'Automatically assign unassigned jobs to the closest available driver within 5km.',
              initialValue: true,
            ),
            _RuleData(
              title: 'Strict vehicle requirement',
              description: 'Enforce strict matching of vehicle type requested by sender.',
              initialValue: true,
            ),
            _RuleData(
              title: 'Allow manual override',
              description: 'Allow dispatchers to manually override system routing decisions.',
              initialValue: false,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),

        _RuleSection(
          title: 'Pricing & Payments',
          icon: Icons.payments_rounded,
          rules: const [
            _RuleData(
              title: 'Dynamic Surge Pricing',
              description: 'Enable surge multiplier during high demand hours (1.5× max).',
              initialValue: true,
            ),
            _RuleData(
              title: 'Auto-settlement processing',
              description: 'Automatically process driver payouts at end of day.',
              initialValue: false,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),

        _RuleSection(
          title: 'Security & Compliance',
          icon: Icons.shield_rounded,
          rules: const [
            _RuleData(
              title: 'Strict KYC verification',
              description: 'Require manual approval of all new driver KYC documents.',
              initialValue: true,
            ),
            _RuleData(
              title: 'Force 2FA for Admin',
              description: 'Require two-factor authentication for all administrator actions.',
              initialValue: true,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}

// ─── Rule data model ──────────────────────────────────────────────────────────

class _RuleData {
  final String title, description;
  final bool initialValue;
  const _RuleData({required this.title, required this.description, required this.initialValue});
}

// ─── Rule Section Card ────────────────────────────────────────────────────────

class _RuleSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<_RuleData> rules;
  const _RuleSection({required this.title, required this.icon, required this.rules});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.md, AppSpacing.md, 0),
            child: Row(
              children: [
                Icon(icon, size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(title.toUpperCase(), style: AppTextStyles.labelSm),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),
          ...rules.map((r) => _RuleTile(data: r)),
        ],
      ),
    );
  }
}

// ─── Rule Tile ────────────────────────────────────────────────────────────────

class _RuleTile extends StatefulWidget {
  final _RuleData data;
  const _RuleTile({required this.data});

  @override
  State<_RuleTile> createState() => _RuleTileState();
}

class _RuleTileState extends State<_RuleTile> {
  late bool _value;

  @override
  void initState() {
    super.initState();
    _value = widget.data.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.data.title, style: AppTextStyles.labelLg),
                    const SizedBox(height: 3),
                    Text(
                      widget.data.description,
                      style: AppTextStyles.bodySm,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Switch(
                value: _value,
                onChanged: (v) => setState(() => _value = v),
                activeColor: AppColors.primary,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
        ),
        const Divider(height: 1, indent: AppSpacing.md, endIndent: AppSpacing.md),
      ],
    );
  }
}
