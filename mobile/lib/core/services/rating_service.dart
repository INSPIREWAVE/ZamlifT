import '../constants/api_constants.dart';
import '../models/rating.dart';
import '../network/api_client.dart';
import '../storage/token_storage.dart';

/// Rating endpoints:
///
/// POST /api/ratings                        (auth – passenger, completed trip)
/// GET  /api/ratings/driver/:driverId       (public)
class RatingService {
  RatingService({required TokenStorage tokenStorage})
      : _client = ApiClient(tokenStorage: tokenStorage);

  final ApiClient _client;

  /// Submit a rating for a completed trip.
  ///
  /// Request body:
  /// ```json
  /// { "tripId": "uuid", "rating": 5, "comment": "Great ride!" }
  /// ```
  /// Constraints: trip must be completed, caller must have a completed booking.
  Future<Rating> createRating({
    required String tripId,
    required int rating,
    String comment = '',
  }) async {
    final data = await _client.post(
      ApiConstants.ratings,
      {
        'tripId': tripId,
        'rating': rating,
        'comment': comment,
      },
    ) as Map<String, dynamic>;
    return Rating.fromJson(data);
  }

  /// Get all ratings for a driver (public).
  Future<List<Rating>> getDriverRatings(String driverId) async {
    final data = await _client.get(
      ApiConstants.driverRatings(driverId),
      auth: false,
    ) as List;
    return data.cast<Map<String, dynamic>>().map(Rating.fromJson).toList();
  }
}
