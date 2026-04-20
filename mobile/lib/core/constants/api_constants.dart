import 'package:flutter/foundation.dart';

/// All backend API paths.
///
/// Override [baseUrl] via [ApiConstants.configure] before starting the app
/// (e.g. from a .env file or compile-time define).
class ApiConstants {
  ApiConstants._();

  static String baseUrl = _defaultBaseUrl();

  static String _defaultBaseUrl() {
    if (kIsWeb) {
      return 'http://localhost:5000';
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:5000';
    }

    return 'http://localhost:5000';
  }

  static void configure(String url) => baseUrl = url.replaceAll(RegExp(r'/$'), '');

  // ── Auth ──────────────────────────────────────────────────────────────────
  static String get register => '$baseUrl/api/auth/register';
  static String get login => '$baseUrl/api/auth/login';

  // ── Drivers ───────────────────────────────────────────────────────────────
  static String get driverProfile => '$baseUrl/api/drivers/profile';
  static String get driverVehicle => '$baseUrl/api/drivers/vehicle';
  static String get driversPending => '$baseUrl/api/drivers/pending';
  static String driverVerify(String driverId) =>
      '$baseUrl/api/drivers/$driverId/verify';

  // ── Routes ────────────────────────────────────────────────────────────────
  static String get routes => '$baseUrl/api/routes';
  static String routeStops(String routeId) =>
      '$baseUrl/api/routes/$routeId/stops';

  // ── Trips ─────────────────────────────────────────────────────────────────
  static String get trips => '$baseUrl/api/trips';
  static String get tripsSearch => '$baseUrl/api/trips/search';
  static String tripById(String tripId) => '$baseUrl/api/trips/$tripId';
  static String tripStatus(String tripId) =>
      '$baseUrl/api/trips/$tripId/status';

  // ── Bookings ──────────────────────────────────────────────────────────────
  static String get bookings => '$baseUrl/api/bookings';
  static String get myBookings => '$baseUrl/api/bookings/my';
  static String bookingStatus(String bookingId) =>
      '$baseUrl/api/bookings/$bookingId/status';

  // ── Payments ──────────────────────────────────────────────────────────────
  static String get deposit => '$baseUrl/api/payments/deposit';
  static String get myPayments => '$baseUrl/api/payments/my';
  static String get allPayments => '$baseUrl/api/payments';
  static String paymentStatus(String paymentId) =>
      '$baseUrl/api/payments/$paymentId/status';

  // ── Ratings ───────────────────────────────────────────────────────────────
  static String get ratings => '$baseUrl/api/ratings';
  static String driverRatings(String driverId) =>
      '$baseUrl/api/ratings/driver/$driverId';

  // ── Smart ─────────────────────────────────────────────────────────────────
  static String get smartStops => '$baseUrl/api/smart/stops';
  static String get smartPricing => '$baseUrl/api/smart/pricing';

  // ── Chat ──────────────────────────────────────────────────────────────────
  static String tripMessages(String tripId) =>
      '$baseUrl/api/chat/trips/$tripId/messages';

  // ── Health ────────────────────────────────────────────────────────────────
  static String get health => '$baseUrl/api/health';
}
