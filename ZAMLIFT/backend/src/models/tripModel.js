const { pool, query } = require('../config/db');

async function createTrip({ driverId, vehicleId, routeId, departureTime, seatsTotal, pricePerSeat, status }) {
  const result = await query(
    `
      INSERT INTO trips (driver_id, vehicle_id, route_id, departure_time, seats_total, seats_available, price_per_seat, status)
      VALUES ($1, $2, $3, $4, $5, $5, $6, $7)
      RETURNING *
    `,
    [driverId, vehicleId, routeId, departureTime, seatsTotal, pricePerSeat, status]
  );

  return result.rows[0];
}

async function findTrips({ fromStopId, toStopId, departureDate }) {
  const result = await query(
    `
      SELECT DISTINCT t.*, r.name AS route_name, r.origin_city, r.destination_city, u.full_name AS driver_name
      FROM trips t
      JOIN routes r ON r.id = t.route_id
      JOIN driver_profiles dp ON dp.id = t.driver_id
      JOIN users u ON u.id = dp.user_id
      JOIN route_stops rs_from ON rs_from.route_id = r.id
      JOIN route_stops rs_to ON rs_to.route_id = r.id
      WHERE rs_from.stop_id = $1
        AND rs_to.stop_id = $2
        AND rs_from.sequence_order < rs_to.sequence_order
        AND DATE(t.departure_time) = $3
        AND t.status IN ('scheduled','ongoing')
        AND t.seats_available > 0
      ORDER BY t.departure_time ASC
    `,
    [fromStopId, toStopId, departureDate]
  );

  return result.rows;
}

async function getTripById(tripId) {
  const result = await query(
    `
      SELECT t.*, r.name AS route_name, r.origin_city, r.destination_city, u.full_name AS driver_name
      FROM trips t
      JOIN routes r ON r.id = t.route_id
      JOIN driver_profiles dp ON dp.id = t.driver_id
      JOIN users u ON u.id = dp.user_id
      WHERE t.id = $1
      LIMIT 1
    `,
    [tripId]
  );

  return result.rows[0] || null;
}

async function updateTripStatus(tripId, status) {
  if (status !== 'completed') {
    const result = await query(
      'UPDATE trips SET status = $2, updated_at = NOW() WHERE id = $1 RETURNING *',
      [tripId, status]
    );

    return result.rows[0] || null;
  }

  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    const tripResult = await client.query(
      'UPDATE trips SET status = $2, updated_at = NOW() WHERE id = $1 RETURNING *',
      [tripId, status]
    );
    const trip = tripResult.rows[0] || null;

    if (!trip) {
      await client.query('ROLLBACK');
      return null;
    }

    const revenueResult = await client.query(
      `
        SELECT COALESCE(SUM(total_price), 0)::numeric(12,2) AS total_revenue
        FROM bookings
        WHERE trip_id = $1
          AND payment_status = 'paid'
          AND status <> 'cancelled'
      `,
      [tripId]
    );
    const totalRevenue = revenueResult.rows[0].total_revenue;

    await client.query(
      `
        INSERT INTO earnings (trip_id, driver_id, total_revenue, calculated_at, updated_at)
        VALUES ($1, $2, $3, NOW(), NOW())
        ON CONFLICT (trip_id)
        DO UPDATE SET
          total_revenue = EXCLUDED.total_revenue,
          calculated_at = NOW(),
          updated_at = NOW()
        WHERE earnings.total_revenue IS DISTINCT FROM EXCLUDED.total_revenue
      `,
      [tripId, trip.driver_id, totalRevenue]
    );

    await client.query('COMMIT');
    return trip;
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
}

async function vehicleBelongsToDriver(vehicleId, driverId) {
  const result = await query(
    'SELECT id FROM vehicles WHERE id = $1 AND driver_id = $2 LIMIT 1',
    [vehicleId, driverId]
  );

  return result.rowCount > 0;
}

async function routeExists(routeId) {
  const result = await query(
    'SELECT id FROM routes WHERE id = $1 LIMIT 1',
    [routeId]
  );

  return result.rowCount > 0;
}

async function adjustTripSeats(tripId, seatDelta) {
  const result = await query(
    `
      UPDATE trips
      SET seats_available = seats_available + $2, updated_at = NOW()
      WHERE id = $1 AND seats_available + $2 >= 0 AND seats_available + $2 <= seats_total
      RETURNING *
    `,
    [tripId, seatDelta]
  );

  return result.rows[0] || null;
}

module.exports = {
  createTrip,
  findTrips,
  getTripById,
  updateTripStatus,
  vehicleBelongsToDriver,
  routeExists,
  adjustTripSeats,
};
