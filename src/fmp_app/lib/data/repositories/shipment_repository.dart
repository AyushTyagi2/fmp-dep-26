import '../datasources/shipment_remote_datasource.dart';
import '../models/shipment/create_shipment_request.dart';

class ShipmentRepository {
  final ShipmentRemoteDataSource remoteDataSource;

  ShipmentRepository(this.remoteDataSource);

  Future<void> createShipment(
      CreateShipmentRequest request) async {
    await remoteDataSource.createShipment(request);
  }
}
