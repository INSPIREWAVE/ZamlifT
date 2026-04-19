const { pool } = require('../config/db');
const BOOKING_STATUS_CANCELLED = 'cancelled';
const ALLOWED_BOOKING_STATUSES = new Set(['pending', 'confirmed', BOOKING_STATUS_CANCELLED, 'completed']);

function httpError(status, message) {
  const error = new Error(message);
  error.status = status;
  return error;
}

async function createBookingWithSeatReservation({
  tripId,
  passengerId,
  pickupStopId,
  dropoffStopId,
  seatsBooked,
}) {
  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    const tripRes = await client.query(
      `
        SELECT *
        FROM trips
        WHERE id = $1
        FOR UPDATE
      `,
      [tripId]
    );

    const trip = tripRes.rows[0];
    if (!trip) {
      throw httpError(404, 'Trip not found');
    }

    if (!['scheduled', 'on_trip'].includes(trip.status)) {
      throw httpError(400, 'Trip is not available for booking');
    }

    if (trip.driver_id === passengerId) {
      throw httpError(400, 'Driver cannot book own trip');
    }

    const routeStopsRes = await client.query(
      `
        SELECT stop_id, sequence_order
        FROM route_stops
        WHERE route_id = $1
          AND stop_id = ANY($2::uuid[])
      `,
      [trip.route_id, [pickupStopId, dropoffStopId]]
    );

    const pickupStopIdText = String(pickupStopId);
    const dropoffStopIdText = String(dropoffStopId);
    const pickupStop = routeStopsRes.rows.find((row) => String(row.stop_id) === pickupStopIdText);
    const dropoffStop = routeStopsRes.rows.find((row) => String(row.stop_id) === dropoffStopIdText);

    if (!pickupStop || !dropoffStop) {
      throw httpError(400, 'Pickup and dropoff stops must belong to the trip route');
    }

    if (pickupStop.sequence_order >= dropoffStop.sequence_order) {
      throw httpError(400, 'Pickup stop must come before dropoff stop on the route');
    }

    if (trip.available_seats < seatsBooked) {
      throw httpError(400, 'Not enough seats available');
    }

    const totalPrice = Number(trip.price) * seatsBooked;

    const bookingRes = await client.query(
      `
        INSERT INTO bookings (trip_id, passenger_id, pickup_stop_id, dropoff_stop_id, seats_booked, total_price, status, payment_status)
        VALUES ($1, $2, $3, $4, $5, $6, 'pending', 'pending')
        RETURNING *
      `,
      [tripId, passengerId, pickupStopId, dropoffStopId, seatsBooked, totalPrice]
    );

    const seatReservationRes = await client.query(
      `
        UPDATE trips
        SET available_seats = available_seats - $2, updated_at = NOW()
        WHERE id = $1 AND available_seats >= $2
        RETURNING id
      `,
      [tripId, seatsBooked]
    );

    if (seatReservationRes.rowCount === 0) {
      throw httpError(409, 'Unable to reserve seats: insufficient availability or concurrent booking conflict');
    }

    await client.query(
      `
        UPDATE stops
        SET popularity_score = popularity_score + 1, updated_at = NOW()
        WHERE id = ANY($1::uuid[])
      `,
      [[pickupStopId, dropoffStopId]]
    );

    await client.query('COMMIT');
    return bookingRes.rows[0];
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
}

async function updateBookingStatusWithSeatAdjustment({
  bookingId,
  status,
}) {
  if (!ALLOWED_BOOKING_STATUSES.has(status)) {
    throw httpError(400, 'Invalid booking status');
  }

  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    const bookingRes = await client.query(
      `
        SELECT id, trip_id, seats_booked, status
        FROM bookings
        WHERE id = $1
        FOR UPDATE
      `,
      [bookingId]
    );

    const booking = bookingRes.rows[0];
    if (!booking) {
      throw httpError(404, 'Booking not found');
    }

    const bookingUpdateRes = await client.query(
      'UPDATE bookings SET status = $2, updated_at = NOW() WHERE id = $1 RETURNING *',
      [bookingId, status]
    );

    const updatedBooking = bookingUpdateRes.rows[0];

    if (status === BOOKING_STATUS_CANCELLED && booking.status !== BOOKING_STATUS_CANCELLED) {
      const seatUpdateRes = await client.query(
        `
          UPDATE trips t
          SET available_seats = t.available_seats + $2, updated_at = NOW()
          FROM vehicles v
          WHERE t.id = $1
            AND t.vehicle_id = v.id
            AND t.available_seats + $2 <= v.seat_capacity
          RETURNING t.id
        `,
        [booking.trip_id, booking.seats_booked]
      );

      if (seatUpdateRes.rowCount === 0) {
        throw httpError(409, 'Unable to restore seats due to invalid trip seat state');
      }
    }

    await client.query('COMMIT');
    return updatedBooking;
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
}

module.exports = { createBookingWithSeatReservation, updateBookingStatusWithSeatAdjustment };
