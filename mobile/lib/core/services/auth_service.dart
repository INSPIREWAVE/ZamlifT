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
  /// { "fullName": "...", "email": "...", "password": "...", "role": "passenger" }
  /// ```
  Future<({AppUser user, String token})> register({
    required String fullName,
    required String email,
    required String password,
    String role = 'passenger',
  }) async {
    final data = await _client.post(
      ApiConstants.register,
      {
        'fullName': fullName,
        'email': email,
        'password': password,
        'role': role,
      },
      auth: false,
    ) as Map<String, dynamic>;

    final token = data['token'] as String;
    await _storage.saveToken(token);
    return (user: AppUser.fromJson(data['user'] as Map<String, dynamic>), token: token);
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
    final data = await _client.post(
      ApiConstants.login,
      {'email': email, 'password': password},
      auth: false,
    ) as Map<String, dynamic>;

    final token = data['token'] as String;
    await _storage.saveToken(token);
    return (user: AppUser.fromJson(data['user'] as Map<String, dynamic>), token: token);
  }

  Future<void> logout() => _storage.deleteToken();

  /// Returns the stored token, or null when not logged in.
  Future<String?> getToken() => _storage.getToken();
}
