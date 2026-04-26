import 'package:flutter/material.dart';
import '../../../core/network/api_shipment_queue.dart';
import '../../../shared/theme/app_theme.dart';

class CreateQueueEventScreen extends StatefulWidget {
  final ShipmentApiService api;
  const CreateQueueEventScreen({super.key, required this.api});

  @override
  State<CreateQueueEventScreen> createState() => _CreateQueueEventScreenState();
}

class _CreateQueueEventScreenState extends State<CreateQueueEventScreen> {
  double  _durationHours = 2.0;
  int     _windowMinutes = 2;
  bool    _submitting    = false;
  String? _error;
  String  _selectedRule  = 'highest_trips';

  String _fmtDuration(double h) {
    if (h < 1) return '${(h * 60).round()} min';
    final int hrs  = h.floor();
    final int mins = ((h - hrs) * 60).round();
    if (mins == 0) return '$hrs hr${hrs > 1 ? 's' : ''}';
    return '$hrs hr $mins min';
  }

  String _fmtEndTime(double h) {
    final end = DateTime.now().add(Duration(minutes: (h * 60).round()));
    final hh  = end.hour.toString().padLeft(2, '0');
    final mm  = end.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  bool get _isConflictError {
    final e = _error ?? '';
    return e.toLowerCase().contains('already active') ||
        e.toLowerCase().contains('already exists') ||
        e.toLowerCase().contains('conflict');
  }

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() { _submitting = true; _error = null; });
    try {
      await widget.api.createQueueEvent(
        durationHours : _durationHours,
        windowSeconds : _windowMinutes * 60,
        priorityRule  : _selectedRule,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('New Queue Session'),
        leading: const BackButton(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            _PreviewCard(
              durationLabel: _fmtDuration(_durationHours),
              endTime      : _fmtEndTime(_durationHours),
              windowMinutes: _windowMinutes,
            ),
            const SizedBox(height: 28),

            _SliderSection(
              icon     : Icons.timer_outlined,
              label    : 'Queue Duration',
              valueText: _fmtDuration(_durationHours),
              minLabel : '30 min',
              maxLabel : '12 hrs',
              value    : _durationHours,
              min      : 0.5,
              max      : 12.0,
              divisions: 23,
              onChanged: (v) => setState(() => _durationHours = v),
            ),
            const SizedBox(height: 28),

            _SliderSection(
              icon     : Icons.hourglass_bottom_rounded,
              label    : 'Driver Window',
              valueText: '$_windowMinutes min',
              minLabel : '1 min',
              maxLabel : '30 min',
              value    : _windowMinutes.toDouble(),
              min      : 1,
              max      : 30,
              divisions: 29,
              onChanged: (v) => setState(() => _windowMinutes = v.round()),
            ),
            const SizedBox(height: 28),

            _RuleSection(
              selectedRule: _selectedRule,
              onChanged: (v) => setState(() => _selectedRule = v!),
            ),
            const SizedBox(height: 32),

            if (_error != null) ...[
              _isConflictError
                  ? _ConflictBanner(onGoBack: () => Navigator.of(context).pop(false))
                  : _ErrorBanner(message: _error!),
              const SizedBox(height: 20),
            ],

            SizedBox(
              width : double.infinity,
              height: 52,
              child : ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textOnPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  elevation: 0,
                ),
                child: _submitting
                    ? const SizedBox(
                        width : 20, height: 20,
                        child : CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.white),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.sensors_rounded, size: 18),
                          SizedBox(width: 8),
                          Text('Create & Go Live',
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.2)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ── Preview card ──────────────────────────────────────────────────────────────

class _PreviewCard extends StatelessWidget {
  final String durationLabel;
  final String endTime;
  final int    windowMinutes;

  const _PreviewCard({
    required this.durationLabel,
    required this.endTime,
    required this.windowMinutes,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding   : const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color       : AppColors.primaryLight,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      border      : Border.all(color: AppColors.primary.withOpacity(0.15)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Queue will run for $durationLabel, ending ~$endTime. '
            'Each driver gets a $windowMinutes-min window per shipment.',
            style: const TextStyle(
              fontSize  : 13,
              color     : AppColors.primary,
              height    : 1.5,
            ),
          ),
        ),
      ],
    ),
  );
}

// ── Slider section ────────────────────────────────────────────────────────────

class _SliderSection extends StatelessWidget {
  final IconData             icon;
  final String               label;
  final String               valueText;
  final String               minLabel;
  final String               maxLabel;
  final double               value;
  final double               min;
  final double               max;
  final int                  divisions;
  final ValueChanged<double> onChanged;

