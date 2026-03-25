import 'dart:async';
import 'package:flutter/material.dart';
import 'auth_api.dart';
import 'package:fmp_app/app_session.dart';

enum AuthStage {
  idle,
  otpSending,
  otpSent,
  verifyingOtp,
  verified, // OTP confirmed, screen resolved — ready to navigate
  error, authenticated,
}

class AuthController extends ChangeNotifier {
  final AuthApi _authApi;

  AuthController(this._authApi);

  AuthStage _stage = AuthStage.idle;

  String? phone;
  String? errorMessage;
  String? resolvedScreen; // screen returned by verify-otp

  int _secondsLeft = 0;
  Timer? _timer;

  AuthStage get stage       => _stage;
  int       get secondsLeft => _secondsLeft;

  // ── STEP 1: SET PHONE ────────────────────────────────────────────────────
  void setPhone(String value) {
    phone = value.trim();
  }

  // ── STEP 2: SEND OTP ─────────────────────────────────────────────────────
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
      print("[AuthController] sendOtp error: $e");
      _setError("Failed to send OTP");
    }
  }

  // ── STEP 3: VERIFY OTP ───────────────────────────────────────────────────
  // Backend returns { screen, token, driverId } — we navigate directly.
  Future<void> verifyOtp(String otp) async {
    if (otp.length < 4) {
      _setError('Enter a valid OTP');
      return;
    }

    _stage = AuthStage.verifyingOtp;
    notifyListeners();

    try {
      final result = await _authApi.verifyOtp(phone!, otp);
      _stopTimer();

      await AppSession.save(
        phone:    phone!,
        token:    result['token']    as String,
        driverId: result['driverId'] as String?,
      );

      resolvedScreen = result['screen'] as String?;
      print("[AuthController] verified → screen=$resolvedScreen");

      _stage = AuthStage.verified;
      notifyListeners();
    } catch (e) {
      print("[AuthController] verifyOtp error: $e");
      _setError("Incorrect or expired OTP");
    }
  }

  // ── STEP 4 (role-selection path only): USER PICKS A ROLE ─────────────────
  Future<void> chooseRole(BuildContext context, String role) async {
    try {
      final res = await _authApi.resolveRole(phone!, role);
      await AppSession.save(
        phone:    phone!,
        token:    res['token']    as String,
        driverId: res['driverId'] as String?,
      );
      _navigateTo(context, res['screen'] as String?);
    } catch (e) {
      _setError("Failed to resolve role");
    }
  }

  // ── NAVIGATION ────────────────────────────────────────────────────────────
  void navigateAfterVerify(BuildContext context) {
    _navigateTo(context, resolvedScreen);
  }

  void _navigateTo(BuildContext context, String? screen) {
    print("[AuthController] navigating → $screen");
    switch (screen) {
      case "driver_dashboard":
        Navigator.pushReplacementNamed(context, '/driver-dashboard');
        break;
      case "driver_onboarding":
        Navigator.pushReplacementNamed(context, '/driver-basic');
        break;
      case "sender_dashboard":
        Navigator.pushReplacementNamed(context, '/organizationuser');
        break;
      case "sender_onboarding":
        Navigator.pushReplacementNamed(context, '/sender-onboarding');
        break;
      case "fleet_dashboard":
        Navigator.pushReplacementNamed(context, '/fleet-dashboard');
        break;
      case "fleet_onboarding":
        Navigator.pushReplacementNamed(context, '/fleet-onboarding');
        break;
      case "union_dashboard":
        Navigator.pushReplacementNamed(context, '/union-dashboard');
        break;
      case "system_admin_dashboard":
        Navigator.pushReplacementNamed(context, '/system_admin');
        break;
      case "role_selection":
      default:
        Navigator.pushReplacementNamed(context, '/role-selection');
        break;
    }
  }

  // ── TIMER ────────────────────────────────────────────────────────────────
  void _startTimer() {
    _secondsLeft = 120;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _secondsLeft--;
      notifyListeners();
      if (_secondsLeft <= 0) {
        timer.cancel();
        _setError('OTP expired. Please request a new one.');
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
    phone          = null;
    errorMessage   = null;
    resolvedScreen = null;
    _stopTimer();
    _stage = AuthStage.idle;
    notifyListeners();
  }
}