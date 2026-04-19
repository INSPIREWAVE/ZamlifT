/// Mirrors `driver_ratings` joined with `users` (passenger_name).
class Rating {
  const Rating({
    required this.id,
    required this.tripId,
    required this.driverId,
    required this.passengerId,
    required this.rating,
    required this.comment,
    this.passengerName,
    this.createdAt,
  });

  final String id;
  final String tripId;
  final String driverId;
  final String passengerId;
  final int rating; // 1..5
  final String comment;
  final String? passengerName; // joined from users
  final DateTime? createdAt;

  factory Rating.fromJson(Map<String, dynamic> json) => Rating(
        id: json['id'] as String,
        tripId: json['trip_id'] as String,
        driverId: json['driver_id'] as String,
        passengerId: json['passenger_id'] as String,
        rating: (json['rating'] as num).toInt(),
        comment: json['comment'] as String? ?? '',
        passengerName: json['passenger_name'] as String?,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : null,
      );
}
