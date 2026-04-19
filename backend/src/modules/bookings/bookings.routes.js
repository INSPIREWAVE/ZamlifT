const express = require('express');
const Joi = require('joi');
const db = require('../../config/db');
const { authenticate, authorize } = require('../../middlewares/auth');
const validate = require('../../middlewares/validate');
const HttpError = require('../../utils/httpError');

const router = express.Router();

const createBookingSchema = Joi.object({
  tripId: Joi.number().integer().required(),
  seatsBooked: Joi.number().integer().min(1).required(),
  pickupStopId: Joi.number().integer().required(),
  dropoffStopId: Joi.number().integer().required(),
});

const statusSchema = Joi.object({
  status: Joi.string().valid('pending', 'confirmed', 'cancelled', 'completed').required(),
});

const BOOKING_STATUS_TRANSITIONS = {
  pending: ['confirmed', 'cancelled'],
  confirmed: ['completed', 'cancelled'],
  cancelled: [],
  completed: [],
};

router.post('/', authenticate, authorize('passenger'), validate(createBookingSchema), async (req, res, next) => {
  try {
    const { tripId, seatsBooked, pickupStopId, dropoffStopId } = req.body;
    const trip = await db.query('SELECT id, available_seats, price FROM trips WHERE id = $1', [tripId]);
    if (!trip.rowCount) throw new HttpError(404, 'Trip not found');
    if (trip.rows[0].available_seats < seatsBooked) throw new HttpError(400, 'Insufficient seats available');

    const amount = Number(trip.rows[0].price) * seatsBooked;
    const booking = await db.query(
      `INSERT INTO bookings (trip_id, passenger_id, seats_booked, pickup_stop_id, dropoff_stop_id, total_amount, status)
       VALUES ($1, $2, $3, $4, $5, $6, 'pending') RETURNING *`,
      [tripId, req.user.id, seatsBooked, pickupStopId, dropoffStopId, amount],
    );
    await db.query('UPDATE trips SET available_seats = available_seats - $1 WHERE id = $2', [seatsBooked, tripId]);

    res.status(201).json(booking.rows[0]);
  } catch (error) {
    next(error);
  }
});

router.get('/me', authenticate, authorize('passenger'), async (req, res, next) => {
  try {
    const result = await db.query(
      `SELECT b.*, t.departure_time, t.start_location, t.destination
       FROM bookings b
       JOIN trips t ON t.id = b.trip_id
       WHERE b.passenger_id = $1
       ORDER BY b.created_at DESC`,
      [req.user.id],
    );
    res.json(result.rows);
  } catch (error) {
    next(error);
  }
});

router.patch('/:id/status', authenticate, authorize('driver', 'admin'), validate(statusSchema), async (req, res, next) => {
  try {
    const nextStatus = req.body.status;
    const updateBookingStatusQuery = `UPDATE bookings SET status = $2, updated_at = NOW()
       WHERE id = $1
         AND (
           (status = 'pending' AND $2 IN ('confirmed', 'cancelled'))
           OR (status = 'confirmed' AND $2 IN ('completed', 'cancelled'))
         )
       RETURNING *`;
    let result = await db.query(updateBookingStatusQuery, [req.params.id, nextStatus]);

    if (!result.rowCount) {
      const currentBooking = await db.query('SELECT status FROM bookings WHERE id = $1', [req.params.id]);
      if (!currentBooking.rowCount) throw new HttpError(404, 'Booking not found');

      const currentStatus = currentBooking.rows[0].status;
      const allowedTransitions = BOOKING_STATUS_TRANSITIONS[currentStatus] || [];
      if (!allowedTransitions.includes(nextStatus)) {
        throw new HttpError(400, `Invalid booking status transition: ${currentStatus} -> ${nextStatus}`);
      }

      result = await db.query(updateBookingStatusQuery, [req.params.id, nextStatus]);
      if (!result.rowCount) throw new HttpError(409, 'Booking status update conflict, please retry');
    }

    res.json(result.rows[0]);
  } catch (error) {
    next(error);
  }
});

module.exports = router;
