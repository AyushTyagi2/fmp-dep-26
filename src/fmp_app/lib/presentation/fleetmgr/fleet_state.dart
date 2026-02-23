import 'package:flutter/foundation.dart';

class FleetState extends ChangeNotifier {
  bool isLoading = false;

  // Basic placeholders for fleet data
  List<dynamic> drivers = [];
  List<dynamic> vehicles = [];
  List<dynamic> trips = [];

  Future<void> loadData() async {
    isLoading = true;
    notifyListeners();
    // TODO: load drivers, vehicles, trips from API
    await Future.delayed(const Duration(milliseconds: 200));
    isLoading = false;
    notifyListeners();
  }

  void addDriver(dynamic driver) {
    drivers.add(driver);
    notifyListeners();
  }

  void updateVehicle(dynamic vehicle) {
    // placeholder
    notifyListeners();
  }
}
