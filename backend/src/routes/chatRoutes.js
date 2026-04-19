const express = require('express');
const { getTripChatMessages } = require('../controllers/chatController');
const { protect } = require('../middleware/authMiddleware');
const { validate } = require('../middleware/validationMiddleware');
const { tripIdSchema } = require('./validators');

const router = express.Router();

router.get('/trips/:tripId/messages', protect, validate(tripIdSchema), getTripChatMessages);

module.exports = router;
