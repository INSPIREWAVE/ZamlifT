const { query } = require('../config/db');

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
  const result = await query(
    'UPDATE trips SET status = $2, updated_at = NOW() WHERE id = $1 RETURNING *',
    [tripId, status]
  );

  return result.rows[0] || null;
}

async function vehicleBelongsToDriver(vehicleId, driverId) {
  const result = await query(
    `
      SELECT v.id
      FROM vehicles v
      JOIN driver_profiles dp ON dp.user_id = v.driver_id
      WHERE v.id = $1
        AND dp.id = $2
      LIMIT 1
    `,
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
