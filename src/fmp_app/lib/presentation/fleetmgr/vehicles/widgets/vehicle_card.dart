import 'package:flutter/material.dart';
import '../../../../core/models/vehicle.dart';
import '../../../../shared/theme/app_theme.dart';

class VehicleCard extends StatelessWidget {
  final Vehicle vehicle;
  final bool isDropMode;
  final bool isSelected;
  final VoidCallback onTap;

  const VehicleCard({
    super.key,
    required this.vehicle,
    this.isDropMode = false,
    this.isSelected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: isSelected ? AppColors.error : AppColors.border,
            width: 2,
          ),
          boxShadow: AppShadows.card,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isDropMode) ...[
              IgnorePointer(
                child: Checkbox(
                  value: isSelected,
                  onChanged: (bool? value) {},
                  activeColor: AppColors.error,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        vehicle.registrationNumber,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getTypeColor(vehicle.vehicleType).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Text(
                          vehicle.vehicleType.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: _getTypeColor(vehicle.vehicleType),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.fitness_center, size: 14, color: AppColors.textHint),
                      const SizedBox(width: 4),
                      Text(
                        'Capacity: ${vehicle.capacityTons ?? 0}t',
                        style: AppTextStyles.bodySm,
                      ),
                      const SizedBox(width: 16),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _getAvailabilityColor(vehicle.availabilityStatus),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        vehicle.availabilityStatus.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: _getAvailabilityColor(vehicle.availabilityStatus),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.person, size: 14, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        vehicle.currentDriverName ?? 'Unassigned',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: vehicle.currentDriverName != null
                              ? AppColors.textPrimary
                              : AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'truck':
        return Colors.blue;
      case 'trailer':
        return Colors.deepPurple;
      case 'tanker':
        return Colors.teal;
      default:
        return AppColors.primary;
    }
  }

  Color _getAvailabilityColor(String status) {
    switch (status.toLowerCase()) {
      case 'available':
        return AppColors.success;
      case 'on-trip':
        return Colors.orange;
      case 'maintenance':
        return AppColors.error;
      default:
        return AppColors.textHint;
    }
  }
}