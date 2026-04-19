const express = require('express');
const {
  depositHandler,
  updatePaymentStatusHandler,
  listMyPaymentsHandler,
  listPaymentsAdminHandler,
} = require('../controllers/paymentController');
const { protect, authorize } = require('../middleware/authMiddleware');
const { validate } = require('../middleware/validationMiddleware');
const { depositSchema, updatePaymentStatusSchema } = require('./validators');

const router = express.Router();

router.post('/deposit', protect, validate(depositSchema), depositHandler);
router.patch('/:paymentId/status', protect, authorize('admin'), validate(updatePaymentStatusSchema), updatePaymentStatusHandler);
router.get('/my', protect, listMyPaymentsHandler);
router.get('/', protect, authorize('admin'), listPaymentsAdminHandler);

module.exports = router;
