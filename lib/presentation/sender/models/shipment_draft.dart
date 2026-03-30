class ShipmentDraft {
  // ===== Parties =====

  // ===== Cargo =====
  String? senderPhone;
  String? receiverPhone;
  String? cargoType;
  String? cargoDescription;
  double? cargoWeightKg;
  double? cargoVolumeCubicMeters;
  int? packageCount;

  // ===== Pickup & Delivery =====
  DateTime? preferredPickupDate;
  DateTime? preferredDeliveryDate;
  bool isUrgent = false;

  // ===== Handling =====
  bool requiresRefrigeration = false;
  bool requiresInsurance = false;
  String? specialHandlingInstructions;

  // ===== Pricing =====
  double? agreedPrice;
  String? pricePerUnit;
  double loadingCharges = 0;
  double unloadingCharges = 0;
  double otherCharges = 0;

  // ===== Documents =====
  String? invoiceNumber;
  double? invoiceValue;
  String? ewayBillNumber;

  @override
  String toString() {
    return '''
ShipmentDraft(
  senderPhone:$senderPhone,
  receiverPhone:$receiverPhone,
  cargoType: $cargoType,
  cargoDescription: $cargoDescription,
  cargoWeightKg: $cargoWeightKg,
  cargoVolumeCubicMeters: $cargoVolumeCubicMeters,
  packageCount: $packageCount,
  preferredPickupDate: $preferredPickupDate,
  preferredDeliveryDate: $preferredDeliveryDate,
  isUrgent: $isUrgent,
  requiresRefrigeration: $requiresRefrigeration,
  requiresInsurance: $requiresInsurance,
  specialHandlingInstructions: $specialHandlingInstructions,
  agreedPrice: $agreedPrice,
  pricePerUnit: $pricePerUnit,
  loadingCharges: $loadingCharges,
  unloadingCharges: $unloadingCharges,
  otherCharges: $otherCharges,
  invoiceNumber: $invoiceNumber,
  invoiceValue: $invoiceValue,
  ewayBillNumber: $ewayBillNumber
)
''';
  }
}
