import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/models/shipment.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_shipment_queue.dart';
import 'widgets/shipment_card.dart';
import 'shipment_detail_screen.dart';

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

  static const _refreshIntervalSeconds = 5;

  @override
  void initState() {
    super.initState();
    _api = ShipmentApiService(ApiClient());
    _loadQueue();
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
      (_) => _silentRefresh(),
    );
  }

  Future<void> _loadQueue({int page = 1}) async {
    setState(() {
      _loading = page == 1;
      _error   = null;
    });

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
      setState(() {
        _error   = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _silentRefresh() async {
    if (_refreshing) return;
    setState(() => _refreshing = true);
    try {
      final result = await _api.fetchQueue(page: _currentPage, pageSize: 20);
      if (!mounted) return;
      setState(() {
        _shipments  = result.items;
        _totalPages = result.totalPages;
      });
    } catch (_) {
      // Silent fail on background refresh
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

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
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => _loadQueue(page: 1),
              tooltip: 'Refresh',
            ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: _buildPagination(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _loadQueue(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_shipments.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 12),
            Text('No shipments in queue',
                style: TextStyle(color: Colors.grey, fontSize: 16)),
            SizedBox(height: 4),
            Text('Check back soon',
                style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadQueue(page: 1),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _shipments.length,
        itemBuilder: (context, index) => ShipmentCard(
          shipment: _shipments[index],
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ShipmentDetailScreen(
                  shipment: _shipments[index],
                  driverId: widget.driverId,
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
              onPressed: _currentPage > 1
                  ? () => _loadQueue(page: _currentPage - 1)
                  : null,
              icon: const Icon(Icons.chevron_left),
              label: const Text('Previous'),
            ),
            Text(
              'Page $_currentPage of $_totalPages',
              style: const TextStyle(color: Colors.grey),
            ),
            TextButton.icon(
              onPressed: _currentPage < _totalPages
                  ? () => _loadQueue(page: _currentPage + 1)
                  : null,
              icon: const Icon(Icons.chevron_right),
              label: const Text('Next'),
            ),
          ],
        ),
      ),
    );
  }
}