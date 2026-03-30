class Shipment {
  final String id;
  final String shipmentNumber;
  final String cargoType;
  final double cargoWeightKg;

  Shipment({
    required this.id,
    required this.shipmentNumber,
    required this.cargoType,
    required this.cargoWeightKg,
  });

  factory Shipment.fromJson(Map<String, dynamic> json) {
    return Shipment(
      id: json['id'],
      shipmentNumber: json['shipmentNumber'],
      cargoType: json['cargoType'],
      cargoWeightKg: (json['cargoWeightKg'] as num).toDouble(),
    );
  }
}