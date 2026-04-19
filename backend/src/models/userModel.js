const { query } = require('../config/db');

async function createUser({ fullName, email, passwordHash, role }) {
  const result = await query(
    `
      INSERT INTO users (full_name, email, password_hash, role)
      VALUES ($1, $2, $3, $4)
      RETURNING id, full_name, email, role, is_active, created_at
    `,
    [fullName, email.toLowerCase(), passwordHash, role]
  );

  return result.rows[0];
}

async function findUserByEmail(email) {
  const result = await query(
    'SELECT * FROM users WHERE email = $1 LIMIT 1',
    [email.toLowerCase()]
  );

  return result.rows[0] || null;
}

module.exports = { createUser, findUserByEmail };
