const express = require('express');
const {
  upsertProfile,
  createVehicle,
  verifyDriver,
  getPendingDrivers,
} = require('../controllers/driverController');
const { protect, authorize } = require('../middleware/authMiddleware');
const { validate } = require('../middleware/validationMiddleware');
const {
  driverProfileSchema,
  vehicleSchema,
  verifyDriverSchema,
} = require('./validators');

const router = express.Router();

router.post('/profile', protect, authorize('driver'), validate(driverProfileSchema), upsertProfile);
router.post('/vehicle', protect, authorize('driver'), validate(vehicleSchema), createVehicle);
router.get('/pending', protect, authorize('admin'), getPendingDrivers);
router.patch('/:driverId/verify', protect, authorize('admin'), validate(verifyDriverSchema), verifyDriver);

module.exports = router;
