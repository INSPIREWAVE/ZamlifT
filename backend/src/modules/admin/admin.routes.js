const express = require('express');
const db = require('../../config/db');
const { authenticate, authorize } = require('../../middlewares/auth');

const router = express.Router();

router.use(authenticate, authorize('admin'));

router.get('/users', async (_req, res, next) => {
  try {
    const result = await db.query('SELECT id, full_name, email, role, created_at FROM users ORDER BY created_at DESC');
    res.json(result.rows);
  } catch (error) {
    next(error);
  }
});

router.get('/drivers/pending', async (_req, res, next) => {
  try {
    const result = await db.query(
      `SELECT u.id, u.full_name, u.email, dp.national_id, dp.license_number, dp.verification_status, dp.created_at
       FROM driver_profiles dp
       JOIN users u ON u.id = dp.user_id
       WHERE dp.verification_status = 'pending'
       ORDER BY dp.created_at DESC`,
    );
    res.json(result.rows);
  } catch (error) {
    next(error);
  }
});

router.get('/trips', async (_req, res, next) => {
  try {
    const result = await db.query(
      `SELECT t.*, u.full_name AS driver_name
       FROM trips t
       JOIN users u ON u.id = t.driver_id
       ORDER BY t.created_at DESC`,
    );
    res.json(result.rows);
  } catch (error) {
    next(error);
  }
});

router.get('/payments', async (_req, res, next) => {
  try {
    const result = await db.query(
      `SELECT p.*, b.passenger_id, b.trip_id
       FROM payments p
       JOIN bookings b ON b.id = p.booking_id
       ORDER BY p.created_at DESC`,
    );
    res.json(result.rows);
  } catch (error) {
    next(error);
  }
});

module.exports = router;
