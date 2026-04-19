const {
  createRoute,
  listRoutes,
  createStop,
  addStopToRoute,
  listRouteStops,
} = require('../models/routeModel');

async function createRouteHandler(req, res, next) {
  try {
    const route = await createRoute(req.validated.body);
    return res.status(201).json(route);
  } catch (error) {
    return next(error);
  }
}

async function listRoutesHandler(req, res, next) {
  try {
    const routes = await listRoutes();
    return res.json(routes);
  } catch (error) {
    return next(error);
  }
}

async function addStopHandler(req, res, next) {
  try {
    const { routeId } = req.validated.params;
    const { name, city, latitude, longitude, sequenceOrder } = req.validated.body;

    const stop = await createStop({ name, city, latitude, longitude });
    const linked = await addStopToRoute({ routeId, stopId: stop.id, sequenceOrder });

    return res.status(201).json({ stop, routeStop: linked });
  } catch (error) {
    return next(error);
  }
}

async function listStopsHandler(req, res, next) {
  try {
    const { routeId } = req.validated.params;
    const stops = await listRouteStops(routeId);
    return res.json(stops);
  } catch (error) {
    return next(error);
  }
}

module.exports = {
  createRouteHandler,
  listRoutesHandler,
  addStopHandler,
  listStopsHandler,
};
