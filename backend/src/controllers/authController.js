const bcrypt = require('bcrypt');
const { createUser, findUserByEmail } = require('../models/userModel');
const { signToken } = require('../services/authService');

function buildMissingFieldError(fieldName) {
  const error = new Error(`${fieldName} is required`);
  error.status = 400;
  return error;
}

async function register(req, res, next) {
  try {
    console.log('[auth.register] incoming body:', req.body);
    const body = req.validated?.body;
    if (!body) {
      const validationError = buildMissingFieldError('Registration payload');
      console.error('[auth.register] validation error:', validationError.message);
      throw validationError;
    }
    const { fullName, email, password, role, phone } = body;

    const existing = await findUserByEmail(email);
    if (existing) {
      return res.status(409).json({ message: 'Email already exists' });
    }

    const passwordHash = await bcrypt.hash(password, 12);
    const user = await createUser({
      fullName: String(fullName).trim(),
      email: String(email).trim(),
      passwordHash,
      role: String(role).trim(),
      phone: String(phone).trim(),
    });
    const token = signToken(user);

    return res.status(201).json({ user, token });
  } catch (error) {
    if (error?.status === 400) {
      console.error('[auth.register] validation error:', error.message);
      return res.status(400).json({ message: error.message });
    }

    if (error?.code || error?.detail) {
      console.error('[auth.register] database error:', {
        code: error.code,
        detail: error.detail,
        constraint: error.constraint,
        message: error.message,
      });
    }

    if (error?.message) {
      return res.status(400).json({ message: error.message });
    }

    return next(error);
  }
}

async function login(req, res, next) {
  try {
    const { email, password } = req.validated.body;

    const user = await findUserByEmail(email);
    if (!user) {
      return res.status(401).json({ message: 'Invalid credentials' });
    }

    const isMatch = await bcrypt.compare(password, user.password_hash);
    if (!isMatch) {
      return res.status(401).json({ message: 'Invalid credentials' });
    }

    const token = signToken(user);

    return res.json({
      user: {
        id: user.id,
        full_name: user.full_name,
        email: user.email,
        role: user.role,
        is_active: user.is_active,
      },
      token,
    });
  } catch (error) {
    return next(error);
  }
}

module.exports = { register, login };
