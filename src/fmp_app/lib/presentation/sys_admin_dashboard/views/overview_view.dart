import 'package:flutter/material.dart';
import '../sys_admin_api.dart';
import '../../../../shared/theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// OVERVIEW VIEW — Redesigned compact stats UI
// ─────────────────────────────────────────────────────────────────────────────

class OverviewView extends StatefulWidget {
  const OverviewView({super.key});

  @override
  State<OverviewView> createState() => _OverviewViewState();
}

class _OverviewViewState extends State<OverviewView> {
  final _api = SysAdminApi();
  Map<String, dynamic>? _metrics;
  List<dynamic> _logs = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results =
          await Future.wait([_api.getMetrics(), _api.getLogs(limit: 10)]);
      setState(() {
        _metrics = results[0] as Map<String, dynamic>;
        _logs = results[1] as List<dynamic>;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: AppColors.errorLight, shape: BoxShape.circle),
            child: const Icon(Icons.error_outline_rounded,
                color: AppColors.error, size: 40),
          ),
          const SizedBox(height: 16),
          const Text('Failed to load data', style: AppTextStyles.headingSm),
          const SizedBox(height: 20),
          SizedBox(
            width: 140,
            child: ElevatedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Retry'),
            ),
          ),
        ]),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Section label ─────────────────────────────────────────────
            Text('PLATFORM METRICS', style: AppTextStyles.labelSm),
            const SizedBox(height: AppSpacing.sm),

            // ── Compact stat rows ─────────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: AppColors.border),
                boxShadow: AppShadows.card,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                child: Column(
                  children: [
                    _CompactStatRow(
                      title: 'Active Drivers',
                      value: '${_metrics!['activeDrivers'] ?? 0}',
                      icon: Icons.local_taxi_rounded,
                      color: AppColors.success,
                      isFirst: true,
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    _CompactStatRow(
                      title: 'Pending Shipments',
                      value: '${_metrics!['pendingShipments'] ?? 0}',
                      icon: Icons.pending_actions_rounded,
                      color: AppColors.warning,
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    _CompactStatRow(
                      title: 'Active Trips',
                      value: '${_metrics!['activeTrips'] ?? 0}',
                      icon: Icons.route_rounded,
                      color: AppColors.primary,
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    _CompactStatRow(
                      title: 'Admin Overrides',
                      value: '${_metrics!['adminOverrides'] ?? 0}',
                      icon: Icons.admin_panel_settings_rounded,
                      color: AppColors.error,
                      isLast: true,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // ── Recent activity ───────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('RECENT ACTIVITY', style: AppTextStyles.labelSm),
                TextButton.icon(
                  onPressed: _load,
                  icon: const Icon(Icons.refresh_rounded, size: 14),
                  label: const Text('Refresh'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),

            if (_logs.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.inbox_rounded,
                        size: 40, color: AppColors.textHint),
                    SizedBox(height: 8),
                    Text('No recent activity', style: AppTextStyles.bodyMd),
                  ],
                ),
              )
            else
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: AppColors.border),
                  boxShadow: AppShadows.card,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _logs.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, indent: 16, endIndent: 16),
                    itemBuilder: (ctx, i) {
                      final log = _logs[i] as Map<String, dynamic>;
                      final eventType = log['eventType']?.toString() ?? '';
                      final isWarning = eventType.contains('force') ||
                          eventType.contains('cancel');
                      final createdAt = log['createdAt']?.toString() ?? '';
                      final timeLabel = createdAt.length >= 16
                          ? createdAt
                              .substring(0, 16)
                              .replaceFirst('T', ' ')
                          : createdAt;
                      final entityId = log['entityId']?.toString() ?? '';

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isWarning
                                ? AppColors.warningLight
                                : AppColors.primaryLight,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isWarning
                                ? Icons.priority_high_rounded
                                : Icons.info_outline_rounded,
                            size: 18,
                            color:
                                isWarning ? AppColors.warning : AppColors.primary,
                          ),
                        ),
                        title: Text(eventType, style: AppTextStyles.labelLg),
                        subtitle: entityId.isNotEmpty
                            ? Text('Entity: $entityId',
                                style: AppTextStyles.bodySm)
                            : null,
                        trailing: Text(timeLabel, style: AppTextStyles.caption),
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Compact Stat Row ─────────────────────────────────────────────────────────
// Replaces the oversized grid cards with tight horizontal rows that put the
// value front-and-centre without wasting vertical space.

class _CompactStatRow extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final bool isFirst;
  final bool isLast;

  const _CompactStatRow({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: isFirst ? 4 : 0,
        bottom: isLast ? 4 : 0,
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        // ── Left: icon badge ──────────────────────────────────────────────
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        // ── Centre: label ─────────────────────────────────────────────────
        title: Text(
          title,
          style: AppTextStyles.bodyMd,
        ),
        // ── Right: value + accent bar ─────────────────────────────────────
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: color,
                height: 1,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 3,
              height: 22,
              decoration: BoxDecoration(
                color: color.withOpacity(0.25),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}