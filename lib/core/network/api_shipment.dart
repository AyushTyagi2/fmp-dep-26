

import 'package:dio/dio.dart';
import 'api_client.dart';
import '../models/queue.dart';

class ShipmentApi {
  final ApiClient _client;

  ShipmentApi(this._client);

  /// Sender dashboard


Future<Map<String, dynamic>> createShipment(Map<String, dynamic> body) async {
  try {
    print("BASE URL: ${_client.dio.options.baseUrl}");
    print("REQUEST BODY: $body");

    final Response response =
        await _client.dio.post("/api/shipments", data: body);

    return response.data;

  } on DioException catch (e) {
    print("STATUS: ${e.response?.statusCode}");
    print("ACTUAL URL: ${e.requestOptions.uri}");
    print("DATA: ${e.response?.data}");
    rethrow;
  }
}


  Future<Map<String, dynamic>> getShipmentsByPhone(String phone) async {
    try {
      final Response response =
          await _client.dio.get("/api/shipments/by-phone/$phone");

      return response.data;
    } on DioException catch (e) {
      throw Exception(
          e.response?.data["message"] ?? "Failed to fetch shipments");
    }
  }

  /// Union request tab
    Future<List<Shipment>> getPendingShipments() async {
  try {
    final Response response =
        await _client.dio.get("/api/shipments/pending");

    print("===== API RESPONSE =====");
    print(response.data);
    print("========================");

    final List data = response.data;

    return data.map((e) => Shipment.fromJson(e)).toList();
  } on DioException catch (e) {
    throw Exception(
        e.response?.data["message"] ?? "Failed to load pending shipments");
  }
}

  /// Approve shipment
  Future<void> approveShipment(String shipmentId) async {
    try {
      await _client.dio.post(
        "/api/shipments/$shipmentId/approve",
      );
    } on DioException catch (e) {
      throw Exception(
          e.response?.data["message"] ?? "Shipment approval failed");
    }
  }

  /// Reject shipment
  Future<void> rejectShipment(String shipmentId) async {
    try {
      await _client.dio.post(
        "/api/shipments/$shipmentId/reject",
        data: {
          "reason": "Rejected by union",
        },
      );
    } on DioException catch (e) {
      throw Exception(
          e.response?.data["message"] ?? "Shipment rejection failed");
    }
  }
}