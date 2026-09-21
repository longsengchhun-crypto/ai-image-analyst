// One-off migration runner: applies migrations/schema.sql to DATABASE_URL.
// Usage: npm run migrate
const fs = require('fs');
const path = require('path');
const { pool } = require('./db');

async function main() {
  const sqlPath = path.join(__dirname, '..', 'migrations', 'schema.sql');
  const sql = fs.readFileSync(sqlPath, 'utf8');
  console.log('[migrate] Applying migrations/schema.sql ...');
  await pool.query(sql);
  console.log('[migrate] Done.');
  await pool.end();
}

main().catch((err) => {
  console.error('[migrate] Failed:', err);
  process.exit(1);
});