  const _SliderSection({
    required this.icon,
    required this.label,
    required this.valueText,
    required this.minLabel,
    required this.maxLabel,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(
                fontSize  : 13,
                fontWeight: FontWeight.w600,
                color     : AppColors.textSecondary,
              )),
          const Spacer(),
          Container(
            padding   : const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color       : AppColors.primaryLight,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Text(valueText,
                style: const TextStyle(
                  fontSize  : 13,
                  fontWeight: FontWeight.w700,
                  color     : AppColors.primary,
                )),
          ),
        ],
      ),
      const SizedBox(height: 8),
      SliderTheme(
        data: SliderTheme.of(context).copyWith(
          activeTrackColor  : AppColors.primary,
          inactiveTrackColor: AppColors.border,
          thumbColor        : AppColors.primary,
          overlayColor      : AppColors.primary.withOpacity(0.12),
          trackHeight       : 4,
          thumbShape        : const RoundSliderThumbShape(enabledThumbRadius: 10),
          overlayShape      : const RoundSliderOverlayShape(overlayRadius: 20),
          trackShape        : const RoundedRectSliderTrackShape(),
          tickMarkShape     : SliderTickMarkShape.noTickMark,
        ),
        child: Slider(
          value    : value,
          min      : min,
          max      : max,
          divisions: divisions,
          onChanged: onChanged,
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(minLabel,
                style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
            Text(maxLabel,
                style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
          ],
        ),
      ),
    ],
  );
}

// ── Conflict banner ───────────────────────────────────────────────────────────

class _ConflictBanner extends StatelessWidget {
  final VoidCallback onGoBack;
  const _ConflictBanner({required this.onGoBack});

  @override
  Widget build(BuildContext context) => Container(
    padding   : const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color       : const Color(0xFFFFF8E1),
      borderRadius: BorderRadius.circular(AppRadius.md),
      border      : Border.all(color: const Color(0xFFF59E0B).withOpacity(0.4)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Icon(Icons.warning_amber_rounded, size: 18, color: Color(0xFFD97706)),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'A queue session is already active',
                style: TextStyle(
                  fontSize  : 14,
                  fontWeight: FontWeight.w700,
                  color     : Color(0xFF92400E),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'Only one live queue can run at a time. '
          'Close the current session before creating a new one.',
          style: TextStyle(fontSize: 13, color: Color(0xFF92400E), height: 1.4),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width : double.infinity,
          height: 40,
          child : OutlinedButton.icon(
            onPressed: onGoBack,
            icon : const Icon(Icons.arrow_back_rounded, size: 16),
            label: const Text('Go Back to Events'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFD97706),
              side           : const BorderSide(color: Color(0xFFF59E0B)),
              shape          : RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

// ── Error banner ──────────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) => Container(
    padding   : const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color       : AppColors.errorLight,
      borderRadius: BorderRadius.circular(AppRadius.md),
    ),
    child: Row(
      children: [
        const Icon(Icons.error_outline_rounded, size: 16, color: AppColors.error),
        const SizedBox(width: 8),
        Expanded(
          child: Text(message,
              style: const TextStyle(fontSize: 13, color: AppColors.error)),
        ),
      ],
    ),
  );
}

// ── Rule section ──────────────────────────────────────────────────────────────

class _RuleSection extends StatelessWidget {
  final String selectedRule;
  final ValueChanged<String?> onChanged;

  const _RuleSection({
    required this.selectedRule,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          const Icon(Icons.rule_rounded, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          const Text('Priority Assignment Rule',
              style: TextStyle(
                fontSize  : 13,
                fontWeight: FontWeight.w600,
                color     : AppColors.textSecondary,
              )),
        ],
      ),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.border),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: selectedRule,
            isExpanded: true,
            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
            onChanged: onChanged,
            items: const [
              DropdownMenuItem(
                value: 'highest_trips',
                child: Text('Highest Trips First (Default)'),
              ),
              DropdownMenuItem(
                value: 'youngest_drivers',
                child: Text('Younger Drivers First'),
              ),
              DropdownMenuItem(
                value: 'least_recently_active',
                child: Text('Least Recently Active'),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}