import 'package:flutter/material.dart';
import '../../../../core/models/shipment.dart';

class ShipmentCard extends StatelessWidget {
  final Shipment shipment;
  final VoidCallback? onTap;

  const ShipmentCard({super.key, required this.shipment, this.onTap});

  Color _statusColor(String status) => switch (status) {
    'waiting'    => const Color(0xFF2196F3),
    'accepted'   => const Color(0xFFFF9800),
    'in_transit' => const Color(0xFF9C27B0),
    'delivered'  => const Color(0xFF4CAF50),
    'cancelled'  => const Color(0xFFF44336),
    _            => const Color(0xFF9E9E9E),
  };

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              _StatusBadge(status: shipment.status, color: _statusColor(shipment.status)),
              if (shipment.isUrgent)
                const Row(children: [
                  Icon(Icons.flash_on, size: 14, color: Colors.red),
                  Text('URGENT', style: TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold)),
                ]),
              if (shipment.agreedPrice != null)
                Text('₹${shipment.agreedPrice!.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
            ]),
            const SizedBox(height: 12),
            _LocationRow(icon: Icons.circle, iconColor: const Color(0xFF4CAF50), label: 'Pickup', location: shipment.pickupLocation),
            Padding(padding: const EdgeInsets.only(left: 9), child: Container(width: 2, height: 18, color: const Color(0xFFBDBDBD))),
            _LocationRow(icon: Icons.location_on, iconColor: const Color(0xFFF44336), label: 'Drop', location: shipment.dropLocation),
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 10),
            Row(children: [
              const Icon(Icons.scale, size: 13, color: Colors.grey),
              const SizedBox(width: 4),
              Text('${shipment.cargoWeightKg.toStringAsFixed(0)} kg', style: const TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(width: 16),
              const Icon(Icons.access_time, size: 13, color: Colors.grey),
              const SizedBox(width: 4),
              Text(_formatTime(shipment.createdAt), style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ]),
          ]),
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1)  return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24)   return '${diff.inHours}h ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

class _StatusBadge extends StatelessWidget {
  final String status; final Color color;
  const _StatusBadge({required this.status, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withOpacity(0.4))),
    child: Text(status, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12)),
  );
}

class _LocationRow extends StatelessWidget {
  final IconData icon; final Color iconColor; final String label; final String location;
  const _LocationRow({required this.icon, required this.iconColor, required this.label, required this.location});

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 18, color: iconColor), const SizedBox(width: 8),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w500)),
        Text(location, style: const TextStyle(fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
      ])),
    ],
  );
}