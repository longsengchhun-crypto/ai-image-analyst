// Local dev entrypoint. On Vercel, api/index.js is used instead.
const app = require('./app');
const config = require('./config');

app.listen(config.port, () => {
  console.log(`[server] AI Image Analyst backend listening on port ${config.port}`);
  console.log(`[server] Demo mode: ${config.isDemoMode ? 'ON (no ANTHROPIC_API_KEY set)' : 'off'}`);
});
