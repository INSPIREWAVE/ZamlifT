const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const morgan = require('morgan');

const env = require('./config/env');
const errorHandler = require('./middlewares/errorHandler');
const authRoutes = require('./modules/auth/auth.routes');
const driverRoutes = require('./modules/drivers/drivers.routes');
const routeRoutes = require('./modules/routes/routes.routes');
const tripRoutes = require('./modules/trips/trips.routes');
const bookingRoutes = require('./modules/bookings/bookings.routes');
const paymentRoutes = require('./modules/payments/payments.routes');
const ratingRoutes = require('./modules/ratings/ratings.routes');
const adminRoutes = require('./modules/admin/admin.routes');
const smartRoutes = require('./modules/smart/smart.routes');

const app = express();

app.use(helmet());
app.use(
  cors({
    origin: env.clientOrigin === '*' ? true : env.clientOrigin,
    credentials: true,
  }),
);
app.use(rateLimit({ windowMs: 15 * 60 * 1000, max: 400 }));
app.use(express.json({ limit: '1mb' }));
app.use(morgan(env.nodeEnv === 'production' ? 'combined' : 'dev'));

app.get('/health', (_req, res) => {
  res.json({ status: 'ok', service: 'ZamLift API' });
});

app.use('/api/auth', authRoutes);
app.use('/api/drivers', driverRoutes);
app.use('/api/routes', routeRoutes);
app.use('/api/trips', tripRoutes);
app.use('/api/bookings', bookingRoutes);
app.use('/api/payments', paymentRoutes);
app.use('/api/ratings', ratingRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api/smart', smartRoutes);

app.use((_req, _res, next) => {
  const err = new Error('Not found');
  err.status = 404;
  next(err);
});

app.use(errorHandler);

module.exports = app;
