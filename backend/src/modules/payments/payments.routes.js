const express = require('express');
const Joi = require('joi');
const db = require('../../config/db');
const { authenticate, authorize } = require('../../middlewares/auth');
const validate = require('../../middlewares/validate');
const HttpError = require('../../utils/httpError');

const router = express.Router();

const paymentSchema = Joi.object({
  bookingId: Joi.number().integer().required(),
  provider: Joi.string().valid('MTN', 'Airtel').required(),
  phoneNumber: Joi.string().required(),
  amount: Joi.number().positive().required(),
});

router.post('/deposit', authenticate, authorize('passenger'), validate(paymentSchema), async (req, res, next) => {
  try {
    const { bookingId, provider, phoneNumber, amount } = req.body;
    const booking = await db.query('SELECT * FROM bookings WHERE id = $1 AND passenger_id = $2', [bookingId, req.user.id]);
    if (!booking.rowCount) throw new HttpError(404, 'Booking not found');

    const status = amount >= Number(booking.rows[0].total_amount) * 0.3 ? 'successful' : 'failed';
    const payment = await db.query(
      `INSERT INTO payments (booking_id, provider, phone_number, amount, status, transaction_ref)
       VALUES ($1, $2, $3, $4, $5, CONCAT('TX-', EXTRACT(EPOCH FROM NOW())::BIGINT, '-', FLOOR(RANDOM()*10000)::INT))
       RETURNING *`,
      [bookingId, provider, phoneNumber, amount, status],
    );

    if (status === 'successful') {
      await db.query("UPDATE bookings SET status = 'confirmed', updated_at = NOW() WHERE id = $1", [bookingId]);
    }

    res.status(201).json(payment.rows[0]);
  } catch (error) {
    next(error);
  }
});

router.get('/:bookingId', authenticate, async (req, res, next) => {
  try {
    const result = await db.query('SELECT * FROM payments WHERE booking_id = $1 ORDER BY created_at DESC', [req.params.bookingId]);
    res.json(result.rows);
  } catch (error) {
    next(error);
  }
});

module.exports = router;
