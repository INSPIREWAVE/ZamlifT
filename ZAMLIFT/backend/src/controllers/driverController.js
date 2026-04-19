const {
  createDriverProfile,
  registerVehicle,
  setDriverVerification,
  listPendingDrivers,
  getDriverProfile,
} = require('../models/driverModel');

async function upsertProfile(req, res, next) {
  try {
    const { licenseNumber, nationalId, phone } = req.validated.body;
    const profile = await createDriverProfile({
      userId: req.user.id,
      licenseNumber,
      nationalId,
      phone,
    });

    return res.status(201).json(profile);
  } catch (error) {
    return next(error);
  }
}

async function createVehicle(req, res, next) {
  try {
    const profile = await getDriverProfile(req.user.id);
    if (!profile) {
      return res.status(400).json({ message: 'Create driver profile first' });
    }

    const { make, model, year, plateNumber, seatCapacity } = req.validated.body;
    const vehicle = await registerVehicle({
      driverId: req.user.id,
      make,
      model,
      year,
      plateNumber,
      seatCapacity,
    });

    return res.status(201).json(vehicle);
  } catch (error) {
    return next(error);
  }
}

async function verifyDriver(req, res, next) {
  try {
    const { driverId } = req.validated.params;
    const { status } = req.validated.body;

    const updated = await setDriverVerification({
      driverId,
      status,
      adminId: req.user.id,
    });

    if (!updated) {
      return res.status(404).json({ message: 'Driver profile not found' });
    }

    return res.json(updated);
  } catch (error) {
    return next(error);
  }
}

async function getPendingDrivers(req, res, next) {
  try {
    const drivers = await listPendingDrivers();
    return res.json(drivers);
  } catch (error) {
    return next(error);
  }
}

module.exports = { upsertProfile, createVehicle, verifyDriver, getPendingDrivers };
