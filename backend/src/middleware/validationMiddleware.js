function validate(schema) {
  return (req, res, next) => {
    const parseResult = schema.safeParse({
      body: req.body,
      params: req.params,
      query: req.query,
    });

    if (!parseResult.success) {
      return res.status(400).json({
        message: 'Validation failed',
        errors: parseResult.error.issues.map((i) => ({
          path: i.path.join('.'),
          message: i.message,
        })),
      });
    }

    req.validated = parseResult.data;
    return next();
  };
}

module.exports = { validate };
