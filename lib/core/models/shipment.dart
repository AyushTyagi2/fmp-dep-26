class Shipment {
  final String  id;
  final String  shipmentNumber;
  final String  cargoType;
  final String  cargoDescription;
  final double  cargoWeightKg;
  // ✅ Resolved human-readable strings like "Delhi, UP"
  final String  pickupLocation;
  final String  dropLocation;
  final double? agreedPrice;
  final String  currency;
  final String  status;
  final bool    isUrgent;
  final DateTime createdAt;

  const Shipment({
    required this.id,
    required this.shipmentNumber,
    required this.cargoType,
    required this.cargoDescription,
    required this.cargoWeightKg,
    required this.pickupLocation,
    required this.dropLocation,
    this.agreedPrice,
    required this.currency,
    required this.status,
    required this.isUrgent,
    required this.createdAt,
  });

  factory Shipment.fromJson(Map<String, dynamic> json) => Shipment(
    id:              json['id']              as String,
    shipmentNumber:  json['shipmentNumber']  as String,
    cargoType:       json['cargoType']       as String,
    cargoDescription: json['cargoDescription'] as String? ?? '',
    cargoWeightKg:   (json['cargoWeightKg']  as num).toDouble(),
    pickupLocation:  json['pickupLocation']  as String? ?? json['pickupAddressId'] as String? ?? '',
    dropLocation:    json['dropLocation']    as String? ?? json['dropAddressId']   as String? ?? '',
    agreedPrice:     (json['agreedPrice']    as num?)?.toDouble(),
    currency:        json['currency']        as String? ?? 'INR',
    status:          json['status']          as String,
    isUrgent:        json['isUrgent']        as bool? ?? false,
    createdAt:       DateTime.parse(json['createdAt'] as String),
  );
}

class PagedResult<T> {
  final List<T> items;
  final int     total;
  final int     page;
  final int     pageSize;
  final int     totalPages;
  final bool    hasNextPage;
  final bool    hasPrevPage;

  const PagedResult({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.totalPages,
    required this.hasNextPage,
    required this.hasPrevPage,
  });

  factory PagedResult.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJson,
  ) =>
      PagedResult(
        items:       (json['items'] as List).map((e) => fromJson(e as Map<String, dynamic>)).toList(),
        total:       json['total']       as int,
        page:        json['page']        as int,
        pageSize:    json['pageSize']    as int,
        totalPages:  json['totalPages']  as int,
        hasNextPage: json['hasNextPage'] as bool,
        hasPrevPage: json['hasPrevPage'] as bool,
      );
}