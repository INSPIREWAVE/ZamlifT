const { query } = require('../config/db');

async function createRating({ tripId, driverId, passengerId, rating, comment }) {
  const result = await query(
    `
      INSERT INTO driver_ratings (trip_id, driver_id, passenger_id, rating, comment)
      VALUES ($1, $2, $3, $4, $5)
      RETURNING *
    `,
    [tripId, driverId, passengerId, rating, comment]
  );

  await query(
    `
      UPDATE driver_profiles dp
      SET average_rating = sub.avg_rating,
          total_ratings = sub.total_ratings,
          updated_at = NOW()
      FROM (
        SELECT driver_id, AVG(rating)::numeric(3,2) AS avg_rating, COUNT(*)::int AS total_ratings
        FROM driver_ratings
        WHERE driver_id = $1
        GROUP BY driver_id
      ) sub
      WHERE dp.user_id = sub.driver_id
    `,
    [driverId]
  );

  return result.rows[0];
}

async function getDriverRatings(driverId) {
  const result = await query(
    `
      SELECT r.*, p.full_name AS passenger_name
      FROM driver_ratings r
      JOIN users p ON p.id = r.passenger_id
      WHERE r.driver_id = $1
      ORDER BY r.created_at DESC
    `,
    [driverId]
  );

  return result.rows;
}

module.exports = { createRating, getDriverRatings };
