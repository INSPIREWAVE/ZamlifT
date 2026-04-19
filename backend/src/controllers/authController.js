const bcrypt = require('bcrypt');
const { createUser, findUserByEmail } = require('../models/userModel');
const { signToken } = require('../services/authService');

async function register(req, res, next) {
  try {
    const { fullName, email, password, role } = req.validated.body;

    const existing = await findUserByEmail(email);
    if (existing) {
      return res.status(409).json({ message: 'Email already registered' });
    }

    const passwordHash = await bcrypt.hash(password, 12);
    const user = await createUser({ fullName, email, passwordHash, role });
    const token = signToken(user);

    return res.status(201).json({ user, token });
  } catch (error) {
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
