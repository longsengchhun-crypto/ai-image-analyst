// POST /api/ask-question
// Accepts the (re-sent) image plus a question and an optional historyId. We
// deliberately do NOT keep original image bytes in the database (see privacy
// notes in README/AI_DOCUMENTATION) — the client re-sends the image bytes it
// already has locally so we can ground the answer, and only the resulting
// Q&A text is persisted.
const express = require('express');
const multer = require('multer');
const db = require('../db');
const config = require('../config');
const { normalizeForAnalysis } = require('../services/imageProcessing');
const { askQuestion, bandToScore } = require('../services/visionProvider');

const router = express.Router();
const upload = multer({ storage: multer.memoryStorage(), limits: { fileSize: config.maxImageBytes } });

router.post('/', upload.single('image'), async (req, res, next) => {
  try {
    const { question, historyId } = req.body;
    if (!req.file) {
      return res.status(400).json({ error: 'No image file provided. Use the "image" form field.' });
    }
    if (!question || !question.trim()) {
      return res.status(400).json({ error: 'A non-empty "question" field is required.' });
    }

    const { buffer, mediaType } = await normalizeForAnalysis(req.file.buffer);
    const result = await askQuestion(buffer, mediaType, question.trim());
    const confidence = bandToScore(result.confidenceBand);

    const qaEntry = {
      question: question.trim(),
      answer: result.answer,
      confidenceBand: result.confidenceBand,
      confidence,
      uncertaintyNote: result.uncertaintyNote || null,
      askedAt: new Date().toISOString(),
    };

    if (historyId) {
      // Append to the existing record's question history, scoped to this user.
      await db.query(
        `UPDATE image_history
         SET user_questions = user_questions || $1::jsonb
         WHERE id = $2 AND user_id = $3`,
        [JSON.stringify([qaEntry]), historyId, req.userId]
      );
    }

    res.status(200).json({ ...qaEntry, isDemoMode: !!result.isDemoMode });
  } catch (err) {
    next(err);
  }
});

module.exports = router;
