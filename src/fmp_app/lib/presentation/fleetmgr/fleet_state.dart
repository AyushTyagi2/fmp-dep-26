import 'package:flutter/foundation.dart';
import '../../core/models/vehicle.dart';
import 'fleet_api.dart';

class FleetState extends ChangeNotifier {
  bool isLoading = false;
  final FleetApi _api = FleetApi();

  List<dynamic> drivers = [];
  List<Vehicle> vehicles = [];
  List<dynamic> trips = [];

  Future<void> loadData() async {
    isLoading = true;
    notifyListeners();
    try {
      await Future.delayed(const Duration(milliseconds: 200));
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadVehicles(String phone) async {
    isLoading = true;
    notifyListeners();
    try {
      vehicles = await _api.getVehiclesByFleetOwnerPhone(phone);
    } catch (e) {
      debugPrint("Error loading vehicles: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Drop a list of vehicles by ID. Selection state is managed by the screen.
  Future<void> dropSelected(String phone, List<String> vehicleIds) async {
    if (vehicleIds.isEmpty) return;
    isLoading = true;
    notifyListeners();
    try {
      await _api.dropVehicles(phone, vehicleIds);
      await loadVehicles(phone);
    } catch (e) {
      debugPrint("Error dropping vehicles: $e");
      isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Drop a single vehicle (used from VehicleDetailSheet).
  Future<void> dropSingle(String phone, String vehicleId) async {
    return dropSelected(phone, [vehicleId]);
  }

  Future<void> addVehicle(String phone, Map<String, dynamic> data) async {
    isLoading = true;
    notifyListeners();
    try {
      await _api.addVehicle(phone, data);
      await loadVehicles(phone);
    } catch (e) {
      isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<Map<String, dynamic>> addVehiclesBulk(
      String phone, List<Map<String, dynamic>> data) async {
    isLoading = true;
    notifyListeners();
    try {
      final res = await _api.addVehiclesBulk(phone, data);
      await loadVehicles(phone);
      return res;
    } catch (e) {
      isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  void addDriver(dynamic driver) {
    drivers.add(driver);
    notifyListeners();
  }

  /// Restore a list of previously dropped vehicles.
  /// Called by the undo action in FleetVehiclesScreen within the 15-second window.
  /// Converts [Vehicle] objects back to the map shape that [FleetApi.addVehiclesBulk]
  /// expects, then refreshes the list from the server.
  Future<void> restoreVehicles(String phone, List<dynamic> vehicles) async {
    if (vehicles.isEmpty) return;
    isLoading = true;
    notifyListeners();
    try {
      final data = vehicles
          .whereType<Vehicle>()
          .map<Map<String, dynamic>>((v) => {
                'registrationNumber': v.registrationNumber,
                'vehicleType': v.vehicleType,
                'capacityTons': v.capacityTons,
                'maxLoadWeightKg': v.maxLoadWeightKg,
                'status': v.status,
                'availabilityStatus': v.availabilityStatus,
                'currentDriverId': v.currentDriverId,
                'currentDriverName': v.currentDriverName,
              })
          .toList();
      await _api.addVehiclesBulk(phone, data);
      await loadVehicles(phone);
    } catch (e) {
      debugPrint('Error restoring vehicles: $e');
      isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  void updateVehicle(dynamic vehicle) {
    notifyListeners();
  }
}