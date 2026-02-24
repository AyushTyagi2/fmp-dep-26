class FleetDashboard {
  final String fleetOwnerId;
  final String fleetOwnerName;
  final int activeDrivers;
  final int activeTrips;
  final int vehicleIssues;
  final int tripsWithIssues;

  FleetDashboard({
    required this.fleetOwnerId,
    required this.fleetOwnerName,
    required this.activeDrivers,
    required this.activeTrips,
    required this.vehicleIssues,
    required this.tripsWithIssues,
  });

  factory FleetDashboard.fromJson(Map<String, dynamic> json) {
    return FleetDashboard(
      fleetOwnerId: (json['fleetOwnerId'] ?? json['fleet_owner_id'] ?? '').toString(),
      fleetOwnerName: (json['fleetOwnerName'] ?? json['fleet_owner_name'] ?? json['businessName'] ?? '').toString(),
      activeDrivers: (json['activeDrivers'] ?? json['active_drivers'] ?? 0) is int ? (json['activeDrivers'] ?? json['active_drivers'] ?? 0) : int.tryParse((json['activeDrivers'] ?? json['active_drivers'] ?? '0').toString()) ?? 0,
      activeTrips: (json['activeTrips'] ?? json['active_trips'] ?? 0) is int ? (json['activeTrips'] ?? json['active_trips'] ?? 0) : int.tryParse((json['activeTrips'] ?? json['active_trips'] ?? '0').toString()) ?? 0,
      vehicleIssues: (json['vehicleIssues'] ?? json['vehicle_issues'] ?? 0) is int ? (json['vehicleIssues'] ?? json['vehicle_issues'] ?? 0) : int.tryParse((json['vehicleIssues'] ?? json['vehicle_issues'] ?? '0').toString()) ?? 0,
      tripsWithIssues: (json['tripsWithIssues'] ?? json['trips_with_issues'] ?? 0) is int ? (json['tripsWithIssues'] ?? json['trips_with_issues'] ?? 0) : int.tryParse((json['tripsWithIssues'] ?? json['trips_with_issues'] ?? '0').toString()) ?? 0,
    );
  }
}
