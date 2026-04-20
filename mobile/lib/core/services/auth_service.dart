import 'dart:async';
import 'dart:io';

import '../constants/api_constants.dart';
import '../models/user.dart';
import '../network/api_client.dart';
import '../storage/token_storage.dart';

/// POST /api/auth/register   – camelCase body → {user, token}
/// POST /api/auth/login      – camelCase body → {user, token}
class AuthService {
  AuthService({required TokenStorage tokenStorage})
      : _client = ApiClient(tokenStorage: tokenStorage),
        _storage = tokenStorage;

  final ApiClient _client;
  final TokenStorage _storage;

  /// Registers a new user (role: 'passenger' or 'driver').
  ///
  /// Request body:
  /// ```json
  /// { "fullName": "...", "email": "...", "password": "...", "phone": "...", "role": "passenger" }
  /// ```
  Future<({AppUser user, String token})> register({
    required String fullName,
    required String email,
    required String password,
    required String phone,
    String role = 'passenger',
  }) async {
    try {
      final data = await _client.post(
        ApiConstants.register,
        {
          'fullName': fullName,
          'email': email,
          'password': password,
          'phone': phone,
          'role': role,
        },
        auth: false,
      );

      return _extractAndPersistAuthPayload(data);
    } on ApiException catch (e) {
      throw ApiException(
        statusCode: e.statusCode,
        message: _readableApiMessage(
          e.message,
          fallback: 'Unable to register right now.',
        ),
      );
    } on TimeoutException {
      throw const ApiException(
        statusCode: 408,
        message: 'Request timed out. Please try again.',
      );
    } on SocketException {
      throw const ApiException(
        statusCode: 503,
        message: 'Unable to connect. Check your internet connection.',
      );
    } on FormatException {
      throw const ApiException(
        statusCode: 500,
        message: 'Received an invalid server response.',
      );
    } catch (e) {
      throw ApiException(
        statusCode: 500,
        message: _readableApiMessage(
          e.toString(),
          fallback: 'Unable to register right now.',
        ),
      );
    }
  }

  /// Logs in with email + password.
  ///
  /// Request body:
  /// ```json
  /// { "email": "...", "password": "..." }
  /// ```
  Future<({AppUser user, String token})> login({
    required String email,
    required String password,
  }) async {
    try {
      final data = await _client.post(
        ApiConstants.login,
        {'email': email, 'password': password},
        auth: false,
      );

      return _extractAndPersistAuthPayload(data);
    } on ApiException catch (e) {
      throw ApiException(
        statusCode: e.statusCode,
        message: _readableApiMessage(e.message, fallback: 'Unable to login right now.'),
      );
    } on TimeoutException {
      throw const ApiException(
        statusCode: 408,
        message: 'Request timed out. Please try again.',
      );
    } on SocketException {
      throw const ApiException(
        statusCode: 503,
        message: 'Unable to connect. Check your internet connection.',
      );
    } on FormatException {
      throw const ApiException(
        statusCode: 500,
        message: 'Received an invalid server response.',
      );
    } catch (e) {
      throw ApiException(
        statusCode: 500,
        message: _readableApiMessage(e.toString(), fallback: 'Unable to login right now.'),
      );
    }
  }

  Future<void> logout() => _storage.deleteToken();

  /// Returns the stored token, or null when not logged in.
  Future<String?> getToken() => _storage.getToken();

  Future<({AppUser user, String token})> _extractAndPersistAuthPayload(
    dynamic payload,
  ) async {
    if (payload is! Map<String, dynamic>) {
      throw const ApiException(
        statusCode: 500,
        message: 'Received an invalid authentication response.',
      );
    }

    final token = payload['token'];
    final userJson = payload['user'];
    final isValidToken =
        token is String && token.isNotEmpty && _hasThreeParts(token);
    final isValidUser = userJson is Map<String, dynamic>;

    if (!isValidToken || !isValidUser) {
      throw const ApiException(
        statusCode: 500,
        message: 'Authentication response is missing required fields.',
      );
    }

    final user = AppUser.fromJson(userJson);
    await _storage.saveToken(token);
    return (user: user, token: token);
  }

  bool _hasThreeParts(String token) => token.split('.').length == 3;

  String _readableApiMessage(
    String raw, {
    required String fallback,
  }) {
    final value = raw.trim();
    if (value.isEmpty) return fallback;
    if (value == 'Exception') return fallback;
    return value.replaceFirst(RegExp(r'^Exception:\s*'), '').trim().isEmpty
        ? fallback
        : value.replaceFirst(RegExp(r'^Exception:\s*'), '').trim();
  }
}
