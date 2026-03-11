import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// ✅ FIX: Session is now persisted in encrypted secure storage.
/// Before: static variables lost on every app kill.
/// After:  token and driverId survive app restarts — user stays logged in.
///
/// Add to pubspec.yaml:
///   flutter_secure_storage: ^9.0.0
class AppSession {
  static const _storage = FlutterSecureStorage();

  // In-memory cache (populated from storage on startup)
  static String? phone;
  static String? driverId;
  static String? token;   // JWT — sent on every API request

  /// Call this in main() before runApp() to restore any saved session.
  static Future<void> restore() async {
    phone    = await _storage.read(key: 'phone');
    driverId = await _storage.read(key: 'driver_id');
    token    = await _storage.read(key: 'token');
  }

  /// Call this after successful OTP verify + role resolve.
  static Future<void> save({
    required String phone,
    required String token,
    String? driverId,
  }) async {
    AppSession.phone    = phone;
    AppSession.token    = token;
    AppSession.driverId = driverId;

    await _storage.write(key: 'phone',     value: phone);
    await _storage.write(key: 'token',     value: token);
    if (driverId != null) {
      await _storage.write(key: 'driver_id', value: driverId);
    }
  }

  /// Call on logout.
  static Future<void> clear() async {
    phone    = null;
    driverId = null;
    token    = null;
    await _storage.deleteAll();
  }

  static bool get isLoggedIn => token != null;
}