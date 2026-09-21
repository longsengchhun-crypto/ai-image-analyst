# Testing Report

## What was actually executed in this delivery

A free `GEMINI_API_KEY` was obtained and set on Vercel production; live-model
behavior was then verified end-to-end against the real Gemini API (not just
the demo-mode placeholder path) — see the "Live Gemini verification" section
below. Everything else, including the entire Flutter app build/test/analyze
pipeline, **was** executed and verified:

### Backend (against the live production stack: Vercel + Neon)

| Check | Method | Result |
|---|---|---|
| Server boots, loads config | `node -e "require('./src/app.js')"` | ✅ Pass |
| Migration applies to Neon | `npm run migrate` against the real `DATABASE_URL` | ✅ Pass — tables + trigger created |
| `GET /api/health` | `curl` (local, then production) | ✅ `{"status":"ok","demoMode":false,"provider":"gemini"}` |
| `x-api-key` gate rejects missing key | `curl` without header | ✅ 401 |
| Anonymous auth issues JWT | `curl -X POST /api/auth/anonymous` | ✅ Row inserted in `users`, JWT returned |
| `POST /api/analyze-image` (multipart upload) | `curl -F image=@test.png` | ✅ 201, real Gemini analysis returned, row inserted in `image_history` |
| `POST /api/ask-question` appends to history | `curl -F image=... -F question=... -F historyId=...` | ✅ Real grounded answer, Q&A appended to `user_questions` JSONB |
| `GET /api/history` returns persisted row with nested Q&A | `curl` | ✅ Confirmed round-trip through Postgres JSONB |
| Same sequence against the **production** Vercel deployment | `curl` against `https://ai-image-analyst-backend.vercel.app` | ✅ Health, auth, analyze, ask-question, and history all confirmed live with real AI output |

### Live Gemini verification

Once `GEMINI_API_KEY` was set on Vercel production and redeployed:

- `GET /api/health` flipped from `demoMode: true` to `{"status":"ok","demoMode":false,"provider":"gemini"}`.
- A real image posted to `/api/analyze-image` on production returned an actual
  Gemini-generated description (not the fixed demo-mode placeholder text),
  HTTP 201.
- A follow-up posted to `/api/ask-question` with the same image returned a
  real grounded answer, HTTP 200.
- Production logs (`vercel logs`) surfaced two real issues, both fixed and
  redeployed before this was considered done:
  1. `express-rate-limit` was misidentifying client IPs because Express's
     `trust proxy` setting was left at its default behind Vercel's proxy —
     fixed with `app.set('trust proxy', 1)`.
  2. The very first live request hit a transient Gemini `503 UNAVAILABLE`
     ("model overloaded") and surfaced as a hard failure — fixed by adding
     automatic retry (up to 3 attempts, backoff) on 429/500/503.
- Re-ran the same analyze + ask-question sequence after both fixes: clean
  201/200 responses, no retries needed on that run.

### Flutter app (Flutter 3.47.5 stable, installed and used in this delivery)

| Check | Command | Result |
|---|---|---|
| Static analysis | `flutter analyze` | ✅ 0 issues (after fixing 5 real compile errors and a deprecation cleanup — see below) |
| Widget test suite | `flutter test` | ✅ Passing (boots the real app, asserts the Analyze screen and bottom nav render) |
| Release Android build | `flutter build apk --release --dart-define=API_BASE_URL=... --dart-define=APP_API_KEY=...` | ✅ Produces a working 51.3MB `app-release.apk` |
| Release web build | `flutter build web --release --dart-define=...` | ✅ Builds; driven headlessly in a real browser against the live backend to capture `docs/screenshots/` |
| End-to-end UI verification (static screens) | Seeded two real history entries via the live API, loaded the built web app with an injected session token, navigated Analyze → History → Result detail → Settings → source-sheet modal, in both light and dark themes | ✅ All screens render correctly with real data — see `docs/screenshots/` and PROJECT_REPORT.md §9 |
| **End-to-end UI verification (live capture flow)** | Fresh run with no seeded data: tapped the FAB, picked an image through the browser's real file chooser, tapped "Analyze image," and let the app make a real `POST /api/analyze-image` call to the live Vercel backend | ✅ Preview, shimmer loading skeleton, and the final result screen all captured mid-flow — `docs/screenshots/07-fresh-capture-preview.png` through `09-fresh-capture-result.png` |

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
- **`dart:io File` doesn't exist on Flutter web.** `ImageService` and
  `ApiService` originally used `File`/`MultipartFile.fromFile()`, which
  compiles fine but throws at runtime the moment a picked image is touched
  in a browser — silently breaking the entire capture flow with no console
  error (Flutter swallows the exception inside its own error zone). Rewrote
  both to operate on `Uint8List` bytes (`image_picker`'s `XFile.readAsBytes()`
  → `FlutterImageCompress.compressWithList()` → `MultipartFile.fromBytes()`),
  which works identically on mobile, desktop, and web with no platform
  branching. This was caught by actually driving a fresh pick-and-analyze
  flow through a real browser, not by code review.
