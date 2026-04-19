const { query } = require('../config/db');

async function createDriverProfile({ userId, licenseNumber, nationalId, phone }) {
  const result = await query(
    `
      INSERT INTO driver_profiles (user_id, license_number, national_id, phone, verification_status)
      VALUES ($1, $2, $3, $4, 'pending')
      ON CONFLICT (user_id)
      DO UPDATE SET license_number = EXCLUDED.license_number, national_id = EXCLUDED.national_id, phone = EXCLUDED.phone
      RETURNING *
    `,
    [userId, licenseNumber, nationalId, phone]
  );

  return result.rows[0];
}

async function registerVehicle({ driverId, make, model, year, plateNumber, seatCapacity }) {
  const result = await query(
    `
      INSERT INTO vehicles (driver_id, make, model, year, plate_number, seat_capacity)
      VALUES ($1, $2, $3, $4, $5, $6)
      RETURNING *
    `,
    [driverId, make, model, year, plateNumber, seatCapacity]
  );

  return result.rows[0];
}

async function setDriverVerification({ driverId, status, adminId }) {
  const result = await query(
    `
      UPDATE driver_profiles
      SET verification_status = $2, verified_by = $3, verified_at = NOW(), updated_at = NOW()
      WHERE user_id = $1
      RETURNING *
    `,
    [driverId, status, adminId]
  );

  return result.rows[0] || null;
}

async function listPendingDrivers() {
  const result = await query(
    `
      SELECT d.*, u.full_name, u.email
      FROM driver_profiles d
      JOIN users u ON u.id = d.user_id
      WHERE d.verification_status = 'pending'
      ORDER BY d.created_at ASC
    `
  );

  return result.rows;
}

async function getDriverProfile(driverId) {
  const result = await query(
    'SELECT * FROM driver_profiles WHERE user_id = $1 LIMIT 1',
    [driverId]
  );
  return result.rows[0] || null;
}

module.exports = {
  createDriverProfile,
  registerVehicle,
  setDriverVerification,
  listPendingDrivers,
  getDriverProfile,
};
