import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app_session.dart';
import '../../../shared/theme/app_theme.dart';
import '../fleet_state.dart';
import 'widgets/vehicle_card.dart';
import 'widgets/add_vehicle_form.dart';
import 'widgets/vehicle_detail_sheet.dart';

class FleetVehiclesScreen extends StatefulWidget {
  const FleetVehiclesScreen({super.key});

  @override
  State<FleetVehiclesScreen> createState() => _FleetVehiclesScreenState();
}

class _FleetVehiclesScreenState extends State<FleetVehiclesScreen> {
  // ── Selection state (ValueNotifier = surgical rebuilds only) ────────────────
  final ValueNotifier<Set<String>> _selectedIds = ValueNotifier({});
  final ValueNotifier<bool> _isDropMode = ValueNotifier(false);

  // ── Undo state ───────────────────────────────────────────────────────────────
  // Holds the vehicles that were just dropped so we can restore them on undo.
  // Cleared when the 15-second window expires or when the user taps Undo.
  List<dynamic> _lastDroppedVehicles = [];
  Timer? _undoTimer;
  // Drives the countdown text inside the SnackBar content widget.
  final ValueNotifier<int> _undoSecondsLeft = ValueNotifier(0);

  // ── Lifecycle ────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final phone = AppSession.email;
      if (phone != null) {
        context.read<FleetState>().loadVehicles(phone);
      }
    });
  }

  @override
  void dispose() {
    _selectedIds.dispose();
    _isDropMode.dispose();
    _undoSecondsLeft.dispose();
    _undoTimer?.cancel();
    super.dispose();
  }

  // ── Selection helpers ────────────────────────────────────────────────────────

  void _toggleDropMode() {
    if (_isDropMode.value) {
      _selectedIds.value = {};
    }
    _isDropMode.value = !_isDropMode.value;
  }

  void _toggleSelection(String id) {
    // Must create a new Set — ValueNotifier compares by reference.
    final updated = Set<String>.from(_selectedIds.value);
    if (updated.contains(id)) {
      updated.remove(id);
    } else {
      updated.add(id);
    }
    _selectedIds.value = updated;
  }

  // ── Undo helpers ─────────────────────────────────────────────────────────────

  /// Kicks off the 15-second undo window after a successful drop.
  /// Shows a custom SnackBar with a live circular countdown.
  void _startUndoWindow(BuildContext context, String phone, FleetState state) {
    _undoTimer?.cancel();
    _undoSecondsLeft.value = 15;

    _undoTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_undoSecondsLeft.value <= 1) {
        timer.cancel();
        _undoSecondsLeft.value = 0;
        _lastDroppedVehicles = []; // window expired — discard saved vehicles
      } else {
        _undoSecondsLeft.value--;
      }
    });

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        // Slightly longer than 15 s so bar doesn't close before final tick.
        duration: const Duration(seconds: 16),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.grey.shade900,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md)),
        content: _UndoCountdownContent(secondsLeft: _undoSecondsLeft),
        action: SnackBarAction(
          label: 'UNDO',
          textColor: AppColors.primary,
          onPressed: () => _handleUndo(context, phone, state),
        ),
      ),
    );
  }

  /// Called when the user taps UNDO. Restores the previously dropped vehicles.
  Future<void> _handleUndo(
      BuildContext context, String phone, FleetState state) async {
    _undoTimer?.cancel();
    _undoSecondsLeft.value = 0;

    if (_lastDroppedVehicles.isEmpty) return;

    final toRestore = List<dynamic>.from(_lastDroppedVehicles);
    _lastDroppedVehicles = [];

    try {
      await state.restoreVehicles(phone, toRestore);
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vehicles restored successfully'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Restore Failed'),
            content: Text(e.toString()),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  // ── Drop confirmation & execution ────────────────────────────────────────────

  Future<void> _confirmAndDrop(
    BuildContext context,
    FleetState state,
    String phone,
    Set<String> selectedIds,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Drop Vehicles?'),
        content: Text(
          'Remove ${selectedIds.length} vehicle(s)?\n'
          'You will have 15 seconds to undo this action.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Drop'),
          ),
        ],
      ),
    );

    if (confirm != true || !context.mounted) return;

    try {
      // Capture the full vehicle objects BEFORE they're removed from state,
      // so we have everything needed to restore them on undo.
      _lastDroppedVehicles = state.vehicles
          .where((v) => selectedIds.contains(v.id))
          .toList();

      await state.dropSelected(phone, selectedIds.toList());

      if (context.mounted) {
        _selectedIds.value = {};
        _isDropMode.value = false;
        _startUndoWindow(context, phone, state);
      }
    } catch (e) {
      _lastDroppedVehicles = []; // drop failed — nothing to undo
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Error'),
            content: Text(e.toString()),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  // ── Misc handlers ────────────────────────────────────────────────────────────

  Future<void> _handleCsvUpload(BuildContext context, String phone) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('CSV upload coming soon')),
    );
  }

  void _showAddVehicleSheet(BuildContext context, String phone) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (_) => AddVehicleForm(phone: phone),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final phone = AppSession.email ?? '';

    return Consumer<FleetState>(
      builder: (context, state, child) {
        return Scaffold(
          backgroundColor: AppColors.background,
          // Always null — bar is embedded in body to avoid Scaffold relayout.
          bottomNavigationBar: null,
          appBar: AppBar(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            automaticallyImplyLeading: false,
            title: const Text(
              'My Vehicles',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                fontFamily: AppTextStyles.fontFamily,
              ),
            ),
          ),
          body: Column(
            children: [
              _buildTopBar(context, state, phone),
              Expanded(
                child: state.isLoading && state.vehicles.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : state.vehicles.isEmpty
                        ? _buildEmptyState(context, phone)
                        : _buildVehicleList(context, state, phone),
              ),
              // Drop action bar — slides in by animating height, so the
              // Scaffold body never changes size and ListView never re-measures.
              _buildDropActionBar(context, state, phone),
            ],
          ),
        );
      },
    );
  }

  // ── Vehicle list ─────────────────────────────────────────────────────────────

  Widget _buildVehicleList(
      BuildContext context, FleetState state, String phone) {
    return RefreshIndicator(
      onRefresh: () async =>
          await state.loadVehicles(AppSession.email ?? ''),
      child: ListView.builder(
        key: const PageStorageKey<String>('vehicles_list'),
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: state.vehicles.length,
        itemBuilder: (context, index) {
          final vehicle = state.vehicles[index];
          // Each card only rebuilds when selection/mode changes — not when
          // unrelated cards are tapped.
          return ValueListenableBuilder2<Set<String>, bool>(
            first: _selectedIds,
            second: _isDropMode,
            builder: (context, selectedIds, isDropMode, _) {
              return VehicleCard(
                vehicle: vehicle,
                isDropMode: isDropMode,
                isSelected: selectedIds.contains(vehicle.id),
                onTap: () {
                  if (isDropMode) {
                    _toggleSelection(vehicle.id);
                  } else {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: AppColors.surface,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                            top: Radius.circular(AppRadius.lg)),
                      ),
                      builder: (_) => VehicleDetailSheet(
                        vehicle: vehicle,
                        phone: AppSession.email ?? '',
                      ),
                    );
                  }
                },
              );
            },
          );
        },
      ),
    );
  }

  // ── Top bar ──────────────────────────────────────────────────────────────────

  Widget _buildTopBar(
      BuildContext context, FleetState state, String phone) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Vehicle count pill
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Text(
              '${state.vehicles.length} Vehicles',
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.upload_file,
                    color: AppColors.primary),
                tooltip: 'Upload CSV',
                onPressed: () => _handleCsvUpload(context, phone),
              ),
              // Drop-mode toggle — only this icon reacts to _isDropMode.
              ValueListenableBuilder<bool>(
                valueListenable: _isDropMode,
                builder: (context, isDropMode, _) {
                  return IconButton(
                    icon: Icon(
                      isDropMode ? Icons.cancel : Icons.checklist,
                      color: isDropMode
                          ? AppColors.error
                          : AppColors.primary,
                    ),
                    tooltip: isDropMode ? 'Cancel Drop' : 'Select to Drop',
                    onPressed: _toggleDropMode,
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.add_circle,
                    color: AppColors.primary),
                tooltip: 'Add Vehicle',
                onPressed: () => _showAddVehicleSheet(context, phone),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Empty state ──────────────────────────────────────────────────────────────

  Widget _buildEmptyState(BuildContext context, String phone) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.local_shipping_outlined,
              size: 64, color: AppColors.textHint),
          const SizedBox(height: 16),
          const Text('No vehicles yet', style: AppTextStyles.headingSm),
          const SizedBox(height: 8),
          const Text('Add your first vehicle to get started.',
              style: AppTextStyles.bodyMd),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md)),
            ),
            onPressed: () => _showAddVehicleSheet(context, phone),
            child: const Text('Add Vehicle'),
          ),
        ],
      ),
    );
  }

  // ── Drop action bar ──────────────────────────────────────────────────────────
  // Slides in from the bottom of the body (not the Scaffold) when one or more
  // vehicles are selected. AnimatedContainer height avoids any Scaffold
  // geometry change, keeping the ListView stable.

  Widget _buildDropActionBar(
      BuildContext context, FleetState state, String phone) {
    return ValueListenableBuilder2<Set<String>, bool>(
      first: _selectedIds,
      second: _isDropMode,
      builder: (context, selectedIds, isDropMode, _) {
        final show = isDropMode && selectedIds.isNotEmpty;
        // CRITICAL: always give AnimatedContainer an explicit width and only
        // render _DropActionBarContent when actually visible.
        // Rendering it at height:0 gave Flutter a Row+Spacer with zero-height
        // constraints → "BoxConstraints forces an infinite width" crash that
        // blanked the entire page.
        return AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeInOut,
          width: double.infinity,
          height: show ? 72 : 0,
          child: show
              ? _DropActionBarContent(
                  count: selectedIds.length,
                  onCancel: _toggleDropMode,
                  onDrop: () =>
                      _confirmAndDrop(context, state, phone, selectedIds),
                )
              : const SizedBox.shrink(),
        );
      },
    );
  }
}

