const { query } = require('../config/db');

async function createBooking({ tripId, passengerId, pickupStopId, dropoffStopId, seatsBooked, totalPrice }) {
  const result = await query(
    `
      INSERT INTO bookings (trip_id, passenger_id, pickup_stop_id, dropoff_stop_id, seats_booked, total_price, status, payment_status)
      VALUES ($1, $2, $3, $4, $5, $6, 'pending', 'pending')
      RETURNING *
    `,
    [tripId, passengerId, pickupStopId, dropoffStopId, seatsBooked, totalPrice]
  );

  return result.rows[0];
}

async function getUserBookings(userId) {
  const result = await query(
    `
      SELECT b.*, t.departure_time, t.status AS trip_status, r.name AS route_name
      FROM bookings b
      JOIN trips t ON t.id = b.trip_id
      JOIN routes r ON r.id = t.route_id
      WHERE b.passenger_id = $1
      ORDER BY b.created_at DESC
    `,
    [userId]
  );

  return result.rows;
}

async function updateBookingStatus(bookingId, status) {
  const result = await query(
    'UPDATE bookings SET status = $2, updated_at = NOW() WHERE id = $1 RETURNING *',
    [bookingId, status]
  );

  return result.rows[0] || null;
}

async function getBookingById(bookingId) {
  const result = await query(
    'SELECT * FROM bookings WHERE id = $1 LIMIT 1',
    [bookingId]
  );

  return result.rows[0] || null;
}

module.exports = {
  createBooking,
  getUserBookings,
  updateBookingStatus,
  getBookingById,
};
