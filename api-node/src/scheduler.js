const { pool } = require('./db');

const pingMonitor = async (monitor) => {
  const start = Date.now();
  let statusCode = null;
  let isUp = false;

  try {
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 10000);
    const response = await fetch(monitor.url, { signal: controller.signal });
    clearTimeout(timeout);
    statusCode = response.status;
    isUp = response.ok;
  } catch (err) {
    isUp = false;
  }

  const responseTimeMs = Date.now() - start;

  await pool.query(
    'INSERT INTO checks (monitor_id, status_code, response_time_ms, is_up) VALUES ($1, $2, $3, $4)',
    [monitor.id, statusCode, responseTimeMs, isUp]
  );
};

const startScheduler = () => {
  const intervalId = setInterval(async () => {
    try {
      const { rows: monitors } = await pool.query(`
        SELECT m.* FROM monitors m
        LEFT JOIN LATERAL (
          SELECT checked_at FROM checks
          WHERE monitor_id = m.id
          ORDER BY checked_at DESC LIMIT 1
        ) c ON true
        WHERE c.checked_at IS NULL
           OR c.checked_at < NOW() - (m.interval_seconds || ' seconds')::INTERVAL
      `);

      await Promise.allSettled(monitors.map(pingMonitor));
    } catch (err) {
      console.error('Scheduler error:', err);
    }
  }, 15000);

  console.log('Scheduler started');
  return () => clearInterval(intervalId);
};

module.exports = { startScheduler };
