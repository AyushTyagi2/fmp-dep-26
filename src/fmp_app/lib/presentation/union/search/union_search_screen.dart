import 'package:flutter/material.dart';
import 'package:fmp_app/core/network/api_client.dart';
import 'package:fmp_app/core/network/api_search.dart';
import '../../../shared/theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// UNION SEARCH SCREEN
// Searches queue/shipments via backend endpoint.
// Filters: status + cargo type + urgent toggle.
// ─────────────────────────────────────────────────────────────────────────────

class UnionSearchScreen extends StatefulWidget {
  const UnionSearchScreen({super.key});

  @override
  State<UnionSearchScreen> createState() => _UnionSearchScreenState();
}

class _UnionSearchScreenState extends State<UnionSearchScreen> {
  final _searchCtrl = TextEditingController();
  final _searchApi   = SearchApi(ApiClient());

  List<dynamic> _results = [];
  bool _loading          = false;
  String? _error;
  bool _searched         = false;

  String? _selectedStatus;
  String? _selectedCargoType;
  bool?   _urgentOnly;

  static const _statuses = [
    'pending', 'pending_approval', 'approved', 'in_transit', 'delivered', 'cancelled',
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _doSearch() async {
    setState(() { _loading = true; _error = null; _searched = true; });
    try {
      final raw = await _searchApi.searchQueueShipments(
        q: _searchCtrl.text.trim(),
        status: _selectedStatus,
        cargoType: _selectedCargoType,
        urgent: _urgentOnly == true ? true : null,
      );
      setState(() { _results = raw; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  void _clearFilters() {
    setState(() { _selectedStatus = null; _selectedCargoType = null; _urgentOnly = null; });
    if (_searched) _doSearch();
  }

  bool get _hasActiveFilter =>
      _selectedStatus != null || _selectedCargoType != null || _urgentOnly == true;

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _UnionFilterSheet(
        selectedStatus: _selectedStatus,
        selectedCargoType: _selectedCargoType,
        urgentOnly: _urgentOnly ?? false,
        onApply: (status, cargo, urgent) {
          setState(() {
            _selectedStatus = status;
            _selectedCargoType = cargo;
            _urgentOnly = urgent ? true : null;
          });
          if (_searched) _doSearch();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: AppColors.surface,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Search Queue',
                    style: TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchCtrl,
                          textInputAction: TextInputAction.search,
                          onSubmitted: (_) => _doSearch(),
                          decoration: InputDecoration(
                            hintText: 'Shipment #, cargo type…',
                            prefixIcon: const Icon(Icons.search_rounded, size: 20),
                            suffixIcon: _searchCtrl.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded, size: 18),
                                    onPressed: () {
                                      _searchCtrl.clear();
                                      setState(() {});
                                    },
                                  )
                                : null,
                            contentPadding: const EdgeInsets.symmetric(vertical: 10),
                            isDense: true,
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _FilterButton(hasFilter: _hasActiveFilter, onTap: _showFilterSheet),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _doSearch,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(0, 46),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                        ),
                        child: const Text('Go'),
                      ),
                    ],
                  ),
                  if (_hasActiveFilter) ...[
                    const SizedBox(height: 8),
                    _ActiveFilterRow(
                      status: _selectedStatus,
                      cargoType: _selectedCargoType,
                      urgentOnly: _urgentOnly == true,
                      onClear: _clearFilters,
                    ),
                  ],
                ],
              ),
            ),
            const Divider(height: 1),

            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : _error != null
                      ? _ErrorState(message: _error!, onRetry: _doSearch)
                      : !_searched
                          ? const _SearchPrompt(
                              icon: Icons.inbox_outlined,
                              message: 'Search the queue',
                              hint: 'Enter a shipment number or cargo type\nto find shipments in the queue.',
                            )
                          : _results.isEmpty
                              ? const _EmptyState()
                              : ListView.separated(
                                  padding: const EdgeInsets.all(16),
                                  itemCount: _results.length,
                                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                                  itemBuilder: (_, i) => _QueueShipmentCard(shipment: _results[i]),
                                ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Filter Sheet ─────────────────────────────────────────────────────────────

class _UnionFilterSheet extends StatefulWidget {
  final String? selectedStatus;
  final String? selectedCargoType;
  final bool urgentOnly;
  final void Function(String? status, String? cargo, bool urgent) onApply;

  const _UnionFilterSheet({
    required this.selectedStatus,
    required this.selectedCargoType,
    required this.urgentOnly,
    required this.onApply,
  });

  @override
  State<_UnionFilterSheet> createState() => _UnionFilterSheetState();
}

class _UnionFilterSheetState extends State<_UnionFilterSheet> {
  String? _status;
  String? _cargo;
  bool _urgent = false;

  static const _statuses = [
    'pending', 'pending_approval', 'approved', 'in_transit', 'delivered', 'cancelled',
  ];
  static const _cargoTypes = [
    'Electronics', 'Furniture', 'Food', 'Apparel', 'Documents', 'Machinery',
  ];

  @override
  void initState() {
    super.initState();
    _status = widget.selectedStatus;
    _cargo  = widget.selectedCargoType;
    _urgent = widget.urgentOnly;
  }

  String _label(String s) => s.replaceAll('_', ' ')
      .split(' ').map((w) => w.isEmpty ? '' : w[0].toUpperCase() + w.substring(1)).join(' ');

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).viewInsets.bottom + 32),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4,
              decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            const Text('Filter Queue', style: AppTextStyles.headingMd),
            const SizedBox(height: 20),

            const Text('Status', style: AppTextStyles.labelLg),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: _statuses.map((s) {
                final active = _status == s;
                return FilterChip(
                  label: Text(_label(s)),
                  selected: active,
                  onSelected: (_) => setState(() => _status = active ? null : s),
                  selectedColor: AppColors.primaryLight,
                  checkmarkColor: AppColors.primary,
                  labelStyle: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600,
                    color: active ? AppColors.primary : AppColors.textSecondary,
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 20),
            const Text('Cargo Type', style: AppTextStyles.labelLg),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: _cargoTypes.map((c) {
                final active = _cargo == c;
                return FilterChip(
                  label: Text(c),
                  selected: active,
                  onSelected: (_) => setState(() => _cargo = active ? null : c),
                  selectedColor: AppColors.primaryLight,
                  checkmarkColor: AppColors.primary,
                  labelStyle: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600,
                    color: active ? AppColors.primary : AppColors.textSecondary,
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Urgent Only', style: AppTextStyles.labelLg),
                Switch(
                  value: _urgent,
                  onChanged: (v) => setState(() => _urgent = v),
                  activeColor: AppColors.primary,
                ),
              ],
            ),

            const SizedBox(height: 24),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () { widget.onApply(null, null, false); Navigator.pop(context); },
                  style: OutlinedButton.styleFrom(minimumSize: const Size(0, 46)),
                  child: const Text('Reset'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () { widget.onApply(_status, _cargo, _urgent); Navigator.pop(context); },
                  style: ElevatedButton.styleFrom(minimumSize: const Size(0, 46)),
                  child: const Text('Apply Filters'),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

// ── Queue Shipment Card ───────────────────────────────────────────────────────

class _QueueShipmentCard extends StatelessWidget {
  final dynamic shipment;
  const _QueueShipmentCard({required this.shipment});

  Color _statusColor(String s) => switch (s.toLowerCase()) {
    'pending' || 'pending_approval' => AppColors.warning,
    'approved' || 'assigned'        => AppColors.primary,
    'in_transit'                    => const Color(0xFF7C3AED),
    'delivered'                     => AppColors.success,
    'cancelled' || 'rejected'       => AppColors.error,
    _                               => AppColors.textSecondary,
  };

  String _statusLabel(String s) => s.replaceAll('_', ' ')
      .split(' ').map((w) => w.isEmpty ? '' : w[0].toUpperCase() + w.substring(1)).join(' ');

  @override
  Widget build(BuildContext context) {
    final status = (shipment['status'] as String? ?? 'unknown').toLowerCase();
    final sc = _statusColor(status);
    final isUrgent = shipment['isUrgent'] == true;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: sc.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(Icons.inbox_rounded, color: sc, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(shipment['shipmentNumber']?.toString() ?? '—', style: AppTextStyles.headingSm),
              Text(shipment['cargoType']?.toString() ?? '—', style: AppTextStyles.bodySm),
            ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: sc.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(color: sc.withOpacity(0.3)),
              ),
              child: Text(_statusLabel(status),
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: sc)),
            ),
            if (isUrgent) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.errorLight, borderRadius: BorderRadius.circular(AppRadius.pill)),
                child: const Text('URGENT',
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppColors.error)),
              ),
            ],
          ]),
        ],
      ),
    );
  }
}

