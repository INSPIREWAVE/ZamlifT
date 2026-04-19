const express = require('express');
const {
  createTripHandler,
  searchTripsHandler,
  getTripHandler,
  updateTripStatusHandler,
} = require('../controllers/tripController');
const { protect, authorize } = require('../middleware/authMiddleware');
const { validate } = require('../middleware/validationMiddleware');
const {
  createTripSchema,
  searchTripsSchema,
  tripIdSchema,
  updateTripStatusSchema,
} = require('./validators');

const router = express.Router();

router.post('/', protect, authorize('driver'), validate(createTripSchema), createTripHandler);
router.get('/search', validate(searchTripsSchema), searchTripsHandler);
router.get('/:tripId', validate(tripIdSchema), getTripHandler);
router.patch('/:tripId/status', protect, validate(updateTripStatusSchema), updateTripStatusHandler);

module.exports = router;
