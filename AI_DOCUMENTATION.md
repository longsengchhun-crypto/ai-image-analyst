# AI Integration Documentation

## Which AI service, and why

**Two pluggable providers, both multimodal "vision" LLMs, selected
automatically by which API key is configured** in
`backend/src/services/visionProvider.js`:

1. **Google Gemini** (`gemini-2.0-flash`, via the Google AI Studio REST API)
   — used if `GEMINI_API_KEY` is set. **This is the recommended default**
   because Google AI Studio issues a genuinely free API key (no credit card,
   generous free-tier quota), which makes it the practical choice for a
   student/portfolio project: get one at
   [aistudio.google.com/apikey](https://aistudio.google.com/apikey) in about
   two minutes.
2. **Anthropic Claude Vision** (`claude-fable-5-1`) — used instead if
   `ANTHROPIC_API_KEY` is set (and no Gemini key is present). Fully
   supported as a drop-in alternative for anyone who already has an
   Anthropic account.

If neither key is set, the backend runs in **demo mode** (see below).

The assignment explicitly allows "Google Cloud Vision API (recommended) or
OpenAI's GPT-4V / Claude Vision." We chose a single multimodal LLM (Gemini or
Claude) over the Cloud-Vision-plus-separate-LLM combination for three
reasons:

1. **One provider, one API key, one coherent confidence story.** Cloud
   Vision's `LABEL_DETECTION` returns calibrated numeric scores, but bolting
   a second LLM on top for VQA means reconciling two different confidence
   systems. A single multimodal call gives description, object list, OCR
   summary, and (on follow-up) grounded Q&A from one model, one prompt
   contract, one honesty standard.
2. **Operational simplicity, and a genuinely free path.** One provider
   credential to manage, one rate limit to reason about, and — critically
   for a student project with no budget — Gemini's free tier means the app
   can run with live AI results at zero cost.
3. **Documented tradeoff, not a blind spot.** Neither Gemini nor Claude
   returns pixel-precise bounding boxes the way Cloud Vision's
   `OBJECT_LOCALIZATION` does. Object detection here is a **labeled list
   with a self-reported qualitative confidence band**, not geometric boxes.
   If bounding-box overlays become a requirement, Cloud Vision's
   `OBJECT_LOCALIZATION` can be added as a second call inside
   `visionProvider.js` without touching any other layer — both providers are
   already isolated behind the shared `analyzeImage()` / `askQuestion()`
   functions, which return the exact same JSON contract regardless of which
   backend produced it.

## Confidence messaging — what the numbers actually mean

The backend maps three qualitative bands to fixed scores for consistent UI
color-coding:

| Band | Score shown | Meaning |
|---|---|---|
| High | 0.92 | The model is very likely correct |
| Medium | 0.65 | Plausible, but could be wrong |
| Low | 0.35 | The model is genuinely unsure |

**This is a self-assessed heuristic, not a calibrated statistical
probability.** Unlike Cloud Vision's numeric label scores (which are
measured against a labeled dataset), an LLM asked to grade its own certainty
is producing a judgment, not a measurement. We surface it as a 3-level badge
rather than a fake-precise percentage (e.g. "95% confident") specifically to
avoid implying false precision — this is documented here and in
`ConfidenceBadge`'s doc comment so nobody mistakes it for ground truth.

## The three required prompts

### 1. Image analysis (description + objects + OCR + confidence)

System prompt sent with every `POST /api/analyze-image` call:

```
You are a careful, honest visual-analysis assistant embedded in an
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
- Output must be valid JSON and nothing else.
```

User turn: the image (base64, re-encoded JPEG, long edge capped at 1568px)
plus the text `"Analyze this image according to your instructions."`

### 2. Visual question answering

System prompt sent with every `POST /api/ask-question` call:

```
You are a careful, honest visual question-answering assistant. You will be
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
and use a low confidence band rather than guessing.
```

User turn: the image plus `"Question: <user's exact text>"`, e.g. `"Question:
How many people are in this image?"` or `"Question: What color is the
car?"`.

### 3. (Documented alternative) Object localization with bounding boxes

Not implemented in v1, but the designed extension point: a Google Cloud
Vision `OBJECT_LOCALIZATION` call would run alongside the Claude call in
`visionProvider.analyzeImage()`, merging `boundingPoly` coordinates into each
entry of the `objects` array returned to the client, so `ResultScreen` could
draw overlay boxes on the image. Left out of v1 to keep a single AI
credential/provider for the whole MVP.

## Honesty about confidence — how uncertainty is surfaced end-to-end

- The prompt requires an `uncertaintyNote` whenever the image is blurry,
  under/over-exposed, abstract, or otherwise hard to interpret.
- `ResultScreen` renders that note in a distinct red-tinted banner above the
  description card — it is never buried in the body text.
- The overall confidence badge is shown next to the description heading, and
  a per-object badge sits inline with every detected-object chip, so a user
  scanning the screen sees at a glance which claims are solid and which
  aren't.
- The backend's `DEMO MODE` fallback (see below) uses the same contract,
  including a medium/low band and an explicit `"Running in demo mode"`
  uncertainty note, so the UI's honesty behavior is exercised even without a
  paid API key.

## Demo mode (no API key configured)

`GET /api/health` reports `demoMode: true/false` and `provider: "gemini" |
"anthropic" | "demo"` based on which key (if any) is set. When neither key is
set, `analyzeImage()` and
`askQuestion()` in `visionProvider.js` return clearly-labeled canned
responses (`isDemoMode: true`) instead of calling Anthropic. This lets the
full pipeline — upload, compression, Postgres persistence, history,
delete, sharing — be developed, demoed, and CI-tested with zero AI spend,
and it was how this project's own end-to-end verification was performed
(see TESTING.md). The moment a real key is set, every downstream layer
(Flutter UI, database schema, sharing/export) works unchanged, because the
response contract is identical in both modes.

## Known limitations (documented, not hidden)

1. **No calibrated bounding boxes.** Object detection is a labeled list, not
   geometric regions — see the Cloud Vision alternative above.
2. **Self-reported confidence, not measured accuracy.** Treat the bands as
   the model's own hedge, not a validated error rate.
3. **VQA re-sends the image every time.** Because full images aren't
   retained server-side (privacy design choice), each question re-uploads
   the same compressed bytes; this is simple and privacy-preserving but
   costs a little more bandwidth than caching the image server-side would.
   Acceptable given typical photo sizes after compression (usually well
   under 500KB).
4. **Live model behavior wasn't evaluated in this delivery** — no
   `ANTHROPIC_API_KEY` was provided during development, so `TESTING.md`'s
   edge-case matrix documents *expected* behavior derived from the prompt
   contract and demo-mode pipeline verification, not observed model outputs
   on real blurry/dark/abstract photos. Re-run the matrix in `TESTING.md`
   once a key is configured and record actual outputs before relying on this
   for a graded demo.
5. **Anonymous auth, not real accounts.** Anyone with the app-level API key
   (bundled in the client, by design — see README) can call
   `POST /api/auth/anonymous` to mint a session. This is adequate for a
   student/portfolio-scale MVP behind rate limiting, but would need real
   accounts (or at least device attestation) before handling sensitive
   content at scale.
