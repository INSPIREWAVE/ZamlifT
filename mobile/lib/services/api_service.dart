import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/env.dart';

class ApiService {
  String? _token;

  void setToken(String token) => _token = token;

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('${Env.apiBaseUrl}/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      throw Exception(data['message'] ?? 'Login failed');
    }
    if (data['token'] != null) {
      setToken(data['token'] as String);
    }
    return data;
  }

  Future<List<dynamic>> searchTrips() async {
    final response = await http.get(Uri.parse('${Env.apiBaseUrl}/trips/search'));
    if (response.statusCode >= 400) {
      throw Exception('Failed to fetch trips');
    }
    return jsonDecode(response.body) as List<dynamic>;
  }

  Future<Map<String, dynamic>> createBooking({
    required int tripId,
    required int seatsBooked,
    required int pickupStopId,
    required int dropoffStopId,
  }) async {
    final response = await http.post(
      Uri.parse('${Env.apiBaseUrl}/bookings'),
      headers: {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      },
      body: jsonEncode({
        'tripId': tripId,
        'seatsBooked': seatsBooked,
        'pickupStopId': pickupStopId,
        'dropoffStopId': dropoffStopId,
      }),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      throw Exception(data['message'] ?? 'Booking failed');
    }
    return data;
  }
}
