class Vehicle {
  final String id;
  final String registrationNumber;
  final String vehicleType;
  final double? capacityTons;
  final double? maxLoadWeightKg;
  final String status;
  final String availabilityStatus;
  final String? currentDriverId;
  final String? currentDriverName;

  Vehicle({
    required this.id,
    required this.registrationNumber,
    required this.vehicleType,
    this.capacityTons,
    this.maxLoadWeightKg,
    required this.status,
    required this.availabilityStatus,
    this.currentDriverId,
    this.currentDriverName,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) => Vehicle(
        id: json['id']?.toString() ?? '',
        registrationNumber: json['registrationNumber'] ?? json['registration_number'] ?? '',
        vehicleType: json['vehicleType'] ?? json['vehicle_type'] ?? '',
        capacityTons: (json['capacityTons'] ?? json['capacity_tons'])?.toDouble(),
        maxLoadWeightKg: (json['maxLoadWeightKg'] ?? json['max_load_weight_kg'])?.toDouble(),
        status: json['status'] ?? 'active',
        availabilityStatus: json['availabilityStatus'] ?? json['availability_status'] ?? 'available',
        currentDriverId: json['currentDriverId']?.toString(),
        currentDriverName: json['currentDriverName'],
      );
}

