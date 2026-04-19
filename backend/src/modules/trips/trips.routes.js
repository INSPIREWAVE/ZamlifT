const express = require('express');
const Joi = require('joi');
const db = require('../../config/db');
const { authenticate, authorize } = require('../../middlewares/auth');
const validate = require('../../middlewares/validate');
const HttpError = require('../../utils/httpError');

const router = express.Router();

const createTripSchema = Joi.object({
  routeId: Joi.number().integer().required(),
  startLocation: Joi.string().required(),
  destination: Joi.string().required(),
  departureTime: Joi.date().iso().required(),
  price: Joi.number().positive().required(),
  availableSeats: Joi.number().integer().min(1).required(),
});

const statusSchema = Joi.object({
  status: Joi.string().valid('scheduled', 'boarding', 'on_trip', 'completed', 'cancelled').required(),
});

const TRIP_STATUS_TRANSITIONS = {
  scheduled: ['boarding', 'cancelled'],
  boarding: ['on_trip', 'cancelled'],
  on_trip: ['completed'],
  completed: [],
  cancelled: [],
};

router.post('/', authenticate, authorize('driver'), validate(createTripSchema), async (req, res, next) => {
  try {
    const profile = await db.query('SELECT verification_status FROM driver_profiles WHERE user_id = $1', [req.user.id]);
    if (!profile.rowCount || profile.rows[0].verification_status !== 'approved') {
      throw new HttpError(403, 'Driver must be approved before creating trips');
    }

    const { routeId, startLocation, destination, departureTime, price, availableSeats } = req.body;
    const result = await db.query(
      `INSERT INTO trips (driver_id, route_id, start_location, destination, departure_time, price, available_seats, status)
       VALUES ($1, $2, $3, $4, $5, $6, $7, 'scheduled') RETURNING *`,
      [req.user.id, routeId, startLocation, destination, departureTime, price, availableSeats],
    );
    res.status(201).json(result.rows[0]);
  } catch (error) {
    next(error);
  }
});

router.get('/search', async (req, res, next) => {
  try {
    const { routeId, departureDate, minPrice, maxPrice } = req.query;
    const filters = ['t.available_seats > 0'];
    const params = [];

    if (routeId) {
      params.push(routeId);
      filters.push(`t.route_id = $${params.length}`);
    }
    if (departureDate) {
      params.push(departureDate);
      filters.push(`DATE(t.departure_time) = DATE($${params.length})`);
    }
    if (minPrice) {
      params.push(minPrice);
      filters.push(`t.price >= $${params.length}`);
    }
    if (maxPrice) {
      params.push(maxPrice);
      filters.push(`t.price <= $${params.length}`);
    }

    const result = await db.query(
      `SELECT t.*, u.full_name AS driver_name, r.name AS route_name
       FROM trips t
       JOIN users u ON u.id = t.driver_id
       JOIN routes r ON r.id = t.route_id
       WHERE ${filters.join(' AND ')}
       ORDER BY t.departure_time ASC`,
      params,
    );
    res.json(result.rows);
  } catch (error) {
    next(error);
  }
});

router.patch('/:id/status', authenticate, authorize('driver', 'admin'), validate(statusSchema), async (req, res, next) => {
  try {
    const nextStatus = req.body.status;
    const updateTripStatusQuery = `UPDATE trips SET status = $2, updated_at = NOW()
       WHERE id = $1
         AND ($3 = 'admin' OR driver_id = $4)
         AND (
           (status = 'scheduled' AND $2 IN ('boarding', 'cancelled'))
           OR (status = 'boarding' AND $2 IN ('on_trip', 'cancelled'))
           OR (status = 'on_trip' AND $2 = 'completed')
         )
       RETURNING *`;
    let result = await db.query(updateTripStatusQuery, [req.params.id, nextStatus, req.user.role, req.user.id]);

    if (!result.rowCount) {
      const currentTrip = await db.query('SELECT status, driver_id FROM trips WHERE id = $1', [req.params.id]);
      if (!currentTrip.rowCount) throw new HttpError(404, 'Trip not found');

      if (req.user.role !== 'admin' && currentTrip.rows[0].driver_id !== req.user.id) {
        throw new HttpError(404, 'Trip not found or not owned by driver');
      }

      const currentStatus = currentTrip.rows[0].status;
      const allowedTransitions = TRIP_STATUS_TRANSITIONS[currentStatus] || [];
      if (!allowedTransitions.includes(nextStatus)) {
        throw new HttpError(400, `Invalid trip status transition: ${currentStatus} -> ${nextStatus}`);
      }

      result = await db.query(updateTripStatusQuery, [req.params.id, nextStatus, req.user.role, req.user.id]);
      if (!result.rowCount) throw new HttpError(409, 'Trip status update conflict, please retry');
    }

    req.app.get('io').to(`trip:${req.params.id}`).emit('trip:status_updated', result.rows[0]);
    res.json(result.rows[0]);
  } catch (error) {
    next(error);
  }
});

router.get('/', async (_req, res, next) => {
  try {
    const result = await db.query('SELECT * FROM trips ORDER BY created_at DESC');
    res.json(result.rows);
  } catch (error) {
    next(error);
  }
});

module.exports = router;
