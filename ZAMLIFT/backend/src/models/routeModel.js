const { query } = require('../config/db');

async function createRoute({ name, originCity, destinationCity, baseDistanceKm }) {
  const result = await query(
    `
      INSERT INTO routes (name, origin_city, destination_city, base_distance_km)
      VALUES ($1, $2, $3, $4)
      RETURNING *
    `,
    [name, originCity, destinationCity, baseDistanceKm]
  );

  return result.rows[0];
}

async function listRoutes() {
  const result = await query(
    'SELECT * FROM routes ORDER BY created_at DESC'
  );

  return result.rows;
}

async function createStop({ name, city, latitude, longitude }) {
  const existing = await query(
    'SELECT * FROM stops WHERE name = $1 AND city = $2 LIMIT 1',
    [name, city]
  );
  if (existing.rowCount > 0) return existing.rows[0];

  const result = await query(
    `
      INSERT INTO stops (name, city, latitude, longitude, popularity_score)
      VALUES ($1, $2, $3, $4, 0)
      RETURNING *
    `,
    [name, city, latitude, longitude]
  );

  return result.rows[0];
}

async function addStopToRoute({ routeId, stopId, sequenceOrder }) {
  const result = await query(
    `
      INSERT INTO route_stops (route_id, stop_id, sequence_order)
      VALUES ($1, $2, $3)
      ON CONFLICT (route_id, stop_id)
      DO UPDATE SET sequence_order = EXCLUDED.sequence_order
      RETURNING *
    `,
    [routeId, stopId, sequenceOrder]
  );

  return result.rows[0];
}

async function listRouteStops(routeId) {
  const result = await query(
    `
      SELECT rs.route_id, rs.sequence_order, s.*
      FROM route_stops rs
      JOIN stops s ON s.id = rs.stop_id
      WHERE rs.route_id = $1
      ORDER BY rs.sequence_order ASC
    `,
    [routeId]
  );

  return result.rows;
}

async function incrementStopPopularity(stopId) {
  await query(
    'UPDATE stops SET popularity_score = popularity_score + 1, updated_at = NOW() WHERE id = $1',
    [stopId]
  );
}

module.exports = {
  createRoute,
  listRoutes,
  createStop,
  addStopToRoute,
  listRouteStops,
  incrementStopPopularity,
};
