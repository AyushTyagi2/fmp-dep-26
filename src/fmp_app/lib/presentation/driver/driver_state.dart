enum TripStatus {
  assigned,
  started,
  reachedPickup,
  loaded,
  inTransit,
  delivered,
}

class ActiveTrip {
  final String route;
  final String pickupTime;
  TripStatus status;

  ActiveTrip({
    required this.route,
    required this.pickupTime,
    this.status = TripStatus.assigned,
  });
}

class DriverState {
  ActiveTrip? activeTrip;

  bool get hasActiveTrip => activeTrip != null;

  void advanceStatus() {
    if (activeTrip == null) return;

    switch (activeTrip!.status) {
      case TripStatus.assigned:
        activeTrip!.status = TripStatus.started;
        break;
      case TripStatus.started:
        activeTrip!.status = TripStatus.reachedPickup;
        break;
      case TripStatus.reachedPickup:
        activeTrip!.status = TripStatus.loaded;
        break;
      case TripStatus.loaded:
        activeTrip!.status = TripStatus.inTransit;
        break;
      case TripStatus.inTransit:
        activeTrip!.status = TripStatus.delivered;
        break;
      case TripStatus.delivered:
        activeTrip = null; // trip ends
        break;
    }
  }
}
