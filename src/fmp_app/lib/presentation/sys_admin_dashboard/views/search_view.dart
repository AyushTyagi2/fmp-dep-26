import 'package:flutter/material.dart';
import 'package:fmp_app/core/network/api_client.dart';
import 'package:fmp_app/core/network/api_search.dart';
import '../../../../shared/theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SYSADMIN SEARCH VIEW — User search only
// Calls GET /sysadmin/users/search?q=&role= backend endpoint.
// Role filter chips; live search on submit.
// ─────────────────────────────────────────────────────────────────────────────

class SearchView extends StatefulWidget {
  const SearchView({super.key});

  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> {
  final _searchCtrl = TextEditingController();
  final _searchApi   = SearchApi(ApiClient());

  List<dynamic> _results = [];
  bool _loading          = false;
  String? _error;
  bool _searched         = false;
  String _selectedRole   = 'All';

  static const _roles = ['All', 'driver', 'sender', 'fleet_manager', 'sys_admin'];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _doSearch() async {
    setState(() { _loading = true; _error = null; _searched = true; });
    try {
      final raw = await _searchApi.searchUsers(
        q: _searchCtrl.text.trim(),
        role: _selectedRole,
      );
      setState(() { _results = raw; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  void _setRole(String role) {
    setState(() => _selectedRole = role);
    if (_searched) _doSearch();
  }

  String _roleLabel(String r) => r == 'All' ? r : r.replaceAll('_', ' ')
      .split(' ').map((w) => w[0].toUpperCase() + w.substring(1)).join(' ');

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Search bar + role chips ──────────────────────────────────────────
        Container(
          color: AppColors.surface,
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.sm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => _doSearch(),
                      decoration: InputDecoration(
                        hintText: 'Search by name, phone, or ID…',
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
                  ElevatedButton(
                    onPressed: _doSearch,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(0, 46),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                    child: const Text('Search'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Role filter chips (horizontal scroll)
              SizedBox(
                height: 32,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _roles.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 6),
                  itemBuilder: (ctx, i) {
                    final r = _roles[i];
                    final active = _selectedRole == r;
                    return GestureDetector(
                      onTap: () => _setRole(r),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: active ? AppColors.primary : AppColors.background,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          border: Border.all(
                            color: active ? AppColors.primary : AppColors.border,
                          ),
                        ),
                        child: Text(
                          _roleLabel(r),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: active ? Colors.white : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // ── Results ──────────────────────────────────────────────────────────
        if (_loading)
          const Expanded(child: Center(child: CircularProgressIndicator(color: AppColors.primary)))
        else if (_error != null)
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    width: 64, height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.errorLight, borderRadius: BorderRadius.circular(16)),
                    child: const Icon(Icons.error_outline_rounded, size: 32, color: AppColors.error),
                  ),
                  const SizedBox(height: 16),
                  const Text('Search failed', style: AppTextStyles.headingSm),
                  const SizedBox(height: 6),
                  Text(_error!, style: AppTextStyles.bodyMd, textAlign: TextAlign.center),
                  const SizedBox(height: 20),
                  ElevatedButton(onPressed: _doSearch, child: const Text('Retry')),
                ]),
              ),
            ),
          )
        else if (!_searched)
          const Expanded(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.manage_search_rounded, size: 64, color: AppColors.textHint),
                  SizedBox(height: 16),
                  Text('Search Users', style: AppTextStyles.headingMd),
                  SizedBox(height: 8),
                  Text(
                    'Enter a name, phone number, or user ID.\nUse the role chips to narrow results.',
                    style: AppTextStyles.bodyMd,
                    textAlign: TextAlign.center,
                  ),
                ]),
              ),
            ),
          )
        else if (_results.isEmpty)
          const Expanded(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.person_search_rounded, size: 56, color: AppColors.textHint),
                  SizedBox(height: 16),
                  Text('No users found', style: AppTextStyles.headingSm),
                  SizedBox(height: 6),
                  Text('Try a different query or select a different role.',
                    style: AppTextStyles.bodyMd, textAlign: TextAlign.center),
                ]),
              ),
            ),
          )
        else
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: _results.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (ctx, i) => _UserResultCard(user: _results[i]),
            ),
          ),
      ],
    );
  }
}

// ── User Result Card ──────────────────────────────────────────────────────────

class _UserResultCard extends StatelessWidget {
  final dynamic user;
  const _UserResultCard({required this.user});

  String _initials(String name) {
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts.last[0]).toUpperCase();
  }

  Color _roleColor(String role) => switch (role.toLowerCase()) {
    'driver'        => AppColors.primary,
    'sender'        => const Color(0xFF7C3AED),
    'fleet_manager' => AppColors.warning,
    'sys_admin'     => AppColors.error,
    _               => AppColors.textSecondary,
  };

  String _roleLabel(String role) => role
      .replaceAll('_', ' ')
      .split(' ')
      .map((w) => w.isEmpty ? '' : w[0].toUpperCase() + w.substring(1))
      .join(' ');

  @override
  Widget build(BuildContext context) {
    final name   = user['fullName']?.toString() ?? '—';
    final phone  = user['phone']?.toString() ?? '—';
    final role   = user['role']?.toString() ?? '';
    final status = user['status']?.toString() ?? '';
    final rc = _roleColor(role);

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
            radius: 20,
            backgroundColor: rc.withOpacity(0.1),
            child: Text(_initials(name),
              style: TextStyle(color: rc, fontWeight: FontWeight.w700, fontSize: 13)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, style: AppTextStyles.labelLg),
              Text(phone, style: AppTextStyles.bodySm),
            ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: rc.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(color: rc.withOpacity(0.25)),
              ),
              child: Text(_roleLabel(role),
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: rc)),
            ),
            if (status.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(status, style: AppTextStyles.caption),
            ],
          ]),
        ],
      ),
    );
  }
}
