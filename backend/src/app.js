// Express app definition, shared between local dev (server.js) and the
// Vercel serverless entrypoint (api/index.js).
const express = require('express');
const cors = require('cors');
const config = require('./config');
const { requireApiKey, requireAuth } = require('./middleware/auth');
const { generalLimiter, aiLimiter } = require('./middleware/rateLimit');
const { notFoundHandler, errorHandler } = require('./middleware/errorHandler');

const authRoutes = require('./routes/auth');
const analyzeRoutes = require('./routes/analyze');
const historyRoutes = require('./routes/history');
const questionRoutes = require('./routes/question');

const app = express();

app.use(
  cors({
    origin: config.corsOrigins.includes('*') ? true : config.corsOrigins,
  })
);
app.use(express.json());
app.use(generalLimiter);

app.get('/api/health', (req, res) => {
  res.json({ status: 'ok', demoMode: config.isDemoMode, provider: config.activeProvider });
});

// Auth is app-key gated but does not require a JWT yet (it issues one).
app.use('/api/auth', requireApiKey, authRoutes);

// Everything else requires both the app key and a valid user session.
app.use('/api/analyze-image', requireApiKey, requireAuth, aiLimiter, analyzeRoutes);
app.use('/api/ask-question', requireApiKey, requireAuth, aiLimiter, questionRoutes);
app.use('/api/history', requireApiKey, requireAuth, historyRoutes);

app.use(notFoundHandler);
app.use(errorHandler);

module.exports = app;
