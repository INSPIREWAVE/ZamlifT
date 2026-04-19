const { getDriverProfile } = require('../models/driverModel');
const {
  createTrip,
  findTrips,
  getTripById,
  updateTripStatus,
} = require('../models/tripModel');

async function createTripHandler(req, res, next) {
  try {
    const profile = await getDriverProfile(req.user.id);
    if (!profile || profile.verification_status !== 'approved') {
      return res.status(403).json({ message: 'Driver is not verified' });
    }

    const trip = await createTrip({
      driverId: req.user.id,
      ...req.validated.body,
      status: 'scheduled',
    });

    return res.status(201).json(trip);
  } catch (error) {
    return next(error);
  }
}

async function searchTripsHandler(req, res, next) {
  try {
    const trips = await findTrips(req.validated.query);
    return res.json(trips);
  } catch (error) {
    return next(error);
  }
}

async function getTripHandler(req, res, next) {
  try {
    const { tripId } = req.validated.params;
    const trip = await getTripById(tripId);
    if (!trip) {
      return res.status(404).json({ message: 'Trip not found' });
    }

    return res.json(trip);
  } catch (error) {
    return next(error);
  }
}

async function updateTripStatusHandler(req, res, next) {
  try {
    const { tripId } = req.validated.params;
    const { status } = req.validated.body;

    const trip = await getTripById(tripId);
    if (!trip) {
      return res.status(404).json({ message: 'Trip not found' });
    }

    if (req.user.role !== 'admin' && trip.driver_id !== req.user.id) {
      return res.status(403).json({ message: 'Forbidden' });
    }

    const updated = await updateTripStatus(tripId, status);
    return res.json(updated);
  } catch (error) {
    return next(error);
  }
}

module.exports = {
  createTripHandler,
  searchTripsHandler,
  getTripHandler,
  updateTripStatusHandler,
};
