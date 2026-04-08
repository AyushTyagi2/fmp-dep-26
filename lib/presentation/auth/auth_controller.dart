import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'auth_api.dart';
import 'package:fmp_app/app_session.dart';

enum AuthStage {
  idle,
  emailEntered,
  otpSending,
  otpSent,
  verifyingOtp,
  googleSigningIn,
  authenticated,
  error,
}

class AuthController extends ChangeNotifier {
  final AuthApi _authApi;

  AuthController(this._authApi);

  AuthStage _stage = AuthStage.idle;

  String? email;
  String? errorMessage;

  int _secondsLeft = 0;
  Timer? _timer;

  AuthStage get stage => _stage;
  int get secondsLeft => _secondsLeft;

  // ── Email / OTP methods (unchanged) ──────────────────────────────────────

  void setEmail(String value) {
    email = value;
    _stage = AuthStage.emailEntered;
    notifyListeners();
  }

  Future<void> sendOtp() async {
    if (email == null || email!.isEmpty) {
      _setError('Email address missing');
      return;
    }

    _stage = AuthStage.otpSending;
    notifyListeners();

    try {
      await _authApi.requestOtp(email!);
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
      await _authApi.verifyOtp(email!, otp);
      _stopTimer();
      _stage = AuthStage.authenticated;
      AppSession.email = email;
      notifyListeners();
    } catch (e) {
      _setError('Incorrect or expired OTP!');
    }
  }

  // ── Google Sign-In ────────────────────────────────────────────────────────

  /// Signs in with Google, sends the ID token to the backend, then
  /// routes the user exactly the same way as the OTP flow does.
  Future<void> signInWithGoogle(BuildContext context) async {
    _stage = AuthStage.googleSigningIn;
    errorMessage = null;
    notifyListeners();

    try {
      final googleSignIn = GoogleSignIn(
        // Use your Web OAuth 2.0 Client ID from Google Cloud Console.
        // Required even on Android/iOS so the backend can validate the token.
        clientId: 'YOUR_WEB_CLIENT_ID.apps.googleusercontent.com',
        scopes: ['email', 'profile'],
      );

      // Ensure a fresh sign-in (avoids stale cached accounts)
      await googleSignIn.signOut();
      final googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        // User dismissed the picker
        _stage = AuthStage.idle;
        notifyListeners();
        return;
      }

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;

      if (idToken == null) {
        _setError('Google sign-in failed: no ID token');
        return;
      }

      // Send to backend — returns { email, token, driverId }
      final res = await _authApi.signInWithGoogle(idToken);

      email = res['email'] as String;

      await AppSession.save(
        email: email!,
        token: res['token'] as String,
        driverId: res['driverId'] as String?,
        role: '',
      );

      _stage = AuthStage.authenticated;
      notifyListeners();

      if (!context.mounted) return;

      // Reuse the same auto-routing logic as the OTP flow
      final autoRouted = await tryAutoRoute(context);
      if (!autoRouted && context.mounted) {
        Navigator.pushReplacementNamed(context, '/role-selection');
      }
    } catch (e) {
      debugPrint('Google sign-in error: $e');
      _setError('Google sign-in failed. Please try again.');
    }
  }

  // ── Shared routing logic ──────────────────────────────────────────────────

  Future<void> chooseRole(BuildContext context, String role) async {
    try {
      final res = await _authApi.resolveRole(email!, role);

      await AppSession.save(
        email: email!,
        token: res['token'] as String,
        driverId: res['driverId'] as String?,
        role: role,
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
        default:
          final msg = 'Unexpected navigation target: $screen';
          try {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(msg)));
          } catch (_) {
            debugPrint(msg);
          }
      }
    } catch (e) {
      _setError('Failed to resolve role');
    }
  }

  Future<bool> tryAutoRoute(BuildContext context) async {
    try {
      for (final role in ['SUPER_ADMIN', 'UNION_MANAGER']) {
        final res = await _authApi.resolveRole(email!, role);
        final screen = res['screen'] as String?;
        debugPrint('tryAutoRoute: role=$role, screen=$screen');

        if (screen == 'admin_dashboard' || screen == 'union_dashboard') {
          await AppSession.save(
            email: email!,
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
      }
    } catch (_) {}
    return false;
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

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
    email = null;
    errorMessage = null;
    _stopTimer();
    _stage = AuthStage.idle;
    notifyListeners();
  }
}