/// Mirrors the `routes` table.
class AppRoute {
  const AppRoute({
    required this.id,
    required this.name,
    required this.originCity,
    required this.destinationCity,
    required this.baseDistanceKm,
    this.createdAt,
  });

  final String id;
  final String name;
  final String originCity;
  final String destinationCity;
  final double baseDistanceKm;
  final DateTime? createdAt;

  factory AppRoute.fromJson(Map<String, dynamic> json) => AppRoute(
        id: json['id'] as String,
        name: json['name'] as String,
        originCity: json['origin_city'] as String,
        destinationCity: json['destination_city'] as String,
        baseDistanceKm:
            double.parse(json['base_distance_km']?.toString() ?? '0'),
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : null,
      );
}
