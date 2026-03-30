import 'package:flutter/material.dart';
import '../sys_admin_api.dart';
import '../../../../shared/theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// LOGS VIEW — Logic unchanged, premium UI applied
// ─────────────────────────────────────────────────────────────────────────────

class LogsView extends StatefulWidget {
  const LogsView({super.key});

  @override
  State<LogsView> createState() => _LogsViewState();
}

class _LogsViewState extends State<LogsView> {
  final _api = SysAdminApi();
  List<dynamic> _allLogs = [];
  String _filter         = 'All Logs';
  bool _loading          = true;
  String? _error;

  static const _filters = [
    'All Logs',
    'force_assigned',
    'cancel',
    'approve',
    'reject',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final logs = await _api.getLogs(limit: 100);
      setState(() { _allLogs = logs; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  List<dynamic> get _filtered {
    if (_filter == 'All Logs') return _allLogs;
    return _allLogs.where((l) {
      final et = (l['eventType'] as String? ?? '').toLowerCase();
      return et.contains(_filter.toLowerCase());
    }).toList();
  }

  Color _eventColor(String eventType) {
    final et = eventType.toLowerCase();
    if (et.contains('cancel') || et.contains('reject')) return AppColors.error;
    if (et.contains('force') || et.contains('override'))  return AppColors.warning;
    if (et.contains('approve') || et.contains('assign'))  return AppColors.success;
    return AppColors.primary;
  }

  IconData _eventIcon(String eventType) {
    final et = eventType.toLowerCase();
    if (et.contains('cancel'))   return Icons.cancel_rounded;
    if (et.contains('reject'))   return Icons.block_rounded;
    if (et.contains('force'))    return Icons.flash_on_rounded;
    if (et.contains('approve'))  return Icons.check_circle_rounded;
    if (et.contains('assign'))   return Icons.assignment_ind_rounded;
    return Icons.info_outline_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Filter chips ──────────────────────────────────────────────────
        Container(
          color: AppColors.surface,
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 32,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _filters.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 6),
                    itemBuilder: (ctx, i) {
                      final f = _filters[i];
                      final active = _filter == f;
                      return GestureDetector(
                        onTap: () => setState(() => _filter = f),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: active ? AppColors.primary : AppColors.background,
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                            border: Border.all(
                              color: active ? AppColors.primary : AppColors.border,
                            ),
                          ),
                          child: Text(
                            f,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: active ? Colors.white : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.border),
                ),
                child: IconButton(
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  onPressed: _load,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // ── Log list ──────────────────────────────────────────────────────
        if (_loading)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else if (_error != null)
          Expanded(
            child: Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 40),
                const SizedBox(height: 12),
                const Text('Failed to load logs', style: AppTextStyles.headingSm),
                const SizedBox(height: 16),
                ElevatedButton(onPressed: _load, child: const Text('Retry')),
              ]),
            ),
          )
        else
          Expanded(
            child: Builder(builder: (ctx) {
              final logs = _filtered;
              if (logs.isEmpty) {
                return Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.inbox_rounded, size: 48, color: AppColors.textHint),
                    const SizedBox(height: 12),
                    const Text('No logs for this filter', style: AppTextStyles.bodyMd),
                  ]),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.md),
                itemCount: logs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemBuilder: (ctx, i) {
                  final log       = logs[i] as Map<String, dynamic>;
                  final eventType = log['eventType']?.toString() ?? '';
                  final createdAt = log['createdAt']?.toString() ?? '';
                  final entityId  = log['entityId']?.toString() ?? '';
                  final timeLabel = createdAt.length >= 16
                      ? createdAt.substring(0, 16).replaceFirst('T', ' ')
                      : createdAt;
                  final color = _eventColor(eventType);

                  return Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: AppColors.border),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(_eventIcon(eventType), size: 16, color: color),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(eventType, style: AppTextStyles.labelLg),
                              if (entityId.isNotEmpty)
                                Text(
                                  'Entity: $entityId',
                                  style: AppTextStyles.bodySm,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                        Text(timeLabel, style: AppTextStyles.caption),
                      ],
                    ),
                  );
                },
              );
            }),
          ),
      ],
    );
  }
}
