/// Mirrors the `bookings` table joined with trip + route data.
///
/// Extra joined fields returned by the API:
///   departure_time, trip_status, route_name
class Booking {
  const Booking({
    required this.id,
    required this.tripId,
    required this.passengerId,
    required this.pickupStopId,
    required this.dropoffStopId,
    required this.seatsBooked,
    required this.totalPrice,
    required this.status,
    required this.paymentStatus,
    this.departureTime,
    this.tripStatus,
    this.routeName,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String tripId;
  final String passengerId;
  final String pickupStopId;
  final String dropoffStopId;
  final int seatsBooked;
  final double totalPrice;
  final String status; // 'pending' | 'confirmed' | 'cancelled' | 'completed'
  final String paymentStatus; // 'pending' | 'paid' | 'failed' | 'refunded'

  // Joined fields (from GET /api/bookings/my)
  final DateTime? departureTime;
  final String? tripStatus;
  final String? routeName;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isPaid => paymentStatus == 'paid';
  bool get isCancelled => status == 'cancelled';

  factory Booking.fromJson(Map<String, dynamic> json) => Booking(
        id: json['id'] as String,
        tripId: json['trip_id'] as String,
        passengerId: json['passenger_id'] as String,
        pickupStopId: json['pickup_stop_id'] as String,
        dropoffStopId: json['dropoff_stop_id'] as String,
        seatsBooked: (json['seats_booked'] as num).toInt(),
        totalPrice: double.parse(json['total_price']?.toString() ?? '0'),
        status: json['status'] as String,
        paymentStatus: json['payment_status'] as String,
        departureTime: json['departure_time'] != null
            ? DateTime.parse(json['departure_time'] as String)
            : null,
        tripStatus: json['trip_status'] as String?,
        routeName: json['route_name'] as String?,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : null,
        updatedAt: json['updated_at'] != null
            ? DateTime.parse(json['updated_at'] as String)
            : null,
      );
}
