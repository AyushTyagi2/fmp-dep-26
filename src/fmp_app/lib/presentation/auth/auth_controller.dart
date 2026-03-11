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

  AuthController(this ._authApi);

  AuthStage _stage = AuthStage.idle;

  String? phone;
  //String? vehicle;
  String? errorMessage;

  int _secondsLeft = 0;
  Timer? _timer;

  AuthStage get stage => _stage;
  int get secondsLeft => _secondsLeft;

  // ---------- STEP 1: ENTER PHONE ----------
  void setPhone(String value) {
    phone = value;
    _stage = AuthStage.phoneEntered;
    notifyListeners();
  }

  Future<void> chooseRole(BuildContext context, String role) async {
  try {
    final res = await _authApi.resolveRole(phone!, role);
    // ✅ Save session HERE before navigating
    await AppSession.save(
      phone:    phone!,
      token:    res['token']    as String,
      driverId: res['driverId'] as String?,
    );
    final screen = res["screen"];

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
      default:
        // Unexpected or unknown screen returned from backend — surface to user
        final msg = 'Unexpected navigation target: $screen';
        try {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg)),
          );
        } catch (_) {
          // If context no longer mounted or Scaffold not found, just print
          print(msg);
        }
        print('Auth.chooseRole received unexpected screen: $screen');
    }
  } catch (e) {
    _setError("Failed to resolve role");
  }
}


  // ---------- STEP 3: SEND OTP ----------
  Future<void> sendOtp() async {
    if (phone == null || phone!.isEmpty) {
      _setError('Phone number missing');
      return;
    }

    _stage = AuthStage.otpSending;
    notifyListeners();

    // MOCK API DELAY
    try {
      print("we reached here");
      await _authApi.requestOtp(phone!);
      
      _startTimer();

      _stage = AuthStage.otpSent;
      notifyListeners();
    } catch(e) {
      print("Error sending OTP: $e");
      _setError("Failed to send OTP");
    }

    // Start OTP timer
  }

  // ---------- STEP 4: VERIFY OTP ----------
  Future<void> verifyOtp(String otp) async {
    if (otp.length < 4) {
      _setError('Invalid OTP');
      return;
    }

    _stage = AuthStage.verifyingOtp;
    notifyListeners();

    // MOCK VERIFY
    try {
      await _authApi.verifyOtp(phone!, otp);
      _stopTimer();
      _stage = AuthStage.authenticated;
      AppSession.phone = phone;
      notifyListeners();
      
    } catch(e){
      _setError("Incorrect or expired Otp!");
    }


  }

  // ---------- TIMER ----------
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

  // ---------- ERROR ----------
  void _setError(String msg) {
    errorMessage = msg;
    _stage = AuthStage.error;
    notifyListeners();
  }

  // ---------- RESET ----------
  void reset() {
    phone = null;
    //vehicle = null;
    errorMessage = null;
    _stopTimer();
    _stage = AuthStage.idle;
    notifyListeners();
  }
}
