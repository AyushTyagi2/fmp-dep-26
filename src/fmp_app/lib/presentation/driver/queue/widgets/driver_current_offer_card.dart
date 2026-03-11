import 'package:flutter/material.dart';
import '../../../../core/network/api_shipment_queue.dart';

/// The pinned "Your Current Offer" card shown at the top of the driver queue.
///
/// Shows:
///  • Shipment number, route, price
///  • Live countdown timer
///  • Accept / Pass buttons
///
/// When no active offer: shows a status banner (waiting, claimed, etc.)
class DriverCurrentOfferCard extends StatelessWidget {
  final QueueSlot   slot;
  final Duration    timeRemaining;
  final bool        isBusy;
  final VoidCallback onAccept;
  final VoidCallback onPass;

  const DriverCurrentOfferCard({
    super.key,
    required this.slot,
    required this.timeRemaining,
    required this.isBusy,
    required this.onAccept,
    required this.onPass,
  });

  @override
  Widget build(BuildContext context) {
    // ── Claimed already ────────────────────────────────────────────────────
    if (slot.hasClaimed) {
      return _StatusBanner(
        color: Colors.green.shade700,
        icon : Icons.check_circle,
        text : 'You have claimed a shipment in this session.',
      );
    }

    // ── Active offer ───────────────────────────────────────────────────────
    if (slot.hasActiveOffer) {
      final offer = slot.currentOffer!;
      final mins  = timeRemaining.inMinutes;
      final secs  = timeRemaining.inSeconds % 60;
      final isLow = timeRemaining.inSeconds <= 60;

      return Container(
        margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
        decoration: BoxDecoration(
          color       : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border      : Border.all(
            color: isLow ? Colors.red.shade400 : const Color(0xFF1B3A6B),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: (isLow ? Colors.red : const Color(0xFF1B3A6B)).withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header bar
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isLow ? Colors.red.shade600 : const Color(0xFF1B3A6B),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              ),
              child: Row(
                children: [
                  Icon(Icons.local_shipping, color: Colors.white, size: 16),
                  const SizedBox(width: 8),
                  const Text('YOUR CURRENT OFFER',
                      style: TextStyle(color: Colors.white, fontSize: 11,
                          fontWeight: FontWeight.bold, letterSpacing: 1)),
                  const Spacer(),
                  // Countdown timer
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.timer, color: Colors.white, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '${mins}m ${secs.toString().padLeft(2, '0')}s',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Shipment details
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(offer.shipmentNumber,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15,
                              color: Color(0xFF1B3A6B))),
                      if (offer.agreedPrice != null)
                        Text('₹${offer.agreedPrice!.toStringAsFixed(0)}',
                            style: const TextStyle(
                                fontSize: 22, fontWeight: FontWeight.bold,
                                color: Color(0xFF1B5E20))),
                    ],
                  ),
                  if (offer.isUrgent)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color : Colors.red.shade50,
                          border: Border.all(color: Colors.red.shade200),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.flash_on, size: 11, color: Colors.red),
                            SizedBox(width: 3),
                            Text('URGENT',
                                style: TextStyle(fontSize: 10, color: Colors.red,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  _RouteRow(pickup: offer.pickupLocation, drop: offer.dropLocation),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.scale, size: 12, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text('${offer.cargoWeightKg.toStringAsFixed(0)} kg',
                          style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      const SizedBox(width: 12),
                      const Icon(Icons.category_outlined, size: 12, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(offer.cargoType,
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Action buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: isBusy ? null : onPass,
                      icon : const Icon(Icons.skip_next),
                      label: const Text('Pass'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange.shade700,
                        side: BorderSide(color: Colors.orange.shade300),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: isBusy ? null : onAccept,
                      icon : isBusy
                          ? const SizedBox(width: 16, height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.check_circle_outline),
                      label: const Text('Accept'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1B3A6B),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // ── Waiting for an offer ───────────────────────────────────────────────
    return _StatusBanner(
      color: Colors.blueGrey.shade700,
      icon : Icons.hourglass_top_rounded,
      text : 'You are in the queue (position #${slot.position}). '
             'Waiting for a shipment to be assigned…',
    );
  }
}

class _RouteRow extends StatelessWidget {
  final String pickup;
  final String drop;
  const _RouteRow({required this.pickup, required this.drop});

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Row(
        children: [
          const Icon(Icons.circle, size: 10, color: Color(0xFF4CAF50)),
          const SizedBox(width: 8),
          const Text('PICKUP ', style: TextStyle(fontSize: 9, color: Colors.grey,
              fontWeight: FontWeight.w600, letterSpacing: 0.5)),
          Expanded(
            child: Text(pickup,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
      Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Container(width: 2, height: 14, color: const Color(0xFFBDBDBD)),
      ),
      Row(
        children: [
          const Icon(Icons.location_on, size: 14, color: Color(0xFFF44336)),
          const SizedBox(width: 4),
          const Text('DROP ', style: TextStyle(fontSize: 9, color: Colors.grey,
              fontWeight: FontWeight.w600, letterSpacing: 0.5)),
          Expanded(
            child: Text(drop,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    ],
  );
}

class _StatusBanner extends StatelessWidget {
  final Color    color;
  final IconData icon;
  final String   text;
  const _StatusBanner({required this.color, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    color: color,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: Row(
      children: [
        Icon(icon, color: Colors.white, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text,
              style: const TextStyle(color: Colors.white, fontSize: 13)),
        ),
      ],
    ),
  );
}