// ── Drop action bar content ──────────────────────────────────────────────────
// Separate const widget so parent doesn't rebuild it unnecessarily.

class _DropActionBarContent extends StatelessWidget {
  const _DropActionBarContent({
    required this.count,
    required this.onCancel,
    required this.onDrop,
  });

  final int count;
  final VoidCallback onCancel;
  final VoidCallback onDrop;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(top: BorderSide(color: AppColors.border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Count badge
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.10),
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.delete_outline,
                    color: AppColors.error, size: 16),
                const SizedBox(width: 4),
                Text(
                  '$count selected',
                  style: const TextStyle(
                    color: AppColors.error,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: onCancel,
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md)),
            ),
            icon: const Icon(Icons.delete_sweep, size: 18),
            label: const Text('Drop Selected'),
            onPressed: onDrop,
          ),
        ],
      ),
    );
  }
}

// ── Undo countdown SnackBar content ─────────────────────────────────────────
// Separate StatefulWidget so its countdown ticks independently — nothing
// outside the SnackBar rebuilds when the timer fires.

class _UndoCountdownContent extends StatefulWidget {
  const _UndoCountdownContent({required this.secondsLeft});

  final ValueNotifier<int> secondsLeft;

  @override
  State<_UndoCountdownContent> createState() => _UndoCountdownContentState();
}

