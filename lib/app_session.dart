import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AppSession {
  static const _storage = FlutterSecureStorage();

  static String? phone;
  static String? driverId;
  static String? token;
  static String? role; // NEW — persisted alongside token

  static Future<void> restore() async {
    phone    = await _storage.read(key: 'phone');
    driverId = await _storage.read(key: 'driver_id');
    token    = await _storage.read(key: 'token');
    role     = await _storage.read(key: 'role');
  }

  static Future<void> save({
    required String phone,
    required String token,
    String? driverId,
    String? role,
  }) async {
    AppSession.phone    = phone;
    AppSession.token    = token;
    AppSession.driverId = driverId;
    AppSession.role     = role;

    await _storage.write(key: 'phone', value: phone);
    await _storage.write(key: 'token', value: token);
    if (driverId != null) {
      await _storage.write(key: 'driver_id', value: driverId);
    }
    if (role != null) {
      await _storage.write(key: 'role', value: role);
    }
  }

  static Future<void> clear() async {
    phone    = null;
    driverId = null;
    token    = null;
    role     = null;
    await _storage.deleteAll();
  }

  static bool get isLoggedIn => token != null;

  /// Human-readable role label for display in the profile page.
  static String get roleLabel {
    switch (role) {
      case 'driver':      return 'Driver';
      case 'sender':
      case 'organization': return 'Sender / Receiver';
      case 'fleet_owner': return 'Fleet Manager';
      case 'admin':
      case 'super_admin': return 'System Administrator';
      case 'union_admin': return 'Union Admin';
      default:            return role ?? 'User';
    }
  }
}