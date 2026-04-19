const express = require('express');
const {
  createRouteHandler,
  listRoutesHandler,
  addStopHandler,
  listStopsHandler,
} = require('../controllers/routeController');
const { protect, authorize } = require('../middleware/authMiddleware');
const { validate } = require('../middleware/validationMiddleware');
const { createRouteSchema, addStopSchema, routeIdSchema } = require('./validators');

const router = express.Router();

router.post('/', protect, authorize('admin'), validate(createRouteSchema), createRouteHandler);
router.get('/', listRoutesHandler);
router.post('/:routeId/stops', protect, authorize('admin'), validate(addStopSchema), addStopHandler);
router.get('/:routeId/stops', validate(routeIdSchema), listStopsHandler);

module.exports = router;
