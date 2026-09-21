// Two-layer auth:
//  1. App-level gate: every request must send a matching `x-api-key` header.
//     This keeps the API from being casually scraped/abused if the URL leaks.
//  2. User-level identity: a JWT (issued by POST /api/auth/anonymous) identifies
//     which anonymous "user" a history row belongs to, without collecting any
//     personal information.
const jwt = require('jsonwebtoken');
const config = require('../config');

function requireApiKey(req, res, next) {
  const key = req.header('x-api-key');
  if (!key || key !== config.appApiKey) {
    return res.status(401).json({ error: 'Missing or invalid API key.' });
  }
  next();
}

function requireAuth(req, res, next) {
  const header = req.header('authorization') || '';
  const token = header.startsWith('Bearer ') ? header.slice(7) : null;
  if (!token) {
    return res.status(401).json({ error: 'Missing bearer token. Call /api/auth/anonymous first.' });
  }
  try {
    const payload = jwt.verify(token, config.jwtSecret);
    req.userId = payload.userId;
    next();
  } catch (err) {
    return res.status(401).json({ error: 'Invalid or expired session token.' });
  }
}

module.exports = { requireApiKey, requireAuth };
