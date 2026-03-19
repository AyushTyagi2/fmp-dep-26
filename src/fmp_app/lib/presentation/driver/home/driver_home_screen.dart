import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_trips.dart';
import '../../../app_session.dart';

// --- Global UI Constants for the Premium Look ---
const _primaryGradient = LinearGradient(
  colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)], // Deep Blue to Bright Blue
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

const _successGradient = LinearGradient(
  colors: [Color(0xFF059669), Color(0xFF10B981)], // Deep Green to Emerald
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

// ============================================================================
// DRIVER HOME SCREEN (PREMIUM DASHBOARD)
// ============================================================================

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  late final TripApiService _api;
  List<TripSummary> _activeTrips = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _api = TripApiService(ApiClient());
    _loadActiveTrips();
  }

  Future<void> _loadActiveTrips() async {
    final driverId = AppSession.driverId;
    if (driverId == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      final all = await _api.getDriverTrips(driverId);
      if (!mounted) return;
      setState(() {
        _activeTrips = all.where((t) => t.currentStatus != 'delivered').toList();
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA), // Slightly cooler, premium off-white
      appBar: AppBar(
        title: const Text('My Dashboard', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 22)),
        centerTitle: false,
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: _primaryGradient)),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6)))
          : _activeTrips.isEmpty
              ? _buildEmptyState()
              : _buildActiveTripDashboard(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: const Color(0xFF3B82F6).withOpacity(0.15), blurRadius: 30, spreadRadius: 10)
                ],
              ),
              child: const Icon(Icons.local_shipping_rounded, size: 72, color: Color(0xFF3B82F6)),
            ),
            const SizedBox(height: 32),
            const Text(
              'You\'re offline or empty',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 12),
            const Text(
              'Head over to the Queue tab to find and accept your next shipment.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF64748B), fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 40),
            Container(
              decoration: BoxDecoration(
                gradient: _primaryGradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: const Color(0xFF3B82F6).withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))
                ]
              ),
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() => _loading = true);
                  _loadActiveTrips();
                },
                icon: const Icon(Icons.refresh_rounded, size: 22),
                label: const Text('Refresh Dashboard', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent, // Let the gradient show
                  foregroundColor: Colors.white,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveTripDashboard() {
    final trip = _activeTrips.first;
    return RefreshIndicator(
      onRefresh: _loadActiveTrips,
      color: const Color(0xFF3B82F6),
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: Colors.amber.shade100, borderRadius: BorderRadius.circular(8)),
                child: Icon(Icons.bolt_rounded, color: Colors.amber.shade600, size: 18),
              ),
              const SizedBox(width: 12),
              const Text(
                'CURRENTLY ACTIVE',
                style: TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w800, letterSpacing: 1.5),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 24, offset: const Offset(0, 8))
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
                        child: Text(
                          'ID: ${trip.tripNumber}',
                          style: const TextStyle(color: Color(0xFF475569), fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ),
                      _PremiumStatusChip(status: trip.currentStatus),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text('Shipment Number', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Text(
                    trip.shipmentNumber,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 32),
                  Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: _primaryGradient,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: const Color(0xFF3B82F6).withOpacity(0.25), blurRadius: 12, offset: const Offset(0, 6))
                      ]
                    ),
                    child: ElevatedButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ActiveTripScreen(tripId: trip.id)),
                      ).then((_) => _loadActiveTrips()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('Manage Trip', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// ACTIVE TRIP SCREEN (PREMIUM DETAILS)
// ============================================================================

class ActiveTripScreen extends StatefulWidget {
  final String tripId;
  const ActiveTripScreen({super.key, required this.tripId});

  @override
  State<ActiveTripScreen> createState() => _ActiveTripScreenState();
}

class _ActiveTripScreenState extends State<ActiveTripScreen> {
  late final TripApiService _api;
  TripSummary? _trip;
  bool _loading = true;
  bool _updating = false;
  String? _error;

  static const _steps = ['assigned', 'in_transit', 'delivered'];
  static const _stepLabels = {
    'assigned': 'Start Delivery',
    'in_transit': 'Mark as Delivered',
    'delivered': 'Completed ✓',
  };
  static const _stepDescriptions = {
    'assigned': 'Shipment assigned to you. Head to the pickup location.',
    'in_transit': 'Cargo picked up. You are currently en route.',
    'delivered': 'Delivery successfully completed!',
  };

  @override
  void initState() {
    super.initState();
    _api = TripApiService(ApiClient());
    _loadTrip();
  }

  // ... [_loadTrip and _advanceStatus remain exactly the same logically] ...
  Future<void> _loadTrip() async {
    setState(() { _loading = true; _error = null; });
    try {
      final trip = await _api.getTripById(widget.tripId);
      if (!mounted) return;
      setState(() { _trip = trip; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _advanceStatus() async {
    if (_trip == null) return;
    final idx = _steps.indexOf(_trip!.currentStatus);
    if (idx < 0 || idx >= _steps.length - 1) return;

    final nextStatus = _steps[idx + 1];
    setState(() => _updating = true);

    final ok = await _api.updateStatus(widget.tripId, nextStatus);
    if (!mounted) return;

    if (ok) {
      setState(() {
        _trip = TripSummary(
          id: _trip!.id, tripNumber: _trip!.tripNumber,
          shipmentId: _trip!.shipmentId, shipmentNumber: _trip!.shipmentNumber,
          currentStatus: nextStatus, agreedPrice: _trip!.agreedPrice,
          createdAt: _trip!.createdAt,
        );
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to update status. Please retry.', style: TextStyle(fontWeight: FontWeight.w600)), 
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
    setState(() => _updating = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDone = _trip?.currentStatus == 'delivered';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      appBar: AppBar(
        title: const Text('Trip Details', style: TextStyle(fontWeight: FontWeight.w700)),
        centerTitle: true,
        flexibleSpace: Container(decoration: BoxDecoration(gradient: isDone ? _successGradient : _primaryGradient)),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6)))
          : _error != null 
              ? _buildError() 
              : _buildContent(),
      bottomNavigationBar: (!_loading && _error == null) 
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: isDone ? _buildCompletedAction() : _buildActionBtn(),
              ),
            )
          : null,
    );
  }

  Widget _buildError() => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle),
            child: Icon(Icons.wifi_off_rounded, size: 56, color: Colors.red.shade400),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF64748B), fontSize: 16)),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _loadTrip, 
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E293B), 
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('Retry Connection', style: TextStyle(fontWeight: FontWeight.w600))
          ),
        ]),
      );

  Widget _buildContent() {
    final trip = _trip!;
    final status = trip.currentStatus;
    final isDone = status == 'delivered';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, 
        children: [
          // Sleek Status Stepper Card
          Container(
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 4))]
            ),
            child: _PremiumStatusStepper(currentStatus: status, steps: _steps),
          ),
          const SizedBox(height: 24),
          
          // Current Status Highlight
          Container(
            width: double.infinity, 
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDone ? const Color(0xFFECFDF5) : const Color(0xFFEFF6FF), // Soft Emerald or Soft Blue
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: isDone ? const Color(0xFFA7F3D0) : const Color(0xFFBFDBFE), width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, 
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDone ? const Color(0xFF10B981) : const Color(0xFF3B82F6),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isDone ? Icons.check_rounded : Icons.navigation_rounded, 
                        color: Colors.white,
                        size: 16
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'CURRENT STATUS', 
                      style: TextStyle(
                        fontSize: 12, 
                        color: isDone ? const Color(0xFF047857) : const Color(0xFF1D4ED8), 
                        fontWeight: FontWeight.w800, 
                        letterSpacing: 1.2
                      )
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  _stepDescriptions[status] ?? status,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF0F172A), height: 1.4)
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          
          if (trip.agreedPrice != null) ...[
            const Text(
              "TRIP DETAILS", 
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8), letterSpacing: 1.2)
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white, 
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 4))],
              ),
              child: Column(
                children: [
                  _PremiumInfoRow(label: 'Trip ID', value: trip.tripNumber),
                  const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(height: 1, color: Color(0xFFF1F5F9))),
                  _PremiumInfoRow(label: 'Shipment #', value: trip.shipmentNumber),
                  const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(height: 1, color: Color(0xFFF1F5F9))),
                  _PremiumInfoRow(
                    label: 'Payout', 
                    value: '₹${trip.agreedPrice!.toStringAsFixed(0)}',
                    valueColor: const Color(0xFF059669), // Rich Green
                    isBold: true,
                    size: 20,
                  ),
                ]
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionBtn() {
    return Container(
      width: double.infinity, 
      height: 60,
      decoration: BoxDecoration(
        gradient: _primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: const Color(0xFF3B82F6).withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 8))]
      ),
      child: ElevatedButton(
        onPressed: _updating ? null : _advanceStatus,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent, 
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        child: _updating
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white))
            : Text(
                _stepLabels[_trip!.currentStatus] ?? 'Update Status',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: 0.5)
              ),
      ),
    );
  }

  Widget _buildCompletedAction() {
    return SizedBox(
      width: double.infinity, 
      height: 60,
      child: OutlinedButton(
        onPressed: () => Navigator.pop(context),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF1E293B),
          backgroundColor: Colors.white,
          side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))
        ),
        child: const Text('Back to Dashboard', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
      ),
    );
  }
}

