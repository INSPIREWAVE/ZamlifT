const { createBooking, getUserBookings, updateBookingStatus, getBookingById } = require('../models/bookingModel');
const { getTripById, adjustTripSeats } = require('../models/tripModel');
const { incrementStopPopularity } = require('../models/routeModel');

async function createBookingHandler(req, res, next) {
  try {
    const { tripId, pickupStopId, dropoffStopId, seatsBooked } = req.validated.body;

    const trip = await getTripById(tripId);
    if (!trip) {
      return res.status(404).json({ message: 'Trip not found' });
    }

    if (!['scheduled', 'ongoing'].includes(trip.status)) {
      return res.status(400).json({ message: 'Trip is not available for booking' });
    }

    if (trip.seats_available < seatsBooked) {
      return res.status(400).json({ message: 'Not enough seats available' });
    }

    const totalPrice = Number(trip.price_per_seat) * seatsBooked;

    const updatedTrip = await adjustTripSeats(tripId, -seatsBooked);
    if (!updatedTrip) {
      return res.status(400).json({ message: 'Unable to reserve seats' });
    }

    const booking = await createBooking({
      tripId,
      passengerId: req.user.id,
      pickupStopId,
      dropoffStopId,
      seatsBooked,
      totalPrice,
    });

    await Promise.all([
      incrementStopPopularity(pickupStopId),
      incrementStopPopularity(dropoffStopId),
    ]);

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

    const updated = await updateBookingStatus(bookingId, status);

    if (status === 'cancelled') {
      await adjustTripSeats(booking.trip_id, booking.seats_booked);
    }

    return res.json(updated);
  } catch (error) {
    return next(error);
  }
}

module.exports = {
  createBookingHandler,
  listMyBookingsHandler,
  updateBookingStatusHandler,
};
