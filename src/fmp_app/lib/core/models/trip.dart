// lib/core/models/trip.dart

class Trip {
  final String tripId;
  final String tripNumber;
  final String currentStatus;

  // Schedule
  final DateTime? plannedStartTime;
  final DateTime? actualStartTime;
  final double? estimatedDistanceKm;

  // Vehicle & Driver
  final String vehicleRegistrationNumber;
  final String driverName;

  // Route
  final String pickupCity;
  final String dropCity;

  // Cargo
  final String cargoType;
  final double? cargoWeightKg;

  const Trip({
    required this.tripId,
    required this.tripNumber,
    required this.currentStatus,
    this.plannedStartTime,
    this.actualStartTime,
    this.estimatedDistanceKm,
    required this.vehicleRegistrationNumber,
    required this.driverName,
    required this.pickupCity,
    required this.dropCity,
    required this.cargoType,
    this.cargoWeightKg,
  });

  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      tripId: json['tripId'] as String? ?? '',
      tripNumber: json['tripNumber'] as String? ?? '',
      currentStatus: json['currentStatus'] as String? ?? 'created',
      plannedStartTime: json['plannedStartTime'] != null
          ? DateTime.tryParse(json['plannedStartTime'] as String)
          : null,
      actualStartTime: json['actualStartTime'] != null
          ? DateTime.tryParse(json['actualStartTime'] as String)
          : null,
      estimatedDistanceKm: (json['estimatedDistanceKm'] as num?)?.toDouble(),
      vehicleRegistrationNumber:
          json['vehicleRegistrationNumber'] as String? ?? '—',
      driverName: json['driverName'] as String? ?? '—',
      pickupCity: json['pickupCity'] as String? ?? '—',
      dropCity: json['dropCity'] as String? ?? '—',
      cargoType: json['cargoType'] as String? ?? '—',
      cargoWeightKg: (json['cargoWeightKg'] as num?)?.toDouble(),
    );
  }
}