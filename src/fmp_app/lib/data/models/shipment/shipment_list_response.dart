class ShipmentListResponse {
  final List<dynamic> sent;
  final List<dynamic> received;

  ShipmentListResponse({
    required this.sent,
    required this.received,
  });

  factory ShipmentListResponse.fromJson(
      Map<String, dynamic> json) {
    return ShipmentListResponse(
      sent: json["sent"] ?? [],
      received: json["received"] ?? [],
    );
  }
}