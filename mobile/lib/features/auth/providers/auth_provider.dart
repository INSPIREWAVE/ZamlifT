import 'package:flutter/material.dart';

import '../../../core/models/user.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/auth_service.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  AuthProvider({required AuthService authService}) : _service = authService;

  final AuthService _service;

  AuthStatus _status = AuthStatus.initial;
  AppUser? _user;
  String? _error;

  AuthStatus get status => _status;
  AppUser? get user => _user;
  String? get error => _error;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isLoading => _status == AuthStatus.loading;
  bool get hasError => _status == AuthStatus.error;

  /// Called on app start – restores the session from stored token.
  Future<void> tryRestoreSession() async {
    _status = AuthStatus.loading;
    notifyListeners();

    try {
      final token = await _service.getToken();
      if (token == null) {
        _status = AuthStatus.unauthenticated;
      } else {
        // Token exists; mark authenticated. The backend will reject expired
        // tokens on the first API call, at which point screens call logout().
        _status = AuthStatus.authenticated;
      }
    } catch (e) {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  /// Logs in with email + password.
  /// Returns `true` on success, `false` on failure.
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _clearError();
    _status = AuthStatus.loading;
    notifyListeners();

    try {
      final result = await _service.login(email: email, password: password);
      _user = result.user;
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _setError(e.message);
      return false;
    } catch (e) {
      _setError('An unexpected error occurred. Please try again.');
      return false;
    }
  }

  /// Registers a new user.
  /// Returns `true` on success, `false` on failure.
  Future<bool> register({
    required String fullName,
    required String email,
    required String password,
    required String phone,
    String role = 'passenger',
  }) async {
    _clearError();
    _status = AuthStatus.loading;
    notifyListeners();

    try {
      final result = await _service.register(
        fullName: fullName,
        email: email,
        password: password,
        phone: phone,
        role: role,
      );
      _user = result.user;
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _setError(e.message);
      return false;
    } catch (e) {
      _setError('An unexpected error occurred. Please try again.');
      return false;
    }
  }

  /// Logs out the current user and clears local state.
  Future<void> logout() async {
    try {
      await _service.logout();
    } finally {
      _user = null;
      _error = null;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
    }
  }

  /// Clears any existing error state.
  void clearError() {
    if (_error != null) {
      _error = null;
      if (_status == AuthStatus.error) {
        _status = AuthStatus.unauthenticated;
      }
      notifyListeners();
    }
  }

  // ─── Private helpers ───────────────────────────────────────────────────────

  void _clearError() {
    _error = null;
  }

  void _setError(String message) {
    _error = message;
    _status = AuthStatus.error;
    notifyListeners();
  }
}
