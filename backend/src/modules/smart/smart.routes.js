const express = require('express');
const db = require('../../config/db');

const router = express.Router();

router.get('/suggestions', async (req, res, next) => {
  try {
    const { routeId } = req.query;
    const routeFilter = routeId ? 't.route_id = $1 AND ' : '';
    const params = routeId ? [routeId] : [];

    const popularStopsQuery = `
      SELECT s.id, s.name, s.popularity_score,
             COUNT(b.id)::INT AS bookings_count
      FROM stops s
      LEFT JOIN bookings b ON b.pickup_stop_id = s.id OR b.dropoff_stop_id = s.id
      GROUP BY s.id
      ORDER BY s.popularity_score DESC, bookings_count DESC
      LIMIT 5
    `;

    const priceRangeQuery = `
      SELECT COALESCE(MIN(t.price), 0) AS min_price,
             COALESCE(AVG(t.price), 0) AS avg_price,
             COALESCE(MAX(t.price), 0) AS max_price
      FROM trips t
      WHERE ${routeFilter}t.status IN ('scheduled', 'boarding', 'on_trip', 'completed')
    `;

    const [popularStops, priceRange] = await Promise.all([
      db.query(popularStopsQuery),
      db.query(priceRangeQuery, params),
    ]);

    res.json({
      suggestedStops: popularStops.rows,
      suggestedPriceRange: priceRange.rows[0],
    });
  } catch (error) {
    next(error);
  }
});

module.exports = router;
