import 'package:flutter/material.dart';
import 'package:fmp_app/app_session.dart';
import 'package:fmp_app/core/network/api_client.dart';
import 'package:fmp_app/core/network/api_search.dart';
import 'package:fmp_app/core/network/api_trips.dart';
import '../../../shared/theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DRIVER SEARCH SCREEN
// Searches trips via backend endpoint, filters by status.
// ─────────────────────────────────────────────────────────────────────────────

class DriverSearchScreen extends StatefulWidget {
  const DriverSearchScreen({super.key});

  @override
  State<DriverSearchScreen> createState() => _DriverSearchScreenState();
}

class _DriverSearchScreenState extends State<DriverSearchScreen> {
  final _searchCtrl = TextEditingController();
  final _searchApi   = SearchApi(ApiClient());

  List<TripSummary> _results = [];
  bool _loading              = false;
  String? _error;
  bool _searched             = false;
  String? _selectedStatus;

  static const _statuses = [
    'assigned', 'in_progress', 'in_transit', 'completed', 'delivered', 'cancelled',
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _doSearch() async {
    final driverId = AppSession.driverId;
    if (driverId == null) return;
    setState(() { _loading = true; _error = null; _searched = true; });
    try {
      final raw = await _searchApi.searchTrips(
        driverId: driverId,
        q: _searchCtrl.text.trim(),
        status: _selectedStatus,
      );
      final trips = raw
          .cast<Map<String, dynamic>>()
          .map(TripSummary.fromJson)
          .toList();
      setState(() { _results = trips; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  void _clearFilters() {
    setState(() => _selectedStatus = null);
    if (_searched) _doSearch();
  }

  bool get _hasActiveFilter => _selectedStatus != null;

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DriverFilterSheet(
        selectedStatus: _selectedStatus,
        onApply: (status) {
          setState(() => _selectedStatus = status);
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
            // ── Header ──────────────────────────────────────────────────────
            Container(
              color: AppColors.surface,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Search Trips',
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
                            hintText: 'Trip #, shipment #…',
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
                      onClear: _clearFilters,
                    ),
                  ],
                ],
              ),
            ),
            const Divider(height: 1),

            // ── Results ─────────────────────────────────────────────────────
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF1A56DB)))
                  : _error != null
                      ? _ErrorState(message: _error!, onRetry: _doSearch)
                      : !_searched
                          ? const _SearchPrompt(
                              icon: Icons.route_outlined,
                              message: 'Search your trips',
                              hint: 'Enter a trip or shipment number\nor filter by status.',
                            )
                          : _results.isEmpty
                              ? const _EmptyState(entity: 'trips')
                              : ListView.separated(
                                  padding: const EdgeInsets.all(16),
                                  itemCount: _results.length,
                                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                                  itemBuilder: (_, i) => _TripResultCard(trip: _results[i]),
                                ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Filter Sheet ─────────────────────────────────────────────────────────────

class _DriverFilterSheet extends StatefulWidget {
  final String? selectedStatus;
  final void Function(String? status) onApply;
  const _DriverFilterSheet({required this.selectedStatus, required this.onApply});

  @override
  State<_DriverFilterSheet> createState() => _DriverFilterSheetState();
}

class _DriverFilterSheetState extends State<_DriverFilterSheet> {
  String? _status;

  static const _statuses = [
    'assigned', 'in_progress', 'in_transit', 'completed', 'delivered', 'cancelled',
  ];

  @override
  void initState() {
    super.initState();
    _status = widget.selectedStatus;
  }

  String _label(String s) => s.replaceAll('_', ' ')
      .split(' ')
      .map((w) => w.isEmpty ? '' : w[0].toUpperCase() + w.substring(1))
      .join(' ');

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).viewInsets.bottom + 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Filter Trips', style: AppTextStyles.headingMd),
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
                selectedColor: const Color(0xFFEBF0FE),
                checkmarkColor: const Color(0xFF1A56DB),
                labelStyle: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600,
                  color: active ? const Color(0xFF1A56DB) : AppColors.textSecondary,
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    widget.onApply(null);
                    Navigator.pop(context);
                  },
                  style: OutlinedButton.styleFrom(minimumSize: const Size(0, 46)),
                  child: const Text('Reset'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () {
                    widget.onApply(_status);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(0, 46),
                    backgroundColor: const Color(0xFF1A56DB),
                  ),
                  child: const Text('Apply Filters'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Trip Result Card ──────────────────────────────────────────────────────────

class _TripResultCard extends StatelessWidget {
  final TripSummary trip;
  const _TripResultCard({required this.trip});

  (Color, Color, String) _statusStyle(String s) {
    switch (s) {
      case 'completed':
      case 'delivered':   return (const Color(0xFFDEF7EC), const Color(0xFF057A55), 'Delivered');
      case 'in_transit':
      case 'in_progress': return (const Color(0xFFEBF0FE), const Color(0xFF1A56DB), 'In Transit');
      case 'assigned':    return (const Color(0xFFF3F4F6), const Color(0xFF374151), 'Assigned');
      case 'cancelled':   return (const Color(0xFFFDE8E8), const Color(0xFFE02424), 'Cancelled');
      default:            return (const Color(0xFFF3F4F6), const Color(0xFF6B7280), s);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (statusBg, statusText, statusLabel) = _statusStyle(trip.currentStatus);
    final isCompleted = trip.currentStatus == 'completed' || trip.currentStatus == 'delivered';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E9F0)),
        boxShadow: const [BoxShadow(color: Color(0x05000000), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: isCompleted ? const Color(0xFFDEF7EC) : const Color(0xFFEBF0FE),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isCompleted ? Icons.check_circle_rounded : Icons.local_shipping_rounded,
              size: 20,
              color: isCompleted ? const Color(0xFF0E9F6E) : const Color(0xFF1A56DB),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(trip.tripNumber,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
                Text(trip.shipmentNumber,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(100)),
                child: Text(statusLabel,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: statusText)),
              ),
              if (trip.agreedPrice != null) ...[
                const SizedBox(height: 4),
                Text('₹${trip.agreedPrice!.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ── Shared widgets (copied from sender_search_screen.dart for self-containment) ─

class _FilterButton extends StatelessWidget {
  final bool hasFilter;
  final VoidCallback onTap;
  const _FilterButton({required this.hasFilter, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 46, width: 46,
        decoration: BoxDecoration(
          color: hasFilter ? const Color(0xFFEBF0FE) : AppColors.background,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: hasFilter ? const Color(0xFF1A56DB) : AppColors.border),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(Icons.tune_rounded, size: 20,
              color: hasFilter ? const Color(0xFF1A56DB) : AppColors.textSecondary),
            if (hasFilter)
              Positioned(
                top: 8, right: 8,
                child: Container(width: 8, height: 8,
                  decoration: const BoxDecoration(color: Color(0xFF1A56DB), shape: BoxShape.circle)),
              ),
          ],
        ),
      ),
    );
  }
}

class _ActiveFilterRow extends StatelessWidget {
  final String? status;
  final VoidCallback onClear;
  const _ActiveFilterRow({this.status, required this.onClear});

  String _label(String s) => s.replaceAll('_', ' ')
      .split(' ').map((w) => w.isEmpty ? '' : w[0].toUpperCase() + w.substring(1)).join(' ');

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.filter_list_rounded, size: 14, color: Color(0xFF1A56DB)),
        const SizedBox(width: 6),
        if (status != null) _Chip(label: _label(status!)),
        const Spacer(),
        GestureDetector(
          onTap: onClear,
          child: const Text('Clear all',
            style: TextStyle(fontSize: 12, color: Color(0xFF1A56DB), fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  const _Chip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFEBF0FE),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(label,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF1A56DB))),
    );
  }
}

class _SearchPrompt extends StatelessWidget {
  final IconData icon;
  final String message;
  final String hint;
  const _SearchPrompt({required this.icon, required this.message, required this.hint});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFEBF0FE),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(icon, size: 38, color: const Color(0xFF1A56DB)),
            ),
            const SizedBox(height: 20),
            Text(message, style: AppTextStyles.headingMd, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(hint, style: AppTextStyles.bodyMd, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String entity;
  const _EmptyState({required this.entity});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(Icons.search_off_rounded, size: 36, color: AppColors.textHint),
            ),
            const SizedBox(height: 16),
            const Text('No results found', style: AppTextStyles.headingSm),
            const SizedBox(height: 6),
            Text('No $entity match your query or filters.',
              style: AppTextStyles.bodyMd, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                color: AppColors.errorLight, borderRadius: BorderRadius.circular(16)),
              child: const Icon(Icons.error_outline_rounded, size: 32, color: AppColors.error),
            ),
            const SizedBox(height: 16),
            const Text('Search failed', style: AppTextStyles.headingSm),
            const SizedBox(height: 6),
            Text(message, style: AppTextStyles.bodyMd, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            TextButton(
              onPressed: onRetry,
              child: const Text('Try Again',
                style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1A56DB))),
            ),
          ],
        ),
      ),
    );
  }
}
