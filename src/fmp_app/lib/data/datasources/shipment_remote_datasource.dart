import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';

import '../models/shipment/create_shipment_request.dart';

class ShipmentRemoteDataSource {
  final Dio dio;

  ShipmentRemoteDataSource(this.dio);

  Future<Response> createShipment(

      CreateShipmentRequest request) async {
        final body = request.toJson();
        print("FINAL JSON: $body");

    return await dio.post(
      "/api/shipments",
      data: request.toJson(),
    );
  }
}
