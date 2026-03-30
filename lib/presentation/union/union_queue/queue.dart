import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/models/shipment.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_shipment_queue.dart';
import 'shipment_detail_screen.dart';
import '../../../shared/theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// UNION QUEUE SCREEN — with Live/Unlive toggle
// ─────────────────────────────────────────────────────────────────────────────

class QueueScreen extends StatefulWidget {
  final String driverId;
  const QueueScreen({super.key, required this.driverId});

  @override
  State<QueueScreen> createState() => _QueueScreenState();
}

class _QueueScreenState extends State<QueueScreen> {
  late final ShipmentApiService _api;

  List<Shipment> _shipments        = [];
  bool           _loading          = true;
  bool           _refreshing       = false;
  String?        _error;
  int            _currentPage      = 1;
  int            _totalPages       = 1;
  Timer?         _autoRefreshTimer;

  // Live-status state
  bool    _isLive            = false;
  String? _activeEventId;
  bool    _toggling          = false;

  static const _refreshIntervalSeconds = 5;

  @override
  void initState() {
    super.initState();
    _api = ShipmentApiService(ApiClient());
    _loadQueue();
    _fetchLiveStatus();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    _autoRefreshTimer = Timer.periodic(
      const Duration(seconds: _refreshIntervalSeconds),
      (_) {
        _silentRefresh();
        _fetchLiveStatus();
      },
    );
  }

