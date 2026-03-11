import 'dart:async';
import 'package:flutter/material.dart';
import 'package:signalr_netcore/signalr_client.dart';
import '../../../core/models/shipment.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_shipment_queue.dart';
import '../../../app_session.dart';
import 'widgets/driver_current_offer_card.dart';
import 'widgets/driver_shipment_card.dart';
import 'driver_shipment_detail_screen.dart';

/// Driver Queue Screen — Parallel Offer Model
///
/// Layout:
///  ┌──────────────────────────────────────┐
///  │  ⏱ YOUR CURRENT OFFER  (pinned top) │  ← DriverCurrentOfferCard
///  │  [Accept]  [Pass]  countdown timer   │
///  └──────────────────────────────────────┘
///  Other shipments (read-only, greyed out):
///   ─────────────────────────────────────
///   SHP-002  Pune → Hyd  ₹2,800  🔒
///   SHP-003  Chennai → Blr ₹1,900  🔒
///
class DriverQueueScreen extends StatefulWidget {
  const DriverQueueScreen({super.key});

  @override
  State<DriverQueueScreen> createState() => _DriverQueueScreenState();
}

class _DriverQueueScreenState extends State<DriverQueueScreen> {
  late final ShipmentApiService _api;

  List<Shipment> _shipments   = [];
  bool           _loading     = true;
  bool           _refreshing  = false;
  String?        _error;
  int            _currentPage = 1;
  int            _totalPages  = 1;

  // Current offer / queue slot
  QueueSlot?    _slot;
  Timer?        _countdownTimer;
  Duration      _offerTimeRemaining = Duration.zero;
  bool          _offerActionBusy   = false;

  // SignalR
  HubConnection? _hub;

  @override
  void initState() {
    super.initState();
    _api = ShipmentApiService(ApiClient());
    _loadQueue();
    _loadQueueSlot();
    _connectSignalR();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _hub?.stop();
    super.dispose();
  }

  // ─── SignalR ──────────────────────────────────────────────────────────────

  Future<void> _connectSignalR() async {
    const baseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:5153');
    _hub = HubConnectionBuilder()
        .withUrl(
          '$baseUrl/hubs/shipment-queue',
          options: HttpConnectionOptions(
            accessTokenFactory: () async => AppSession.token ?? '',
          ),
        )
        .withAutomaticReconnect()
        .build();

    _hub!.on('NewShipmentAvailable', (args) {
      if (!mounted || args == null || args.isEmpty) return;
      try {
        final dto = Shipment.fromJson(args[0] as Map<String, dynamic>);
        setState(() {
          if (!_shipments.any((s) => s.id == dto.id)) {
            _shipments = [dto, ..._shipments];
          }
        });
      } catch (_) {}
    });

    _hub!.on('ShipmentAccepted', (args) {
      if (!mounted || args == null || args.isEmpty) return;
      final acceptedId = args[0]?.toString();
      if (acceptedId != null) {
        setState(() => _shipments.removeWhere((s) => s.id == acceptedId));
      }
    });

    // ← NEW: server signals that offers have been updated (pass/expire/new assignment)
    _hub!.on('OfferUpdated', (args) {
      if (!mounted) return;
      _loadQueueSlot(); // refresh the pinned offer card
    });

    try { await _hub!.start(); } catch (_) {}
  }

  // ─── Queue Slot / Offer Countdown ────────────────────────────────────────

