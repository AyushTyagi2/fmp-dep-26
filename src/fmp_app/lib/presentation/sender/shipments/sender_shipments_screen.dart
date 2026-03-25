import 'package:flutter/material.dart';
import 'package:fmp_app/app_session.dart';
import 'package:fmp_app/core/network/api_client.dart';
import '../../../core/network/api_shipment.dart';
import '../../../shared/theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SENDER SHIPMENTS — Logic unchanged, premium UI applied
// ─────────────────────────────────────────────────────────────────────────────

class SenderShipmentsScreen extends StatefulWidget {
  const SenderShipmentsScreen({super.key});

  @override
  State<SenderShipmentsScreen> createState() => _SenderShipmentsScreenState();
}

class _SenderShipmentsScreenState extends State<SenderShipmentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ShipmentApi _api;
  late ApiClient _client;

  List<dynamic> sentShipments = [];
  List<dynamic> receivedShipments = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _client = ApiClient();
    _api = ShipmentApi(_client);
    _loadShipments();
  }

  Future<void> _loadShipments() async {
    if (sentShipments.isEmpty && receivedShipments.isEmpty) {
      setState(() => isLoading = true);
    }
    final phone = AppSession.phone;
    if (phone == null) {
      if (mounted) setState(() => isLoading = false);
      return;
    }
    try {
      final response = await _api.getShipmentsByPhone(phone);
      if (!mounted) return;
      setState(() {
        sentShipments = response['sent'] ?? [];
        receivedShipments = response['received'] ?? [];
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to refresh shipments.')),
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Shipments'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: isLoading ? null : _loadShipments,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.upload_rounded, size: 16),
                  const SizedBox(width: 6),
                  const Text('Sent'),
                  if (!isLoading && sentShipments.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    _CountBadge(count: sentShipments.length),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.download_rounded, size: 16),
                  const SizedBox(width: 6),
                  const Text('Received'),
                  if (!isLoading && receivedShipments.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    _CountBadge(count: receivedShipments.length),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadShipments,
              color: AppColors.primary,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _ShipmentList(shipments: sentShipments),
                  _ShipmentList(shipments: receivedShipments),
                ],
              ),
            ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  final int count;
  const _CountBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primary,
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
    );
  }
}

class _ShipmentList extends StatelessWidget {
  final List<dynamic> shipments;
  const _ShipmentList({required this.shipments});

  @override
  Widget build(BuildContext context) {
    if (shipments.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.xl),
        children: [
          const SizedBox(height: 60),
          Center(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Icon(
                    Icons.inventory_2_outlined,
                    size: 48,
                    color: AppColors.textHint,
                  ),
                ),
                const SizedBox(height: 16),
                const Text('No shipments found', style: AppTextStyles.headingSm),
                const SizedBox(height: 6),
                const Text(
                  'Pull down to refresh',
                  style: AppTextStyles.bodyMd,
                ),
              ],
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: shipments.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (ctx, i) => _ShipmentCard(shipment: shipments[i]),
    );
  }
}

class _ShipmentCard extends StatelessWidget {
  final dynamic shipment;
  const _ShipmentCard({required this.shipment});

  Color _statusColor(String status) => switch (status.toLowerCase()) {
    'pending' || 'pending_approval' => AppColors.warning,
    'approved' || 'assigned'        => AppColors.primary,
    'in_transit'                    => const Color(0xFF7C3AED),
    'delivered'                     => AppColors.success,
    'cancelled' || 'rejected'       => AppColors.error,
    _                               => AppColors.textSecondary,
  };

  String _statusLabel(String status) => status
      .replaceAll('_', ' ')
      .split(' ')
      .map((w) => w.isEmpty ? '' : w[0].toUpperCase() + w.substring(1))
      .join(' ');

  @override
  Widget build(BuildContext context) {
    final status = (shipment['status'] as String? ?? 'unknown').toLowerCase();
    final sc = _statusColor(status);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        shipment['shipmentNumber']?.toString() ?? '—',
                        style: AppTextStyles.headingSm,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: sc.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        border: Border.all(color: sc.withOpacity(0.3)),
                      ),
                      child: Text(
                        _statusLabel(status),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: sc,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.inventory_outlined,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      shipment['cargoType']?.toString() ?? '—',
                      style: AppTextStyles.bodySm,
                    ),
                    if (shipment['isUrgent'] == true) ...[
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.errorLight,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: const Text(
                          'URGENT',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: AppColors.error,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (shipment['agreedPrice'] != null) ...[
                  const SizedBox(height: 8),
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Agreed Price', style: AppTextStyles.bodyMd),
                      Text(
                        '₹${shipment['agreedPrice']}',
                        style: AppTextStyles.labelLg.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