  Future<void> _loadQueue({int page = 1}) async {
    setState(() { _loading = page == 1; _error = null; });
    try {
      final result = await _api.fetchQueue(page: page, pageSize: 20);
      if (!mounted) return;
      setState(() {
        _shipments   = result.items;
        _currentPage = result.page;
        _totalPages  = result.totalPages;
        _loading     = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _silentRefresh() async {
    if (_refreshing) return;
    setState(() => _refreshing = true);
    try {
      final result = await _api.fetchQueue(page: _currentPage, pageSize: 20);
      if (!mounted) return;
      setState(() { _shipments = result.items; });
    } catch (_) {
      // silent
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  Future<void> _fetchLiveStatus() async {
    try {
      final data = await _api.getQueueLiveStatus();
      if (!mounted) return;
      setState(() {
        _isLive        = data['isLive'] as bool? ?? false;
        _activeEventId = data['eventId'] as String?;
      });
    } catch (_) {}
  }

  Future<void> _toggleLive() async {
    if (_toggling) return;
    if (_activeEventId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No queue event found. Create a queue event first.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Color(0xFFE02424),
        ),
      );
      return;
    }
    setState(() => _toggling = true);
    try {
      final result = await _api.toggleQueueEvent(_activeEventId!);
      if (!mounted) return;
      final newStatus = result['status'] as String?;
      setState(() => _isLive = newStatus == 'live');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isLive
              ? 'Queue is now LIVE — drivers can see shipments.'
              : 'Queue closed — hidden from drivers.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor:
              _isLive ? const Color(0xFF057A55) : const Color(0xFF374151),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Toggle failed: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFFE02424),
        ),
      );
    } finally {
      if (mounted) setState(() => _toggling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Shipment Queue'),
        actions: [
          _LiveToggleButton(
            isLive: _isLive,
            toggling: _toggling,
            hasEvent: _activeEventId != null,
            onToggle: _toggleLive,
          ),
          if (_refreshing)
            const Padding(
              padding: EdgeInsets.all(14),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.primary,
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () => _loadQueue(),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : _shipments.isEmpty
                  ? _buildEmpty()
                  : _buildList(),
    );
  }

  Widget _buildError() => Center(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.errorLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.wifi_off_rounded, size: 40, color: AppColors.error),
          ),
          const SizedBox(height: 16),
          const Text('Connection error', style: AppTextStyles.headingSm),
          const SizedBox(height: 6),
          Text(_error!, style: AppTextStyles.bodyMd, textAlign: TextAlign.center),
          const SizedBox(height: 24),
          SizedBox(
            width: 140,
            child: ElevatedButton(
              onPressed: () => _loadQueue(),
              child: const Text('Retry'),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildEmpty() => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.inbox_rounded, size: 48, color: AppColors.primary),
        ),
        const SizedBox(height: 16),
        const Text('Queue is empty', style: AppTextStyles.headingSm),
        const SizedBox(height: 6),
        const Text(
          'No shipments are available right now.\nAuto-refreshing every 5 seconds.',
          style: AppTextStyles.bodyMd,
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );

  Widget _buildList() {
    return RefreshIndicator(
      onRefresh: () => _loadQueue(),
      color: AppColors.primary,
      child: Column(
        children: [
          _QueueStatusBanner(
            isLive: _isLive,
            shipmentCount: _shipments.length,
            refreshSeconds: _refreshIntervalSeconds,
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: _shipments.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (ctx, i) => _QueueShipmentCard(
                shipment: _shipments[i],
                driverId: widget.driverId,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ShipmentDetailScreen(
                      shipment: _shipments[i],
                      driverId: widget.driverId,
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (_totalPages > 1)
            Container(
              color: AppColors.surface,
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded),
                    onPressed: _currentPage > 1
                        ? () => _loadQueue(page: _currentPage - 1)
                        : null,
                    color: AppColors.primary,
                  ),
                  Text(
                    'Page $_currentPage of $_totalPages',
                    style: AppTextStyles.labelMd,
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded),
                    onPressed: _currentPage < _totalPages
                        ? () => _loadQueue(page: _currentPage + 1)
                        : null,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Live Toggle Button ───────────────────────────────────────────────────────

class _LiveToggleButton extends StatelessWidget {
  final bool isLive;
  final bool toggling;
  final bool hasEvent;
  final VoidCallback onToggle;

  const _LiveToggleButton({
    required this.isLive,
    required this.toggling,
    required this.hasEvent,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: toggling
          ? const SizedBox(
              width: 72,
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          : GestureDetector(
              onTap: hasEvent ? onToggle : null,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isLive
                      ? const Color(0xFF057A55)
                      : const Color(0xFF6B7280),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isLive) _PulsingDot() else const _OfflineDot(),
                    const SizedBox(width: 6),
                    Text(
                      isLive ? 'LIVE' : 'OFFLINE',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _OfflineDot extends StatelessWidget {
  const _OfflineDot();
  @override
  Widget build(BuildContext context) => Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.5),
          shape: BoxShape.circle,
        ),
      );
}

class _PulsingDot extends StatefulWidget {
  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: _anim,
        child: Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
              color: Color(0xFF34D399), shape: BoxShape.circle),
        ),
      );
}

// ─── Status Banner ────────────────────────────────────────────────────────────

class _QueueStatusBanner extends StatelessWidget {
  final bool isLive;
  final int  shipmentCount;
  final int  refreshSeconds;

  const _QueueStatusBanner({
    required this.isLive,
    required this.shipmentCount,
    required this.refreshSeconds,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: isLive ? const Color(0xFFDEF7EC) : const Color(0xFFF3F4F6),
      child: Row(
        children: [
          Icon(
            isLive ? Icons.sensors_rounded : Icons.sensors_off_rounded,
            size: 15,
            color: isLive ? const Color(0xFF057A55) : const Color(0xFF9CA3AF),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isLive
                  ? 'Queue LIVE — $shipmentCount shipment${shipmentCount == 1 ? '' : 's'} visible to drivers'
                  : 'Queue OFFLINE — drivers cannot see shipments. Tap OFFLINE to go live.',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isLive
                    ? const Color(0xFF057A55)
                    : const Color(0xFF6B7280),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Queue Shipment Card ──────────────────────────────────────────────────────

class _QueueShipmentCard extends StatelessWidget {
  final Shipment shipment;
  final String driverId;
  final VoidCallback onTap;

  const _QueueShipmentCard({
    required this.shipment,
    required this.driverId,
    required this.onTap,
  });

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1)  return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24)   return '${diff.inHours}h ago';
    return '${dt.day}/${dt.month}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: shipment.isUrgent
              ? AppColors.error.withOpacity(0.4)
              : AppColors.border,
        ),
        boxShadow: AppShadows.card,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _StatusBadge(status: shipment.status),
                    if (shipment.isUrgent) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.errorLight,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.bolt_rounded,
                                size: 12, color: AppColors.error),
                            SizedBox(width: 2),
                            Text(
                              'URGENT',
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.error),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const Spacer(),
                    if (shipment.agreedPrice != null)
                      Text(
                        '₹${shipment.agreedPrice!.toStringAsFixed(0)}',
                        style: AppTextStyles.headingSm
                            .copyWith(color: AppColors.success),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: AppColors.success,
                            shape: BoxShape.circle,
                            border:
                                Border.all(color: AppColors.success, width: 2),
                          ),
                        ),
                        Container(width: 2, height: 20, color: AppColors.border),
                        const Icon(Icons.location_on_rounded,
                            size: 14, color: AppColors.error),
                      ],
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(shipment.pickupLocation,
                              style: AppTextStyles.labelLg,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 12),
                          Text(shipment.dropLocation,
                              style: AppTextStyles.labelLg,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Divider(height: 1),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.scale_rounded,
                        size: 13, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text('${shipment.cargoWeightKg.toStringAsFixed(0)} kg',
                        style: AppTextStyles.bodySm),
                    const SizedBox(width: 14),
                    const Icon(Icons.access_time_rounded,
                        size: 13, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(_timeAgo(shipment.createdAt),
                        style: AppTextStyles.bodySm),
                    const Spacer(),
                    const Text(
                      'View Details →',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  Color get _color => switch (status) {
        'waiting'    => AppColors.primary,
        'accepted'   => AppColors.warning,
        'in_transit' => const Color(0xFF7C3AED),
        'delivered'  => AppColors.success,
        'cancelled'  => AppColors.error,
        _            => AppColors.textSecondary,
      };

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: _color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: _color.withOpacity(0.3)),
        ),
        child: Text(
          status
              .replaceAll('_', ' ')
              .split(' ')
              .map((w) =>
                  w.isEmpty ? '' : w[0].toUpperCase() + w.substring(1))
              .join(' '),
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600, color: _color),
        ),
      );
}