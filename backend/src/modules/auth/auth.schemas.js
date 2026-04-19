const Joi = require('joi');

exports.registerSchema = Joi.object({
  fullName: Joi.string().min(3).max(120).required(),
  email: Joi.string().email().required(),
  password: Joi.string().min(8).max(128).required(),
  role: Joi.string().valid('passenger', 'driver', 'admin').default('passenger'),
  phone: Joi.string().min(7).max(20).optional(),
});

exports.loginSchema = Joi.object({
  email: Joi.string().email().required(),
  password: Joi.string().required(),
});
