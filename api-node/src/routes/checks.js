const express = require('express');
const router = express.Router();
const { pool } = require('../db');

router.get('/:monitorId', async (req, res) => {
  const { monitorId } = req.params;

  const [historyResult, uptimeResult] = await Promise.all([
    pool.query(
      'SELECT * FROM checks WHERE monitor_id = $1 ORDER BY checked_at DESC LIMIT 50',
      [monitorId]
    ),
    pool.query(
      `SELECT
        COUNT(*) FILTER (WHERE is_up = true) AS up_count,
        COUNT(*) AS total_count
      FROM checks
      WHERE monitor_id = $1 AND checked_at > NOW() - INTERVAL '24 hours'`,
      [monitorId]
    ),
  ]);

  const { up_count, total_count } = uptimeResult.rows[0];
  const uptime_percentage = total_count > 0
    ? ((up_count / total_count) * 100).toFixed(2)
    : null;

  res.json({
    checks: historyResult.rows,
    uptime_percentage,
  });
});

module.exports = router;
