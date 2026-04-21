const { getUserBookings, listAllBookings, getBookingById } = require('../models/bookingModel');
const { getTripById } = require('../models/tripModel');
const {
  createBookingWithSeatReservation,
  updateBookingStatusWithSeatAdjustment,
} = require('../services/bookingService');

async function createBookingHandler(req, res, next) {
  try {
    const booking = await createBookingWithSeatReservation({
      ...req.validated.body,
      passengerId: req.user.id,
    });

    return res.status(201).json(booking);
  } catch (error) {
    return next(error);
  }
}

async function listMyBookingsHandler(req, res, next) {
  try {
    const bookings = await getUserBookings(req.user.id);
    return res.json(bookings);
  } catch (error) {
    return next(error);
  }
}

async function listBookingsAdminHandler(req, res, next) {
  try {
    const bookings = await listAllBookings();
    return res.json(bookings);
  } catch (error) {
    return next(error);
  }
}

async function updateBookingStatusHandler(req, res, next) {
  try {
    const { bookingId } = req.validated.params;
    const { status } = req.validated.body;

    const booking = await getBookingById(bookingId);
    if (!booking) {
      return res.status(404).json({ message: 'Booking not found' });
    }

    const trip = await getTripById(booking.trip_id);
    if (
      req.user.role !== 'admin' &&
      (trip === null || trip.driver_id !== req.user.id) &&
      booking.passenger_id !== req.user.id
    ) {
      return res.status(403).json({ message: 'Forbidden' });
    }

    const updated = await updateBookingStatusWithSeatAdjustment({
      bookingId,
      status,
    });

    return res.json(updated);
  } catch (error) {
    return next(error);
  }
}

module.exports = {
  createBookingHandler,
  listMyBookingsHandler,
  listBookingsAdminHandler,
  updateBookingStatusHandler,
};
