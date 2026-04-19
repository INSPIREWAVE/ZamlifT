const { query } = require('../config/db');

async function ensureTripParticipant(userId, tripId) {
  const tripOwner = await query('SELECT driver_id FROM trips WHERE id = $1', [tripId]);
  if (tripOwner.rows[0]?.driver_id === userId) return true;

  const booking = await query(
    `SELECT id FROM bookings WHERE trip_id = $1 AND passenger_id = $2 AND status IN ('pending', 'confirmed', 'completed') LIMIT 1`,
    [tripId, userId]
  );

  return booking.rowCount > 0;
}

async function saveTripMessage({ tripId, senderId, message }) {
  const result = await query(
    `
      INSERT INTO trip_messages (trip_id, sender_id, message)
      VALUES ($1, $2, $3)
      RETURNING id, trip_id, sender_id, message, created_at
    `,
    [tripId, senderId, message]
  );

  return result.rows[0];
}

async function getTripMessages(tripId, limit = 100) {
  const result = await query(
    `
      SELECT m.id, m.trip_id, m.sender_id, u.full_name AS sender_name, m.message, m.created_at
      FROM trip_messages m
      JOIN users u ON u.id = m.sender_id
      WHERE m.trip_id = $1
      ORDER BY m.created_at DESC
      LIMIT $2
    `,
    [tripId, limit]
  );

  return result.rows.reverse();
}

module.exports = { ensureTripParticipant, saveTripMessage, getTripMessages };
