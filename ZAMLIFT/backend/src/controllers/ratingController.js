const { getTripById } = require('../models/tripModel');
const { createRating, getDriverRatings } = require('../models/ratingModel');
const { query } = require('../config/db');

async function createRatingHandler(req, res, next) {
  try {
    const { tripId, rating, comment } = req.validated.body;

    const trip = await getTripById(tripId);
    if (!trip) {
      return res.status(404).json({ message: 'Trip not found' });
    }

    if (trip.status !== 'completed') {
      return res.status(400).json({ message: 'Trip must be completed before rating' });
    }

    const bookingCheck = await query(
      `SELECT id FROM bookings
       WHERE trip_id = $1 AND passenger_id = $2 AND status = 'completed'
       LIMIT 1`,
      [tripId, req.user.id]
    );
    if (bookingCheck.rowCount === 0) {
      return res.status(403).json({ message: 'Only passengers with a completed booking may rate this trip' });
    }

    const created = await createRating({
      tripId,
      driverId: trip.driver_id,
      passengerId: req.user.id,
      rating,
      comment,
    });

    return res.status(201).json(created);
  } catch (error) {
    return next(error);
  }
}

async function getDriverRatingsHandler(req, res, next) {
  try {
    const { driverId } = req.validated.params;
    const ratings = await getDriverRatings(driverId);
    return res.json(ratings);
  } catch (error) {
    return next(error);
  }
}

module.exports = { createRatingHandler, getDriverRatingsHandler };
