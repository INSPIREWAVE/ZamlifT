const express = require('express');
const {
  createRatingHandler,
  getDriverRatingsHandler,
} = require('../controllers/ratingController');
const { protect } = require('../middleware/authMiddleware');
const { validate } = require('../middleware/validationMiddleware');
const { createRatingSchema, driverIdSchema } = require('./validators');

const router = express.Router();

router.post('/', protect, validate(createRatingSchema), createRatingHandler);
router.get('/driver/:driverId', validate(driverIdSchema), getDriverRatingsHandler);

module.exports = router;
