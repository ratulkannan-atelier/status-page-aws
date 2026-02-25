const express = require('express');
const router = express.Router();
const { pool } = require('../db');

router.get('/', async (req, res) => {
  const result = await pool.query(`
    SELECT m.*,
      c.is_up AS last_is_up,
      c.response_time_ms AS last_response_time_ms,
      c.checked_at AS last_checked_at
    FROM monitors m
    LEFT JOIN LATERAL (
      SELECT is_up, response_time_ms, checked_at
      FROM checks WHERE monitor_id = m.id
      ORDER BY checked_at DESC LIMIT 1
    ) c ON true
    ORDER BY m.created_at
  `);
  res.json(result.rows);
});

router.post('/', async (req, res) => {
  const { name, url, interval_seconds = 60 } = req.body;
  if (!name || !url) {
    return res.status(400).json({ error: 'name and url are required' });
  }
  const result = await pool.query(
    'INSERT INTO monitors (name, url, interval_seconds) VALUES ($1, $2, $3) RETURNING *',
    [name, url, interval_seconds]
  );
  res.status(201).json(result.rows[0]);
});

router.delete('/:id', async (req, res) => {
  await pool.query('DELETE FROM monitors WHERE id = $1', [req.params.id]);
  res.status(204).end();
});

module.exports = router;