  Future<void> _loadQueueSlot() async {
    final driverId = AppSession.driverId;
    if (driverId == null) return;
    final slot = await _api.getMyQueueSlot(driverId);
    if (!mounted) return;
    setState(() => _slot = slot);
    _startCountdown();
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    if (_slot?.hasActiveOffer != true) return;

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final remaining = _slot?.currentOffer?.timeRemaining ?? Duration.zero;
      setState(() => _offerTimeRemaining = remaining);
      if (remaining == Duration.zero) {
        _countdownTimer?.cancel();
        _loadQueueSlot(); // offer expired — reload to get next offer
      }
    });
  }

  // ─── Data Loading ─────────────────────────────────────────────────────────

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
      setState(() { _shipments = result.items; _totalPages = result.totalPages; });
    } catch (_) {} finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  // ─── Actions ─────────────────────────────────────────────────────────────

  Future<void> _onAcceptOffer() async {
    final offer    = _slot?.currentOffer;
    final driverId = AppSession.driverId;
    if (offer == null || driverId == null || _offerActionBusy) return;

    setState(() => _offerActionBusy = true);
    try {
      final result = await _api.acceptShipment(
        shipmentQueueId : offer.shipmentQueueId,
        driverId        : driverId,
      );
      if (!mounted) return;
      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Shipment accepted! Trip created.'), backgroundColor: Colors.green),
        );
        await _loadQueueSlot();
        await _loadQueue();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message ?? 'Accept failed'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _offerActionBusy = false);
    }
  }

  Future<void> _onPassOffer() async {
    final offer    = _slot?.currentOffer;
    final driverId = AppSession.driverId;
    if (offer == null || driverId == null || _offerActionBusy) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Pass this shipment?'),
        content: const Text('The shipment will be offered to the next driver in line.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Pass', style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _offerActionBusy = true);
    try {
      final result = await _api.passShipment(
        shipmentQueueId : offer.shipmentQueueId,
        driverId        : driverId,
      );
      if (!mounted) return;
      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Offer passed. Waiting for next shipment…')),
        );
        await _loadQueueSlot();
        await _loadQueue();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message ?? 'Pass failed'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _offerActionBusy = false);
    }
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Shipments'),
        backgroundColor: const Color(0xFF1B3A6B),
        foregroundColor: Colors.white,
        actions: [
          if (_refreshing)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(width: 18, height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
            )
          else
            IconButton(icon: const Icon(Icons.refresh), onPressed: () => _loadQueue(page: 1)),
        ],
      ),
      body: Column(
        children: [
          // ── Pinned offer card ─────────────────────────────────────────────
          if (_slot != null)
            DriverCurrentOfferCard(
              slot             : _slot!,
              timeRemaining    : _offerTimeRemaining,
              isBusy           : _offerActionBusy,
              onAccept         : _onAcceptOffer,
              onPass           : _onPassOffer,
            ),

          // ── Other shipments (read-only) ───────────────────────────────────
          Expanded(child: _buildBody()),
        ],
      ),
      bottomNavigationBar: _buildPagination(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: () => _loadQueue(), child: const Text('Retry')),
          ],
        ),
      );
    }

    // Filter out the currently-offered shipment from the list view —
    // it's already shown in the pinned card above.
    final offeredId = _slot?.currentOffer?.shipmentQueueId;
    final otherShipments = offeredId == null
        ? _shipments
        : _shipments.where((s) => s.id != offeredId).toList();

    if (otherShipments.isEmpty && _slot?.hasActiveOffer == true) {
      return const Center(
        child: Text('No other shipments in queue',
            style: TextStyle(color: Colors.grey, fontSize: 14)),
      );
    }

    if (otherShipments.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 12),
            Text('No shipments in queue', style: TextStyle(color: Colors.grey, fontSize: 16)),
            SizedBox(height: 4),
            Text('Check back soon', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      );
    }

    if (_slot?.hasActiveOffer == true) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text('Other shipments in queue',
                style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _loadQueue(page: 1),
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: otherShipments.length,
                itemBuilder: (context, index) => DriverShipmentCard(
                  shipment  : otherShipments[index],
                  isLocked  : true,    // ← greyed-out, no tap
                ),
              ),
            ),
          ),
        ],
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadQueue(page: 1),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: otherShipments.length,
        itemBuilder: (context, index) => DriverShipmentCard(
          shipment : otherShipments[index],
          onTap    : () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DriverShipmentDetailScreen(
                  shipment : otherShipments[index],
                  driverId : AppSession.driverId ?? '',
                ),
              ),
            );
            _silentRefresh();
          },
        ),
      ),
    );
  }

  Widget? _buildPagination() {
    if (_totalPages <= 1) return null;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton.icon(
              onPressed: _currentPage > 1 ? () => _loadQueue(page: _currentPage - 1) : null,
              icon: const Icon(Icons.chevron_left),
              label: const Text('Previous'),
            ),
            Text('Page $_currentPage of $_totalPages',
                style: const TextStyle(color: Colors.grey)),
            TextButton.icon(
              onPressed: _currentPage < _totalPages
                  ? () => _loadQueue(page: _currentPage + 1) : null,
              icon: const Icon(Icons.chevron_right),
              label: const Text('Next'),
            ),
          ],
        ),
      ),
    );
  }
}