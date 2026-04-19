const { v4: uuidv4 } = require('uuid');
const { query } = require('../config/db');

async function createDeposit({ bookingId, payerId, amount, phoneNumber }) {
  const ref = `MM-${uuidv4()}`;

  const result = await query(
    `
      INSERT INTO payments (booking_id, payer_id, amount, provider, reference, phone_number, status)
      VALUES ($1, $2, $3, $4, $5, $6, 'pending')
      RETURNING *
    `,
    [
      bookingId,
      payerId,
      amount,
      process.env.MOBILE_MONEY_PROVIDER || 'ZamMobileMoney',
      ref,
      phoneNumber,
    ]
  );

  return result.rows[0];
}

async function updatePaymentStatus(paymentId, status) {
  const paymentRes = await query(
    'UPDATE payments SET status = $2, updated_at = NOW() WHERE id = $1 RETURNING *',
    [paymentId, status]
  );

  const payment = paymentRes.rows[0];
  if (!payment) return null;

  if (status === 'completed') {
    await query(
      `
        UPDATE bookings
        SET payment_status = 'paid', status = CASE WHEN status = 'pending' THEN 'confirmed' ELSE status END, updated_at = NOW()
        WHERE id = $1
      `,
      [payment.booking_id]
    );
  }

  if (status === 'failed') {
    await query(
      `
        UPDATE bookings
        SET payment_status = 'failed', updated_at = NOW()
        WHERE id = $1
      `,
      [payment.booking_id]
    );
  }

  return payment;
}

module.exports = { createDeposit, updatePaymentStatus };
