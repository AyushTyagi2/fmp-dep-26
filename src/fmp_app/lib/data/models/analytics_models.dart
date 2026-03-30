class TimePointModel {
  final String dateStr;
  final double value;

  TimePointModel({required this.dateStr, required this.value});

  factory TimePointModel.fromJson(Map<String, dynamic> json) {
    return TimePointModel(
      dateStr: json['dateStr'] ?? '',
      value: (json['value'] ?? 0).toDouble(),
    );
  }
}

class PieSliceModel {
  final String label;
  final int count;

  PieSliceModel({required this.label, required this.count});

  factory PieSliceModel.fromJson(Map<String, dynamic> json) {
    return PieSliceModel(
      label: json['label'] ?? '',
      count: json['count'] ?? 0,
    );
  }
}

class MetricCardModel {
  final String title;
  final String value;
  final String? subtitle;

  MetricCardModel({required this.title, required this.value, this.subtitle});

  factory MetricCardModel.fromJson(Map<String, dynamic> json) {
    return MetricCardModel(
      title: json['title'] ?? '',
      value: json['value'] ?? '',
      subtitle: json['subtitle'],
    );
  }
}

class SysAdminAnalyticsModel {
  final List<TimePointModel> platformActivity;
  final List<PieSliceModel> shipmentStatusBreakdown;
  final List<MetricCardModel> keyMetrics;

  SysAdminAnalyticsModel({
    required this.platformActivity,
    required this.shipmentStatusBreakdown,
    required this.keyMetrics,
  });

  factory SysAdminAnalyticsModel.fromJson(Map<String, dynamic> json) {
    return SysAdminAnalyticsModel(
      platformActivity: (json['platformActivity'] as List?)?.map((e) => TimePointModel.fromJson(e)).toList() ?? [],
      shipmentStatusBreakdown: (json['shipmentStatusBreakdown'] as List?)?.map((e) => PieSliceModel.fromJson(e)).toList() ?? [],
      keyMetrics: (json['keyMetrics'] as List?)?.map((e) => MetricCardModel.fromJson(e)).toList() ?? [],
    );
  }
}

class SenderAnalyticsModel {
  final List<TimePointModel> logisticsSpend;
  final List<PieSliceModel> shipmentStatusBreakdown;
  final List<MetricCardModel> keyMetrics;

  SenderAnalyticsModel({
    required this.logisticsSpend,
    required this.shipmentStatusBreakdown,
    required this.keyMetrics,
  });

  factory SenderAnalyticsModel.fromJson(Map<String, dynamic> json) {
    return SenderAnalyticsModel(
      logisticsSpend: (json['logisticsSpend'] as List?)?.map((e) => TimePointModel.fromJson(e)).toList() ?? [],
      shipmentStatusBreakdown: (json['shipmentStatusBreakdown'] as List?)?.map((e) => PieSliceModel.fromJson(e)).toList() ?? [],
      keyMetrics: (json['keyMetrics'] as List?)?.map((e) => MetricCardModel.fromJson(e)).toList() ?? [],
    );
  }
}

class DriverAnalyticsModel {
  final List<TimePointModel> dailyEarnings;
  final List<MetricCardModel> keyMetrics;

  DriverAnalyticsModel({
    required this.dailyEarnings,
    required this.keyMetrics,
  });

  factory DriverAnalyticsModel.fromJson(Map<String, dynamic> json) {
    return DriverAnalyticsModel(
      dailyEarnings: (json['dailyEarnings'] as List?)?.map((e) => TimePointModel.fromJson(e)).toList() ?? [],
      keyMetrics: (json['keyMetrics'] as List?)?.map((e) => MetricCardModel.fromJson(e)).toList() ?? [],
    );
  }
}

class UnionAnalyticsModel {
  final List<TimePointModel> dailyTripsManaged;
  final List<PieSliceModel> fleetStatusBreakdown;
  final List<MetricCardModel> keyMetrics;

  UnionAnalyticsModel({
    required this.dailyTripsManaged,
    required this.fleetStatusBreakdown,
    required this.keyMetrics,
  });

  factory UnionAnalyticsModel.fromJson(Map<String, dynamic> json) {
    return UnionAnalyticsModel(
      dailyTripsManaged: (json['dailyTripsManaged'] as List?)?.map((e) => TimePointModel.fromJson(e)).toList() ?? [],
      fleetStatusBreakdown: (json['fleetStatusBreakdown'] as List?)?.map((e) => PieSliceModel.fromJson(e)).toList() ?? [],
      keyMetrics: (json['keyMetrics'] as List?)?.map((e) => MetricCardModel.fromJson(e)).toList() ?? [],
    );
  }
}
