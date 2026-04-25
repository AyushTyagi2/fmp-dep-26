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

  // ─── DEBUG TAG ─────────────────────────────────────────────────────────────
  static const _tag = '[QueueScreen]';

  @override
  void initState() {
    super.initState();
    debugPrint('$_tag initState called — driverId: ${widget.driverId}');
    _api = ShipmentApiService(ApiClient());
    _loadQueue();
    _fetchLiveStatus();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    debugPrint('$_tag dispose called — cancelling auto-refresh timer');
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    debugPrint('$_tag _startAutoRefresh — interval: ${_refreshIntervalSeconds}s');
    _autoRefreshTimer = Timer.periodic(
      const Duration(seconds: _refreshIntervalSeconds),
      (_) {
        debugPrint('$_tag [AutoRefresh] tick fired');
        _silentRefresh();
        _fetchLiveStatus();
      },
    );
  }

  Future<void> _loadQueue({int page = 1}) async {
    debugPrint('$_tag _loadQueue called — page: $page');
    setState(() { _loading = page == 1; _error = null; });
    try {
      final result = await _api.fetchQueue(page: page, pageSize: 20);
      debugPrint('$_tag _loadQueue SUCCESS — items: ${result.items.length}, '
          'page: ${result.page}/${result.totalPages}');
      if (!mounted) return;
      setState(() {
        _shipments   = result.items;
        _currentPage = result.page;
        _totalPages  = result.totalPages;
        _loading     = false;
      });
    } catch (e, st) {
      debugPrint('$_tag _loadQueue ERROR: $e\n$st');
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _silentRefresh() async {
    if (_refreshing) {
      debugPrint('$_tag _silentRefresh SKIPPED — already refreshing');
      return;
    }
    debugPrint('$_tag _silentRefresh START');
    setState(() => _refreshing = true);
    try {
      final result = await _api.fetchQueue(page: _currentPage, pageSize: 20);
      debugPrint('$_tag _silentRefresh SUCCESS — items: ${result.items.length}');
      if (!mounted) return;
      setState(() { _shipments = result.items; });
    } catch (e) {
      debugPrint('$_tag _silentRefresh ERROR (silent): $e');
    } finally {
      if (mounted) setState(() => _refreshing = false);
      debugPrint('$_tag _silentRefresh DONE');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // LIVE STATUS FETCH — most likely source of toggle bugs
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _fetchLiveStatus() async {
    debugPrint('$_tag _fetchLiveStatus called — '
        'current _isLive: $_isLive, _activeEventId: $_activeEventId, _toggling: $_toggling');
    try {
      final data = await _api.getQueueLiveStatus();

      // ── Raw response dump ─────────────────────────────────────────────────
      debugPrint('$_tag _fetchLiveStatus RAW response: $data');
      debugPrint('$_tag   Keys present   : ${data.keys.toList()}');
      debugPrint('$_tag   isLive raw     : ${data['isLive']}  (runtimeType: ${data['isLive']?.runtimeType})');
      debugPrint('$_tag   eventId raw    : ${data['eventId']}  (runtimeType: ${data['eventId']?.runtimeType})');

      if (!mounted) {
        debugPrint('$_tag _fetchLiveStatus — widget unmounted, aborting setState');
        return;
      }
      if (_toggling) {
        // ⚠️  This is a common bug source: a stale poll arriving mid-toggle
        // can snap the UI back to the wrong state before the API responds.
        debugPrint('$_tag _fetchLiveStatus — _toggling is TRUE, '
            'SKIPPING setState to avoid overwriting optimistic flip. '
            'Polled isLive=${data['isLive']}, current UI _isLive=$_isLive');
        return;
      }

      final polledIsLive  = data['isLive'] as bool? ?? false;
      final polledEventId = data['eventId'] as String?;

      // ── Detect unexpected state drift ─────────────────────────────────────
      if (polledIsLive != _isLive) {
        debugPrint('$_tag ⚠️  STATE DRIFT detected — '
            'UI _isLive=$_isLive but server says isLive=$polledIsLive. '
            'Correcting UI.');
      }
      if (polledEventId != _activeEventId) {
        debugPrint('$_tag ⚠️  EVENT ID CHANGED — '
            'was: $_activeEventId → now: $polledEventId');
      }
      if (polledEventId == null) {
        debugPrint('$_tag ⚠️  eventId is NULL — toggle button will be DISABLED. '
            'Check that the backend returns a valid eventId field.');
      }

      setState(() {
        _isLive        = polledIsLive;
        _activeEventId = polledEventId;
      });
      debugPrint('$_tag _fetchLiveStatus setState done — '
          '_isLive: $_isLive, _activeEventId: $_activeEventId');
    } catch (e, st) {
      debugPrint('$_tag _fetchLiveStatus ERROR: $e\n$st');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // TOGGLE — the main action handler
  //
  // Flow:
  //   No active event  → show _CreateQueueSheet to seed a new event
  //   Active event     → toggle live ↔ closed on the existing event
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _toggleLive() async {
    if (_toggling) return;

    // ── No event yet → open creation sheet ──────────────────────────────────
    if (_activeEventId == null) {
      final created = await showModalBottomSheet<bool>(
        context            : context,
        isScrollControlled : true,
        backgroundColor    : Colors.transparent,
        builder: (_) => _CreateQueueSheet(api: _api),
      );
      if (created == true) {
        await _fetchLiveStatus();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Queue created and is now LIVE'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Color(0xFF057A55),
          ),
        );
      }
      return;
    }

    // ── Toggle existing event ────────────────────────────────────────────────
    final previousState   = _isLive;
    final optimisticState = !_isLive;
    setState(() { _toggling = true; _isLive = optimisticState; });

    try {
      final result        = await _api.toggleQueueEvent(_activeEventId!);
      if (!mounted) return;
      final newStatus     = result['status'] as String?;
      final confirmedLive = newStatus == 'live';
      setState(() => _isLive = confirmedLive);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(confirmedLive
              ? 'Queue is now LIVE — drivers can see shipments.'
              : 'Queue closed — hidden from drivers.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor:
              confirmedLive ? const Color(0xFF057A55) : const Color(0xFF374151),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLive = previousState);
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

// ─── Drop-in replacement for _LiveToggleButton ───────────────────────────────
// Paste this class over your existing one temporarily.
// It adds a raw pointer listener OUTSIDE the GestureDetector to catch
// whether touches are even reaching the widget at all.
// ─────────────────────────────────────────────────────────────────────────────

class _LiveToggleButton extends StatefulWidget {
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
  State<_LiveToggleButton> createState() => _LiveToggleButtonState();
}

class _LiveToggleButtonState extends State<_LiveToggleButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _slideAnim;

  late bool _isLive;

  static const _tag     = '[LiveToggleButton]';
  static const _offColor = Color(0xFF374151);
  static const _onColor  = Color(0xFF057A55);
  static const double _trackW   = 100;
  static const double _thumbD   = 26;
  static const double _pad      = 4;
  static const double _thumbOn  = _trackW - _thumbD - (_pad*2); // 73
  static const double _thumbOff = _pad;                      // 3

  @override
  void initState() {
    super.initState();
    _isLive = widget.isLive;
    debugPrint('$_tag initState — isLive=$_isLive hasEvent=${widget.hasEvent} '
        'toggling=${widget.toggling}');
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
      value: _isLive ? 1.0 : 0.0,
    );
    _slideAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void didUpdateWidget(_LiveToggleButton old) {
    super.didUpdateWidget(old);
    if (old.isLive != widget.isLive ||
        old.toggling != widget.toggling ||
        old.hasEvent != widget.hasEvent) {
      debugPrint('$_tag didUpdateWidget — '
          'isLive: ${old.isLive}→${widget.isLive}  '
          'toggling: ${old.toggling}→${widget.toggling}  '
          'hasEvent: ${old.hasEvent}→${widget.hasEvent}');
    }
    if (old.isLive != widget.isLive) {
      _isLive = widget.isLive;
      _isLive ? _ctrl.forward() : _ctrl.reverse();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  // ─── STEP 1: does ANY pointer land on this widget? ───────────────────────
  void _onPointerDown(PointerDownEvent e) {
    debugPrint('$_tag ✅ POINTER DOWN at ${e.localPosition} — '
        'this confirms the widget IS receiving raw touch events');
  }

  void _onPointerUp(PointerUpEvent e) {
    debugPrint('$_tag ✅ POINTER UP at ${e.localPosition}');
  }

  // ─── STEP 2: does the GestureDetector fire? ──────────────────────────────
  void _onTapDown(TapDownDetails d) {
    debugPrint('$_tag ✅ TAP DOWN — GestureDetector recognised a tap start '
        'at ${d.localPosition}');
  }

  void _onTap() {
    if (widget.toggling) return;
    widget.onToggle();
  }

  void _onTapCancel() {
    debugPrint('$_tag ⚠️  TAP CANCELLED — pointer moved out or another '
        'gesture won the arena. This is the #1 reason taps silently vanish '
        'inside AppBar action widgets.');
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('$_tag build — isLive=${widget.isLive} '
        'hasEvent=${widget.hasEvent} toggling=${widget.toggling} '
        'ctrl=${_ctrl.value.toStringAsFixed(2)}');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      child: Listener(
        // Raw pointer listener — fires even if GestureDetector is blocked
        onPointerDown: _onPointerDown,
        onPointerUp:   _onPointerUp,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque, // ← crucial: fills the whole box
          onTapDown:   _onTapDown,
          onTap:       _onTap,
          onTapCancel: _onTapCancel,
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) {
              final t         = _slideAnim.value;
              final thumbLeft = _thumbOff + (_thumbOn - _thumbOff) * t;
              final bg        = Color.lerp(_offColor, _onColor, t)!;

              return Container(
                width: _trackW,
                height: 30,
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Stack(
                  children: [
                    // LIVE label
                    Positioned(
                      left: 10, top: 0, bottom: 0,
                      child: Opacity(
                        opacity: t,
                        child: const Align(
                          alignment: Alignment.centerRight,
                          child: Text('LIVE',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                              )),
                        ),
                      ),
                    ),
                    // OFF label
                    Positioned(
                      right: 10, top: 0, bottom: 0,
                      child: Opacity(
                        opacity: 1 - t,
                        child: const Align(
                          alignment: Alignment.centerLeft,
                          child: Text('OFF',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                              )),
                        ),
                      ),
                    ),
                    // Thumb
                    Positioned(
                      left: thumbLeft,
                      top: _pad,
                      bottom: _pad,
                      child: Container(
                        width: _thumbD,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Center(
                          child: widget.toggling
                              ? const SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFF374151),
                                  ),
                                )
                              : _isLive
                                  ? _PulsingDot()
                                  : Container(
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF9CA3AF),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
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
// ─────────────────────────────────────────────────────────────────────────────
// CREATE QUEUE SHEET
// Bottom sheet that collects duration + window size, then seeds a new
// queue event via POST /api/queue-events.
// ─────────────────────────────────────────────────────────────────────────────

class _CreateQueueSheet extends StatefulWidget {
  final ShipmentApiService api;
  const _CreateQueueSheet({required this.api});

  @override
  State<_CreateQueueSheet> createState() => _CreateQueueSheetState();
}

class _CreateQueueSheetState extends State<_CreateQueueSheet>
    with SingleTickerProviderStateMixin {

  final _formKey = GlobalKey<FormState>();

  // ── controllers ─────────────────────────────────────────────────────────
  final _durationCtrl = TextEditingController(text: '2');
  final _windowCtrl   = TextEditingController(text: '5');

  // ── form state ──────────────────────────────────────────────────────────
  String  _durationUnit = 'hours';   // 'minutes' | 'hours'
  bool    _submitting   = false;
  String? _error;

  // ── enter animation ─────────────────────────────────────────────────────
  late AnimationController _ctrl;
  late Animation<double>   _fade;
  late Animation<Offset>   _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 340));
    _fade  = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _durationCtrl.dispose();
    _windowCtrl.dispose();
    super.dispose();
  }

  // ── computed values for the preview card ─────────────────────────────────
  double get _durationHours {
    final v = double.tryParse(_durationCtrl.text) ?? 0;
    return _durationUnit == 'hours' ? v : v / 60;
  }

  int get _windowMinutes => int.tryParse(_windowCtrl.text) ?? 0;

  String _fmtDuration() {
    final h = _durationHours;
    if (h <= 0) return '—';
    if (h < 1)  return '${(h * 60).round()} min';
    final hrs  = h.floor();
    final mins = ((h - hrs) * 60).round();
    if (mins == 0) return '$hrs hr${hrs > 1 ? 's' : ''}';
    return '$hrs hr $mins min';
  }

  String _fmtEndTime() {
    final h = _durationHours;
    if (h <= 0) return '—';
    final end = DateTime.now().add(Duration(minutes: (h * 60).round()));
    final hh  = end.hour.toString().padLeft(2, '0');
    final mm  = end.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  // ── submit ───────────────────────────────────────────────────────────────
  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_submitting) return;
    setState(() { _submitting = true; _error = null; });
    try {
      await widget.api.createQueueEvent(
        durationHours : _durationHours,
        windowSeconds : _windowMinutes * 60,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  // ── field decoration ─────────────────────────────────────────────────────
  InputDecoration _fieldDecoration({
    required String label,
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) =>
      InputDecoration(
        labelText     : label,
        hintText      : hint,
        prefixIcon    : Icon(icon, size: 18, color: AppColors.textSecondary),
        suffixIcon    : suffix,
        filled        : true,
        fillColor     : AppColors.background,
        labelStyle    : AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary),
        hintStyle     : AppTextStyles.bodySm.copyWith(color: AppColors.textHint),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide  : const BorderSide(color: AppColors.border, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide  : const BorderSide(color: AppColors.border, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide  : const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide  : const BorderSide(color: AppColors.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide  : const BorderSide(color: AppColors.error, width: 2),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).viewInsets.bottom;

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          decoration: BoxDecoration(
            color        : AppColors.surface,
            borderRadius : BorderRadius.circular(AppRadius.xl),
            boxShadow    : [
              BoxShadow(
                color     : Colors.black.withOpacity(0.18),
                blurRadius: 32,
                offset    : const Offset(0, -4),
              ),
            ],
          ),
          padding: EdgeInsets.fromLTRB(24, 8, 24, 24 + bottomPad),
          child: Form(
            key: _formKey,
            onChanged: () => setState(() {}), // rebuild preview on every keystroke
            child: Column(
              mainAxisSize     : MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ── drag handle ─────────────────────────────────────────
                Center(
                  child: Container(
                    margin     : const EdgeInsets.only(bottom: 20),
                    width      : 36,
                    height     : 4,
                    decoration : BoxDecoration(
                      color        : AppColors.border,
                      borderRadius : BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
                ),

                // ── header ──────────────────────────────────────────────
                Row(
                  children: [
                    Container(
                      width      : 40,
                      height     : 40,
                      decoration : BoxDecoration(
                        color        : AppColors.primaryLight,
                        borderRadius : BorderRadius.circular(AppRadius.md),
                      ),
                      child: const Icon(
                        Icons.broadcast_on_personal_rounded,
                        color: AppColors.primary,
                        size : 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Start Queue Session',
                            style: AppTextStyles.headingSm),
                        Text('Configure and go live',
                            style: AppTextStyles.bodySm
                                .copyWith(color: AppColors.textSecondary)),
                      ],
                    ),
                    const Spacer(),
                    IconButton(
                      icon    : const Icon(Icons.close_rounded, size: 20),
                      color   : AppColors.textSecondary,
                      onPressed: () => Navigator.of(context).pop(false),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ── live preview card ────────────────────────────────────
                AnimatedContainer(
                  duration   : const Duration(milliseconds: 200),
                  padding    : const EdgeInsets.all(14),
                  decoration : BoxDecoration(
                    color        : AppColors.primaryLight,
                    borderRadius : BorderRadius.circular(AppRadius.lg),
                    border       : Border.all(
                        color: AppColors.primary.withOpacity(0.15)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded,
                          size: 16, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Queue will run for ${_fmtDuration()}, ending ~${_fmtEndTime()}. '
                          'Each driver gets a ${_windowMinutes > 0 ? '$_windowMinutes-min' : '—'} window per shipment.',
                          style: AppTextStyles.bodySm.copyWith(
                              color : AppColors.primary,
                              height: 1.5),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ── Queue Duration field ─────────────────────────────────
                Text('Queue Duration',
                    style: AppTextStyles.labelMd
                        .copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // numeric input
                    Expanded(
                      child: TextFormField(
                        controller  : _durationCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style       : AppTextStyles.bodyMd,
                        decoration  : _fieldDecoration(
                          label: 'Amount',
                          hint : 'e.g. 2',
                          icon : Icons.timer_outlined,
                        ),
                        validator: (v) {
                          final n = double.tryParse(v ?? '');
                          if (n == null || n <= 0) return 'Enter a number';
                          final hrs = _durationUnit == 'hours' ? n : n / 60;
                          if (hrs > 24) return 'Max 24 hrs';
                          if (hrs < 0.083) return 'Min 5 min';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    // unit dropdown
                    SizedBox(
                      width: 110,
                      child: DropdownButtonFormField<String>(
                        value      : _durationUnit,
                        style      : AppTextStyles.bodyMd,
                        decoration : _fieldDecoration(
                          label: 'Unit',
                          hint : '',
                          icon : Icons.access_time_rounded,
                        ),
                        items: const [
                          DropdownMenuItem(value: 'minutes', child: Text('Minutes')),
                          DropdownMenuItem(value: 'hours',   child: Text('Hours')),
                        ],
                        onChanged: (v) =>
                            setState(() => _durationUnit = v ?? 'hours'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Driver Window field ──────────────────────────────────
                Text('Driver Window',
                    style: AppTextStyles.labelMd
                        .copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                TextFormField(
                  controller  : _windowCtrl,
                  keyboardType: TextInputType.number,
                  style       : AppTextStyles.bodyMd,
                  decoration  : _fieldDecoration(
                    label : 'Minutes per shipment',
                    hint  : 'e.g. 5',
                    icon  : Icons.hourglass_bottom_rounded,
                    suffix: Padding(
                      padding: const EdgeInsets.only(right: 14),
                      child: Align(
                        widthFactor: 1,
                        child: Text('min',
                            style: AppTextStyles.labelMd
                                .copyWith(color: AppColors.textSecondary)),
                      ),
                    ),
                  ),
                  validator: (v) {
                    final n = int.tryParse(v ?? '');
                    if (n == null || n <= 0) return 'Enter a whole number';
                    if (n > 60) return 'Max 60 min';
                    return null;
                  },
                ),
                const SizedBox(height: 28),

                // ── error banner ─────────────────────────────────────────
                if (_error != null) ...[
                  Container(
                    padding   : const EdgeInsets.all(12),
                    margin    : const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color        : AppColors.errorLight,
                      borderRadius : BorderRadius.circular(AppRadius.md),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded,
                            size: 16, color: AppColors.error),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(_error!,
                              style: AppTextStyles.bodySm
                                  .copyWith(color: AppColors.error)),
                        ),
                      ],
                    ),
                  ),
                ],

                // ── submit ───────────────────────────────────────────────
                SizedBox(
                  width : double.infinity,
                  height: 52,
                  child : ElevatedButton(
                    onPressed: _submitting ? null : _submit,
                    style    : ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textOnPrimary,
                      shape          : RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                      ),
                      elevation: 0,
                    ),
                    child: _submitting
                        ? const SizedBox(
                            width : 20,
                            height: 20,
                            child : CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color      : Colors.white,
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.sensors_rounded, size: 18),
                              SizedBox(width: 8),
                              Text('Go Live',
                                  style: TextStyle(
                                      fontSize    : 15,
                                      fontWeight  : FontWeight.w600,
                                      letterSpacing: 0.2)),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}