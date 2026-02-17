import '../../../presentation/sender/models/shipment_draft.dart';

class CreateShipmentRequest {
  final String receiverOrganizationId;
  final String pickupAddressId;
  final String dropAddressId;

  final String cargoType;
  final String cargoDescription;
  final double cargoWeightKg;

  final bool requiresRefrigeration;
  final bool requiresInsurance;
  final bool isUrgent;

  CreateShipmentRequest({
    required this.receiverOrganizationId,
    required this.pickupAddressId,
    required this.dropAddressId,
    required this.cargoType,
    required this.cargoDescription,
    required this.cargoWeightKg,
    required this.requiresRefrigeration,
    required this.requiresInsurance,
    required this.isUrgent,
  });

  Map<String, dynamic> toJson() {
    return {
      "receiverOrganizationId": receiverOrganizationId,
      "pickupAddressId": pickupAddressId,
      "dropAddressId": dropAddressId,
      "cargoType": cargoType,
      "cargoDescription": cargoDescription,
      "cargoWeightKg": cargoWeightKg,
      "requiresRefrigeration": requiresRefrigeration,
      "requiresInsurance": requiresInsurance,
      "isUrgent": isUrgent,
    };
  }
}

// 👇 EXTENSION MUST BE OUTSIDE THE CLASS
extension ShipmentDraftMapper on ShipmentDraft {
  CreateShipmentRequest toRequest() {
    return CreateShipmentRequest(
      receiverOrganizationId: receiverOrganizationId!,
      pickupAddressId: pickupAddressId!,
      dropAddressId: dropAddressId!,
      cargoType: cargoType ?? "",
      cargoDescription: cargoDescription ?? "",
      cargoWeightKg: cargoWeightKg ?? 0,
      requiresRefrigeration: requiresRefrigeration,
      requiresInsurance: requiresInsurance,
      isUrgent: isUrgent,
    );
  }
}

