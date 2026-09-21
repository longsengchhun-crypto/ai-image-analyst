# Testing Report

## What was actually executed in this delivery

No `ANTHROPIC_API_KEY` was available during development, so live-model
behavior on real blurry/dark/abstract photos was **not** observed. What
*was* executed and verified, against the live production stack (Vercel +
Neon), is the full request/response pipeline in demo mode:

| Check | Method | Result |
|---|---|---|
| Server boots, loads config | `node -e "require('./src/app.js')"` | ✅ Pass |
| Migration applies to Neon | `npm run migrate` against the real `DATABASE_URL` | ✅ Pass — tables + trigger created |
| `GET /api/health` | `curl` (local, then production) | ✅ `{"status":"ok","demoMode":true}` |
| `x-api-key` gate rejects missing key | `curl` without header | ✅ 401 |
| Anonymous auth issues JWT | `curl -X POST /api/auth/anonymous` | ✅ Row inserted in `users`, JWT returned |
| `POST /api/analyze-image` (multipart upload) | `curl -F image=@test.png` | ✅ 201, demo-mode analysis returned, row inserted in `image_history` |
| `POST /api/ask-question` appends to history | `curl -F image=... -F question=... -F historyId=...` | ✅ Q&A appended to `user_questions` JSONB |
| `GET /api/history` returns persisted row with nested Q&A | `curl` | ✅ Confirmed round-trip through Postgres JSONB |
| Same sequence against the **production** Vercel deployment | `curl` against `https://ai-image-analyst-backend.vercel.app` | ✅ Health, auth, and history all confirmed live |

This proves the plumbing — upload handling, image normalization, JWT/API-key
auth, Postgres persistence (including JSONB append), and serverless
deployment — is correct and production-ready. It does **not** prove the AI's
description/object/VQA quality on any specific image, since demo mode
returns fixed placeholder text rather than calling Claude.

## Edge-case matrix: expected behavior per the prompt contract (re-run once a key is set)

The table below is derived directly from the system prompts in
`AI_DOCUMENTATION.md` and states what the contract *requires* the model to
do. Once `ANTHROPIC_API_KEY` is configured, re-run each case with a real
photo, record the actual `description` / `objects` / `uncertaintyNote`
output, and replace the "Expected" column with "Observed."

| Case | Input | Contract requires | How the UI should show it |
|---|---|---|---|
| Clear, high-resolution photo | Sharp daylight photo of a common scene | Accurate 2–3 sentence description; 5–15 objects; `overallConfidenceBand: high`; `uncertaintyNote: null` | Green confidence badge, no warning banner |
| Blurry image | Motion-blurred or out-of-focus photo | Description still attempted, but `uncertaintyNote` explains blur; confidence dropped to medium/low | Red-tinted uncertainty banner above the description card |
| Very dark / underexposed | Near-black photo | Model states it can barely make out content; low confidence; may still list faint recognizable shapes | Uncertainty banner + low (red) badges throughout |
| Very bright / overexposed | Blown-out/washed-out photo | Same pattern as dark: honest low-confidence description rather than a fabricated confident one | Same |
| Complex scene, many objects | Busy street or cluttered room | Objects list capped at 15, ordered most-prominent-first; description summarizes rather than lists everything | Object chips wrap across multiple rows; scroll to see all |
| Text-heavy image / screenshot | Photo of a document, sign, or a UI screenshot | `detectedText` contains a verbatim transcription; description references that it's mostly text | "Text found in image (OCR)" card appears with monospace, selectable text |
| Abstract / artistic image | Abstract painting or pattern | Model avoids over-confident literal claims; `uncertaintyNote` flags the interpretive nature; medium/low confidence | Same uncertainty banner pattern |
| Image with people | Photo containing one or more people | Factual count/activity description; **no** facial identification, no precise age guesses, no biometric claims (enforced by prompt rule) | Description reads naturally; no "person #1 looks like..." style output |
| Multiple languages / scripts in image | Sign with mixed-language text | `detectedText` transcribes what's legible; may note uncertainty for scripts it reads less reliably | OCR card shows whatever was transcribed; low confidence if partial |
| Ambiguous VQA question ("what's outside the frame?") | Any image + an out-of-scope question | `uncertaintyNote` explains the question can't be answered from the image; low confidence rather than a guess | Uncertainty note shown under that specific Q&A entry |

## Network / failure-mode testing (verified against the running backend)

| Scenario | Expected client behavior | Verified |
|---|---|---|
| No `x-api-key` header | 401, generic "Missing or invalid API key" — no internal detail leaked | ✅ (see table above) |
| Expired/invalid JWT | 401 "Invalid or expired session token"; `ApiService` maps this to "Your session expired. Please try again." | ✅ code path exists in `middleware/auth.js` + `api_service.dart` |
| Oversized image (>8MB) | 413, mapped client-side to "That image is too large. Please use an image under 8MB." | ✅ `multer` limit + `errorHandler.js` + `api_service.dart` mapping |
| Unsupported file type | 400 "Unsupported image format..." from `multer.fileFilter` | ✅ code path in `routes/analyze.js` |
| Rate limit exceeded (12 AI calls/min/IP) | 429, mapped to "Too many requests right now..." | ✅ `express-rate-limit` configured in `middleware/rateLimit.js` |
| Backend/provider throws an unexpected error | 500 with a generic message only — no stack trace or provider error text returned | ✅ `errorHandler.js` always returns a fixed safe string for 5xx |
| No network on device | Dio `connectionError`/timeout mapped to "Couldn't reach the server..." | ✅ code path in `api_service.dart` |
| Offline History view | SQLite cache renders immediately; refresh failure keeps showing cached items with an error message rather than blanking the screen | ✅ `HistoryProvider.refresh()` preserves `items` on failure when non-empty |

## What's left to do before a graded live demo

1. Set `ANTHROPIC_API_KEY` on Vercel and redeploy (`vercel env add
   ANTHROPIC_API_KEY production && vercel deploy --prod --yes`).
2. Re-run the edge-case matrix above with real sample photos (Unsplash/Pexels
   are good sources, per the assignment's own guidance) and fill in the
   "Observed" behavior.
3. Install Flutter locally, run `flutter create .` inside `app/`, then
   `flutter pub get` and `flutter run` to capture the 8–10 required
   screenshots and confirm end-to-end on a real device/emulator.