// ============================================================================
// PREMIUM SUPPORTING WIDGETS
// ============================================================================

class _PremiumStatusStepper extends StatelessWidget {
  final String currentStatus;
  final List<String> steps;
  const _PremiumStatusStepper({required this.currentStatus, required this.steps});

  @override
  Widget build(BuildContext context) {
    final idx = steps.indexOf(currentStatus);
    return Row(
      children: List.generate(steps.length * 2 - 1, (i) {
        if (i.isOdd) {
          final done = (i ~/ 2) < idx;
          return Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 4, 
              decoration: BoxDecoration(
                color: done ? const Color(0xFF10B981) : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2)
              ),
            )
          );
        }
        final stepIdx = i ~/ 2;
        final done    = stepIdx <= idx;
        final isCurrent = stepIdx == idx;
        
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 36, height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle, 
            color: done ? const Color(0xFF10B981) : Colors.white,
            border: Border.all(
              color: done ? const Color(0xFF10B981) : (isCurrent ? const Color(0xFF3B82F6) : const Color(0xFFCBD5E1)),
              width: isCurrent && !done ? 3 : 1.5,
            ),
            boxShadow: isCurrent && !done ? [
              BoxShadow(color: const Color(0xFF3B82F6).withOpacity(0.3), blurRadius: 8, spreadRadius: 2)
            ] : null,
          ),
          child: done
              ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
              : Center(
                  child: Text(
                    '${stepIdx + 1}', 
                    style: TextStyle(
                      color: isCurrent ? const Color(0xFF1D4ED8) : const Color(0xFF94A3B8), 
                      fontWeight: FontWeight.w800,
                      fontSize: 14
                    )
                  )
                ),
        );
      }),
    );
  }
}

