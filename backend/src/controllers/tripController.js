const { getDriverProfile } = require('../models/driverModel');
const {
  createTrip,
  findTrips,
  getTripById,
  updateTripStatus,
  listTripsForAdmin,
  vehicleBelongsToDriver,
  routeExists,
} = require('../models/tripModel');

async function createTripHandler(req, res, next) {
  try {
    if (req.user.role !== 'driver') {
      return res.status(403).json({ message: 'Only drivers can create trips' });
    }

    const profile = await getDriverProfile(req.user.id);
    const driverUserId = profile?.user_id;
    if (!profile || !driverUserId || profile.verification_status !== 'approved') {
      return res.status(403).json({ message: 'Driver is not verified' });
    }

    const { vehicleId, routeId } = req.validated.body;
    const [vehicleOwned, routeFound] = await Promise.all([
      vehicleBelongsToDriver(vehicleId, driverUserId),
      routeExists(routeId),
    ]);

    if (!routeFound) {
      return res.status(404).json({ message: 'Route not found' });
    }

    if (!vehicleOwned) {
      return res.status(403).json({ message: 'Vehicle must belong to the authenticated driver' });
    }

    const trip = await createTrip({
      driverId: driverUserId,
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

async function listTripsAdminHandler(req, res, next) {
  try {
    const trips = await listTripsForAdmin();
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

    if (req.user.role !== 'admin') {
      const profile = await getDriverProfile(req.user.id);
      if (!profile) {
        return res.status(403).json({ message: 'Driver profile is required to modify this trip' });
      }
      if (trip.driver_id !== profile.user_id) {
        return res.status(403).json({ message: 'You do not have permission to modify this trip' });
      }
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
  listTripsAdminHandler,
  getTripHandler,
  updateTripStatusHandler,
};
