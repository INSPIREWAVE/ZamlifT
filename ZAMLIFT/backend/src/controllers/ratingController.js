const { getTripById } = require('../models/tripModel');
const { createRating, getDriverRatings } = require('../models/ratingModel');

async function createRatingHandler(req, res, next) {
  try {
    const { tripId, rating, comment } = req.validated.body;

    const trip = await getTripById(tripId);
    if (!trip) {
      return res.status(404).json({ message: 'Trip not found' });
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
