import '../constants/api_constants.dart';
import '../models/driver_profile.dart';
import '../models/vehicle.dart';
import '../network/api_client.dart';
import '../storage/token_storage.dart';

/// Driver & vehicle endpoints:
///
/// POST  /api/drivers/profile          (driver auth)
/// POST  /api/drivers/vehicle          (driver auth)
/// GET   /api/drivers/pending          (admin auth)
/// PATCH /api/drivers/:driverId/verify (admin auth)
class DriverService {
  DriverService({required TokenStorage tokenStorage})
      : _client = ApiClient(tokenStorage: tokenStorage);

  final ApiClient _client;

  /// Create or update the caller's driver profile.
  ///
  /// Request body:
  /// ```json
  /// { "licenseNumber": "...", "nationalId": "...", "phone": "..." }
  /// ```
  Future<DriverProfile> upsertProfile({
    required String licenseNumber,
    required String nationalId,
    required String phone,
  }) async {
    final data = await _client.post(
      ApiConstants.driverProfile,
      {
        'licenseNumber': licenseNumber,
        'nationalId': nationalId,
        'phone': phone,
      },
    ) as Map<String, dynamic>;
    return DriverProfile.fromJson(data);
  }

  /// Register a vehicle for the authenticated driver.
  ///
  /// Request body:
  /// ```json
  /// { "make": "...", "model": "...", "year": 2020,
  ///   "plateNumber": "...", "seatCapacity": 4 }
  /// ```
  Future<Vehicle> registerVehicle({
    required String make,
    required String model,
    required int year,
    required String plateNumber,
    required int seatCapacity,
  }) async {
    final data = await _client.post(
      ApiConstants.driverVehicle,
      {
        'make': make,
        'model': model,
        'year': year,
        'plateNumber': plateNumber,
        'seatCapacity': seatCapacity,
      },
    ) as Map<String, dynamic>;
    return Vehicle.fromJson(data);
  }

  /// [Admin only] List drivers awaiting verification.
  Future<List<DriverProfile>> listPendingDrivers() async {
    final data = await _client.get(ApiConstants.driversPending) as List;
    return data
        .cast<Map<String, dynamic>>()
        .map(DriverProfile.fromJson)
        .toList();
  }

  /// [Admin only] Approve or reject a driver.
  ///
  /// [status]: 'approved' | 'rejected'
  Future<DriverProfile> verifyDriver({
    required String driverId,
    required String status,
  }) async {
    final data = await _client.patch(
      ApiConstants.driverVerify(driverId),
      {'status': status},
    ) as Map<String, dynamic>;
    return DriverProfile.fromJson(data);
  }
}
