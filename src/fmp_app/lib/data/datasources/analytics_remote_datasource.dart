import 'package:dio/dio.dart';
import '../models/analytics_models.dart';

class AnalyticsRemoteDataSource {
  final Dio dio;

  AnalyticsRemoteDataSource(this.dio);

  Future<SysAdminAnalyticsModel> getSysAdminAnalytics() async {
    final response = await dio.get('/api/analytics/sysadmin');
    return SysAdminAnalyticsModel.fromJson(response.data);
  }

  Future<SenderAnalyticsModel> getSenderAnalytics() async {
    final response = await dio.get('/api/analytics/sender');
    return SenderAnalyticsModel.fromJson(response.data);
  }

  Future<DriverAnalyticsModel> getDriverAnalytics() async {
    final response = await dio.get('/api/analytics/driver');
    return DriverAnalyticsModel.fromJson(response.data);
  }

  Future<UnionAnalyticsModel> getUnionAnalytics() async {
    final response = await dio.get('/api/analytics/union');
    return UnionAnalyticsModel.fromJson(response.data);
  }
}
