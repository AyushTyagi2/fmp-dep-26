import 'package:flutter/material.dart';
import 'package:fmp_app/app_session.dart';
import 'package:fmp_app/core/network/api_client.dart';
import 'package:fmp_app/core/network/api_search.dart';
import '../../../shared/theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// FLEET MANAGER SEARCH SCREEN
// Searches drivers under this fleet owner via backend endpoint.
// Filters: status chip.
// ─────────────────────────────────────────────────────────────────────────────

class FleetSearchScreen extends StatefulWidget {
  const FleetSearchScreen({super.key});

  @override
  State<FleetSearchScreen> createState() => _FleetSearchScreenState();
}

class _FleetSearchScreenState extends State<FleetSearchScreen> {
  final _searchCtrl = TextEditingController();
  final _searchApi   = SearchApi(ApiClient());

  List<dynamic> _results = [];
  bool _loading          = false;
  String? _error;
  bool _searched         = false;
  String? _selectedStatus;

  static const _statuses = ['active', 'inactive', 'suspended', 'pending'];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _doSearch() async {
    final phone = AppSession.phone;
    if (phone == null) return;
    setState(() { _loading = true; _error = null; _searched = true; });
    try {
      final raw = await _searchApi.searchFleetDrivers(
        phone: phone,
        q: _searchCtrl.text.trim(),
        status: _selectedStatus,
      );
      setState(() { _results = raw; _loading = false; });
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
      builder: (_) => _FleetFilterSheet(
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
            Container(
              color: AppColors.surface,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Search Drivers',
                    style: TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Text(
                    'Find drivers in your fleet',
                    style: AppTextStyles.bodyMd,
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
                            hintText: 'Driver name, phone, or ID…',
                            prefixIcon: const Icon(Icons.search_rounded, size: 20),
                            suffixIcon: _searchCtrl.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded, size: 18),
                                    onPressed: () { _searchCtrl.clear(); setState(() {}); },
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
                    _ActiveFilterRow(status: _selectedStatus, onClear: _clearFilters),
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
                              icon: Icons.people_outlined,
                              message: 'Search your drivers',
                              hint: 'Enter a driver name, phone, or ID\nto find them in your fleet.',
                            )
                          : _results.isEmpty
                              ? const _EmptyState()
                              : ListView.separated(
                                  padding: const EdgeInsets.all(16),
                                  itemCount: _results.length,
                                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                                  itemBuilder: (_, i) => _DriverCard(driver: _results[i]),
                                ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Filter Sheet ─────────────────────────────────────────────────────────────

class _FleetFilterSheet extends StatefulWidget {
  final String? selectedStatus;
  final void Function(String? status) onApply;
  const _FleetFilterSheet({required this.selectedStatus, required this.onApply});

  @override
  State<_FleetFilterSheet> createState() => _FleetFilterSheetState();
}

class _FleetFilterSheetState extends State<_FleetFilterSheet> {
  String? _status;
  static const _statuses = ['active', 'inactive', 'suspended', 'pending'];

  @override
  void initState() { super.initState(); _status = widget.selectedStatus; }

  String _label(String s) => s[0].toUpperCase() + s.substring(1);

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
          Center(child: Container(width: 40, height: 4,
            decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          const Text('Filter Drivers', style: AppTextStyles.headingMd),
          const SizedBox(height: 20),

          const Text('Driver Status', style: AppTextStyles.labelLg),
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

          const SizedBox(height: 24),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () { widget.onApply(null); Navigator.pop(context); },
                style: OutlinedButton.styleFrom(minimumSize: const Size(0, 46)),
                child: const Text('Reset'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: () { widget.onApply(_status); Navigator.pop(context); },
                style: ElevatedButton.styleFrom(minimumSize: const Size(0, 46)),
                child: const Text('Apply Filters'),
              ),
            ),
          ]),
        ],
      ),
    );
  }
}

// ── Driver Result Card ────────────────────────────────────────────────────────

class _DriverCard extends StatelessWidget {
  final dynamic driver;
  const _DriverCard({required this.driver});

  String _initials(String name) {
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts.last[0]).toUpperCase();
  }

  Color _statusColor(String s) => switch (s.toLowerCase()) {
    'active'    => AppColors.success,
    'inactive'  => AppColors.textSecondary,
    'suspended' => AppColors.error,
    'pending'   => AppColors.warning,
    _           => AppColors.textSecondary,
  };

  @override
  Widget build(BuildContext context) {
    final name   = driver['fullName']?.toString() ?? driver['name']?.toString() ?? '—';
    final phone  = driver['phone']?.toString() ?? '—';
    final status = driver['status']?.toString() ?? '';
    final sc = _statusColor(status);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.primaryLight,
            child: Text(_initials(name),
              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 14)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, style: AppTextStyles.labelLg),
              Text(phone, style: AppTextStyles.bodySm),
            ]),
          ),
          if (status.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: sc.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(color: sc.withOpacity(0.25)),
              ),
              child: Text(
                status[0].toUpperCase() + status.substring(1),
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: sc),
              ),
            ),
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
  final String? status; final VoidCallback onClear;
  const _ActiveFilterRow({this.status, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      const Icon(Icons.filter_list_rounded, size: 14, color: AppColors.primary),
      const SizedBox(width: 6),
      if (status != null) _Chip(label: status![0].toUpperCase() + status!.substring(1)),
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
      child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary)),
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
          const Text('No drivers found', style: AppTextStyles.headingSm),
          const SizedBox(height: 6),
          const Text('Try different keywords or adjust the filter.',
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
