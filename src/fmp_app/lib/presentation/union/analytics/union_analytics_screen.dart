import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../../data/datasources/analytics_remote_datasource.dart';
import '../../../../data/models/analytics_models.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../widgets/charts/app_line_chart.dart';
import '../../widgets/charts/app_pie_chart.dart';
import '../../../../app_session.dart';
import '../../../../core/network/api_client.dart';

class UnionAnalyticsScreen extends StatefulWidget {
  const UnionAnalyticsScreen({Key? key}) : super(key: key);

  @override
  State<UnionAnalyticsScreen> createState() => _UnionAnalyticsScreenState();
}

class _UnionAnalyticsScreenState extends State<UnionAnalyticsScreen> {
  UnionAnalyticsModel? _data;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final source = AnalyticsRemoteDataSource(ApiClient().dio);
      final data = await source.getUnionAnalytics();
      if (mounted) {
        setState(() {
          _data = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_error != null) return Scaffold(body: Center(child: Text("Error: $_error")));
    if (_data == null) return const Scaffold(body: Center(child: Text("No data available.")));

    return Scaffold(
      appBar: AppBar(title: const Text('Fleet Analytics')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: _data!.keyMetrics.map((m) => Expanded(
                child: Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Text(m.title, style: TextStyle(color: AppColors.textSecondary, fontSize: 12), textAlign: TextAlign.center),
                        const SizedBox(height: 8),
                        Text(m.value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary), textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                ),
              )).toList(),
            ),
            const SizedBox(height: 24),
            AppLineChart(title: 'Trips Managed (Last 7 Days)', data: _data!.dailyTripsManaged),
            const SizedBox(height: 24),
            AppPieChart(title: 'Fleet Status', data: _data!.fleetStatusBreakdown),
          ],
        ),
      ),
    );
  }
}
