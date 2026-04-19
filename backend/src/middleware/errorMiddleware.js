function notFound(req, res, next) {
  if (process.env.NODE_ENV === 'production') {
    return res.status(404).json({ message: 'Resource not found' });
  }

  return res.status(404).json({ message: `Route not found: ${req.originalUrl}` });
}

function errorHandler(err, req, res, next) {
  const status = err.status || 500;
  const payload = {
    message: err.message || 'Internal Server Error',
  };

  if (process.env.NODE_ENV !== 'production' && err.stack) {
    payload.stack = err.stack;
  }

  res.status(status).json(payload);
}

module.exports = { notFound, errorHandler };
