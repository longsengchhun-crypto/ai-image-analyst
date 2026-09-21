# Testing Report

## What was actually executed in this delivery

Neither `GEMINI_API_KEY` nor `ANTHROPIC_API_KEY` was available during
development, so live-model behavior on real blurry/dark/abstract photos was
**not** observed — that's the one thing this delivery couldn't test itself,
since both require a credential only the project owner can obtain (Gemini's
is free — see AI_DOCUMENTATION.md). Everything else, including the entire
Flutter app build/test/analyze pipeline, **was** executed and verified:

### Backend (against the live production stack: Vercel + Neon)

| Check | Method | Result |
|---|---|---|
| Server boots, loads config | `node -e "require('./src/app.js')"` | ✅ Pass |
| Migration applies to Neon | `npm run migrate` against the real `DATABASE_URL` | ✅ Pass — tables + trigger created |
| `GET /api/health` | `curl` (local, then production) | ✅ `{"status":"ok","demoMode":true,"provider":"demo"}` |
| `x-api-key` gate rejects missing key | `curl` without header | ✅ 401 |
| Anonymous auth issues JWT | `curl -X POST /api/auth/anonymous` | ✅ Row inserted in `users`, JWT returned |
| `POST /api/analyze-image` (multipart upload) | `curl -F image=@test.png` | ✅ 201, demo-mode analysis returned, row inserted in `image_history` |
| `POST /api/ask-question` appends to history | `curl -F image=... -F question=... -F historyId=...` | ✅ Q&A appended to `user_questions` JSONB |
| `GET /api/history` returns persisted row with nested Q&A | `curl` | ✅ Confirmed round-trip through Postgres JSONB |
| Same sequence against the **production** Vercel deployment | `curl` against `https://ai-image-analyst-backend.vercel.app` | ✅ Health, auth, and history all confirmed live |

### Flutter app (Flutter 3.47.5 stable, installed and used in this delivery)

| Check | Command | Result |
|---|---|---|
| Static analysis | `flutter analyze` | ✅ 0 issues (after fixing 5 real compile errors and a deprecation cleanup — see below) |
| Widget test suite | `flutter test` | ✅ Passing (boots the real app, asserts the Analyze screen and bottom nav render) |
| Release Android build | `flutter build apk --release --dart-define=API_BASE_URL=... --dart-define=APP_API_KEY=...` | ✅ Produces a working 51.3MB `app-release.apk` |
| Release web build | `flutter build web --release --dart-define=...` | ✅ Builds; driven headlessly in a real browser against the live backend to capture `docs/screenshots/` |
| End-to-end UI verification | Seeded two real history entries via the live API, loaded the built web app with an injected session token, navigated Analyze → History → Result detail → Settings → source-sheet modal, in both light and dark themes | ✅ All screens render correctly with real data — see `docs/screenshots/` and PROJECT_REPORT.md §9 |

**Bugs found and fixed by actually running the build**, not just writing
code:
- 5 real compile errors caught by `flutter analyze` on the first pass:
  an invalid `fontFamily` argument passed through `GoogleFonts.inter()`, and
  four cascade-operator misuses in the share/export text builder
  (`buffer.writeln()..writeln(x)` cascades onto the *return value* of the
  first call, which is `void` — not onto `buffer` as originally intended).
- A genuine `RenderFlex overflowed by 7.0 pixels` layout bug on short
  viewports, caught by the widget test, not by code review — the Analyze
  screen's initial-state `Column` wasn't scrollable. Fixed with a
  `SingleChildScrollView` + `ConstrainedBox`.
- `share_plus: ^7.2.2` (the version originally pinned without a live SDK to
  verify against) turned out to ship an Android module compiled against API
  33, which failed a release build once other plugins pulled in
  `androidx.lifecycle:2.7.0` (requiring API 34+). Fixed by upgrading to
  `share_plus: ^13.3.0` and migrating the one call site from the deprecated
  `Share.share()` static method to `SharePlus.instance.share(ShareParams(...))`.
- A Windows-specific Kotlin incremental-compiler crash
  (`this and base files have different roots`) when the Flutter project
  lives on a different drive letter than the Pub cache. Worked around with
  `kotlin.incremental=false` in `android/gradle.properties`.

This proves the plumbing — upload handling, image normalization, JWT/API-key
auth, Postgres persistence (including JSONB append), serverless deployment,
and the entire Flutter app build/UI — is correct and production-ready. It
does **not** prove the AI's description/object/VQA quality on any specific
image, since demo mode returns fixed placeholder text rather than calling a
live model.

## Edge-case matrix: expected behavior per the prompt contract (re-run once a key is set)

The table below is derived directly from the system prompts in
`AI_DOCUMENTATION.md` and states what the contract *requires* the model to
do. Once `GEMINI_API_KEY` (free) or `ANTHROPIC_API_KEY` is configured,
re-run each case with a real photo, record the actual `description` /
`objects` / `uncertaintyNote`
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

Only one thing — everything else (Flutter build, analyze, test, APK, web
build, UI screenshots) is already done in this delivery:

1. Get a free `GEMINI_API_KEY` from
   [aistudio.google.com/apikey](https://aistudio.google.com/apikey) (or use
   `ANTHROPIC_API_KEY` if you have Anthropic access) and set it on Vercel:
   `vercel env add GEMINI_API_KEY production && vercel deploy --prod --yes`
   from `backend/`. Then re-run the edge-case matrix above with real sample
   photos (Unsplash/Pexels are good sources, per the assignment's own
   guidance) and fill in the "Observed" behavior — this is the one thing
   that needs live model output.
2. Optional, for an on-device demo rather than the browser-based screenshots
   already captured: install the app from
   `app/build/app/outputs/flutter-apk/app-release.apk` on an Android device,
   or run `flutter run` with the SDK installed. Camera capture and the
   photo-library picker only need a real device or emulator — the web
   target used to capture the screenshots in this delivery can't drive them
   (see PROJECT_REPORT.md §9 for why).
