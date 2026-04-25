import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/network/api_shipment_queue.dart';
import '../../../shared/theme/app_theme.dart';

class QueueEventDetailScreen extends StatefulWidget {
  final Map<String, dynamic> event;
  final ShipmentApiService   api;

  const QueueEventDetailScreen({
    super.key,
    required this.event,
    required this.api,
  });

  @override
  State<QueueEventDetailScreen> createState() => _QueueEventDetailScreenState();
}

class _QueueEventDetailScreenState extends State<QueueEventDetailScreen> {
  late Map<String, dynamic> _event;
  bool     _toggling  = false;
  Timer?   _countdown;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _event = Map<String, dynamic>.from(widget.event);
    _startCountdown();
  }

  @override
  void dispose() {
    _countdown?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _updateRemaining();
    _countdown = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      _updateRemaining();
    });
  }

  void _updateRemaining() {
    final end  = _parseUtc(_event['endTime'] as String? ?? '');
    if (end == null) { setState(() => _remaining = Duration.zero); return; }
    final diff = end.difference(DateTime.now());
    setState(() => _remaining = diff.isNegative ? Duration.zero : diff);
  }

  bool get _isLive {
    final status = _event['status'] as String? ?? '';
    return status == 'live' && _remaining > Duration.zero;
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

  String _fmtCountdown(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '${h}h ${m}m ${s}s' : '${m}m ${s}s';
  }

  String _window(dynamic secs) {
    final s = (secs as num?)?.toInt() ?? 0;
    if (s == 0) return '—';
    return s < 60 ? '${s}s' : '${s ~/ 60} min';
  }

  Future<void> _toggle() async {
    if (_toggling) return;
    final eventId = _event['id'] as String?;
    if (eventId == null) return;

    setState(() => _toggling = true);
    try {
      final result = await widget.api.toggleQueueEvent(eventId);
      if (!mounted) return;
      setState(() {
        _event['status']  = result['status'];
        _event['endTime'] = result['endTime']?.toString() ?? _event['endTime'];
      });
      _updateRemaining();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content        : Text(_isLive ? 'Queue is now LIVE' : 'Queue closed'),
          behavior       : SnackBarBehavior.floating,
          backgroundColor: _isLive
              ? const Color(0xFF057A55)
              : const Color(0xFF374151),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content        : Text('Failed: $e'),
          behavior       : SnackBarBehavior.floating,
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _toggling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final live = _isLive;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Event Detail'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding   : const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color       : live ? const Color(0xFF057A55) : AppColors.border,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  live ? 'LIVE' : 'CLOSED',
                  style: TextStyle(
                    color       : live ? Colors.white : AppColors.textSecondary,
                    fontSize    : 11,
                    fontWeight  : FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child  : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            _CountdownBanner(
              isLive   : live,
              remaining: _remaining,
              fmtFn    : _fmtCountdown,
            ),
            const SizedBox(height: 16),

            const _SectionHeader('Event Details'),
            const SizedBox(height: 12),
            _StatsGrid(children: [
              _StatTile(
                icon : Icons.play_circle_outline_rounded,
                label: 'Started',
                value: _fmt(_event['startTime'] as String?),
              ),
              _StatTile(
                icon : Icons.stop_circle_outlined,
                label: 'Ends',
                value: _fmt(_event['endTime'] as String?),
              ),
              _StatTile(
                icon : Icons.hourglass_bottom_rounded,
                label: 'Driver Window',
                value: _window(_event['windowSeconds']),
              ),
              _StatTile(
                icon : Icons.fingerprint_rounded,
                label: 'Event ID',
                value: ((_event['id'] as String?) ?? '—').length > 8
                    ? ((_event['id'] as String?)!.substring(0, 8) + '…')
                    : ((_event['id'] as String?) ?? '—'),
              ),
            ]),
            const SizedBox(height: 24),

            const _SectionHeader('Queue Control'),
            const SizedBox(height: 12),
            _ToggleCard(
              isLive  : live,
              toggling: _toggling,
              onToggle: _toggle,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ─── Countdown Banner ─────────────────────────────────────────────────────────

class _CountdownBanner extends StatelessWidget {
  final bool     isLive;
  final Duration remaining;
  final String Function(Duration) fmtFn;

  const _CountdownBanner({
    required this.isLive,
    required this.remaining,
    required this.fmtFn,
  });

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration   : const Duration(milliseconds: 300),
    width      : double.infinity,
    padding    : const EdgeInsets.all(20),
    decoration : BoxDecoration(
      color       : isLive
          ? const Color(0xFFDEF7EC)
          : AppColors.border.withOpacity(0.3),
      borderRadius: BorderRadius.circular(AppRadius.lg),
      border      : Border.all(
        color: isLive
            ? const Color(0xFF057A55).withOpacity(0.3)
            : AppColors.border,
      ),
    ),
    child: Column(
      children: [
        Icon(
          isLive ? Icons.sensors_rounded : Icons.sensors_off_rounded,
          size : 32,
          color: isLive ? const Color(0xFF057A55) : AppColors.textSecondary,
        ),
        const SizedBox(height: 8),
        Text(
          isLive ? fmtFn(remaining) : 'Ended',
          style: TextStyle(
            fontSize    : 28,
            fontWeight  : FontWeight.w800,
            color       : isLive
                ? const Color(0xFF057A55)
                : AppColors.textSecondary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          isLive ? 'remaining' : 'This event has ended',
          style: TextStyle(
            fontSize: 13,
            color   : isLive
                ? const Color(0xFF057A55).withOpacity(0.7)
                : AppColors.textSecondary,
          ),
        ),
      ],
    ),
  );
}

// ─── Toggle Card ──────────────────────────────────────────────────────────────

class _ToggleCard extends StatelessWidget {
  final bool         isLive;
  final bool         toggling;
  final VoidCallback onToggle;

  const _ToggleCard({
    required this.isLive,
    required this.toggling,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding   : const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color       : AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      border      : Border.all(color: AppColors.border),
      boxShadow   : AppShadows.card,
    ),
    child: Row(
      children: [
        Container(
          width     : 44,
          height    : 44,
          decoration: BoxDecoration(
            color       : isLive
                ? const Color(0xFFDEF7EC)
                : AppColors.errorLight,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Icon(
            isLive ? Icons.pause_rounded : Icons.play_arrow_rounded,
            color: isLive ? const Color(0xFF057A55) : AppColors.error,
            size : 24,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isLive ? 'Queue is Live' : 'Queue is Closed',
                style: const TextStyle(
                  fontSize  : 14,
                  fontWeight: FontWeight.w600,
                  color     : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                isLive
                    ? 'Tap to close — drivers will stop seeing shipments.'
                    : 'Tap to go live — drivers will see shipments.',
                style: const TextStyle(
                  fontSize: 12,
                  color   : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          height: 40,
          child : toggling
              ? const SizedBox(
                  width : 24, height: 24,
                  child : CircularProgressIndicator(strokeWidth: 2.5),
                )
              : ElevatedButton(
                  onPressed: onToggle,
                  style    : ElevatedButton.styleFrom(
                    backgroundColor: isLive
                        ? const Color(0xFF374151)
                        : const Color(0xFF057A55),
                    foregroundColor: Colors.white,
                    elevation      : 0,
                    padding        : const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 0),
                    shape          : RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                  child: Text(isLive ? 'Close' : 'Go Live'),
                ),
        ),
      ],
    ),
  );
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontSize  : 16,
      fontWeight: FontWeight.w700,
      color     : AppColors.textPrimary,
    ),
  );
}

class _StatsGrid extends StatelessWidget {
  final List<Widget> children;
  const _StatsGrid({required this.children});

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i += 2) {
      final hasSecond = i + 1 < children.length;
      rows.add(
        Row(
          children: [
            Expanded(child: children[i]),
            const SizedBox(width: 10),
            Expanded(child: hasSecond ? children[i + 1] : const SizedBox()),
          ],
        ),
      );
      if (i + 2 < children.length) rows.add(const SizedBox(height: 10));
    }
    return Column(mainAxisSize: MainAxisSize.min, children: rows);
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   value;

  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding   : const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color       : AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.md),
      border      : Border.all(color: AppColors.border),
    ),
    child: Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize      : MainAxisSize.min,
            children          : [
              Text(label,
                  style   : const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text(value,
                  style   : const TextStyle(
                      fontSize  : 13,
                      fontWeight: FontWeight.w700,
                      color     : AppColors.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    ),
  );
}