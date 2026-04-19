import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists the JWT token securely on-device using the platform's keystore
/// (Keychain on iOS, EncryptedSharedPreferences on Android).
class TokenStorage {
  static const _tokenKey = 'zamlift_jwt';

  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  Future<void> saveToken(String token) =>
      _storage.write(key: _tokenKey, value: token);

  Future<String?> getToken() => _storage.read(key: _tokenKey);

  Future<void> deleteToken() => _storage.delete(key: _tokenKey);
}
