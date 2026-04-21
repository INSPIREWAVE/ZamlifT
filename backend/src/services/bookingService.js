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

    if (passengerId === trip.driver_id) {
      throw httpError(400, 'Driver cannot book own trip');
    }

    const stopsRes = await client.query(
      `
        SELECT rs.stop_id AS id, rs.sequence_order
        FROM route_stops rs
        WHERE rs.route_id = $1
          AND rs.stop_id = ANY($2::uuid[])
      `,
      [trip.route_id, [pickupStopId, dropoffStopId]]
    );

    const pickupStopIdText = String(pickupStopId);
    const dropoffStopIdText = String(dropoffStopId);
    const pickupStop = stopsRes.rows.find((row) => String(row.id) === pickupStopIdText);
    const dropoffStop = stopsRes.rows.find((row) => String(row.id) === dropoffStopIdText);

    if (!pickupStop || !dropoffStop) {
      throw httpError(400, 'Pickup and dropoff stops must belong to the trip route');
    }

    if (pickupStop.sequence_order >= dropoffStop.sequence_order) {
      throw httpError(400, 'Pickup stop must come before dropoff stop on the route');
    }

    if (trip.seats_available < seatsBooked) {
      throw httpError(400, 'Not enough seats available');
    }

    const totalPrice = Number(trip.price_per_seat) * seatsBooked;

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
        SET seats_available = seats_available - $2, updated_at = NOW()
        WHERE id = $1 AND seats_available >= $2
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
          SET seats_available = t.seats_available + $2, updated_at = NOW()
          WHERE t.id = $1
            AND t.seats_available + $2 <= t.seats_total
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
