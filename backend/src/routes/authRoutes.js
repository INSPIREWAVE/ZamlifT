const express = require('express');
const { register, login } = require('../controllers/authController');
const { validate } = require('../middleware/validationMiddleware');
const { authRegisterSchema, authLoginSchema } = require('./validators');

const router = express.Router();

router.post('/register', validate(authRegisterSchema), register);
router.post('/login', validate(authLoginSchema), login);

module.exports = router;
