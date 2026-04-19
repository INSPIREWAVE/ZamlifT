import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../storage/token_storage.dart';

/// Thin HTTP wrapper that:
///  * attaches `Authorization: Bearer <token>` when a token is stored,
///  * sets `Content-Type: application/json`,
///  * parses JSON responses and throws [ApiException] on non-2xx status codes.
class ApiClient {
  ApiClient({required TokenStorage tokenStorage})
      : _tokenStorage = tokenStorage;

  final TokenStorage _tokenStorage;
  static const Duration _timeout = Duration(seconds: 30);

  // ── helpers ────────────────────────────────────────────────────────────────

  Future<Map<String, String>> _headers({bool auth = true}) async {
    final headers = <String, String>{
      HttpHeaders.contentTypeHeader: 'application/json',
      HttpHeaders.acceptHeader: 'application/json',
    };
    if (auth) {
      final token = await _tokenStorage.getToken();
      if (token != null) {
        headers[HttpHeaders.authorizationHeader] = 'Bearer $token';
      }
    }
    return headers;
  }

  dynamic _parse(http.Response response) {
    final body = response.body.isEmpty ? '{}' : response.body;
    final decoded = jsonDecode(body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }
    final message = (decoded is Map && decoded['message'] is String)
        ? decoded['message'] as String
        : 'Request failed (${response.statusCode})';
    throw ApiException(statusCode: response.statusCode, message: message);
  }

  // ── public methods ─────────────────────────────────────────────────────────

  Future<dynamic> get(
    String url, {
    Map<String, String>? queryParams,
    bool auth = true,
  }) async {
    final uri = Uri.parse(url).replace(queryParameters: queryParams);
    final response = await http
        .get(uri, headers: await _headers(auth: auth))
        .timeout(_timeout);
    return _parse(response);
  }

  Future<dynamic> post(
    String url,
    Map<String, dynamic> body, {
    bool auth = true,
  }) async {
    final response = await http
        .post(
          Uri.parse(url),
          headers: await _headers(auth: auth),
          body: jsonEncode(body),
        )
        .timeout(_timeout);
    return _parse(response);
  }

  Future<dynamic> patch(
    String url,
    Map<String, dynamic> body, {
    bool auth = true,
  }) async {
    final response = await http
        .patch(
          Uri.parse(url),
          headers: await _headers(auth: auth),
          body: jsonEncode(body),
        )
        .timeout(_timeout);
    return _parse(response);
  }
}

class ApiException implements Exception {
  const ApiException({required this.statusCode, required this.message});
  final int statusCode;
  final String message;

  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isNotFound => statusCode == 404;
  bool get isConflict => statusCode == 409;

  @override
  String toString() => 'ApiException($statusCode): $message';
}
