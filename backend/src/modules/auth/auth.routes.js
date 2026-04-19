const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const db = require('../../config/db');
const env = require('../../config/env');
const validate = require('../../middlewares/validate');
const HttpError = require('../../utils/httpError');
const { registerSchema, loginSchema } = require('./auth.schemas');
const { authenticate } = require('../../middlewares/auth');

const router = express.Router();

router.post('/register', validate(registerSchema), async (req, res, next) => {
  try {
    const { fullName, email, password, role, phone } = req.body;
    const existing = await db.query('SELECT id FROM users WHERE email = $1', [email.toLowerCase()]);
    if (existing.rowCount) throw new HttpError(409, 'Email already registered');

    const passwordHash = await bcrypt.hash(password, 10);
    const result = await db.query(
      `INSERT INTO users (full_name, email, password_hash, role, phone)
       VALUES ($1, $2, $3, $4, $5) RETURNING id, full_name, email, role`,
      [fullName, email.toLowerCase(), passwordHash, role, phone || null],
    );

    const token = jwt.sign({ id: result.rows[0].id, role: result.rows[0].role }, env.jwtSecret, {
      expiresIn: env.jwtExpiresIn,
    });

    res.status(201).json({ token, user: result.rows[0] });
  } catch (error) {
    next(error);
  }
});

router.post('/login', validate(loginSchema), async (req, res, next) => {
  try {
    const { email, password } = req.body;
    const result = await db.query('SELECT id, full_name, email, role, password_hash FROM users WHERE email = $1', [
      email.toLowerCase(),
    ]);
    if (!result.rowCount) throw new HttpError(401, 'Invalid credentials');

    const user = result.rows[0];
    const isMatch = await bcrypt.compare(password, user.password_hash);
    if (!isMatch) throw new HttpError(401, 'Invalid credentials');

    const token = jwt.sign({ id: user.id, role: user.role }, env.jwtSecret, { expiresIn: env.jwtExpiresIn });
    delete user.password_hash;
    res.json({ token, user });
  } catch (error) {
    next(error);
  }
});

router.get('/me', authenticate, async (req, res, next) => {
  try {
    const result = await db.query('SELECT id, full_name, email, role, phone, created_at FROM users WHERE id = $1', [req.user.id]);
    if (!result.rowCount) throw new HttpError(404, 'User not found');
    res.json(result.rows[0]);
  } catch (error) {
    next(error);
  }
});

module.exports = router;
