// AI vision provider abstraction.
//
// Two backends are supported, selected automatically by which API key is
// configured (see config.js: Gemini is preferred if GEMINI_API_KEY is set,
// otherwise Anthropic if ANTHROPIC_API_KEY is set, otherwise demo mode).
//
// Why Gemini as the default recommendation: Google AI Studio issues a
// genuinely free API key (no credit card, generous free-tier quota), which
// makes it the practical choice for a student/portfolio project. Claude
// Vision remains fully supported as a drop-in alternative — same prompts,
// same response contract — for anyone who already has an Anthropic key.
//
// Why either of these over Google Cloud Vision + a separate LLM: the spec
// allows "Google Cloud Vision API (recommended) or OpenAI's GPT-4V / Claude
// Vision." A single multimodal model call gives description, object
// listing, OCR summary AND grounded Q&A from one provider/one API key. The
// documented tradeoff (see AI_DOCUMENTATION.md) is that neither Gemini nor
// Claude returns pixel-precise bounding boxes the way Cloud Vision's
// OBJECT_LOCALIZATION does — object detection here is a labeled list with a
// self-reported confidence band, not geometric boxes.
const Anthropic = require('@anthropic-ai/sdk');
const config = require('../config');

const anthropicClient = config.anthropicApiKey ? new Anthropic({ apiKey: config.anthropicApiKey }) : null;

const CONFIDENCE_BANDS = {
  high: 0.92,
  medium: 0.65,
  low: 0.35,
};

function bandToScore(band) {
  return CONFIDENCE_BANDS[band] ?? 0.5;
}

// The structured-output contract we ask the model to fill. Kept
// intentionally simple/flat so it is cheap to validate and safe to store as
// JSONB, and identical across both providers.
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
  // Defensively strip any accidental markdown fencing before parsing, even
  // though both providers are instructed to return raw JSON.
  const cleaned = text.trim().replace(/^```(json)?/i, '').replace(/```$/, '').trim();
  return JSON.parse(cleaned);
}

function demoAnalysis() {
  return {
    description:
      'DEMO MODE (no GEMINI_API_KEY or ANTHROPIC_API_KEY configured): this is a placeholder ' +
      'analysis so the app remains fully testable end-to-end. It shows what a real response ' +
      'looks like — a short, natural-language description of the uploaded image would appear here.',
    objects: [
      { name: 'sample object A', confidenceBand: 'high' },
      { name: 'sample object B', confidenceBand: 'medium' },
      { name: 'background / setting', confidenceBand: 'low' },
    ],
    detectedText: null,
    overallConfidenceBand: 'medium',
    uncertaintyNote: 'Running in demo mode — set GEMINI_API_KEY (free, see README) or ANTHROPIC_API_KEY on the backend for live analysis.',
    isDemoMode: true,
  };
}

function demoAnswer(question) {
  return {
    answer: `DEMO MODE: a grounded answer to "${question}" would appear here once a live AI key is configured.`,
    confidenceBand: 'medium',
    uncertaintyNote: 'Running in demo mode — set GEMINI_API_KEY (free, see README) or ANTHROPIC_API_KEY on the backend for live answers.',
    isDemoMode: true,
  };
}

// ---------------------------------------------------------------------------
// Gemini backend (Google AI Studio — free tier)
// ---------------------------------------------------------------------------
const GEMINI_MAX_ATTEMPTS = 3;
const GEMINI_RETRY_STATUS = new Set([429, 500, 503]);

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

async function callGemini(systemPrompt, userText, imageBuffer, mediaType) {
  const url = `https://generativelanguage.googleapis.com/v1beta/models/${config.geminiModel}:generateContent?key=${config.geminiApiKey}`;

  const body = {
    systemInstruction: { parts: [{ text: systemPrompt }] },
    contents: [
      {
        role: 'user',
        parts: [
          { inline_data: { mime_type: mediaType, data: imageBuffer.toString('base64') } },
          { text: userText },
        ],
      },
    ],
    generationConfig: {
      responseMimeType: 'application/json',
      temperature: 0.4,
      maxOutputTokens: 1024,
    },
  };

  let resp;
  for (let attempt = 1; attempt <= GEMINI_MAX_ATTEMPTS; attempt += 1) {
    resp = await fetch(url, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(body),
    });

    if (resp.ok) break;

    const errText = await resp.text().catch(() => '');
    console.error(`[visionProvider] Gemini API error ${resp.status} (attempt ${attempt}/${GEMINI_MAX_ATTEMPTS}):`, errText);

    const shouldRetry = GEMINI_RETRY_STATUS.has(resp.status) && attempt < GEMINI_MAX_ATTEMPTS;
    if (!shouldRetry) {
      throw new Error('AI provider request failed.');
    }
    await sleep(500 * attempt);
  }

  const data = await resp.json();
  const text = data.candidates?.[0]?.content?.parts?.find((p) => p.text)?.text;
  if (!text) {
    console.error('[visionProvider] Gemini returned no text content:', JSON.stringify(data).slice(0, 500));
    throw new Error('AI provider returned an empty response.');
  }
  return extractJson(text);
}

// ---------------------------------------------------------------------------
// Anthropic backend (Claude Vision)
// ---------------------------------------------------------------------------
async function callAnthropic(systemPrompt, userText, imageBuffer, mediaType) {
  const message = await anthropicClient.messages.create({
    model: config.anthropicModel,
    max_tokens: 1024,
    system: systemPrompt,
    messages: [
      {
        role: 'user',
        content: [
          {
            type: 'image',
            source: { type: 'base64', media_type: mediaType, data: imageBuffer.toString('base64') },
          },
          { type: 'text', text: userText },
        ],
      },
    ],
  });

  const raw = message.content.find((c) => c.type === 'text')?.text || '{}';
  return extractJson(raw);
}

/**
 * Analyze an image: description + object list + OCR summary + overall confidence.
 * @param {Buffer} imageBuffer - compressed image bytes
 * @param {string} mediaType - e.g. 'image/jpeg'
 */
async function analyzeImage(imageBuffer, mediaType) {
  if (config.activeProvider === 'gemini') {
    const parsed = await callGemini(ANALYSIS_SYSTEM_PROMPT, 'Analyze this image according to your instructions.', imageBuffer, mediaType);
    return { ...parsed, isDemoMode: false };
  }
  if (config.activeProvider === 'anthropic') {
    const parsed = await callAnthropic(ANALYSIS_SYSTEM_PROMPT, 'Analyze this image according to your instructions.', imageBuffer, mediaType);
    return { ...parsed, isDemoMode: false };
  }
  return demoAnalysis();
}

/**
 * Answer a free-form question about an already-analyzed image.
 */
async function askQuestion(imageBuffer, mediaType, question) {
  const userText = `Question: ${question}`;
  if (config.activeProvider === 'gemini') {
    const parsed = await callGemini(VQA_SYSTEM_PROMPT, userText, imageBuffer, mediaType);
    return { ...parsed, isDemoMode: false };
  }
  if (config.activeProvider === 'anthropic') {
    const parsed = await callAnthropic(VQA_SYSTEM_PROMPT, userText, imageBuffer, mediaType);
    return { ...parsed, isDemoMode: false };
  }
  return demoAnswer(question);
}

module.exports = { analyzeImage, askQuestion, bandToScore };
