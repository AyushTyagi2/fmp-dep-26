import 'package:flutter/material.dart';
import '../sys_admin_api.dart';
import '../../../../shared/theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// QUEUE VIEW — Logic unchanged, premium UI applied
// ─────────────────────────────────────────────────────────────────────────────

class QueueView extends StatefulWidget {
  const QueueView({super.key});

  @override
  State<QueueView> createState() => _QueueViewState();
}

class _QueueViewState extends State<QueueView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _api = SysAdminApi();

  List<dynamic> _pending  = [];
  List<dynamic> _approved = [];
  List<dynamic> _all      = [];
  bool _loading           = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([
        _api.getShipments(status: 'pending_approval'),
        _api.getShipments(status: 'approved'),
        _api.getShipments(),
      ]);
      setState(() {
        _pending  = results[0];
        _approved = results[1];
        _all      = results[2];
        _loading  = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _approve(String id) async {
    try {
      await _api.approveShipment(id);
      _showSnack('Shipment approved ✓', AppColors.success);
      _load();
    } catch (e) {
      _showSnack('Error: $e', AppColors.error);
    }
  }

  Future<void> _reject(String id) async {
    final reason = await _showReasonDialog('Reject Shipment');
    if (reason == null) return;
    try {
      await _api.rejectShipment(id, reason);
      _showSnack('Shipment rejected', AppColors.warning);
      _load();
    } catch (e) {
      _showSnack('Error: $e', AppColors.error);
    }
  }

  Future<void> _cancel(String id) async {
    final reason = await _showReasonDialog('Cancel Shipment');
    if (reason == null) return;
    try {
      await _api.cancelShipment(id, reason);
      _showSnack('Shipment cancelled', AppColors.textSecondary);
      _load();
    } catch (e) {
      _showSnack('Error: $e', AppColors.error);
    }
  }

  void _showSnack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  Future<String?> _showReasonDialog(String title) async {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        title: Text(title, style: AppTextStyles.headingSm),
        content: TextField(
          controller: ctrl,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Enter reason…',
            labelText: 'Reason',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final r = ctrl.text.trim();
              Navigator.pop(ctx, r.isEmpty ? null : r);
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Tabs ──────────────────────────────────────────────────────────
        Container(
          color: AppColors.surface,
          child: TabBar(
            controller: _tabs,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            indicatorWeight: 3,
            labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            tabs: [
              _TabWithBadge(label: 'Pending', count: _pending.length, color: AppColors.warning),
              _TabWithBadge(label: 'Approved', count: _approved.length, color: AppColors.success),
              _TabWithBadge(label: 'All', count: _all.length, color: AppColors.primary),
            ],
          ),
        ),
        const Divider(height: 1),

        if (_loading)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else if (_error != null)
          Expanded(
            child: Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 40),
                const SizedBox(height: 12),
                const Text('Failed to load shipments', style: AppTextStyles.headingSm),
                const SizedBox(height: 16),
                ElevatedButton(onPressed: _load, child: const Text('Retry')),
              ]),
            ),
          )
        else
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _ShipmentList(
                  shipments: _pending,
                  onApprove: _approve,
                  onReject: _reject,
                  onCancel: _cancel,
                  showApprove: true,
                ),
                _ShipmentList(
                  shipments: _approved,
                  onApprove: _approve,
                  onReject: _reject,
                  onCancel: _cancel,
                  showApprove: false,
                ),
                _ShipmentList(
                  shipments: _all,
                  onApprove: _approve,
                  onReject: _reject,
                  onCancel: _cancel,
                  showApprove: false,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ─── Tab with badge count ────────────────────────────────────────────────────

class _TabWithBadge extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _TabWithBadge({required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) => Tab(
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label),
        if (count > 0) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ],
    ),
  );
}

// ─── Shipment List ────────────────────────────────────────────────────────────

class _ShipmentList extends StatelessWidget {
  final List<dynamic> shipments;
  final Future<void> Function(String) onApprove;
  final Future<void> Function(String) onReject;
  final Future<void> Function(String) onCancel;
  final bool showApprove;

  const _ShipmentList({
    required this.shipments,
    required this.onApprove,
    required this.onReject,
    required this.onCancel,
    required this.showApprove,
  });

  Color _statusColor(String s) => switch (s.toLowerCase()) {
    'pending_approval' || 'pending' => AppColors.warning,
    'approved'                      => AppColors.success,
    'in_transit'                    => AppColors.primary,
    'delivered'                     => const Color(0xFF059669),
    'cancelled' || 'rejected'       => AppColors.error,
    _                               => AppColors.textSecondary,
  };

  @override
  Widget build(BuildContext context) {
    if (shipments.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.inbox_rounded, size: 48, color: AppColors.textHint),
          const SizedBox(height: 12),
          const Text('No shipments here', style: AppTextStyles.bodyMd),
        ]),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: shipments.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (ctx, i) {
        final s      = shipments[i] as Map<String, dynamic>;
        final id     = s['id']?.toString() ?? '';
        final num    = s['shipmentNumber']?.toString() ?? id;
        final status = (s['status']?.toString() ?? '').toLowerCase();
        final sc     = _statusColor(status);
        final isPending = status == 'pending_approval' || status == 'pending';

        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: isPending ? AppColors.warning.withOpacity(0.4) : AppColors.border,
            ),
            boxShadow: AppShadows.card,
          ),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Shipment #$num',
                      style: AppTextStyles.headingSm,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: sc.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(color: sc.withOpacity(0.3)),
                    ),
                    child: Text(
                      status.replaceAll('_', ' ').split(' ')
                          .map((w) => w.isEmpty ? '' : w[0].toUpperCase() + w.substring(1))
                          .join(' '),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: sc,
                      ),
                    ),
                  ),
                ],
              ),
              if (s['cargoType'] != null) ...[
                const SizedBox(height: 4),
                Text(
                  '${s['cargoType']}${s['cargoWeightKg'] != null ? ' • ${s['cargoWeightKg']} kg' : ''}',
                  style: AppTextStyles.bodySm,
                ),
              ],
              if (isPending || showApprove) ...[
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 10),
                Row(
                  children: [
                    if (showApprove || isPending)
                      Expanded(
                        child: _ActionBtn(
                          label: 'Approve',
                          icon: Icons.check_circle_rounded,
                          color: AppColors.success,
                          onTap: () => onApprove(id),
                        ),
                      ),
                    if (showApprove || isPending) const SizedBox(width: 8),
                    Expanded(
                      child: _ActionBtn(
                        label: 'Reject',
                        icon: Icons.block_rounded,
                        color: AppColors.error,
                        onTap: () => onReject(id),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ActionBtn(
                        label: 'Cancel',
                        icon: Icons.cancel_rounded,
                        color: AppColors.textSecondary,
                        onTap: () => onCancel(id),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn({required this.label, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    ),
  );
}
