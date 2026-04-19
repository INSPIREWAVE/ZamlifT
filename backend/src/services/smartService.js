const { query } = require('../config/db');

async function getSuggestedStops(searchTerm = '') {
  const result = await query(
    `
      SELECT id, name, city, latitude, longitude, popularity_score
      FROM stops
      WHERE ($1 = '' OR name ILIKE '%' || $1 || '%' OR city ILIKE '%' || $1 || '%')
      ORDER BY popularity_score DESC, name ASC
      LIMIT 10
    `,
    [searchTerm.trim()]
  );

  return result.rows;
}

async function getRoutePriceSuggestion(routeId) {
  const result = await query(
    `
      SELECT
        AVG(b.total_price / NULLIF(b.seats_booked, 0))::numeric(10,2) AS avg_price_per_seat,
        COUNT(*)::int AS booking_count
      FROM bookings b
      JOIN trips t ON t.id = b.trip_id
      WHERE t.route_id = $1 AND b.status IN ('confirmed', 'completed')
    `,
    [routeId]
  );

  const row = result.rows[0];

  return {
    routeId,
    suggestedPricePerSeat:
      row.avg_price_per_seat === null ? null : Number(row.avg_price_per_seat),
    historicalBookingCount: row.booking_count,
  };
}

module.exports = { getSuggestedStops, getRoutePriceSuggestion };
