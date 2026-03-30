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
    try {
      // load drivers from API if phone available
      // avoid import cycle by using dynamic here and parsing in UI if necessary
      // we'll call FleetApi directly
      // lazy import to avoid top-level dependency when unused
      final sessionPhone = await Future.value(null);
      await Future.delayed(const Duration(milliseconds: 200));
    } finally {
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
}
