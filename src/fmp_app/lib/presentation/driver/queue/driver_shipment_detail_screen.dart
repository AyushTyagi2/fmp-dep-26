import 'package:flutter/material.dart';
import '../../../core/models/shipment.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_shipment_queue.dart';
import '../home/driver_home_screen.dart';
import '../../../app_session.dart';

class DriverShipmentDetailScreen extends StatefulWidget {
  final Shipment shipment;
  final String   driverId;

  const DriverShipmentDetailScreen({
    super.key,
    required this.shipment,
    required this.driverId,
  });

  @override
  State<DriverShipmentDetailScreen> createState() => _DriverShipmentDetailScreenState();
}

class _DriverShipmentDetailScreenState extends State<DriverShipmentDetailScreen> {
  late final ShipmentApiService _api;
  bool _isAccepting = false;
  bool _accepted    = false;

  @override
  void initState() {
    super.initState();
    _api = ShipmentApiService(ApiClient());
  }

  Future<void> _handleAccept() async {
    debugPrint('=== SESSION DEBUG ===');
    debugPrint('driverId: ${AppSession.driverId}');
    debugPrint('token: ${AppSession.token}');
    debugPrint('phone: ${AppSession.phone}');
    debugPrint('====================');

    if (widget.driverId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session error: driver ID not found. Please re-login.')),
      );
      return;
    }

    setState(() => _isAccepting = true);

    try {
      final result = await _api.acceptShipment(
        shipmentQueueId: widget.shipment.id,   // ← renamed parameter
        driverId:        widget.driverId,
      );

      if (!mounted) return;

      if (result.success) {
        setState(() => _accepted = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Shipment accepted! Starting your trip...'),
            backgroundColor: Color(0xFF4CAF50),
            behavior: SnackBarBehavior.floating,
          ),
        );
        await Future.delayed(const Duration(milliseconds: 600));
        if (!mounted) return;

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => ActiveTripScreen(tripId: result.tripId ?? ''),
          ),
          (route) => route.isFirst,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message ?? 'Unknown error'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 10),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isAccepting = false);
    }
  }

  void _showAlreadyTakenDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Row(children: [
          Icon(Icons.warning_amber, color: Colors.orange),
          SizedBox(width: 8),
          Text('Already Taken'),
        ]),
        content: const Text(
            'Another driver just accepted this shipment. Go back to the queue to find another one.'),
        actions: [
          ElevatedButton(
            onPressed: () { Navigator.pop(context); Navigator.pop(context); },
            child: const Text('Back to Queue'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.shipment;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shipment Details'),
        backgroundColor: const Color(0xFF1B3A6B),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF1B3A6B), Color(0xFF2E75B6)]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(children: [
                const Text('Payout', style: TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 4),
                Text(
                  s.agreedPrice != null ? '₹${s.agreedPrice!.toStringAsFixed(0)}' : 'TBD',
                  style: const TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.bold),
                ),
                if (s.isUrgent) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                        color: Colors.red.shade400, borderRadius: BorderRadius.circular(12)),
                    child: const Text('⚡ URGENT',
                        style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ],
              ]),
            ),
            const SizedBox(height: 20),
            _SectionCard(
              title: 'ROUTE',
              child: Column(children: [
                _DetailRow(icon: Icons.circle, color: const Color(0xFF4CAF50), label: 'Pickup', value: s.pickupLocation),
                const Padding(padding: EdgeInsets.only(left: 12, top: 4, bottom: 4), child: _DotDivider()),
                _DetailRow(icon: Icons.location_on, color: const Color(0xFFF44336), label: 'Drop-off', value: s.dropLocation),
              ]),
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: 'CARGO DETAILS',
              child: Column(children: [
                _InfoRow(label: 'Shipment #', value: s.shipmentNumber),
                _InfoRow(label: 'Type',       value: s.cargoType),
                _InfoRow(label: 'Weight',     value: '${s.cargoWeightKg.toStringAsFixed(1)} kg'),
                _InfoRow(label: 'Currency',   value: s.currency),
              ]),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity, height: 54,
            child: ElevatedButton(
              onPressed: (_accepted || _isAccepting) ? null : _handleAccept,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B3A6B),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                disabledBackgroundColor: const Color(0xFF4CAF50),
              ),
              child: _isAccepting
                  ? const SizedBox(width: 24, height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(_accepted ? '✓ Accepted' : 'Accept Shipment',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey, letterSpacing: 1.2)),
      const SizedBox(height: 8),
      Container(
        width: double.infinity, padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: child,
      ),
    ],
  );
}

class _DetailRow extends StatelessWidget {
  final IconData icon; final Color color; final String label; final String value;
  const _DetailRow({required this.icon, required this.color, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, color: color, size: 20), const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
      ])),
    ],
  );
}

class _InfoRow extends StatelessWidget {
  final String label; final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(children: [
      SizedBox(width: 100, child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13))),
      Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
    ]),
  );
}

class _DotDivider extends StatelessWidget {
  const _DotDivider();
  @override
  Widget build(BuildContext context) => Column(
    children: List.generate(3, (_) => Container(
      width: 2, height: 4, margin: const EdgeInsets.symmetric(vertical: 1), color: Colors.grey.shade300,
    )),
  );
}