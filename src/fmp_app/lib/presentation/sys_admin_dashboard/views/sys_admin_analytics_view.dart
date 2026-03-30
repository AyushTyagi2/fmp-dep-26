import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../data/datasources/analytics_remote_datasource.dart';
import '../../../data/models/analytics_models.dart';
import '../../../shared/theme/app_theme.dart';
import '../../widgets/charts/app_line_chart.dart';
import '../../widgets/charts/app_pie_chart.dart';
import '../../../app_session.dart';
import '../../../core/network/api_client.dart';

class SysAdminAnalyticsView extends StatefulWidget {
  const SysAdminAnalyticsView({Key? key}) : super(key: key);

  @override
  State<SysAdminAnalyticsView> createState() => _SysAdminAnalyticsViewState();
}

class _SysAdminAnalyticsViewState extends State<SysAdminAnalyticsView> {
  SysAdminAnalyticsModel? _data;
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
      final data = await source.getSysAdminAnalytics();
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
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text("Error: $_error"));
    }
    if (_data == null) {
      return const Center(child: Text("No data available."));
    }

    return SingleChildScrollView(
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
                      Text(m.title, style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      const SizedBox(height: 8),
                      Text(m.value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primary)),
                    ],
                  ),
                ),
              ),
            )).toList(),
          ),
          const SizedBox(height: 24),
          AppLineChart(title: 'Platform Activity (Trips per Day)', data: _data!.platformActivity),
          const SizedBox(height: 24),
          AppPieChart(title: 'Shipment Status Breakdown', data: _data!.shipmentStatusBreakdown),
        ],
      ),
    );
  }
}