class _UndoCountdownContentState extends State<_UndoCountdownContent> {
  @override
  void initState() {
    super.initState();
    widget.secondsLeft.addListener(_onTick);
  }

  @override
  void dispose() {
    widget.secondsLeft.removeListener(_onTick);
    super.dispose();
  }

  void _onTick() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.secondsLeft.value;
    return Row(
      children: [
        // Circular countdown ring
        SizedBox(
          width: 30,
          height: 30,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CircularProgressIndicator(
                value: s / 15.0,
                strokeWidth: 2.5,
                backgroundColor: Colors.white24,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
              Center(
                child: Text(
                  '$s',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            'Vehicles dropped. Tap UNDO to restore.',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }
}

// ── ValueListenableBuilder2 ──────────────────────────────────────────────────
// Listens to two ValueListenables and rebuilds when either fires.
// No extra packages required.

class ValueListenableBuilder2<A, B> extends StatelessWidget {
  const ValueListenableBuilder2({
    super.key,
    required this.first,
    required this.second,
    required this.builder,
    this.child,
  });

  final ValueListenable<A> first;
  final ValueListenable<B> second;
  final Widget Function(BuildContext, A, B, Widget?) builder;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<A>(
      valueListenable: first,
      builder: (context, a, _) {
        return ValueListenableBuilder<B>(
          valueListenable: second,
          builder: (context, b, __) => builder(context, a, b, child),
        );
      },
    );
  }
}