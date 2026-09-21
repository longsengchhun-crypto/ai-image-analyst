// Vercel serverless function entrypoint. Vercel's Node runtime can invoke an
// Express app directly as the request handler (req, res) => app(req, res).
const app = require('../src/app');

module.exports = (req, res) => app(req, res);
