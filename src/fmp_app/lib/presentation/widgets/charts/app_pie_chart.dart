import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../data/models/analytics_models.dart';

class AppPieChart extends StatelessWidget {
  final List<PieSliceModel> data;
  final String title;

  const AppPieChart({Key? key, required this.data, required this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    List<Color> colors = [
      theme.colorScheme.primary,
      theme.colorScheme.secondary,
      theme.colorScheme.tertiary,
      theme.colorScheme.error,
      Colors.green,
      Colors.orange,
    ];

    int total = data.fold(0, (sum, item) => sum + item.count);
    if (total == 0) total = 1;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  sections: data.asMap().entries.map((entry) {
                    final index = entry.key;
                    final slice = entry.value;
                    final pct = (slice.count / total) * 100;
                    return PieChartSectionData(
                      color: colors[index % colors.length],
                      value: slice.count.toDouble(),
                      title: '${pct.toStringAsFixed(1)}%',
                      radius: 50,
                      titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: data.asMap().entries.map((entry) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 12, height: 12, color: colors[entry.key % colors.length]),
                    const SizedBox(width: 4),
                    Text('${entry.value.label} (${entry.value.count})', style: const TextStyle(fontSize: 12)),
                  ],
                );
              }).toList(),
            )
          ],
        ),
      ),
    );
  }
}
