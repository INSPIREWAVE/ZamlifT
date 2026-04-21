/// Mirrors the `trips` table joined with `routes` and `users` data.
///
/// Extra joined fields returned by the API:
///   route_name, origin_city, destination_city, driver_name
class Trip {
  const Trip({
    required this.id,
    required this.driverId,
    required this.vehicleId,
    required this.routeId,
    required this.departureTime,
    required this.seatsTotal,
    required this.seatsAvailable,
    required this.pricePerSeat,
    required this.status,
    this.routeName,
    this.originCity,
    this.destinationCity,
    this.driverName,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String driverId;
  final String vehicleId;
  final String routeId;
  final DateTime departureTime;
  final int seatsTotal;
  final int seatsAvailable;
  final double pricePerSeat;
  final String status; // 'scheduled' | 'on_trip' | 'completed' | 'cancelled'

  // Joined fields
  final String? routeName;
  final String? originCity;
  final String? destinationCity;
  final String? driverName;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isBookable =>
      (status == 'scheduled' || status == 'on_trip') && seatsAvailable > 0;

  factory Trip.fromJson(Map<String, dynamic> json) => Trip(
        id: json['id'] as String,
        driverId: json['driver_id'] as String,
        vehicleId: json['vehicle_id'] as String,
        routeId: json['route_id'] as String,
        departureTime: DateTime.parse(json['departure_time'] as String),
        seatsTotal: (json['seats_total'] as num).toInt(),
        seatsAvailable: (json['seats_available'] as num).toInt(),
        pricePerSeat:
            double.parse(json['price_per_seat']?.toString() ?? '0'),
        status: json['status'] as String,
        routeName: json['route_name'] as String?,
        originCity: json['origin_city'] as String?,
        destinationCity: json['destination_city'] as String?,
        driverName: json['driver_name'] as String?,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : null,
        updatedAt: json['updated_at'] != null
            ? DateTime.parse(json['updated_at'] as String)
            : null,
      );
}
