const express = require('express');
const Joi = require('joi');
const db = require('../../config/db');
const { authenticate, authorize } = require('../../middlewares/auth');
const validate = require('../../middlewares/validate');

const router = express.Router();

const ratingSchema = Joi.object({
  tripId: Joi.number().integer().required(),
  driverId: Joi.number().integer().required(),
  score: Joi.number().integer().min(1).max(5).required(),
  comment: Joi.string().max(500).allow('', null),
});

router.post('/', authenticate, authorize('passenger'), validate(ratingSchema), async (req, res, next) => {
  try {
    const { tripId, driverId, score, comment } = req.body;
    const rating = await db.query(
      `INSERT INTO ratings (trip_id, passenger_id, driver_id, score, comment)
       VALUES ($1, $2, $3, $4, $5)
       ON CONFLICT (trip_id, passenger_id)
       DO UPDATE SET score = EXCLUDED.score, comment = EXCLUDED.comment, updated_at = NOW()
       RETURNING *`,
      [tripId, req.user.id, driverId, score, comment || null],
    );

    await db.query(
      `UPDATE driver_profiles
       SET average_rating = (SELECT COALESCE(AVG(score), 0) FROM ratings WHERE driver_id = $1),
           ratings_count = (SELECT COUNT(*) FROM ratings WHERE driver_id = $1)
       WHERE user_id = $1`,
      [driverId],
    );

    res.status(201).json(rating.rows[0]);
  } catch (error) {
    next(error);
  }
});

router.get('/driver/:driverId', async (req, res, next) => {
  try {
    const summary = await db.query(
      `SELECT COALESCE(AVG(score), 0) AS average_rating, COUNT(*)::INT AS total_ratings
       FROM ratings
       WHERE driver_id = $1`,
      [req.params.driverId],
    );
    res.json(summary.rows[0]);
  } catch (error) {
    next(error);
  }
});

module.exports = router;
