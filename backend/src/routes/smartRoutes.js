const express = require('express');
const { suggestedStopsHandler, suggestedPricingHandler } = require('../controllers/smartController');
const { validate } = require('../middleware/validationMiddleware');
const { smartStopsSchema, smartPricingSchema } = require('./validators');

const router = express.Router();

router.get('/stops', validate(smartStopsSchema), suggestedStopsHandler);
router.get('/pricing', validate(smartPricingSchema), suggestedPricingHandler);

module.exports = router;
