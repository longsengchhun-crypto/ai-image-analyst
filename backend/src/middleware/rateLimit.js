// Rate limiting to prevent abuse of the (metered) AI vision endpoints.
const rateLimit = require('express-rate-limit');

// General API traffic
const generalLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 300,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Too many requests. Please slow down and try again shortly.' },
});

// Stricter limit specifically on the expensive AI calls (image analysis, Q&A)
const aiLimiter = rateLimit({
  windowMs: 60 * 1000, // 1 minute
  max: 12,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Too many analysis requests. Please wait a minute before trying again.' },
});

module.exports = { generalLimiter, aiLimiter };
