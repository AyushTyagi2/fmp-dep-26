import 'package:flutter/material.dart';

class RulesView extends StatelessWidget {
  const RulesView({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 4),
          child: Text(
            "System Business Rules",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.0),
          child: Text(
            "Configure global business logic overrides and feature toggles.",
            style: TextStyle(color: Colors.grey),
          ),
        ),
        const SizedBox(height: 24),
        _RuleSection(
          title: "Driver Matching Rules",
          rules: [
            _RuleTile(title: "Auto-assign nearest driver", description: "Automatically assign unassigned jobs to the closest available driver within 5km.", initialValue: true),
            _RuleTile(title: "Strict vehicle requirement", description: "Enforce strict matching of vehicle type requested by sender.", initialValue: true),
            _RuleTile(title: "Allow manual override", description: "Allow dispatchers to manually override system routing.", initialValue: false),
          ],
        ),
        const SizedBox(height: 16),
        _RuleSection(
          title: "Pricing & Payments",
          rules: [
            _RuleTile(title: "Dynamic Surge Pricing", description: "Enable surge multiplier during high demand hours (1.5x max).", initialValue: true),
            _RuleTile(title: "Auto-settlement processing", description: "Automatically process driver payouts at end of day.", initialValue: false),
          ],
        ),
        const SizedBox(height: 16),
        _RuleSection(
          title: "Security & Compliance",
          rules: [
            _RuleTile(title: "Strict KYC verification", description: "Require manual approval of all new driver KYC documents.", initialValue: true),
            _RuleTile(title: "Force 2FA for Admin", description: "Require two-factor authentication for all system administrator actions.", initialValue: true),
          ],
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

class _RuleSection extends StatelessWidget {
  final String title;
  final List<_RuleTile> rules;

  const _RuleSection({required this.title, required this.rules});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.indigo.shade400, letterSpacing: 1.2),
          ),
        ),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: Column(
            children: rules.asMap().entries.map((entry) {
              final index = entry.key;
              final rule = entry.value;
              return Column(
                children: [
                  rule,
                  if (index < rules.length - 1)
                    const Divider(height: 1),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _RuleTile extends StatefulWidget {
  final String title;
  final String description;
  final bool initialValue;

  const _RuleTile({required this.title, required this.description, required this.initialValue});

  @override
  State<_RuleTile> createState() => _RuleTileState();
}

class _RuleTileState extends State<_RuleTile> {
  late bool _value;

  @override
  void initState() {
    super.initState();
    _value = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    return SwitchListTile.adaptive(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      title: Text(widget.title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: Text(widget.description, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
      ),
      value: _value,
      activeColor: Colors.indigo,
      onChanged: (val) {
        setState(() {
          _value = val;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${widget.title} ${_value ? 'enabled' : 'disabled'}"),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          )
        );
      },
    );
  }
}