import 'package:flutter/material.dart';
import '../../../../core/models/shipment.dart';

// --- Premium UI Constants ---
const _textColorDark = Color(0xFF0F172A);
const _textColorMuted = Color(0xFF64748B);
const _successColor = Color(0xFF10B981);
const _errorColor = Color(0xFFEF4444);
const _primaryColor = Color(0xFF3B82F6);

/// A premium shipment card shown in the queue list.
class DriverShipmentCard extends StatelessWidget {
  final Shipment shipment;
  final VoidCallback? onTap;
  final bool isLocked;

  const DriverShipmentCard({
    super.key,
    required this.shipment,
    this.onTap,
    this.isLocked = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isLocked ? const Color(0xFFF8FAFC) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isLocked ? const Color(0xFFE2E8F0) : Colors.transparent, 
          width: 1
        ),
        boxShadow: isLocked ? [] : [
          BoxShadow(
            color: Colors.black.withOpacity(0.04), 
            blurRadius: 20, 
            offset: const Offset(0, 4)
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLocked ? null : onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Badges & Price
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (isLocked)
                            const _PremiumBadge(
                              backgroundColor: Color(0xFFF1F5F9),
                              textColor: _textColorMuted,
                              icon: Icons.lock_outline_rounded,
                              label: 'OFFERED TO ANOTHER DRIVER',
                            )
                          else if (shipment.isUrgent)
                            _PremiumBadge(
                              backgroundColor: _errorColor.withOpacity(0.1),
                              borderColor: _errorColor.withOpacity(0.2),
                              textColor: _errorColor,
                              icon: Icons.local_fire_department_rounded,
                              label: 'URGENT',
                            )
                          else
                            _PremiumBadge(
                              backgroundColor: _primaryColor.withOpacity(0.1),
                              textColor: _primaryColor,
                              label: 'NEW REQUEST',
                            ),
                        ],
                      ),
                    ),
                    if (shipment.agreedPrice != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '₹${shipment.agreedPrice!.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: isLocked ? const Color(0xFF94A3B8) : _successColor,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            'Est. Payout',
                            style: TextStyle(fontSize: 10, color: isLocked ? const Color(0xFFCBD5E1) : _textColorMuted, fontWeight: FontWeight.w600),
                          )
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 20),

                // Body: Route (Pickup -> Dropoff)
                Opacity(
                  opacity: isLocked ? 0.6 : 1.0,
                  child: Stack(
                    children: [
                      // The dashed line connecting the icons
                      Positioned(
                        left: 9, // Center of the icons
                        top: 24,
                        bottom: 24,
                        child: CustomPaint(
                          size: const Size(1, double.infinity),
                          painter: _DashedLinePainter(color: const Color(0xFFCBD5E1)),
                        ),
                      ),
                      Column(
                        children: [
                          _LocationRow(
                            icon: Icons.radio_button_checked_rounded,
                            iconColor: _primaryColor,
                            label: 'PICKUP',
                            location: shipment.pickupLocation,
                          ),
                          const SizedBox(height: 16),
                          _LocationRow(
                            icon: Icons.location_on_rounded,
                            iconColor: _errorColor,
                            label: 'DROP-OFF',
                            location: shipment.dropLocation,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                
                // Footer: Metadata
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFF1F5F9))
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _MetaItem(
                        icon: Icons.scale_rounded, 
                        label: '${shipment.cargoWeightKg.toStringAsFixed(0)} kg'
                      ),
                      _MetaItem(
                        icon: Icons.inventory_2_outlined, 
                        label: shipment.cargoType,
                        isFlexible: true,
                      ),
                      _MetaItem(
                        icon: Icons.schedule_rounded, 
                        label: _formatTime(shipment.createdAt)
                      ),
                    ],
                  ),
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

// ============================================================================
// SUPPORTING WIDGETS
// ============================================================================

class _PremiumBadge extends StatelessWidget {
  final Color backgroundColor;
  final Color? borderColor;
  final Color textColor;
  final IconData? icon;
  final String label;

  const _PremiumBadge({
    required this.backgroundColor,
    this.borderColor,
    required this.textColor,
    this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(8),
      border: borderColor != null ? Border.all(color: borderColor!) : null,
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[Icon(icon, size: 12, color: textColor), const SizedBox(width: 4)],
        Text(
          label, 
          style: TextStyle(color: textColor, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5)
        ),
      ],
    ),
  );
}

class _LocationRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String location;

  const _LocationRow({
    required this.icon, 
    required this.iconColor, 
    required this.label, 
    required this.location
  });

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        padding: const EdgeInsets.all(2),
        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
        child: Icon(icon, size: 16, color: iconColor),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label, 
              style: const TextStyle(fontSize: 10, color: _textColorMuted, fontWeight: FontWeight.w800, letterSpacing: 1.0)
            ),
            const SizedBox(height: 2),
            Text(
              location, 
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _textColorDark),
              maxLines: 2, 
              overflow: TextOverflow.ellipsis
            ),
          ],
        ),
      ),
    ],
  );
}

class _MetaItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isFlexible;

  const _MetaItem({required this.icon, required this.label, this.isFlexible = false});

  @override
  Widget build(BuildContext context) {
    Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: const Color(0xFF94A3B8)),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label, 
            style: const TextStyle(color: _textColorMuted, fontSize: 13, fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );

    if (isFlexible) {
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: content,
        ),
      );
    }
    return content;
  }
}

// Custom Painter for the vertical dashed line connecting locations
class _DashedLinePainter extends CustomPainter {
  final Color color;

  _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    var max = size.height;
    var dashWidth = 4.0;
    var dashSpace = 4.0;
    double startY = 0;

    while (startY < max) {
      canvas.drawLine(Offset(0, startY), Offset(0, startY + dashWidth), paint);
      startY += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}