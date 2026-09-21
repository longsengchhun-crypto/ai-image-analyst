// GET /api/history, GET /api/history/:id, DELETE /api/history/:id, DELETE /api/history
const express = require('express');
const db = require('../db');

const router = express.Router();

// List (paginated, newest first)
router.get('/', async (req, res, next) => {
  try {
    const limit = Math.min(parseInt(req.query.limit, 10) || 20, 100);
    const offset = Math.max(parseInt(req.query.offset, 10) || 0, 0);

    const { rows } = await db.query(
      `SELECT id, image_thumbnail, description, detected_objects, detected_text,
              user_questions, confidence_score, confidence_band, is_demo_mode,
              created_at, updated_at
       FROM image_history
       WHERE user_id = $1
       ORDER BY created_at DESC
       LIMIT $2 OFFSET $3`,
      [req.userId, limit, offset]
    );

    res.json({ items: rows.map(serialize), limit, offset });
  } catch (err) {
    next(err);
  }
});

// Single record detail
router.get('/:id', async (req, res, next) => {
  try {
    const { rows } = await db.query(
      `SELECT * FROM image_history WHERE id = $1 AND user_id = $2`,
      [req.params.id, req.userId]
    );
    if (!rows.length) return res.status(404).json({ error: 'History item not found.' });
    res.json(serialize(rows[0]));
  } catch (err) {
    next(err);
  }
});

// Delete one
router.delete('/:id', async (req, res, next) => {
  try {
    const { rowCount } = await db.query(
      `DELETE FROM image_history WHERE id = $1 AND user_id = $2`,
      [req.params.id, req.userId]
    );
    if (!rowCount) return res.status(404).json({ error: 'History item not found.' });
    res.status(204).send();
  } catch (err) {
    next(err);
  }
});

// Clear all history for this user
router.delete('/', async (req, res, next) => {
  try {
    await db.query(`DELETE FROM image_history WHERE user_id = $1`, [req.userId]);
    res.status(204).send();
  } catch (err) {
    next(err);
  }
});

function serialize(row) {
  return {
    id: row.id,
    thumbnail: row.image_thumbnail,
    description: row.description,
    objects: row.detected_objects,
    detectedText: row.detected_text,
    questions: row.user_questions,
    confidenceScore: row.confidence_score,
    confidenceBand: row.confidence_band,
    isDemoMode: row.is_demo_mode,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
  };
}

module.exports = router;
