const { getSuggestedStops, getRoutePriceSuggestion } = require('../services/smartService');

async function suggestedStopsHandler(req, res, next) {
  try {
    const { query } = req.validated.query;
    const stops = await getSuggestedStops(query || '');
    return res.json(stops);
  } catch (error) {
    return next(error);
  }
}

async function suggestedPricingHandler(req, res, next) {
  try {
    const { routeId } = req.validated.query;
    const suggestion = await getRoutePriceSuggestion(routeId);
    return res.json(suggestion);
  } catch (error) {
    return next(error);
  }
}

module.exports = { suggestedStopsHandler, suggestedPricingHandler };
