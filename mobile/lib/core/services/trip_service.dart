import '../constants/api_constants.dart';
import '../models/trip.dart';
import '../network/api_client.dart';
import '../storage/token_storage.dart';

/// Trip endpoints:
///
/// POST  /api/trips                      (driver auth)
/// GET   /api/trips/search?fromStopId=&toStopId=&departureDate=
/// GET   /api/trips/:tripId
/// PATCH /api/trips/:tripId/status       (auth)
class TripService {
  TripService({required TokenStorage tokenStorage})
      : _client = ApiClient(tokenStorage: tokenStorage);

  final ApiClient _client;

  /// Create a scheduled trip (driver only).
  ///
  /// Request body:
  /// ```json
  /// { "vehicleId": "uuid", "routeId": "uuid",
  ///   "departureTime": "2025-12-01T08:00:00.000Z",
  ///   "seatsTotal": 4, "pricePerSeat": 250.00 }
  /// ```
  Future<Trip> createTrip({
    required String vehicleId,
    required String routeId,
    required DateTime departureTime,
    required int seatsTotal,
    required double pricePerSeat,
  }) async {
    final data = await _client.post(
      ApiConstants.trips,
      {
        'vehicleId': vehicleId,
        'routeId': routeId,
        'departureTime': departureTime.toUtc().toIso8601String(),
        'seatsTotal': seatsTotal,
        'pricePerSeat': pricePerSeat,
      },
    ) as Map<String, dynamic>;
    return Trip.fromJson(data);
  }

  /// Search for available trips.
  ///
  /// [departureDate] must be formatted as `YYYY-MM-DD`.
  Future<List<Trip>> searchTrips({
    required String fromStopId,
    required String toStopId,
    required String departureDate,
  }) async {
    final data = await _client.get(
      ApiConstants.tripsSearch,
      queryParams: {
        'fromStopId': fromStopId,
        'toStopId': toStopId,
        'departureDate': departureDate,
      },
      auth: false,
    ) as List;
    return data.cast<Map<String, dynamic>>().map(Trip.fromJson).toList();
  }

  /// Get a single trip by ID.
  Future<Trip> getTripById(String tripId) async {
    final data =
        await _client.get(ApiConstants.tripById(tripId), auth: false)
            as Map<String, dynamic>;
    return Trip.fromJson(data);
  }

  /// Update the status of a trip (driver or admin).
  ///
  /// [status]: 'scheduled' | 'ongoing' | 'completed' | 'cancelled'
  Future<Trip> updateTripStatus({
    required String tripId,
    required String status,
  }) async {
    final data = await _client.patch(
      ApiConstants.tripStatus(tripId),
      {'status': status},
    ) as Map<String, dynamic>;
    return Trip.fromJson(data);
  }
}
