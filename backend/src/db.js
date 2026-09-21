// Postgres connection pool for Neon.
// Neon's pooled connection string (the "-pooler" host) works well with a small
// pg Pool even in serverless environments like Vercel functions.
const { Pool } = require('pg');
const config = require('./config');

if (!config.databaseUrl) {
  console.error('[db] DATABASE_URL is not set. Set it in backend/.env (local) or as a Vercel project env var.');
}

const pool = new Pool({
  connectionString: config.databaseUrl,
  ssl: { rejectUnauthorized: false }, // Neon requires TLS; sslmode=require is in the URL too
  max: 5, // keep small — serverless functions each get their own pool
  idleTimeoutMillis: 10_000,
});

pool.on('error', (err) => {
  console.error('[db] Unexpected error on idle client', err.message);
});

module.exports = {
  query: (text, params) => pool.query(text, params),
  pool,
};
