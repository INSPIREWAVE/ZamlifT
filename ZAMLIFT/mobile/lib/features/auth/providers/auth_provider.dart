import 'package:flutter/material.dart';

import '../../../core/models/user.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/auth_service.dart';

enum AuthStatus { loading, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  AuthProvider({required AuthService authService})
      : _service = authService;

  final AuthService _service;

  AuthStatus _status = AuthStatus.loading;
  AppUser? _user;
  String? _error;

  AuthStatus get status => _status;
  AppUser? get user => _user;
  String? get error => _error;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  /// Called on app start – restores the session from stored token.
  /// We don't have a /me endpoint, so we store the user in memory only;
  /// if the token is missing the user is considered logged out.
  Future<void> tryRestoreSession() async {
    final token = await _service.getToken();
    if (token == null) {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }
    // Token exists; mark authenticated. The backend will reject expired tokens
    // on the first API call, at which point screens call logout().
    _status = AuthStatus.authenticated;
    notifyListeners();
  }

  Future<bool> login({required String email, required String password}) async {
    _error = null;
    _status = AuthStatus.loading;
    notifyListeners();
    try {
      final result = await _service.login(email: email, password: password);
      _user = result.user;
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String fullName,
    required String email,
    required String password,
    String role = 'passenger',
  }) async {
    _error = null;
    _status = AuthStatus.loading;
    notifyListeners();
    try {
      final result = await _service.register(
        fullName: fullName,
        email: email,
        password: password,
        role: role,
      );
      _user = result.user;
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _service.logout();
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }
}
