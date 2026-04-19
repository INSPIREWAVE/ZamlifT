import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/models/route.dart';
import '../../../core/models/stop.dart';
import '../../../core/models/trip.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/route_service.dart';
import '../../../core/services/trip_service.dart';

class TripProvider extends ChangeNotifier {
  TripProvider({
    required TripService tripService,
    required RouteService routeService,
  })  : _tripService = tripService,
        _routeService = routeService;

  final TripService _tripService;
  final RouteService _routeService;

  List<Trip> _searchResults = [];
  List<AppRoute> _routes = [];
  List<Stop> _stops = [];
  bool _loading = false;
  String? _error;

  List<Trip> get searchResults => _searchResults;
  List<AppRoute> get routes => _routes;
  List<Stop> get stops => _stops;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> loadRoutes() async {
    try {
      _routes = await _routeService.listRoutes();
      notifyListeners();
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
    }
  }

  Future<void> loadStopsForRoute(String routeId) async {
    try {
      _stops = await _routeService.listRouteStops(routeId);
      notifyListeners();
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
    }
  }

  Future<void> searchTrips({
    required String fromStopId,
    required String toStopId,
    required DateTime departureDate,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(departureDate);
      _searchResults = await _tripService.searchTrips(
        fromStopId: fromStopId,
        toStopId: toStopId,
        departureDate: dateStr,
      );
    } on ApiException catch (e) {
      _error = e.message;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<Trip?> createTrip({
    required String vehicleId,
    required String routeId,
    required DateTime departureTime,
    required int seatsTotal,
    required double pricePerSeat,
  }) async {
    _error = null;
    try {
      return await _tripService.createTrip(
        vehicleId: vehicleId,
        routeId: routeId,
        departureTime: departureTime,
        seatsTotal: seatsTotal,
        pricePerSeat: pricePerSeat,
      );
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return null;
    }
  }
}