// ── Shared helpers ────────────────────────────────────────────────────────────

class _FilterButton extends StatelessWidget {
  final bool hasFilter; final VoidCallback onTap;
  const _FilterButton({required this.hasFilter, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 46, width: 46,
        decoration: BoxDecoration(
          color: hasFilter ? AppColors.primaryLight : AppColors.background,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: hasFilter ? AppColors.primary : AppColors.border),
        ),
        child: Stack(alignment: Alignment.center, children: [
          Icon(Icons.tune_rounded, size: 20,
            color: hasFilter ? AppColors.primary : AppColors.textSecondary),
          if (hasFilter)
            Positioned(top: 8, right: 8,
              child: Container(width: 8, height: 8,
                decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle))),
        ]),
      ),
    );
  }
}

class _ActiveFilterRow extends StatelessWidget {
  final String? status; final String? cargoType; final bool urgentOnly; final VoidCallback onClear;
  const _ActiveFilterRow({this.status, this.cargoType, required this.urgentOnly, required this.onClear});

  String _label(String s) => s.replaceAll('_', ' ')
      .split(' ').map((w) => w.isEmpty ? '' : w[0].toUpperCase() + w.substring(1)).join(' ');

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      const Icon(Icons.filter_list_rounded, size: 14, color: AppColors.primary),
      const SizedBox(width: 6),
      if (status != null) _Chip(label: _label(status!)),
      if (cargoType != null) _Chip(label: cargoType!),
      if (urgentOnly) const _Chip(label: 'Urgent'),
      const Spacer(),
      GestureDetector(onTap: onClear,
        child: const Text('Clear all',
          style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600))),
    ]);
  }
}

