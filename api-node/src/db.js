const fs = require('fs');
const { Pool } = require('pg');

const databaseUrl =
  process.env.DATABASE_URL ||
  fs.readFileSync(process.env.DATABASE_URL_FILE, 'utf8');

const pool = new Pool({
  connectionString: databaseUrl,
});

pool.on('error', (err) => {
  console.error('Unexpected error on idle client', err);
  process.exit(-1);
});

const getDateTime = async () => {
  const res = await pool.query('SELECT NOW() as now');
  return res.rows[0];
};

const initDb = async () => {
  await pool.query(`
    CREATE TABLE IF NOT EXISTS monitors (
      id SERIAL PRIMARY KEY,
      name VARCHAR(255) NOT NULL,
      url VARCHAR(2048) NOT NULL,
      interval_seconds INTEGER NOT NULL DEFAULT 60,
      created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
    );
    CREATE TABLE IF NOT EXISTS checks (
      id SERIAL PRIMARY KEY,
      monitor_id INTEGER NOT NULL REFERENCES monitors(id) ON DELETE CASCADE,
      status_code INTEGER,
      response_time_ms INTEGER,
      is_up BOOLEAN NOT NULL,
      checked_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
    );
    CREATE INDEX IF NOT EXISTS idx_checks_monitor_id_checked_at
      ON checks (monitor_id, checked_at DESC);
  `);
  console.log('Database tables initialized');
};

module.exports = { pool, getDateTime, initDb };
