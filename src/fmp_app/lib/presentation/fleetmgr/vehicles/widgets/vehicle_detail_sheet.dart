import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/models/vehicle.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../fleet_state.dart';

class VehicleDetailSheet extends StatelessWidget {
  final Vehicle vehicle;
  final String phone;

  const VehicleDetailSheet(
      {super.key, required this.vehicle, required this.phone});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(vehicle.registrationNumber,
                  style: AppTextStyles.headingMd),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              )
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _buildDetailRow('Vehicle Type', vehicle.vehicleType.toUpperCase()),
          _buildDetailRow('Capacity', '${vehicle.capacityTons ?? 0} Tons'),
          _buildDetailRow(
              'Max Load', '${vehicle.maxLoadWeightKg ?? 0} Kg'),
          _buildDetailRow('Status', vehicle.status),
          _buildDetailRow('Availability', vehicle.availabilityStatus),
          _buildDetailRow(
              'Current Driver', vehicle.currentDriverName ?? 'Unassigned'),
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: () => _handleRemove(context),
              child: const Text('Remove this vehicle'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500)),
          Text(value,
              style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Future<void> _handleRemove(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Vehicle?'),
        content: Text(
            'Are you sure you want to remove ${vehicle.registrationNumber}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      try {
        // Uses dropSingle — never touches selection state
        await context.read<FleetState>().dropSingle(phone, vehicle.id);
        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Vehicle removed successfully')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }
}