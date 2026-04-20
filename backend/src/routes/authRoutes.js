const express = require('express');
const { register: registerHandler, login: loginHandler } = require('../controllers/authController');
const { validate } = require('../middleware/validationMiddleware');
const { authRegisterSchema, authLoginSchema } = require('./validators');

const router = express.Router();

router.post('/register', validate(authRegisterSchema), registerHandler);
router.post('/login', validate(authLoginSchema), loginHandler);

module.exports = router;
