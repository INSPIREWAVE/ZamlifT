function validate(schema) {
  return (req, res, next) => {
    const parseResult = schema.safeParse({
      body: req.body,
      params: req.params,
      query: req.query,
    });

    if (!parseResult.success) {
      const errors = parseResult.error.issues.map((i) => ({
        path: i.path.join('.'),
        message: i.message,
      }));
      const message = errors[0]?.message || 'Validation failed';
      console.error('[validation] request validation failed', {
        path: req.originalUrl,
        method: req.method,
        errors,
      });
      return res.status(400).json({
        message,
        errors,
      });
    }

    req.validated = parseResult.data;
    return next();
  };
}

module.exports = { validate };
