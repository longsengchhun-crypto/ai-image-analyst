// Server-side image normalization: re-encode to JPEG, cap dimensions, and
// build a small base64 thumbnail for history storage. Doing this server-side
// (in addition to client-side compression in the Flutter app) keeps bandwidth
// and AI-provider token costs predictable regardless of what the client sends.
const sharp = require('sharp');

const MAX_DIMENSION = 1568; // Claude vision's recommended max long edge
const THUMBNAIL_DIMENSION = 256;

async function normalizeForAnalysis(buffer) {
  const normalized = await sharp(buffer)
    .rotate() // respect EXIF orientation
    .resize({ width: MAX_DIMENSION, height: MAX_DIMENSION, fit: 'inside', withoutEnlargement: true })
    .jpeg({ quality: 82 })
    .toBuffer();
  return { buffer: normalized, mediaType: 'image/jpeg' };
}

async function buildThumbnail(buffer) {
  const thumb = await sharp(buffer)
    .rotate()
    .resize({ width: THUMBNAIL_DIMENSION, height: THUMBNAIL_DIMENSION, fit: 'inside' })
    .jpeg({ quality: 60 })
    .toBuffer();
  return `data:image/jpeg;base64,${thumb.toString('base64')}`;
}

module.exports = { normalizeForAnalysis, buildThumbnail };