class _PremiumStatusChip extends StatelessWidget {
  final String status;
  const _PremiumStatusChip({required this.status});

  Color get _baseColor => switch (status) {
    'assigned'   => const Color(0xFFF59E0B), // Amber
    'in_transit' => const Color(0xFF8B5CF6), // Purple
    'delivered'  => const Color(0xFF10B981), // Emerald
    _            => const Color(0xFF64748B), // Slate
  };

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: _baseColor.withOpacity(0.12), 
      borderRadius: BorderRadius.circular(10), 
      border: Border.all(color: _baseColor.withOpacity(0.2))
    ),
    child: Text(
      status.replaceAll('_', ' ').toUpperCase(), 
      style: TextStyle(color: _baseColor, fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 0.8)
    ),
  );
}

class _PremiumInfoRow extends StatelessWidget {
  final String label; 
  final String value;
  final Color? valueColor;
  final bool isBold;
  final double size;
  
  const _PremiumInfoRow({
    required this.label, 
    required this.value,
    this.valueColor,
    this.isBold = false,
    this.size = 15,
  });

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 15, fontWeight: FontWeight.w500)),
      const Spacer(),
      Text(
        value, 
        style: TextStyle(
          fontSize: size, 
          fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
          color: valueColor ?? const Color(0xFF0F172A),
          fontFamily: value.startsWith('₹') ? null : 'monospace',
        ),
      ),
    ]
  );
}