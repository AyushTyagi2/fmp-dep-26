import 'package:dio/dio.dart';
import 'api_client.dart';

class ShipmentApi {
  final ApiClient _client;

  ShipmentApi(this._client);

  Future<Map<String, dynamic>> getShipmentsByPhone(
      String phone) async {

    try {
      final Response response = await _client.dio.get(
        "/shipments/by-phone/$phone",
      );

      return response.data;
    } on DioException catch (e) {
      throw Exception(
          e.response?.data["message"] ?? "Failed to fetch shipments");
    }
  }
}