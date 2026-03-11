import 'package:flutter/material.dart';
import '../../../../core/models/shipment.dart';

/// A shipment card shown in the queue list.
///
/// [isLocked] = true when the driver already has an active offer.
///   → card is greyed out and non-tappable (read-only)
///
/// [isLocked] = false (default) → normal tappable card.
class DriverShipmentCard extends StatelessWidget {
  final Shipment      shipment;
  final VoidCallback? onTap;
  final bool          isLocked;

  const DriverShipmentCard({
    super.key,
    required this.shipment,
    this.onTap,
    this.isLocked = false,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isLocked ? 0.45 : 1.0,
      child: Card(
        margin    : const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        elevation : isLocked ? 0 : 2,
        color     : isLocked ? Colors.grey.shade100 : Colors.white,
        shape     : RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child     : InkWell(
          onTap         : isLocked ? null : onTap,
          borderRadius  : BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Status badge
                    if (isLocked)
                      _Badge(
                        color     : Colors.grey.shade200,
                        textColor : Colors.grey,
                        label     : '🔒 Offered to another driver',
                      )
                    else if (shipment.isUrgent)
                      _Badge(
                        color     : Colors.red.shade50,
                        borderColor: Colors.red.shade200,
                        textColor : Colors.red,
                        icon      : Icons.flash_on,
                        label     : 'URGENT',
                      )
                    else
                      _Badge(
                        color     : const Color(0xFF2196F3).withOpacity(0.1),
                        borderColor: const Color(0xFF2196F3).withOpacity(0.3),
                        textColor : const Color(0xFF2196F3),
                        label     : 'Available',
                      ),

                    // Price
                    if (shipment.agreedPrice != null)
                      Text(
                        '₹${shipment.agreedPrice!.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize    : 18,
                          fontWeight  : FontWeight.bold,
                          color       : isLocked ? Colors.grey : const Color(0xFF1B5E20),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                _LocationRow(
                  icon      : Icons.circle,
                  iconColor : isLocked ? Colors.grey : const Color(0xFF4CAF50),
                  label     : 'PICKUP',
                  location  : shipment.pickupLocation,
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 9),
                  child: Container(width: 2, height: 16, color: const Color(0xFFBDBDBD)),
                ),
                _LocationRow(
                  icon      : Icons.location_on,
                  iconColor : isLocked ? Colors.grey : const Color(0xFFF44336),
                  label     : 'DROP-OFF',
                  location  : shipment.dropLocation,
                ),
                const SizedBox(height: 10),
                const Divider(height: 1),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.scale, size: 12, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text('${shipment.cargoWeightKg.toStringAsFixed(0)} kg',
                        style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    const SizedBox(width: 10),
                    const Icon(Icons.category_outlined, size: 12, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(shipment.cargoType,
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                          overflow: TextOverflow.ellipsis),
                    ),
                    const Icon(Icons.access_time, size: 12, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(_formatTime(shipment.createdAt),
                        style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ],
            ),
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

class _Badge extends StatelessWidget {
  final Color    color;
  final Color?   borderColor;
  final Color    textColor;
  final IconData? icon;
  final String   label;
  const _Badge({required this.color, this.borderColor, required this.textColor, this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color       : color,
      borderRadius: BorderRadius.circular(20),
      border      : borderColor != null ? Border.all(color: borderColor!) : null,
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[Icon(icon, size: 11, color: textColor), const SizedBox(width: 3)],
        Text(label, style: TextStyle(color: textColor, fontSize: 10, fontWeight: FontWeight.w600)),
      ],
    ),
  );
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
      Icon(icon, size: 16, color: iconColor),
      const SizedBox(width: 8),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey,
                fontWeight: FontWeight.w600, letterSpacing: 0.5)),
            Text(location, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    ],
  );
}