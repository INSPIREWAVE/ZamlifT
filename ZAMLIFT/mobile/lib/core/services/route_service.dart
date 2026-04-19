import '../constants/api_constants.dart';
import '../models/route.dart';
import '../models/stop.dart';
import '../network/api_client.dart';
import '../storage/token_storage.dart';

/// Routes & stops endpoints:
///
/// POST /api/routes                        (admin)
/// GET  /api/routes
/// POST /api/routes/:routeId/stops         (admin)
/// GET  /api/routes/:routeId/stops
class RouteService {
  RouteService({required TokenStorage tokenStorage})
      : _client = ApiClient(tokenStorage: tokenStorage);

  final ApiClient _client;

  /// [Admin only] Create a new route.
  ///
  /// Request body:
  /// ```json
  /// { "name": "...", "originCity": "...", "destinationCity": "...",
  ///   "baseDistanceKm": 320.5 }
  /// ```
  Future<AppRoute> createRoute({
    required String name,
    required String originCity,
    required String destinationCity,
    required double baseDistanceKm,
  }) async {
    final data = await _client.post(
      ApiConstants.routes,
      {
        'name': name,
        'originCity': originCity,
        'destinationCity': destinationCity,
        'baseDistanceKm': baseDistanceKm,
      },
    ) as Map<String, dynamic>;
    return AppRoute.fromJson(data);
  }

  /// List all routes (public).
  Future<List<AppRoute>> listRoutes() async {
    final data = await _client.get(ApiConstants.routes, auth: false) as List;
    return data.cast<Map<String, dynamic>>().map(AppRoute.fromJson).toList();
  }

  /// [Admin only] Add a stop to a route.
  ///
  /// Request body:
  /// ```json
  /// { "name": "...", "city": "...", "latitude": -15.4, "longitude": 28.3,
  ///   "sequenceOrder": 1 }
  /// ```
  ///
  /// Returns `{"stop": {...}, "routeStop": {...}}`.
  Future<({Stop stop, Map<String, dynamic> routeStop})> addStop({
    required String routeId,
    required String name,
    required String city,
    required double latitude,
    required double longitude,
    required int sequenceOrder,
  }) async {
    final data = await _client.post(
      ApiConstants.routeStops(routeId),
      {
        'name': name,
        'city': city,
        'latitude': latitude,
        'longitude': longitude,
        'sequenceOrder': sequenceOrder,
      },
    ) as Map<String, dynamic>;
    return (
      stop: Stop.fromJson(data['stop'] as Map<String, dynamic>),
      routeStop: data['routeStop'] as Map<String, dynamic>,
    );
  }

  /// Get ordered stops for a route (public).
  Future<List<Stop>> listRouteStops(String routeId) async {
    final data =
        await _client.get(ApiConstants.routeStops(routeId), auth: false) as List;
    return data.cast<Map<String, dynamic>>().map(Stop.fromJson).toList();
  }
}
