const express = require('express');
const {
  createBookingHandler,
  listMyBookingsHandler,
  updateBookingStatusHandler,
} = require('../controllers/bookingController');
const { protect } = require('../middleware/authMiddleware');
const { validate } = require('../middleware/validationMiddleware');
const { createBookingSchema, updateBookingStatusSchema } = require('./validators');

const router = express.Router();

router.post('/', protect, validate(createBookingSchema), createBookingHandler);
router.get('/my', protect, listMyBookingsHandler);
router.patch('/:bookingId/status', protect, validate(updateBookingStatusSchema), updateBookingStatusHandler);

module.exports = router;
