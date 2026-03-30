import 'dart:async';
import 'package:flutter/material.dart';
import 'auth_api.dart';
import 'package:fmp_app/app_session.dart';

enum AuthStage {
  idle,
  phoneEntered,
  otpSending,
  otpSent,
  verifyingOtp,
  authenticated,
  error,
}

class AuthController extends ChangeNotifier {
  final AuthApi _authApi;

  AuthController(this._authApi);

  AuthStage _stage = AuthStage.idle;

  String? phone;
  String? errorMessage;

  int _secondsLeft = 0;
  Timer? _timer;

  AuthStage get stage => _stage;
  int get secondsLeft => _secondsLeft;

  void setPhone(String value) {
    phone = value;
    _stage = AuthStage.phoneEntered;
    notifyListeners();
  }

  Future<void> chooseRole(BuildContext context, String role) async {
    try {
      final res = await _authApi.resolveRole(phone!, role);

      // Save session including the chosen role
      await AppSession.save(
        phone:    phone!,
        token:    res['token'] as String,
        driverId: res['driverId'] as String?,
        role:     role,
      );

      final screen = res['screen'];

      if (!context.mounted) return;

      switch (screen) {
        case 'driver_dashboard':
          Navigator.pushReplacementNamed(context, '/driver-dashboard');
          break;
        case 'driver_onboarding':
          Navigator.pushReplacementNamed(context, '/driver-basic');
          break;
        case 'sender_dashboard':
          Navigator.pushReplacementNamed(context, '/organizationuser');
          break;
        case 'sender_onboarding':
          Navigator.pushReplacementNamed(context, '/sender-onboarding');
          break;
        case 'fleet_dashboard':
          Navigator.pushReplacementNamed(context, '/fleet-dashboard');
          break;
        case 'fleet_onboarding':
          Navigator.pushReplacementNamed(context, '/fleet-onboarding');
          break;
        case 'admin_dashboard':
          Navigator.pushReplacementNamed(context, '/system_admin');
          break;
        case 'union_dashboard':
          Navigator.pushReplacementNamed(context, '/union-dashboard');
          break;
        case 'unauthorized':
          _setError('You do not have permission to access this role');
          break;
        default:
          final msg = 'Unexpected navigation target: $screen';
          try {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(msg)));
          } catch (_) {
            debugPrint(msg);
          }
          debugPrint('Auth.chooseRole received unexpected screen: $screen');
      }
    } catch (e) {
      _setError('Failed to resolve role');
    }
  }

    Future<bool> tryAutoRoute(BuildContext context) async {
  try {
    for (final role in ['SUPER_ADMIN', 'UNION_MANAGER']) {
      final res = await _authApi.resolveRole(phone!, role);
      final screen = res['screen'] as String?;
      debugPrint('tryAutoRoute: role=$role, screen=$screen');

      if (screen == 'admin_dashboard' || screen == 'union_dashboard') {
        await AppSession.save(
          phone: phone!,
          token: res['token'] as String,
          driverId: null,
          role: role,
        );
        if (!context.mounted) return false;
        Navigator.pushReplacementNamed(
          context,
          screen == 'admin_dashboard' ? '/system_admin' : '/union-dashboard',
        );
        return true;
      }
      // 'unauthorized' or anything else → continue loop
    }
  } catch (_) {}
  return false;
}


  Future<void> sendOtp() async {
    if (phone == null || phone!.isEmpty) {
      _setError('Phone number missing');
      return;
    }

    _stage = AuthStage.otpSending;
    notifyListeners();

    try {
      await _authApi.requestOtp(phone!);
      _startTimer();
      _stage = AuthStage.otpSent;
      notifyListeners();
    } catch (e) {
      debugPrint('Error sending OTP: $e');
      _setError('Failed to send OTP');
    }
  }

  Future<void> verifyOtp(String otp) async {
    if (otp.length < 4) {
      _setError('Invalid OTP');
      return;
    }

    _stage = AuthStage.verifyingOtp;
    notifyListeners();

    try {
      await _authApi.verifyOtp(phone!, otp);
      _stopTimer();
      _stage = AuthStage.authenticated;
      AppSession.phone = phone;
      notifyListeners();
    } catch (e) {
      _setError('Incorrect or expired OTP!');
    }
  }

  void _startTimer() {
    _secondsLeft = 120;
    _timer?.cancel();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _secondsLeft--;
      notifyListeners();
      if (_secondsLeft <= 0) {
        timer.cancel();
        _setError('OTP expired');
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _secondsLeft = 0;
  }

  void _setError(String msg) {
    errorMessage = msg;
    _stage = AuthStage.error;
    notifyListeners();
  }

  void reset() {
    phone = null;
    errorMessage = null;
    _stopTimer();
    _stage = AuthStage.idle;
    notifyListeners();
  }
}