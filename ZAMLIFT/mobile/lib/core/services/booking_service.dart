import '../constants/api_constants.dart';
import '../models/booking.dart';
import '../network/api_client.dart';
import '../storage/token_storage.dart';

/// Booking endpoints:
///
/// POST  /api/bookings                          (auth)
/// GET   /api/bookings/my                       (auth)
/// PATCH /api/bookings/:bookingId/status        (auth)
class BookingService {
  BookingService({required TokenStorage tokenStorage})
      : _client = ApiClient(tokenStorage: tokenStorage);

  final ApiClient _client;

  /// Book seats on a trip.
  ///
  /// Request body:
  /// ```json
  /// { "tripId": "uuid", "pickupStopId": "uuid",
  ///   "dropoffStopId": "uuid", "seatsBooked": 2 }
  /// ```
  Future<Booking> createBooking({
    required String tripId,
    required String pickupStopId,
    required String dropoffStopId,
    required int seatsBooked,
  }) async {
    final data = await _client.post(
      ApiConstants.bookings,
      {
        'tripId': tripId,
        'pickupStopId': pickupStopId,
        'dropoffStopId': dropoffStopId,
        'seatsBooked': seatsBooked,
      },
    ) as Map<String, dynamic>;
    return Booking.fromJson(data);
  }

  /// List the authenticated user's bookings.
  Future<List<Booking>> getMyBookings() async {
    final data = await _client.get(ApiConstants.myBookings) as List;
    return data.cast<Map<String, dynamic>>().map(Booking.fromJson).toList();
  }

  /// Update a booking's status (passenger, driver, or admin).
  ///
  /// [status]: 'pending' | 'confirmed' | 'cancelled' | 'completed'
  Future<Booking> updateBookingStatus({
    required String bookingId,
    required String status,
  }) async {
    final data = await _client.patch(
      ApiConstants.bookingStatus(bookingId),
      {'status': status},
    ) as Map<String, dynamic>;
    return Booking.fromJson(data);
  }
}
