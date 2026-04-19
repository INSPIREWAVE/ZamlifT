import 'package:flutter/material.dart';

import '../../../core/models/booking.dart';
import '../../../core/models/payment.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/booking_service.dart';
import '../../../core/services/payment_service.dart';

class BookingProvider extends ChangeNotifier {
  BookingProvider({
    required BookingService bookingService,
    required PaymentService paymentService,
  })  : _bookingService = bookingService,
        _paymentService = paymentService;

  final BookingService _bookingService;
  final PaymentService _paymentService;

  List<Booking> _bookings = [];
  bool _loading = false;
  String? _error;

  List<Booking> get bookings => _bookings;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> loadMyBookings() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _bookings = await _bookingService.getMyBookings();
    } on ApiException catch (e) {
      _error = e.message;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<Booking?> createBooking({
    required String tripId,
    required String pickupStopId,
    required String dropoffStopId,
    required int seatsBooked,
  }) async {
    _error = null;
    try {
      final booking = await _bookingService.createBooking(
        tripId: tripId,
        pickupStopId: pickupStopId,
        dropoffStopId: dropoffStopId,
        seatsBooked: seatsBooked,
      );
      _bookings = [booking, ..._bookings];
      notifyListeners();
      return booking;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return null;
    }
  }

  Future<Booking?> cancelBooking(String bookingId) async {
    _error = null;
    try {
      final updated = await _bookingService.updateBookingStatus(
        bookingId: bookingId,
        status: 'cancelled',
      );
      _bookings = [
        for (final b in _bookings) b.id == bookingId ? updated : b,
      ];
      notifyListeners();
      return updated;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return null;
    }
  }

  Future<Payment?> deposit({
    required String bookingId,
    required double amount,
    required String phoneNumber,
  }) async {
    _error = null;
    try {
      return await _paymentService.deposit(
        bookingId: bookingId,
        amount: amount,
        phoneNumber: phoneNumber,
      );
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return null;
    }
  }
}