class _Chip extends StatelessWidget {
  final String label; const _Chip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(AppRadius.pill)),
      child: Text(label,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary)),
    );
  }
}

class _SearchPrompt extends StatelessWidget {
  final IconData icon; final String message; final String hint;
  const _SearchPrompt({required this.icon, required this.message, required this.hint});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(20)),
            child: Icon(icon, size: 38, color: AppColors.primary),
          ),
          const SizedBox(height: 20),
          Text(message, style: AppTextStyles.headingMd, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(hint, style: AppTextStyles.bodyMd, textAlign: TextAlign.center),
        ]),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              color: AppColors.background, borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border)),
            child: const Icon(Icons.search_off_rounded, size: 36, color: AppColors.textHint),
          ),
          const SizedBox(height: 16),
          const Text('No results found', style: AppTextStyles.headingSm),
          const SizedBox(height: 6),
          const Text('Try different keywords or adjust filters.',
            style: AppTextStyles.bodyMd, textAlign: TextAlign.center),
        ]),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message; final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(color: AppColors.errorLight, borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.error_outline_rounded, size: 32, color: AppColors.error),
          ),
          const SizedBox(height: 16),
          const Text('Search failed', style: AppTextStyles.headingSm),
          const SizedBox(height: 6),
          Text(message, style: AppTextStyles.bodyMd, textAlign: TextAlign.center),
          const SizedBox(height: 20),
          TextButton(onPressed: onRetry,
            child: const Text('Try Again',
              style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary))),
        ]),
      ),
    );
  }
}
