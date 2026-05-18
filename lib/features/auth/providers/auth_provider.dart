import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../services/firebase/auth_service.dart';
import '../../../services/analytics/analytics_service.dart';
import '../../../services/analytics/analytics_constants.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider(this._authService, this._analytics);

  final AuthService _authService;
  final AnalyticsService _analytics;

  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;
  User? get currentUser => _authService.currentUser;

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    try {
      await _authService.signInWithEmailAndPassword(email, password);
      await _analytics.logEmailLoginUsed();
      await _analytics.logLoginSuccess(loginMethod: AnalyticsLoginMethods.email);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  Future<bool> loginWithGoogle() async {
    _setLoading(true);
    try {
      await _authService.signInWithGoogle();
      await _analytics.logGoogleSignInUsed();
      await _analytics.logLoginSuccess(loginMethod: AnalyticsLoginMethods.google);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  Future<bool> register(String email, String password, String nickname) async {
    _setLoading(true);
    try {
      await _authService.registerWithEmailAndPassword(email, password, nickname);
      await _analytics.logSignupSuccess(loginMethod: AnalyticsLoginMethods.email);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  Future<void> logout() async {
    await _analytics.logLogout();
    await _authService.signOut();
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    _error = null;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
  }
}