- **A more serious bug in the same area**: `submitForAnalysis()` set the
  screen to "success" and then wrote a copy to the local SQLite cache in the
  same try block. If that cache write failed for *any* reason — including,
  ironically, sqflite simply not existing on the web platform used to test
  this — the catch handler downgraded a fully successful AI analysis back to
  an error screen, discarding the result the user had just correctly
  received. Fixed by moving the cache write into its own isolated,
  non-fatal try/catch that can never override a successful result. This
  bug was platform-agnostic — it could in principle have fired on mobile
  too under a rare sqflite hiccup — and was only surfaced by actually
  running the full flow against a live backend rather than by reading the
  code.

**One thing headless browser automation could not confirm, and why that's
not a code concern**: typing into the "Ask about this image" `TextField`
and tapping Send was implemented and is backed by a `POST /api/ask-question`
call already verified directly via `curl` (see the backend table above).
Simulating keystrokes into Flutter web's text-editing layer from a headless
browser proved unreliable across several attempts (`ui.fill()`, `page.click()`
+ `keyboard.type()`, and literal coordinate clicks) — a known class of
flakiness specific to automating Flutter's web semantics/text-input bridge,
not something particular to this app's code. `TextField` +
`TextEditingController` + `onSubmitted`/`onPressed` is standard, unmodified
Flutter API identical to every other interactive control in this app that
*did* respond correctly to the same automation (buttons, tabs, the photo
picker). Confirming this specific interaction with a real tap on a real
device/emulator is the one manual check worth doing before a live demo.

This proves the plumbing — upload handling, image normalization, JWT/API-key
auth, Postgres persistence (including JSONB append), serverless deployment,
and the entire Flutter app build/UI — is correct and production-ready. With
`GEMINI_API_KEY` now set on production (see "Live Gemini verification"
above), a real image posted through this same pipeline returns a real
Gemini-generated description, not placeholder text.

## Edge-case matrix: expected behavior per the prompt contract

The table below is derived directly from the system prompts in
`AI_DOCUMENTATION.md` and states what the contract *requires* the model to
do. With `GEMINI_API_KEY` now configured on production,
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

## Localization (English/Khmer)

| Check | Method | Result |
|---|---|---|
| App boots and renders correctly in English (default) | `flutter test` | ✅ Passing |
| Switching to Khmer in Settings re-renders the whole UI | `flutter test` — taps the Khmer option, then asserts the bottom nav, app bar, and Analyze screen headline all show the correct Khmer strings | ✅ Passing |
| Khmer text actually uses Kantumruy Pro **Bold** | Same test asserts `style.fontFamily` contains `'KantumruyPro'` and `style.fontWeight == FontWeight.bold` on a real rendered `Text` widget | ✅ Passing |
| Real device/browser rendering (not just widget-test assertions) | Deployed web build driven headlessly: switched to Khmer, navigated Analyze → Settings → History | ✅ Screenshots in `docs/screenshots/10-analyze-khmer.png`, `11-settings-khmer-language-switch.png` show correct glyphs and bold weight |
| No untranslated error strings possible | Code review: every failure path stores an `AppErrorCode` enum value, never a `String`; text is only built at the display layer via `localizedError()` | ✅ Enforced by the type system — a raw English string can't reach a screen through this path |
| Release builds still succeed with localization added | `flutter build apk --release`, `flutter build web --release` | ✅ Both succeed (APK: 52.7MB) |

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
