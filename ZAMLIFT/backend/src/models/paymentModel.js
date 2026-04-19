const { query } = require('../config/db');

async function listUserPayments(userId) {
  const result = await query(
    `
      SELECT p.*, b.trip_id
      FROM payments p
      JOIN bookings b ON b.id = p.booking_id
      WHERE p.payer_id = $1
      ORDER BY p.created_at DESC
    `,
    [userId]
  );

  return result.rows;
}

async function listAllPayments() {
  const result = await query(
    `
      SELECT p.*, b.trip_id, u.full_name AS payer_name
      FROM payments p
      JOIN bookings b ON b.id = p.booking_id
      JOIN users u ON u.id = p.payer_id
      ORDER BY p.created_at DESC
    `
  );

  return result.rows;
}

module.exports = { listUserPayments, listAllPayments };
