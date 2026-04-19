const HttpError = require('../utils/httpError');

module.exports = (schema) => (req, _res, next) => {
  const { error, value } = schema.validate(req.body, { abortEarly: false, stripUnknown: true });
  if (error) {
    return next(new HttpError(400, error.details.map((d) => d.message).join(', ')));
  }
  req.body = value;
  return next();
};
