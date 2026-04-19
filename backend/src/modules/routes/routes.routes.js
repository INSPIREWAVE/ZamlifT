const express = require('express');
const Joi = require('joi');
const db = require('../../config/db');
const { authenticate, authorize } = require('../../middlewares/auth');
const validate = require('../../middlewares/validate');

const router = express.Router();

const routeSchema = Joi.object({
  name: Joi.string().required(),
  startCity: Joi.string().required(),
  endCity: Joi.string().required(),
});

const stopSchema = Joi.object({
  name: Joi.string().required(),
  latitude: Joi.number().required(),
  longitude: Joi.number().required(),
  popularityScore: Joi.number().integer().min(0).default(0),
  position: Joi.number().integer().min(1).required(),
});

router.post('/', authenticate, authorize('admin', 'driver'), validate(routeSchema), async (req, res, next) => {
  try {
    const { name, startCity, endCity } = req.body;
    const result = await db.query(
      'INSERT INTO routes (name, start_city, end_city, created_by) VALUES ($1, $2, $3, $4) RETURNING *',
      [name, startCity, endCity, req.user.id],
    );
    res.status(201).json(result.rows[0]);
  } catch (error) {
    next(error);
  }
});

router.post('/:routeId/stops', authenticate, authorize('admin', 'driver'), validate(stopSchema), async (req, res, next) => {
  try {
    const { name, latitude, longitude, popularityScore, position } = req.body;
    const result = await db.query(
      `INSERT INTO stops (route_id, name, latitude, longitude, popularity_score, position)
       VALUES ($1, $2, $3, $4, $5, $6)
       RETURNING *`,
      [req.params.routeId, name, latitude, longitude, popularityScore, position],
    );
    res.status(201).json(result.rows[0]);
  } catch (error) {
    next(error);
  }
});

router.get('/', async (_req, res, next) => {
  try {
    const result = await db.query(
      `SELECT r.*, COALESCE(JSON_AGG(s.* ORDER BY s.position) FILTER (WHERE s.id IS NOT NULL), '[]') AS stops
       FROM routes r
       LEFT JOIN stops s ON s.route_id = r.id
       GROUP BY r.id
       ORDER BY r.created_at DESC`,
    );
    res.json(result.rows);
  } catch (error) {
    next(error);
  }
});

router.get('/popular-stops', async (_req, res, next) => {
  try {
    const result = await db.query(
      'SELECT * FROM stops ORDER BY popularity_score DESC, updated_at DESC LIMIT 10',
    );
    res.json(result.rows);
  } catch (error) {
    next(error);
  }
});

module.exports = router;
