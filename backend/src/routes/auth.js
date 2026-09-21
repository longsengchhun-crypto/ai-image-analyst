// Anonymous session issuance. No email/password/PII is collected — a UUID is
// created server-side and a JWT identifying it is handed back. The Flutter
// app persists this token locally and sends it as a Bearer token thereafter.
const express = require('express');
const jwt = require('jsonwebtoken');
const db = require('../db');
const config = require('../config');

const router = express.Router();

router.post('/anonymous', async (req, res, next) => {
  try {
    const { rows } = await db.query('INSERT INTO users DEFAULT VALUES RETURNING id');
    const userId = rows[0].id;
    const token = jwt.sign({ userId }, config.jwtSecret, { expiresIn: '180d' });
    res.status(201).json({ token, userId });
  } catch (err) {
    next(err);
  }
});

module.exports = router;
