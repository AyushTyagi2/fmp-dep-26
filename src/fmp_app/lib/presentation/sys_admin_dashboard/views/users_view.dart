import 'package:flutter/material.dart';
import '../sys_admin_api.dart';
import '../../../../shared/theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// USERS VIEW — Logic unchanged, premium UI applied
// ─────────────────────────────────────────────────────────────────────────────

class UsersView extends StatefulWidget {
  const UsersView({super.key});

  @override
  State<UsersView> createState() => _UsersViewState();
}

class _UsersViewState extends State<UsersView> {
  final _api = SysAdminApi();
  List<dynamic> _allUsers  = [];
  List<dynamic> _displayed = [];
  bool _loading             = true;
  String? _error;
  final _searchCtrl = TextEditingController();
  String _roleFilter = 'All';

  static const _roles = ['All', 'driver', 'sender', 'fleet_manager', 'sys_admin'];

  @override
  void initState() {
    super.initState();
    _load();
    _searchCtrl.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final users = await _api.getUsers();
      setState(() { _allUsers = users; _displayed = users; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  void _applyFilter() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _displayed = _allUsers.where((u) {
        final name  = (u['fullName']  as String? ?? '').toLowerCase();
        final phone = (u['phone']     as String? ?? '').toLowerCase();
        final id    = (u['id']        as String? ?? '').toLowerCase();
        final role  = (u['role']      as String? ?? '').toLowerCase();
        final matchQ = q.isEmpty || name.contains(q) || phone.contains(q) || id.contains(q);
        final matchRole = _roleFilter == 'All' || role == _roleFilter;
        return matchQ && matchRole;
      }).toList();
    });
  }

  void _setRole(String role) {
    setState(() => _roleFilter = role);
    _applyFilter();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Search + filter bar ───────────────────────────────────────────
        Container(
          color: AppColors.surface,
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.sm),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      decoration: InputDecoration(
                        hintText: 'Search by name, phone, or ID…',
                        prefixIcon: const Icon(Icons.search_rounded, size: 20),
                        suffixIcon: _searchCtrl.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18),
                                onPressed: () {
                                  _searchCtrl.clear();
                                  _applyFilter();
                                },
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.refresh_rounded, size: 20),
                      onPressed: _load,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 32,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _roles.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 6),
                  itemBuilder: (ctx, i) {
                    final r = _roles[i];
                    final active = _roleFilter == r;
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
                          r == 'All' ? r : r.replaceAll('_', ' ').split(' ')
                              .map((w) => w[0].toUpperCase() + w.substring(1)).join(' '),
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

        // ── User list ─────────────────────────────────────────────────────
        if (_loading)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else if (_error != null)
          Expanded(
            child: Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 40),
                const SizedBox(height: 12),
                const Text('Failed to load users', style: AppTextStyles.headingSm),
                const SizedBox(height: 16),
                ElevatedButton(onPressed: _load, child: const Text('Retry')),
              ]),
            ),
          )
        else if (_displayed.isEmpty)
          Expanded(
            child: Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.person_search_rounded, size: 48, color: AppColors.textHint),
                const SizedBox(height: 12),
                const Text('No users found', style: AppTextStyles.headingSm),
                const SizedBox(height: 6),
                const Text('Try adjusting your search or filter.', style: AppTextStyles.bodyMd),
              ]),
            ),
          )
        else
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: _displayed.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (ctx, i) => _UserCard(user: _displayed[i]),
            ),
          ),
      ],
    );
  }
}

class _UserCard extends StatelessWidget {
  final dynamic user;
  const _UserCard({required this.user});

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
    final name  = user['fullName']?.toString() ?? '—';
    final phone = user['phone']?.toString() ?? '—';
    final role  = user['role']?.toString() ?? '';
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
            child: Text(
              _initials(name),
              style: TextStyle(
                color: rc,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AppTextStyles.labelLg),
                Text(phone, style: AppTextStyles.bodySm),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: rc.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(color: rc.withOpacity(0.25)),
                ),
                child: Text(
                  _roleLabel(role),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: rc,
                  ),
                ),
              ),
              if (status.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(status, style: AppTextStyles.caption),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
