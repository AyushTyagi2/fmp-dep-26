import 'package:flutter/material.dart';
import 'package:fmp_app/core/network/api_sys_admin.dart';

class RulesView extends StatefulWidget {
  const RulesView({super.key});

  @override
  State<RulesView> createState() => _RulesViewState();
}

class _RulesViewState extends State<RulesView> {
  final ApiSysAdmin _apiSysAdmin = ApiSysAdmin();
  late Future<List<Map<String, dynamic>>> _rulesFuture;

  @override
  void initState() {
    super.initState();
    _fetchRules();
  }

  void _fetchRules() {
    setState(() {
      _rulesFuture = _apiSysAdmin.getSystemRules();
    });
  }

  Map<String, List<Map<String, dynamic>>> _groupRules(List<Map<String, dynamic>> rules) {
    // Basic grouping based on rule keys. In a more complex app, the model might have a 'Category' field.
    final grouped = <String, List<Map<String, dynamic>>>{
      'Driver Matching Rules': [],
      'Pricing & Payments': [],
      'Security & Compliance': [],
      'Other Rules': [],
    };

    for (var rule in rules) {
      final key = rule['ruleKey'] as String? ?? '';
      if (key.contains('Assign') || key.contains('Requirement') || key.contains('Override')) {
        grouped['Driver Matching Rules']!.add(rule);
      } else if (key.contains('Pricing') || key.contains('Settlement')) {
        grouped['Pricing & Payments']!.add(rule);
      } else if (key.contains('KYC') || key.contains('2FA')) {
        grouped['Security & Compliance']!.add(rule);
      } else {
        grouped['Other Rules']!.add(rule);
      }
    }
    
    // Remove empty groups
    grouped.removeWhere((key, value) => value.isEmpty);
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _rulesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text("Failed to load rules: ${snapshot.error}", style: const TextStyle(color: Colors.red)));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("No rules found."),
                const SizedBox(height: 16),
                ElevatedButton(onPressed: _fetchRules, child: const Text("Retry"))
              ],
            )
          );
        }

        final groupedRules = _groupRules(snapshot.data!);

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 4),
                  child: Text(
                    "System Business Rules",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _fetchRules,
                  tooltip: 'Refresh Rules',
                )
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.0),
              child: Text(
                "Configure global business logic overrides and feature toggles.",
                style: TextStyle(color: Colors.grey),
              ),
            ),
            const SizedBox(height: 24),
            ...groupedRules.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: _RuleSection(
                  title: entry.key,
                  rules: entry.value.map((r) => _RuleTile(
                    ruleKey: r['ruleKey'],
                    title: _formatRuleKey(r['ruleKey']), 
                    description: r['description'] ?? r['ruleKey'], 
                    initialValue: r['isEnabled'] == true,
                    ruleValue: r['value'],
                    apiSysAdmin: _apiSysAdmin,
                    onUpdate: _fetchRules,
                  )).toList(),
                ),
              );
            }).toList(),
            const SizedBox(height: 32),
          ],
        );
      }
    );
  }

  String _formatRuleKey(String key) {
    // Basic camel case splitting for UI display
    final RegExp exp = RegExp(r'(?<=[a-z])(?=[A-Z])|(?<=[A-Za-z])(?=[A-Z][a-z])');
    final List<String> parts = key.split(exp);
    return parts.join(' ');
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
            border: BorderSide(color: Colors.grey.shade200),
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
  final String ruleKey;
  final String title;
  final String description;
  final bool initialValue;
  final String? ruleValue;
  final ApiSysAdmin apiSysAdmin;
  final VoidCallback onUpdate;

  const _RuleTile({
    required this.ruleKey,
    required this.title, 
    required this.description, 
    required this.initialValue,
    required this.apiSysAdmin,
    required this.onUpdate,
    this.ruleValue,
  });

  @override
  State<_RuleTile> createState() => _RuleTileState();
}

class _RuleTileState extends State<_RuleTile> {
  late bool _value;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _value = widget.initialValue;
  }

  Future<void> _toggleRule(bool val) async {
    setState(() {
      _isUpdating = true;
    });

    final success = await widget.apiSysAdmin.updateSystemRule(widget.ruleKey, val, widget.ruleValue);

    if (success) {
      setState(() {
        _value = val;
        _isUpdating = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("${widget.title} ${val ? 'enabled' : 'disabled'}"),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        )
      );
    } else {
      setState(() {
        _isUpdating = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to update ${widget.title}"),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        )
      );
    }
  }

  Future<void> _editValue() async {
    final controller = TextEditingController(text: widget.ruleValue ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Edit ${widget.title} Value"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: "Enter configuration value",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, null), child: const Text("Cancel")),
          ElevatedButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text("Save")),
        ],
      )
    );

    if (result != null && result != widget.ruleValue) {
      setState(() { _isUpdating = true; });
      final success = await widget.apiSysAdmin.updateSystemRule(widget.ruleKey, _value, result);
      setState(() { _isUpdating = false; });
      
      if (success) {
        widget.onUpdate(); // Refresh the list to show new value
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Value updated successfully")));
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to update value", style: TextStyle(color: Colors.red))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SwitchListTile.adaptive(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          title: Text(widget.title, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(widget.description, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          ),
          value: _value,
          activeColor: Colors.indigo,
          onChanged: _isUpdating ? null : _toggleRule,
          secondary: _isUpdating ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)) : null,
        ),
        if (widget.ruleValue != null && widget.ruleValue!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 12.0),
            child: Row(
               children: [
                 Container(
                   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                   decoration: BoxDecoration(
                     color: Colors.indigo.shade50,
                     borderRadius: BorderRadius.circular(6),
                     border: BorderSide(color: Colors.indigo.shade100)
                   ),
                   child: Row(
                     mainAxisSize: MainAxisSize.min,
                     children: [
                       Text("Value: ", style: TextStyle(fontSize: 12, color: Colors.indigo.shade900, fontWeight: FontWeight.bold)),
                       Text(widget.ruleValue!, style: TextStyle(fontSize: 12, color: Colors.indigo.shade700)),
                     ],
                   ),
                 ),
                 IconButton(
                   icon: Icon(Icons.edit, size: 16, color: Colors.indigo.shade300),
                   constraints: const BoxConstraints(),
                   padding: const EdgeInsets.only(left: 8),
                   onPressed: _isUpdating ? null : _editValue,
                 )
               ],
            ),
          )
      ],
    );
  }
}