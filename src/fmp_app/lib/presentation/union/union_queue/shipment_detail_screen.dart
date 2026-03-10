import 'package:flutter/material.dart';
import '../../../core/models/shipment.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_shipment_queue.dart';

class ShipmentDetailScreen extends StatefulWidget {
  final Shipment shipment;
  final String   driverId;

  const ShipmentDetailScreen({
    super.key,
    required this.shipment,
    required this.driverId,
  });

  @override
  State<ShipmentDetailScreen> createState() => _ShipmentDetailScreenState();
}

//s.price  →  s.agreedPrice
//s.pickupLocation  →  s.pickupAddressId
//s.dropLocation  →  s.dropAddressId
//s.weightKg  →  s.cargoWeightKg


class _ShipmentDetailScreenState extends State<ShipmentDetailScreen> {
  late final ShipmentApiService _api;
  bool _isAccepting = false;
  bool _accepted    = false;

  @override
  void initState() {
    super.initState();
    _api = ShipmentApiService(ApiClient());
  }

  Future<void> _handleAccept() async {
    setState(() => _isAccepting = true);

    try {
      final result = await _api.acceptShipment(
        shipmentId: widget.shipment.id,
        driverId:   widget.driverId,
      );
      final success = result.success;

      if (!mounted) return;

      if (success) {
        setState(() => _accepted = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Shipment accepted! Check your assigned jobs.'),
            backgroundColor: Color(0xFF4CAF50),
            behavior: SnackBarBehavior.floating,
          ),
        );
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) Navigator.pop(context);
      } else {
        _showAlreadyTakenDialog();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isAccepting = false);
    }
  }

  void _showAlreadyTakenDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.orange),
            SizedBox(width: 8),
            Text('Already Taken'),
          ],
        ),
        content: const Text(
          'Another driver just accepted this shipment. '
          'Go back to the queue to find another one.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // close dialog
              Navigator.pop(context); // back to queue
            },
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
            if (s.agreedPrice != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1B3A6B), Color(0xFF2E75B6)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Text('Payout',
                        style: TextStyle(color: Colors.white70, fontSize: 14)),
                    Text(
                      '\$${s.agreedPrice!.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (s.cargoWeightKg != null)
                      Text('${s.cargoWeightKg} kg',
                          style: const TextStyle(color: Colors.white70)),
                  ],
                ),
              ),

            const SizedBox(height: 24),

            _SectionCard(
              title: 'Route',
              child: Column(
                children: [
                  _DetailRow(
                    icon:  Icons.circle,
                    color: const Color(0xFF4CAF50),
                    label: 'Pickup',
              value: s.pickupLocation,
                  ),
                  const Padding(
                    padding: EdgeInsets.only(left: 12),
                    child: Column(
                      children: [
                        SizedBox(height: 4),
                        _DotDivider(),
                        SizedBox(height: 4),
                      ],
                    ),
                  ),
                  _DetailRow(
                    icon:  Icons.location_on,
                    color: const Color(0xFFF44336),
                    label: 'Drop-off',
                    value: s.dropLocation,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            _SectionCard(
              title: 'Details',
              child: Column(
                children: [
                  _InfoRow(label: 'Shipment ID', value: s.id),
                  _InfoRow(label: 'Status',      value: s.status),
                  if (s.cargoWeightKg != null)
                    _InfoRow(label: 'Weight', value: '${s.cargoWeightKg} kg'),
                  if (s.agreedPrice != null)
                    _InfoRow(label: 'Price',
                        value: '\$${s.agreedPrice!.toStringAsFixed(2)}'),
                  _InfoRow(
                    label: 'Posted',
                    value: s.createdAt.toLocal().toString().substring(0, 16),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: (_accepted || _isAccepting) ? null : _handleAccept,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B3A6B),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _isAccepting
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      _accepted ? 'Accepted ✓' : 'Accept Shipment',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Supporting widgets ────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Colors.grey,
                  letterSpacing: 1.2)),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2))
              ],
            ),
            child: child,
          ),
        ],
      );
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final Color    color;
  final String   label;
  final String   value;

  const _DetailRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(fontSize: 11, color: Colors.grey)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 15)),
              ],
            ),
          ),
        ],
      );
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 110,
              child: Text(label,
                  style: const TextStyle(color: Colors.grey, fontSize: 13)),
            ),
            Expanded(
              child: Text(value,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500)),
            ),
          ],
        ),
      );
}

class _DotDivider extends StatelessWidget {
  const _DotDivider();

  @override
  Widget build(BuildContext context) => Column(
        children: List.generate(
            3,
            (_) => Container(
                  width: 2,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 1),
                  color: Colors.grey.shade300,
                )),
      );
}