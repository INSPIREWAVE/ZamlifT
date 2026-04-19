const express = require('express');
const Joi = require('joi');
const db = require('../../config/db');
const { authenticate, authorize } = require('../../middlewares/auth');
const validate = require('../../middlewares/validate');
const HttpError = require('../../utils/httpError');

const router = express.Router();

const profileSchema = Joi.object({
  nationalId: Joi.string().required(),
  licenseNumber: Joi.string().required(),
  bio: Joi.string().max(500).allow('', null),
});

const vehicleSchema = Joi.object({
  make: Joi.string().required(),
  model: Joi.string().required(),
  plateNumber: Joi.string().required(),
  seats: Joi.number().integer().min(1).max(100).required(),
  color: Joi.string().optional(),
});

router.post('/profile', authenticate, authorize('driver'), validate(profileSchema), async (req, res, next) => {
  try {
    const { nationalId, licenseNumber, bio } = req.body;
    const result = await db.query(
      `INSERT INTO driver_profiles (user_id, national_id, license_number, bio)
       VALUES ($1, $2, $3, $4)
       ON CONFLICT (user_id)
       DO UPDATE SET national_id = EXCLUDED.national_id, license_number = EXCLUDED.license_number, bio = EXCLUDED.bio
       RETURNING *`,
      [req.user.id, nationalId, licenseNumber, bio || null],
    );
    res.status(201).json(result.rows[0]);
  } catch (error) {
    next(error);
  }
});

router.post('/vehicle', authenticate, authorize('driver'), validate(vehicleSchema), async (req, res, next) => {
  try {
    const { make, model, plateNumber, seats, color } = req.body;
    const result = await db.query(
      `INSERT INTO vehicles (driver_id, make, model, plate_number, seats, color)
       VALUES ($1, $2, $3, $4, $5, $6)
       ON CONFLICT (plate_number)
       DO UPDATE SET make = EXCLUDED.make, model = EXCLUDED.model, seats = EXCLUDED.seats, color = EXCLUDED.color
       RETURNING *`,
      [req.user.id, make, model, plateNumber, seats, color || null],
    );
    res.status(201).json(result.rows[0]);
  } catch (error) {
    next(error);
  }
});

router.get('/me', authenticate, authorize('driver'), async (req, res, next) => {
  try {
    const result = await db.query(
      `SELECT u.id, u.full_name, dp.national_id, dp.license_number, dp.verification_status, v.make, v.model, v.plate_number, v.seats
       FROM users u
       LEFT JOIN driver_profiles dp ON dp.user_id = u.id
       LEFT JOIN vehicles v ON v.driver_id = u.id
       WHERE u.id = $1`,
      [req.user.id],
    );
    if (!result.rowCount) throw new HttpError(404, 'Driver not found');
    res.json(result.rows[0]);
  } catch (error) {
    next(error);
  }
});

router.patch('/:id/approve', authenticate, authorize('admin'), async (req, res, next) => {
  try {
    const result = await db.query(
      `UPDATE driver_profiles
       SET verification_status = 'approved', verified_by = $2, verified_at = NOW()
       WHERE user_id = $1
       RETURNING *`,
      [req.params.id, req.user.id],
    );
    if (!result.rowCount) throw new HttpError(404, 'Driver profile not found');
    res.json(result.rows[0]);
  } catch (error) {
    next(error);
  }
});

module.exports = router;
