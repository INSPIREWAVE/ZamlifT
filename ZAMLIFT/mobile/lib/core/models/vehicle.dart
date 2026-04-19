/// Mirrors the `vehicles` table.
class Vehicle {
  const Vehicle({
    required this.id,
    required this.driverId,
    required this.make,
    required this.model,
    required this.year,
    required this.plateNumber,
    required this.seatCapacity,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String driverId;
  final String make;
  final String model;
  final int year;
  final String plateNumber;
  final int seatCapacity;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory Vehicle.fromJson(Map<String, dynamic> json) => Vehicle(
        id: json['id'] as String,
        driverId: json['driver_id'] as String,
        make: json['make'] as String,
        model: json['model'] as String,
        year: (json['year'] as num).toInt(),
        plateNumber: json['plate_number'] as String,
        seatCapacity: (json['seat_capacity'] as num).toInt(),
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : null,
        updatedAt: json['updated_at'] != null
            ? DateTime.parse(json['updated_at'] as String)
            : null,
      );
}
