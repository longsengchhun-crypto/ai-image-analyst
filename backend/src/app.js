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

// The bare domain root has no meaning as an API endpoint, but people will
// naturally visit it in a browser (this is a REST API, not a website) — a
// short explanation beats a bare 404.
app.get('/', (req, res) => {
  res.json({
    name: 'AI Image Analyst API',
    description: 'Backend for the AI Image Understanding App. This is a REST API, not a webpage — there is no UI to view here.',
    status: 'ok',
    demoMode: config.isDemoMode,
    provider: config.activeProvider,
    healthCheck: '/api/health',
    repository: 'https://github.com/longsengchhun-crypto/ai-image-analyst',
    endpoints: [
      'POST /api/auth/anonymous',
      'POST /api/analyze-image',
      'POST /api/ask-question',
      'GET /api/history',
      'GET /api/history/:id',
      'DELETE /api/history/:id',
      'DELETE /api/history',
    ],
  });
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
