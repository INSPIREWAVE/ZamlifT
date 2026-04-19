import '../constants/api_constants.dart';
import '../models/stop.dart';
import '../network/api_client.dart';
import '../storage/token_storage.dart';

/// Smart / AI endpoints:
///
/// GET /api/smart/stops?query=   (public)
/// GET /api/smart/pricing?routeId=uuid  (public)
class SmartService {
  SmartService({required TokenStorage tokenStorage})
      : _client = ApiClient(tokenStorage: tokenStorage);

  final ApiClient _client;

  /// Get popular / matching stops for autocomplete.
  ///
  /// [query]: partial stop name or city (optional).
  Future<List<Stop>> getSuggestedStops({String query = ''}) async {
    final data = await _client.get(
      ApiConstants.smartStops,
      queryParams: query.isNotEmpty ? {'query': query} : null,
      auth: false,
    ) as List;
    return data.cast<Map<String, dynamic>>().map(Stop.fromJson).toList();
  }

  /// Get the historically suggested price per seat for a route.
  ///
  /// Returns:
  /// ```json
  /// { "routeId": "uuid",
  ///   "suggestedPricePerSeat": 250.00,
  ///   "historicalBookingCount": 42 }
  /// ```
  Future<({String routeId, double? suggestedPricePerSeat, int historicalBookingCount})>
      getRoutePriceSuggestion(String routeId) async {
    final data = await _client.get(
      ApiConstants.smartPricing,
      queryParams: {'routeId': routeId},
      auth: false,
    ) as Map<String, dynamic>;
    return (
      routeId: data['routeId'] as String,
      suggestedPricePerSeat: data['suggestedPricePerSeat'] != null
          ? (data['suggestedPricePerSeat'] as num).toDouble()
          : null,
      historicalBookingCount:
          (data['historicalBookingCount'] as num).toInt(),
    );
  }
}
