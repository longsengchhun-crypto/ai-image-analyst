// AI vision provider abstraction.
//
// Why Claude Vision (Anthropic) instead of Google Cloud Vision + a separate LLM:
// the spec allows either "Google Cloud Vision API (recommended) or OpenAI's
// GPT-4V / Claude Vision". A single multimodal model call gives us description,
// object listing, OCR summary AND grounded Q&A from one provider/one API key,
// which is simpler to operate and keeps the whole analysis under one coherent
// "confidence" story. The documented tradeoff (see AI_DOCUMENTATION.md) is that
// Claude does not return pixel-precise bounding boxes the way Cloud Vision's
// OBJECT_LOCALIZATION does — object detection here is a labeled list with a
// self-reported confidence band, not geometric boxes. Swapping in Cloud Vision
// for the labeling step later is a drop-in change confined to this file.
const Anthropic = require('@anthropic-ai/sdk');
const config = require('../config');

const client = config.anthropicApiKey ? new Anthropic({ apiKey: config.anthropicApiKey }) : null;

const CONFIDENCE_BANDS = {
  high: 0.92,
  medium: 0.65,
  low: 0.35,
};

function bandToScore(band) {
  return CONFIDENCE_BANDS[band] ?? 0.5;
}

// The structured-output contract we ask Claude to fill. Kept intentionally
// simple/flat so it is cheap to validate and safe to store as JSONB.
const ANALYSIS_SYSTEM_PROMPT = `You are a careful, honest visual-analysis assistant embedded in an
accessibility and productivity app. You will be shown one image. Respond with ONLY a single JSON
object (no markdown fences, no commentary) matching exactly this shape:

{
  "description": string,          // 2-3 sentences, written for someone who cannot see the image
  "objects": [
    { "name": string, "confidenceBand": "high" | "medium" | "low" }
  ],                                // every visible object/entity/animal/person/landmark you can identify, most prominent first
  "detectedText": string | null,    // verbatim transcription of any readable text/OCR content, or null if none
  "overallConfidenceBand": "high" | "medium" | "low",
  "uncertaintyNote": string | null  // plain-language caveat if the image is blurry, too dark/bright,
                                     // abstract, ambiguous, or otherwise hard to interpret; otherwise null
}

Rules:
- Never claim certainty you do not have. If the image is blurry, very dark/bright, abstract art,
  or otherwise ambiguous, say so plainly in "uncertaintyNote" and lower the confidence bands honestly.
- If the image contains people, describe them factually (count, general activity/appearance) and do
  NOT attempt facial identification, age-guessing beyond broad ranges, or any biometric inference.
- confidenceBand is a self-assessed qualitative judgment, not a calibrated statistic — treat "high"
  as "very likely correct", "medium" as "plausible but could be wrong", "low" as "genuinely unsure".
- Keep the objects list to at most 15 entries.
- Output must be valid JSON and nothing else.`;

const VQA_SYSTEM_PROMPT = `You are a careful, honest visual question-answering assistant. You will be
shown one image and a user's question about it. Respond with ONLY a single JSON object (no markdown
fences, no commentary) matching exactly this shape:

{
  "answer": string,                 // direct, grounded answer to the question, 1-3 sentences
  "confidenceBand": "high" | "medium" | "low",
  "uncertaintyNote": string | null   // set this if the question can't be reliably answered from the
                                      // image (e.g. asks about something outside the frame, or the
                                      // image is too unclear); otherwise null
}
Only answer based on what is visually verifiable in the image. If you cannot tell, say so honestly
and use a low confidence band rather than guessing.`;

function extractJson(text) {
  // Claude is instructed to return raw JSON, but defensively strip any
  // accidental markdown fencing before parsing.
  const cleaned = text.trim().replace(/^```(json)?/i, '').replace(/```$/, '').trim();
  return JSON.parse(cleaned);
}

function demoAnalysis() {
  return {
    description:
      'DEMO MODE (no ANTHROPIC_API_KEY configured): this is a placeholder analysis so the app ' +
      'remains fully testable end-to-end. It shows what a real response looks like — a short, ' +
      'natural-language description of the uploaded image would appear here.',
    objects: [
      { name: 'sample object A', confidenceBand: 'high' },
      { name: 'sample object B', confidenceBand: 'medium' },
      { name: 'background / setting', confidenceBand: 'low' },
    ],
    detectedText: null,
    overallConfidenceBand: 'medium',
    uncertaintyNote: 'Running in demo mode — set ANTHROPIC_API_KEY on the backend for live analysis.',
    isDemoMode: true,
  };
}

function demoAnswer(question) {
  return {
    answer: `DEMO MODE: a grounded answer to "${question}" would appear here once ANTHROPIC_API_KEY is configured.`,
    confidenceBand: 'medium',
    uncertaintyNote: 'Running in demo mode — set ANTHROPIC_API_KEY on the backend for live answers.',
    isDemoMode: true,
  };
}

/**
 * Analyze an image: description + object list + OCR summary + overall confidence.
 * @param {Buffer} imageBuffer - compressed image bytes
 * @param {string} mediaType - e.g. 'image/jpeg'
 */
async function analyzeImage(imageBuffer, mediaType) {
  if (!client) return demoAnalysis();

  const message = await client.messages.create({
    model: config.anthropicModel,
    max_tokens: 1024,
    system: ANALYSIS_SYSTEM_PROMPT,
    messages: [
      {
        role: 'user',
        content: [
          {
            type: 'image',
            source: { type: 'base64', media_type: mediaType, data: imageBuffer.toString('base64') },
          },
          { type: 'text', text: 'Analyze this image according to your instructions.' },
        ],
      },
    ],
  });

  const raw = message.content.find((c) => c.type === 'text')?.text || '{}';
  const parsed = extractJson(raw);
  return { ...parsed, isDemoMode: false };
}

/**
 * Answer a free-form question about an already-analyzed image.
 */
async function askQuestion(imageBuffer, mediaType, question) {
  if (!client) return demoAnswer(question);

  const message = await client.messages.create({
    model: config.anthropicModel,
    max_tokens: 512,
    system: VQA_SYSTEM_PROMPT,
    messages: [
      {
        role: 'user',
        content: [
          {
            type: 'image',
            source: { type: 'base64', media_type: mediaType, data: imageBuffer.toString('base64') },
          },
          { type: 'text', text: `Question: ${question}` },
        ],
      },
    ],
  });

  const raw = message.content.find((c) => c.type === 'text')?.text || '{}';
  const parsed = extractJson(raw);
  return { ...parsed, isDemoMode: false };
}

module.exports = { analyzeImage, askQuestion, bandToScore };
