const { pool } = require('../config/db');

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

    if (!['scheduled', 'ongoing'].includes(trip.status)) {
      throw httpError(400, 'Trip is not available for booking');
    }

    if (trip.driver_id === passengerId) {
      throw httpError(400, 'Driver cannot book own trip');
    }

    const routeStopsRes = await client.query(
      `
        SELECT pick.sequence_order AS pickup_order, dropoff.sequence_order AS dropoff_order
        FROM route_stops pick
        JOIN route_stops dropoff ON dropoff.route_id = pick.route_id
        WHERE pick.route_id = $1
          AND pick.stop_id = $2
          AND dropoff.stop_id = $3
        LIMIT 1
      `,
      [trip.route_id, pickupStopId, dropoffStopId]
    );

    const routeStops = routeStopsRes.rows[0];
    if (!routeStops) {
      throw httpError(400, 'Pickup and dropoff stops must belong to the trip route');
    }

    if (routeStops.pickup_order >= routeStops.dropoff_order) {
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

    await client.query(
      `
        UPDATE trips
        SET seats_available = seats_available - $2, updated_at = NOW()
        WHERE id = $1
        RETURNING id
      `,
      [tripId, seatsBooked]
    );

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

module.exports = { createBookingWithSeatReservation };
