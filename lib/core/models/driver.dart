import 'vehicle.dart';

class Driver {
  final String id;
  final String userId;
  final String fullName;
  final String phone;
  final String licenseNumber;
  final String licenseType;
  final String status;
  final double averageRating;
  final int totalTripsCompleted;
  final Vehicle? currentVehicle;

  Driver({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.phone,
    required this.licenseNumber,
    required this.licenseType,
    required this.status,
    required this.averageRating,
    required this.totalTripsCompleted,
    this.currentVehicle,
  });

  factory Driver.fromJson(Map<String, dynamic> json) {
    dynamic pick(List<String> keys) {
      for (final k in keys) {
        if (json.containsKey(k) && json[k] != null) return json[k];
      }
      return null;
    }

    final idVal = pick(['id', 'Id', 'ID', 'driverId', 'DriverId']);
    final userIdVal = pick(['userId', 'UserId', 'user_id']);
    final fullNameVal = pick(['fullName', 'FullName', 'full_name']);
    final phoneVal = pick(['phone', 'Phone', 'businessContactPhone', 'business_contact_phone']);
    final licenseNumberVal = pick(['licenseNumber', 'license_number']);
    final licenseTypeVal = pick(['licenseType', 'license_type']);
    final statusVal = pick(['status', 'Status']);
    final avgVal = pick(['averageRating', 'AverageRating', 'average_rating']);
    final tripsVal = pick(['totalTripsCompleted', 'TotalTripsCompleted', 'total_trips_completed']);
    final vehicleVal = pick(['currentVehicle', 'current_vehicle']);

    double parseDouble(dynamic v) {
      if (v == null) return 0.0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0.0;
    }

    int parseInt(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString()) ?? 0;
    }

    return Driver(
      id: idVal?.toString() ?? '',
      userId: userIdVal?.toString() ?? '',
      fullName: fullNameVal?.toString() ?? '',
      phone: phoneVal?.toString() ?? '',
      licenseNumber: licenseNumberVal?.toString() ?? '',
      licenseType: licenseTypeVal?.toString() ?? '',
      status: statusVal?.toString() ?? '',
      averageRating: parseDouble(avgVal),
      totalTripsCompleted: parseInt(tripsVal),
      currentVehicle: vehicleVal != null ? Vehicle.fromJson(Map<String, dynamic>.from(vehicleVal)) : null,
    );
  }
}
