// POST /api/analyze-image
// Accepts a multipart image upload, runs it through the vision provider, and
// persists a history row scoped to the authenticated (anonymous) user.
const express = require('express');
const multer = require('multer');
const db = require('../db');
const config = require('../config');
const { normalizeForAnalysis, buildThumbnail } = require('../services/imageProcessing');
const { analyzeImage, bandToScore } = require('../services/visionProvider');

const router = express.Router();

const ACCEPTED_MIME = new Set(['image/jpeg', 'image/png', 'image/webp']);

const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: config.maxImageBytes },
  fileFilter: (req, file, cb) => {
    if (!ACCEPTED_MIME.has(file.mimetype)) {
      const err = new Error('Unsupported image format. Please use JPEG, PNG, or WebP.');
      err.status = 400;
      return cb(err);
    }
    cb(null, true);
  },
});

router.post('/', upload.single('image'), async (req, res, next) => {
  try {
    if (!req.file) {
      return res.status(400).json({ error: 'No image file provided. Use the "image" form field.' });
    }

    // Thumbnail generation doesn't depend on the normalized buffer, so it can
    // run fully overlapped with the (much slower) AI call instead of adding
    // to the request's wall-clock time.
    const thumbnailPromise = buildThumbnail(req.file.buffer);
    const { buffer, mediaType } = await normalizeForAnalysis(req.file.buffer);
    const [analysis, thumbnail] = await Promise.all([
      analyzeImage(buffer, mediaType),
      thumbnailPromise,
    ]);

    const overallScore = bandToScore(analysis.overallConfidenceBand);
    const objects = (analysis.objects || []).map((o) => ({
      name: o.name,
      confidenceBand: o.confidenceBand,
      confidence: bandToScore(o.confidenceBand),
    }));

    const { rows } = await db.query(
      `INSERT INTO image_history
        (user_id, image_thumbnail, description, detected_objects, detected_text,
         confidence_score, confidence_band, is_demo_mode)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
       RETURNING id, created_at`,
      [
        req.userId,
        thumbnail,
        analysis.description,
        JSON.stringify(objects),
        analysis.detectedText || null,
        overallScore,
        analysis.overallConfidenceBand,
        !!analysis.isDemoMode,
      ]
    );

    res.status(201).json({
      id: rows[0].id,
      createdAt: rows[0].created_at,
      description: analysis.description,
      objects,
      detectedText: analysis.detectedText || null,
      confidenceScore: overallScore,
      confidenceBand: analysis.overallConfidenceBand,
      uncertaintyNote: analysis.uncertaintyNote || null,
      isDemoMode: !!analysis.isDemoMode,
      thumbnail,
      questions: [],
    });
  } catch (err) {
    next(err);
  }
});

module.exports = router;
