# AI Image Analyst

**Try it now, no install: https://ai-image-analyst-web.vercel.app** — this is
the actual app running in your browser (Flutter compiled to web), talking to
the live backend below. Pick a photo and click Analyze; everything through
description + detected objects works for real. (Camera capture needs a
device with a camera — use "Choose from gallery" in a desktop browser.)

A mobile app that lets a user capture or upload a photo and get an AI-generated
description, a list of detected objects, OCR text extraction, and grounded
answers to free-form questions about the image — with honest confidence
messaging throughout, never a bare "I don't know."

## Preview on your phone

This app is built with **Flutter**, not React Native/Expo — **Expo Go
cannot open it**, at any SDK version, the same way an iOS app can't run
inside an Android launcher. It's a different runtime entirely (Expo Go
loads a JavaScript bundle; Flutter compiles to its own Skia/Impeller
engine). Two options that actually work from a phone:

1. **Open in your phone's browser, no install**:
   https://ai-image-analyst-web.vercel.app — full app UI, works
   immediately. Camera capture needs a device with a camera; gallery
   picking works everywhere.
2. **Install the real native app on Android** (full camera/gallery access,
   faster, works offline for cached history): download the release APK from
   [the latest GitHub release](https://github.com/longsengchhun-crypto/ai-image-analyst/releases/latest)
   onto an Android phone and install it (Android will prompt to allow
   "install unknown apps" for your browser — that's expected for a
   non-Play-Store APK).

**iOS**: the Xcode project is committed at `app/ios/` (generated and ready
to open), but it has not been built here — compiling and running an iOS app
requires Xcode on a Mac, which this environment doesn't have, and there is
no side-load path around that (Apple doesn't allow installing an unsigned
build on a physical iPhone without either Xcode or a paid Developer account,
unlike Android's "install unknown apps"). On a Mac: `cd app && open
ios/Runner.xcworkspace`, pick a Simulator or your plugged-in iPhone, and hit
Run — no other setup needed. Until then, option 1 above (the browser link)
works identically on an iPhone's Safari.

| Layer | Tech | Status |
|---|---|---|
| Mobile app | Flutter (Dart) | **Verified**: `flutter analyze` clean, tests pass, release APK builds — see [app/](app/) |
| Web build (same app) | Flutter → web | **Live**: https://ai-image-analyst-web.vercel.app |
| iOS | Flutter (Xcode project) | Scaffolded (`app/ios/`), not built — needs a Mac; see "Preview on your phone" |
| Languages | English + Khmer | Full UI translation, switchable in Settings; Khmer renders in **Kantumruy Pro Bold** |
| Backend API | Node.js + Express | Complete, tested against live DB — see [backend/](backend/) |
| Database | Postgres on Neon | Migrated and live |
| Hosting | Vercel (serverless) | **Deployed**: `https://ai-image-analyst-backend.vercel.app` |
| AI provider | Google Gemini (`gemini-flash-lite-latest`, with model fallback) | **Live** — real AI analysis, not demo mode |

## Live backend

```
Base URL: https://ai-image-analyst-backend.vercel.app
Health check: GET /api/health -> {"status":"ok","demoMode":false,"provider":"gemini"}
```

`demoMode: false` means a real Gemini API key is configured in production, so
`/api/analyze-image` and `/api/ask-question` return real AI-generated output —
verified with live end-to-end calls against the production URL (a real
description, detected objects, and a grounded follow-up answer, not
placeholders). **The rest of the pipeline — auth, image upload, Postgres
persistence, history, delete — is fully live too**, verified end-to-end
against the production Neon database, including a seeded history entry with a
follow-up question, visible in the running app (see screenshots below).

Two real issues surfaced only once live traffic hit the real Gemini API, both
fixed and verified: a transient "model overloaded" 503, and — more
significantly — this key's free tier caps `gemini-flash-latest` at only 20
requests/day, which normal testing exhausted outright and surfaced as hard
500s. The backend now (a) retries automatically on 429/500/503, and (b) if a
model still fails, falls back to a different Gemini model with its own
separate quota/capacity pool (`gemini-flash-lite-latest`, chosen as the
primary model precisely because its free-tier quota is much larger) before
giving up. See TESTING.md for the full incident writeup.

If you ever need to swap providers or rotate the key:
```bash
vercel env add GEMINI_API_KEY production   # paste the new key
cd backend && vercel deploy --prod --yes
```
Anthropic Claude Vision works identically if you set `ANTHROPIC_API_KEY`
instead (Gemini is checked first if both are set).

## Verified end-to-end

This was not left as an on-paper design — everything below was actually run:

- **Backend**: migrated against the live Neon database, then exercised
  through every endpoint (`auth/anonymous`, `analyze-image`, `ask-question`,
  `history` list/get/delete) both locally and against the production Vercel
  URL. See TESTING.md for the full command-by-command log.
- **Flutter app**: `flutter analyze` reports zero issues; the widget test
  suite passes; `flutter build apk --release` produces a working release
  APK; `flutter build web --release` produces a working web build.
- **Real screenshots**, captured from the actual running app (web build,
  driven headlessly) — not mockups — including a genuine, un-seeded
  pick-a-photo → analyze → view-result run against the live backend, with no
  data pre-loaded. See `docs/screenshots/` (`07`–`09` are the fresh-capture
  run) and `PROJECT_REPORT.md` §9.
- **Seven real bugs found and fixed** by actually running the app end to
  end, not just reading the code:
  1. A `RenderFlex overflowed by 7.0 pixels` layout bug on short viewports —
     the Analyze screen's guidance content wasn't scrollable.
  2. `ImageService`/`ApiService` used `dart:io File`, which doesn't exist on
     Flutter web — the entire capture flow silently broke the moment an
     image was picked. Rewritten to work on raw bytes everywhere (mobile,
     desktop, and web) instead.
  3. A more serious one: a failed local-cache write could silently downgrade
     a **successful** AI analysis into an error screen, discarding a correct
     result the user had already received. This could in principle have hit
     mobile too, not just web — see TESTING.md for the full explanation and fix.
  4. Found only after switching on the real Gemini key and inspecting Vercel's
     production logs: Express's `trust proxy` setting was left at its default
     (`false`) behind Vercel's proxy, which made `express-rate-limit`
     misidentify every request's source IP. Fixed with `app.set('trust proxy', 1)`.
  5. A transient Gemini `503 UNAVAILABLE` ("model overloaded") surfaced as a
     hard failure to the user on the very first live production request.
     Fixed by retrying automatically up to 3 times with backoff on
     429/500/503 before giving up.
  6. Found by actually driving the deployed web app through a real
     pick-photo → analyze → open-History run (not just curl): the History
     tab went stale after a fresh analysis and only updated on a manual
     pull-to-refresh, because its provider only loads once (the tab's state
     survives switching tabs). Fixed by giving the analysis flow a live
     reference to History and updating it the instant an analysis completes,
     plus batching the local SQLite sync into one transaction instead of one
     round trip per row so the screen never blocks on it.
  7. That same real end-to-end run also exhausted this Gemini key's
     20-requests/day free-tier quota on `gemini-flash-latest`, turning into
     hard 500s mid-testing — see the AI provider note above for the fix
     (switched primary model, added cross-model fallback).
- **Full English/Khmer localization**, verified with a real widget test that
  switches the app to Khmer and asserts the UI actually re-renders in Khmer
  (not just that the translation files parse) — see
  `docs/screenshots/10-analyze-khmer.png` and `11-settings-khmer-language-switch.png`
  for real screenshots of the deployed web app running in Khmer, captured
  the same way as the English ones.

## Repository layout

```
.
├── app/            # Flutter mobile app (Dart source; run `flutter create .` once — see app/README.md)
├── backend/        # Express REST API, deployed to Vercel, backed by Neon Postgres
├── docs/screenshots/  # Real screenshots captured from the running app
├── ARCHITECTURE.md # System diagram and component responsibilities
├── AI_DOCUMENTATION.md  # Provider choice, prompts used, test results, limitations
├── TESTING.md       # What was verified, command-by-command, plus the edge-case matrix
└── PROJECT_REPORT.md    # Full project write-up covering the assignment's 15 sections
```

## Quick start (local development)

**Backend:**
```bash
cd backend
npm install
cp .env.example .env     # fill in DATABASE_URL (Neon), JWT_SECRET, APP_API_KEY, and GEMINI_API_KEY (free) or ANTHROPIC_API_KEY
npm run migrate          # applies migrations/schema.sql to your Neon database
npm run dev               # http://localhost:8080
```

**Flutter app:**
```bash
cd app
flutter pub get   # android/, web/, and a scaffolded ios/ are already committed
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080 --dart-define=APP_API_KEY=<your APP_API_KEY>
```

## Security & privacy posture

- No AI provider API key ever ships inside the Flutter app or is reachable
  from the client — it lives only in the backend's environment variables.
- The Neon connection string lives only in `backend/.env` (gitignored) and as
  an encrypted Vercel environment variable — never in source control.
- The app only stores a small thumbnail + AI text output per analysis, not
  the original full-resolution photo, once analysis completes.
- Users are shown a consent notice before the first upload (see the
  Analyze screen) and can clear all history from Settings, which deletes
  both the on-device cache and the server-side rows.

See [AI_DOCUMENTATION.md](AI_DOCUMENTATION.md) for the AI provider rationale,
exact prompts, and documented failure modes, and [TESTING.md](TESTING.md) for
everything that was actually verified plus the edge-case test matrix.
