const express = require('express');
const {
  createBookingHandler,
  listMyBookingsHandler,
  listBookingsAdminHandler,
  updateBookingStatusHandler,
} = require('../controllers/bookingController');
const { protect, authorize } = require('../middleware/authMiddleware');
const { validate } = require('../middleware/validationMiddleware');
const { createBookingSchema, updateBookingStatusSchema } = require('./validators');

const router = express.Router();

router.get('/', protect, authorize('admin'), listBookingsAdminHandler);
router.post('/', protect, validate(createBookingSchema), createBookingHandler);
router.get('/my', protect, listMyBookingsHandler);
router.patch('/:bookingId/status', protect, validate(updateBookingStatusSchema), updateBookingStatusHandler);

module.exports = router;
