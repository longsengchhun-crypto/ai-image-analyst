# AI Image Analyst

A mobile app that lets a user capture or upload a photo and get an AI-generated
description, a list of detected objects, OCR text extraction, and grounded
answers to free-form questions about the image — with honest confidence
messaging throughout, never a bare "I don't know."

| Layer | Tech | Status |
|---|---|---|
| Mobile app | Flutter (Dart) | Source complete — see [app/](app/) |
| Backend API | Node.js + Express | Complete, tested against live DB — see [backend/](backend/) |
| Database | Postgres on Neon | Migrated and live |
| Hosting | Vercel (serverless) | **Deployed**: `https://ai-image-analyst-backend.vercel.app` |
| AI provider | Anthropic Claude Vision | Pluggable; demo mode when no key is set |

## Live backend

```
Base URL: https://ai-image-analyst-backend.vercel.app
Health check: GET /api/health -> {"status":"ok","demoMode":true}
```

`demoMode: true` means no `ANTHROPIC_API_KEY` is configured yet, so
`/api/analyze-image` and `/api/ask-question` currently return clearly-labeled
placeholder responses instead of live AI output. **The rest of the pipeline
— auth, image upload, Postgres persistence, history, delete — is fully live
and was verified end-to-end against the production Neon database.** To turn
on real AI analysis:

```bash
vercel env add ANTHROPIC_API_KEY production   # paste your Anthropic key
cd backend && vercel deploy --prod --yes
```

## Repository layout

```
.
├── app/            # Flutter mobile app (Dart source; run `flutter create .` once — see app/README.md)
├── backend/        # Express REST API, deployed to Vercel, backed by Neon Postgres
├── ARCHITECTURE.md # System diagram and component responsibilities
├── AI_DOCUMENTATION.md  # Provider choice, prompts used, test results, limitations
├── TESTING.md       # Edge-case test matrix (blurry/dark/text-heavy/abstract images, etc.)
└── PROJECT_REPORT.md    # Full project write-up covering the assignment's 15 sections
```

## Quick start (local development)

**Backend:**
```bash
cd backend
npm install
cp .env.example .env     # fill in DATABASE_URL (Neon), JWT_SECRET, APP_API_KEY
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
the edge-case test matrix.
