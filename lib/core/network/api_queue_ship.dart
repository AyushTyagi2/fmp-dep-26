import 'package:dio/dio.dart';
import 'api_client.dart';
import '../models/queue.dart';

class ShipmentApi {
  final ApiClient apiClient;

  ShipmentApi(this.apiClient);

  Future<List<Shipment>> getPendingShipments() async {
    final Response res = await apiClient.dio.get(
      "/api/shipments/pending",
    );

    final List data = res.data;

    return data.map((e) => Shipment.fromJson(e)).toList();
  }

  Future<void> approveShipment(String id) async {
    await apiClient.dio.post(
      "/api/shipments/$id/approve",
    );
  }

  Future<void> rejectShipment(String id) async {
    await apiClient.dio.post(
      "/api/shipments/$id/reject",
      data: {
        "reason": "Rejected by union",
      },
    );
  }
}




