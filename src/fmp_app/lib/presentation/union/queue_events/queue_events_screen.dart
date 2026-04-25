import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_shipment_queue.dart';
import '../../../shared/theme/app_theme.dart';
import 'create_queue_event_screen.dart';
import 'queue_event_detail_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// QUEUE EVENTS SCREEN
// Lists past + current queue events. The active one gets a LIVE badge.
// + button → push to CreateQueueEventScreen.
// Tap a card → push to QueueEventDetailScreen.
// ─────────────────────────────────────────────────────────────────────────────

class QueueEventsScreen extends StatefulWidget {
  const QueueEventsScreen({super.key});

  @override
  State<QueueEventsScreen> createState() => _QueueEventsScreenState();
}

class _QueueEventsScreenState extends State<QueueEventsScreen> {
  late final ShipmentApiService _api;

  List<Map<String, dynamic>> _events  = [];
  bool                       _loading = true;
  String?                    _error;
  Timer?                     _refreshTimer;

  @override
  void initState() {
    super.initState();
    _api = ShipmentApiService(ApiClient());
    _load();
    // Refresh every 10 s so LIVE badge stays accurate
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _load(silent: true),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) setState(() { _loading = true; _error = null; });
    try {
      final data = await _api.getAllQueueEvents();
      if (!mounted) return;
      setState(() { _events = data; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      if (!silent) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _openCreate() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CreateQueueEventScreen(api: _api),
      ),
    );
    if (created == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Queue Events'),
        actions: [
          IconButton(
            icon     : const Icon(Icons.add_rounded),
            tooltip  : 'New Event',
            onPressed: _openCreate,
          ),
          IconButton(
            icon     : const Icon(Icons.refresh_rounded),
            onPressed: () => _load(),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : _events.isEmpty
                  ? _buildEmpty()
                  : _buildList(),
    );
  }

  // ── States ────────────────────────────────────────────────────────────────

  Widget _buildError() => Center(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child  : Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.error),
          const SizedBox(height: 12),
          Text(_error!,
              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
              textAlign: TextAlign.center),
          const SizedBox(height: 20),
          ElevatedButton(onPressed: _load, child: const Text('Retry')),
        ],
      ),
    ),
  );

  Widget _buildEmpty() => Center(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child  : Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding   : const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.event_rounded, size: 48, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          const Text('No queue events yet',
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          const Text(
            'Tap + to create your first queue session.',
            style    : TextStyle(fontSize: 14, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _openCreate,
            icon : const Icon(Icons.add_rounded, size: 18),
            label: const Text('Create Event'),
          ),
        ],
      ),
    ),
  );

  Widget _buildList() => RefreshIndicator(
    onRefresh: _load,
    color    : AppColors.primary,
    child    : ListView.separated(
      padding         : const EdgeInsets.all(AppSpacing.md),
      itemCount       : _events.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder     : (_, i) => _EventCard(
        event: _events[i],
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => QueueEventDetailScreen(
                event: _events[i],
                api  : _api,
              ),
            ),
          );
          _load();  // refresh in case toggle changed status
        },
      ),
    ),
  );
}

// ─── Event Card ───────────────────────────────────────────────────────────────

class _EventCard extends StatelessWidget {
  final Map<String, dynamic> event;
  final VoidCallback         onTap;

  const _EventCard({required this.event, required this.onTap});

  bool get _isLive {
    final status  = event['status'] as String? ?? '';
    final endTime = _parseUtc(event['endTime'] as String? ?? '');
    return status == 'live' && (endTime?.isAfter(DateTime.now()) ?? false);
  }

  DateTime? _parseUtc(String raw) {
    if (raw.isEmpty) return null;
    try { return DateTime.parse(raw).toLocal(); } catch (_) { return null; }
  }

  String _fmt(String? raw) {
    final dt = _parseUtc(raw ?? '');
    if (dt == null) return '—';
    return '${dt.day}/${dt.month}/${dt.year}  '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _window(dynamic secs) {
    final s = (secs as num?)?.toInt() ?? 0;
    if (s == 0) return '—';
    return s < 60 ? '${s}s' : '${s ~/ 60} min';
  }

  @override
  Widget build(BuildContext context) {
    final live = _isLive;
    return Container(
      decoration: BoxDecoration(
        color       : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border      : Border.all(
          color: live ? const Color(0xFF057A55).withOpacity(0.35) : AppColors.border,
          width: live ? 1.5 : 1,
        ),
        boxShadow   : AppShadows.card,
      ),
      child: Material(
        color       : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          onTap       : onTap,
          child       : Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child  : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ── status badge + chevron ──────────────────────────────
                Row(
                  children: [
                    if (live) ...[
                      Container(
                        padding   : const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color       : const Color(0xFF057A55),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _PulsingDot(),
                            const SizedBox(width: 5),
                            const Text('LIVE',
                                style: TextStyle(
                                    color       : Colors.white,
                                    fontSize    : 11,
                                    fontWeight  : FontWeight.w800,
                                    letterSpacing: 0.6)),
                          ],
                        ),
                      ),
                    ] else ...[
                      Container(
                        padding   : const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color       : AppColors.border,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: const Text('CLOSED',
                            style: TextStyle(
                                color       : AppColors.textSecondary,
                                fontSize    : 11,
                                fontWeight  : FontWeight.w700,
                                letterSpacing: 0.6)),
                      ),
                    ],
                    const Spacer(),
                    const Icon(Icons.chevron_right_rounded,
                        color: AppColors.textHint),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),

                // ── meta rows ──────────────────────────────────────────
                _MetaRow(
                  icon : Icons.play_circle_outline_rounded,
                  label: 'Started',
                  value: _fmt(event['startTime'] as String?),
                ),
                const SizedBox(height: 6),
                _MetaRow(
                  icon : Icons.stop_circle_outlined,
                  label: 'Ends',
                  value: _fmt(event['endTime'] as String?),
                ),
                const SizedBox(height: 6),
                _MetaRow(
                  icon : Icons.hourglass_bottom_rounded,
                  label: 'Window',
                  value: _window(event['windowSeconds']),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   value;
  const _MetaRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 14, color: AppColors.textSecondary),
      const SizedBox(width: 6),
      Text('$label: ',
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
      Text(value,
          style: const TextStyle(
              fontSize  : 13,
              fontWeight: FontWeight.w600,
              color     : AppColors.textPrimary)),
    ],
  );
}

class _PulsingDot extends StatefulWidget {
  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double>   _a;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _a = Tween<double>(begin: 0.4, end: 1.0).animate(_c);
  }

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _a,
    child  : Container(
      width    : 7, height: 7,
      decoration: const BoxDecoration(
          color: Colors.white, shape: BoxShape.circle),
    ),
  );
}