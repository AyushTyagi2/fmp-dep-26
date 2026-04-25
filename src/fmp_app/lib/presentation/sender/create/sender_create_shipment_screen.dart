import 'package:flutter/material.dart';
import 'widgets/cargo.dart';
import 'widgets/date.dart';
import 'widgets/insurance.dart';
import 'widgets/pricing.dart';
import '../models/shipment_draft.dart';
import '../../../data/datasources/shipment_remote_datasource.dart';
import '../../../data/repositories/shipment_repository.dart';
import '../../../data/models/shipment/create_shipment_request.dart';
import '../../../core/network/api_client.dart';
import 'package:dio/dio.dart';
import 'package:fmp_app/app_session.dart';
import '../../../shared/theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SENDER CREATE SHIPMENT — Logic unchanged, premium UI applied
// ─────────────────────────────────────────────────────────────────────────────

class SenderCreateShipmentScreen extends StatefulWidget {
  const SenderCreateShipmentScreen({super.key});

  @override
  State<SenderCreateShipmentScreen> createState() =>
      _SenderCreateShipmentScreenState();
}

class _SenderCreateShipmentScreenState
    extends State<SenderCreateShipmentScreen> {
  final ShipmentDraft draft = ShipmentDraft();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool isLoading = false;
  int _step = 0; // 0=Cargo, 1=Scheduling, 2=Compliance, 3=Pricing

  static const _steps = ['Cargo', 'Schedule', 'Handling', 'Pricing'];

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => isLoading = true);
    try {
      final senderPhone = AppSession.email;
      if (senderPhone == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Session expired. Please login again.')),
        );
        return;
      }
      final request = draft.toRequest(senderPhone);
      print('REQUEST BODY: ${request.toJson()}');
      final apiClient = ApiClient();
      final remote = ShipmentRemoteDataSource(apiClient.dio);
      final repository = ShipmentRepository(remote);
      await repository.createShipment(request);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Shipment created successfully ✓'),
          backgroundColor: AppColors.success,
        ),
      );
      setState(() => _step = 0);
    } catch (e) {
      print('Error submitting shipment: $e');
      if (e is DioException) {
        print('STATUS: ${e.response?.statusCode}');
        print('DATA: ${e.response?.data}');
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to create shipment. Please try again.'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Create Shipment'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: _StepIndicator(currentStep: _step, steps: _steps),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _buildCurrentStep(),
              ),
              const SizedBox(height: AppSpacing.lg),
              _buildNavButtons(),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    return switch (_step) {
      0 => _SectionCard(
          key: const ValueKey(0),
          title: 'Cargo Details',
          icon: Icons.inventory_2_rounded,
          child: CargoDetailsSection(draft: draft),
        ),
      1 => _SectionCard(
          key: const ValueKey(1),
          title: 'Pickup & Delivery',
          icon: Icons.calendar_today_rounded,
          child: PickupDeliverySection(draft: draft),
        ),
      2 => _SectionCard(
          key: const ValueKey(2),
          title: 'Handling & Compliance',
          icon: Icons.shield_rounded,
          child: HandlingComplianceSection(draft: draft),
        ),
      _ => _SectionCard(
          key: const ValueKey(3),
          title: 'Financial & Pricing',
          icon: Icons.payments_rounded,
          child: PricingSection(draft: draft),
        ),
    };
  }

  Widget _buildNavButtons() {
    final isLast = _step == _steps.length - 1;
    return Row(
      children: [
        if (_step > 0)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => setState(() => _step--),
              icon: const Icon(Icons.arrow_back_rounded, size: 18),
              label: const Text('Back'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 50),
              ),
            ),
          ),
        if (_step > 0) const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed: isLoading
                ? null
                : () {
                    if (isLast) {
                      _submit();
                    } else {
                      setState(() => _step++);
                    }
                  },
            icon: isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : Icon(
                    isLast
                        ? Icons.check_circle_rounded
                        : Icons.arrow_forward_rounded,
                    size: 18,
                  ),
            label: Text(isLast ? 'Submit Shipment' : 'Continue'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(0, 50),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Step Indicator ───────────────────────────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  final int currentStep;
  final List<String> steps;
  const _StepIndicator({required this.currentStep, required this.steps});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: List.generate(steps.length * 2 - 1, (i) {
          if (i.isOdd) {
            final done = (i ~/ 2) < currentStep;
            return Expanded(
              child: Container(
                height: 2,
                color: done ? AppColors.primary : AppColors.border,
              ),
            );
          }
          final si = i ~/ 2;
          final done = si < currentStep;
          final active = si == currentStep;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done || active ? AppColors.primary : AppColors.border,
                ),
                child: done
                    ? const Icon(Icons.check_rounded,
                        color: Colors.white, size: 16)
                    : Center(
                        child: Text(
                          '${si + 1}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: active
                                ? Colors.white
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: 3),
              Text(
                steps[si],
                style: TextStyle(
                  fontSize: 9,
                  fontWeight:
                      active ? FontWeight.w700 : FontWeight.w400,
                  color: active ? AppColors.primary : AppColors.textHint,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

// ─── Section Card wrapper ─────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  const _SectionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              0,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 18),
                ),
                const SizedBox(width: 12),
                Text(title, style: AppTextStyles.headingSm),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              AppSpacing.md,
            ),
            child: child,
          ),
        ],
      ),
    );
  }
}
