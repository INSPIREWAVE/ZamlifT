const jwt = require('jsonwebtoken');

function signToken(user) {
  return jwt.sign(
    { role: user.role },
    process.env.JWT_SECRET,
    {
      subject: user.id,
      expiresIn: process.env.JWT_EXPIRES_IN || '7d',
    }
  );
}

module.exports = { signToken };
