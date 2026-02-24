class Vehicle {
  final String id;
  final String registrationNumber;
  final String vehicleType;

  Vehicle({required this.id, required this.registrationNumber, required this.vehicleType});

  factory Vehicle.fromJson(Map<String, dynamic> json) => Vehicle(
        id: json['id'].toString(),
        registrationNumber: json['registrationNumber'] ?? json['registration_number'] ?? '',
        vehicleType: json['vehicleType'] ?? json['vehicle_type'] ?? '',
      );
}
