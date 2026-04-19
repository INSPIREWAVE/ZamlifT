/// Mirrors the `stops` table (also returned with `route_stops` JOIN).
class Stop {
  const Stop({
    required this.id,
    required this.name,
    required this.city,
    required this.latitude,
    required this.longitude,
    required this.popularityScore,
    this.sequenceOrder,
    this.routeId,
  });

  final String id;
  final String name;
  final String city;
  final double latitude;
  final double longitude;
  final int popularityScore;

  // Only present when returned from GET /api/routes/:routeId/stops
  final int? sequenceOrder;
  final String? routeId;

  String get displayName => '$name, $city';

  factory Stop.fromJson(Map<String, dynamic> json) => Stop(
        id: json['id'] as String,
        name: json['name'] as String,
        city: json['city'] as String,
        latitude: double.parse(json['latitude']?.toString() ?? '0'),
        longitude: double.parse(json['longitude']?.toString() ?? '0'),
        popularityScore: (json['popularity_score'] as num?)?.toInt() ?? 0,
        sequenceOrder: (json['sequence_order'] as num?)?.toInt(),
        routeId: json['route_id'] as String?,
      );
}
