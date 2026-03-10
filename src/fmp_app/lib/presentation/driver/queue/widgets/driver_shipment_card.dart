import 'package:flutter/material.dart';
import '../../../../core/models/shipment.dart';

class DriverShipmentCard extends StatelessWidget {
  final Shipment shipment;
  final VoidCallback? onTap;

  const DriverShipmentCard({super.key, required this.shipment, this.onTap});

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (shipment.isUrgent)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.flash_on, size: 12, color: Colors.red),
                          SizedBox(width: 3),
                          Text('URGENT', style: TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2196F3).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF2196F3).withOpacity(0.3)),
                      ),
                      child: const Text('Available',
                          style: TextStyle(color: Color(0xFF2196F3), fontSize: 11, fontWeight: FontWeight.w600)),
                    ),
                  if (shipment.agreedPrice != null)
                    Text(
                      '₹${shipment.agreedPrice!.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20)),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              _LocationRow(icon: Icons.circle, iconColor: const Color(0xFF4CAF50), label: 'PICKUP', location: shipment.pickupLocation),
              Padding(
                padding: const EdgeInsets.only(left: 9),
                child: Container(width: 2, height: 18, color: const Color(0xFFBDBDBD)),
              ),
              _LocationRow(icon: Icons.location_on, iconColor: const Color(0xFFF44336), label: 'DROP-OFF', location: shipment.dropLocation),
              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.scale, size: 13, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text('${shipment.cargoWeightKg.toStringAsFixed(0)} kg', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(width: 12),
                  const Icon(Icons.category_outlined, size: 13, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(shipment.cargoType,
                        style: const TextStyle(color: Colors.grey, fontSize: 12), overflow: TextOverflow.ellipsis),
                  ),
                  const Icon(Icons.access_time, size: 13, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(_formatTime(shipment.createdAt), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1)  return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24)   return '${diff.inHours}h ago';
    return '${dt.day}/${dt.month}';
  }
}

class _LocationRow extends StatelessWidget {
  final IconData icon;
  final Color    iconColor;
  final String   label;
  final String   location;
  const _LocationRow({required this.icon, required this.iconColor, required this.label, required this.location});

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 18, color: iconColor),
      const SizedBox(width: 8),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
            Text(location, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    ],
  );
}