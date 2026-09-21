# AI Image Analyst

A mobile app that lets a user capture or upload a photo and get an AI-generated
description, a list of detected objects, OCR text extraction, and grounded
answers to free-form questions about the image — with honest confidence
messaging throughout, never a bare "I don't know."

| Layer | Tech | Status |
|---|---|---|
| Mobile app | Flutter (Dart) | **Verified**: `flutter analyze` clean, tests pass, release APK builds — see [app/](app/) |
| Backend API | Node.js + Express | Complete, tested against live DB — see [backend/](backend/) |
| Database | Postgres on Neon | Migrated and live |
| Hosting | Vercel (serverless) | **Deployed**: `https://ai-image-analyst-backend.vercel.app` |
| AI provider | Google Gemini (free) or Anthropic Claude Vision | Pluggable; demo mode when no key is set |

## Live backend

```
Base URL: https://ai-image-analyst-backend.vercel.app
Health check: GET /api/health -> {"status":"ok","demoMode":true,"provider":"demo"}
```

`demoMode: true` means no AI key is configured yet, so `/api/analyze-image`
and `/api/ask-question` currently return clearly-labeled placeholder
responses instead of live AI output. **The rest of the pipeline — auth,
image upload, Postgres persistence, history, delete — is fully live and was
verified end-to-end against the production Neon database**, including a
seeded history entry with a follow-up question, visible in the running app
(see screenshots below).

### Turning on real AI analysis — free option (recommended)

1. Go to [aistudio.google.com/apikey](https://aistudio.google.com/apikey),
   sign in with any Google account, click "Create API key." No credit card,
   no payment required for the free tier.
2. ```bash
   vercel env add GEMINI_API_KEY production   # paste the key
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
  driven headlessly) against the live backend — not mockups — covering the
  Analyze screen, a populated History list (seeded via the live API), the
  full analysis detail/Q&A screen, the Settings screen, and the photo-source
  bottom sheet. See `docs/screenshots/` for the images and
  `PROJECT_REPORT.md` §9 for what each one shows and the one interaction
  path (fresh camera/gallery capture inside a browser) that a device or
  emulator is needed to demo, and why.
- **A real overflow bug** on short viewports was caught by the automated
  test and fixed (the Analyze screen's guidance content is now scrollable
  instead of a fixed `Column`) — see `app/lib/screens/image_upload_screen.dart`.

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
flutter create .          # one-time: generates android/ios/web platform folders
flutter pub get
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
