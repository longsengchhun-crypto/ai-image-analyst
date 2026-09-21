# Project Report — AI Image Understanding App

**Project 11 · AI Image Analyst**

---

## 1. Executive summary

AI Image Analyst is a mobile application that lets a user capture or upload a
photo and receive, within seconds: a natural-language description, a list of
detected objects with honest confidence indicators, any text found in the
image (OCR), and grounded answers to follow-up questions about the photo.
The system is built as three independently deployable pieces — a Flutter
client, a Node.js/Express REST API, and a managed Postgres database (Neon)
— with all AI provider credentials isolated to the backend. The backend is
deployed and live on Vercel, migrated against the production Neon database,
and verified end-to-end (auth, upload, persistence, retrieval, deletion).
The Flutter client's full source is complete and documented; final on-device
verification and screenshots require running `flutter create .` once on a
machine with the Flutter SDK installed (not available in this build
environment — see §12).

## 2. Purpose and target users

Students, educators, professionals, and content creators frequently need to
quickly understand the content of an image — for accessibility (describing a
photo for someone who can't see it), for cataloguing (what objects/text are
in this photo?), or for quick fact-finding about a specific photo (how many
people, what color, what does the sign say). AI Image Analyst serves all
three needs through one flow: capture → analyze → ask.

## 3. Core workflow

```
Image Input (Camera/Gallery)
   → client-side compression
   → Image Upload (multipart, authenticated)
   → Vision AI Processing (description + objects + OCR + confidence)
   → Display Results with Confidence Indicators
   → optional: Ask a Question (VQA), repeatable
   → User History (local + server) & Share/Export
```

## 4. Functional requirements — how each was met

### 4.1 Image input & capture
- Camera and gallery access via `image_picker` (`ImageService` in
  `app/lib/services/image_service.dart`).
- Client-side compression/downscaling via `flutter_image_compress` before
  any upload, capping the long edge and re-encoding as JPEG regardless of
  source format (JPEG/PNG/WebP/HEIC), which also normalizes format support.
- Preview before submission, with Retake/Analyze actions
  (`_PreviewState` in `image_upload_screen.dart`).
- Server-side re-validation: MIME allowlist (JPEG/PNG/WebP), 8MB cap,
  EXIF-safe rotate + re-encode + resize via `sharp`
  (`backend/src/services/imageProcessing.js`).
- Web drag-and-drop was scoped out: the assignment marks it optional
  ("if web-enabled") and this delivery targets mobile first: `image_picker`
  does support Flutter web file selection, but drag-and-drop specifically
  was not implemented.

### 4.2 AI vision processing
- **Description**: 2–3 sentence natural-language description generated per
  image (see AI_DOCUMENTATION.md for the exact prompt).
- **Object detection**: a labeled list (up to 15 entries) with a qualitative
  confidence band per object — chosen over raw bounding-box detection for
  reasons documented in AI_DOCUMENTATION.md §"Why this shape."
- **VQA**: free-form question input, answered by a second, narrower prompt
  contract that explicitly refuses to guess when the answer isn't visually
  grounded.
- **Confidence/uncertainty messaging**: every description, object, and
  answer carries a high/medium/low band rendered as a color-coded badge;
  a dedicated uncertainty banner appears whenever the model flags blur,
  poor exposure, ambiguity, or an out-of-scope question.
- **Edge cases**: documented expected behavior and a re-test checklist in
  TESTING.md for blurry, dark/bright, abstract, and text-heavy images
  (live-model verification pending an API key — see §12).

### 4.3 UI & UX
- Bottom navigation across three sections: Analyze (default/home), History,
  Settings — matching the requested IA.
- Deep-blue + warm-coral palette (`app/lib/utils/constants.dart`), Inter
  typeface via `google_fonts`, 8/16/24px spacing grid, 14–16px corner radii,
  light and dark themes both implemented (`app/lib/theme.dart`,
  `themeMode: ThemeMode.system` in `main.dart`).
- States implemented per screen: initial/empty (`_InitialState`), loading
  with a shimmer skeleton that mirrors the eventual card layout rather than
  a bare spinner (`AnalysisSkeleton`), success (`ResultScreen`), error with
  retry (`_ErrorState`), and an explicit "no objects confidently identified"
  message inside the success state rather than a silent empty list.
  History has its own loading/empty/error states.
- Results are expandable/collapsible cards (`_sectionCard` in
  `result_screen.dart`) with 200–220ms `AnimatedSize`/`AnimatedRotation`
  transitions.
- Pinch-to-zoom on the freshly-analyzed image via `photo_view`; share via
  `share_plus` (exports description + objects + OCR text + full Q&A history
  as shareable plain text).
- FAB for starting a new analysis; bottom-sheet source picker
  (camera/gallery); pull-to-refresh on History via `RefreshIndicator`;
  swipe-to-delete on history rows via `Dismissible`.

### 4.4 Data management & history
- Server of record: Neon Postgres, `image_history` table (see §6 and
  `backend/migrations/schema.sql`) — thumbnail, description, detected
  objects (JSONB), OCR text, Q&A history (JSONB), confidence score/band,
  timestamps.
- On-device mirror: SQLite via `sqflite`
  (`app/lib/services/database_service.dart`), giving instant History loads
  and read-only offline browsing of previously-synced items.
- Delete one item or clear all, from either the History screen or Settings;
  both act on-device and server-side.
- Share/export implemented as plain-text share sheet; PDF export was
  scoped as a bonus and not implemented in this delivery (see §13).

### 4.5 Backend API
All four required endpoints, plus an anonymous-auth endpoint, implemented in
Express (`backend/src/routes/`):

| Endpoint | Purpose |
|---|---|
| `POST /api/auth/anonymous` | Issue a session JWT for a new anonymous user |
| `POST /api/analyze-image` | Multipart image upload → AI analysis → persisted result |
| `POST /api/ask-question` | Image + question → grounded answer, appended to history |
| `GET /api/history` | Paginated list of the caller's past analyses |
| `GET /api/history/:id` | Single record detail |
| `DELETE /api/history/:id` | Delete one record |
| `DELETE /api/history` | Clear all of the caller's history |

Auth: shared `x-api-key` header (app-level anti-abuse gate) plus a
per-session JWT (user-scoping), per §4.5's "simple JWT or API key" wording —
implemented as both, layered, rather than choosing one (see
ARCHITECTURE.md). Rate limiting via `express-rate-limit`: 300 req/15min
generally, 12 req/min specifically on the two AI-calling endpoints. Errors
are normalized to safe, generic messages server-side
(`middleware/errorHandler.js`) — no stack traces, SQL, or provider error
bodies ever reach the client.

### 4.6 AI service integration
Covered fully in AI_DOCUMENTATION.md: provider choice and rationale, the
three prompts, demo-mode behavior, and documented limitations.

### 4.7 Testing & QA
Covered fully in TESTING.md: what was actually executed against the live
Vercel + Neon deployment, the edge-case expectation matrix derived from the
prompt contract, and the remaining steps for a live-model demo.

### 4.8 Security & privacy
- All AI provider keys live only in backend environment variables /
  encrypted Vercel project settings — never in the app bundle or git
  history.
- `backend/.env` (holding the real Neon connection string locally) is
  gitignored; only `.env.example` (no secrets) is committed.
- Consent notice shown on the initial Analyze screen before first upload;
  Settings screen explains what is/isn't stored and that a third-party AI
  service processes images.
- People in photos are handled via an explicit prompt rule: factual
  description only, no facial identification or biometric inference.
- Users can delete individual history items or clear everything, which
  removes the corresponding Postgres rows (not just a client-side hide).
- Generic error messages throughout; no backend/provider internals ever
  surfaced to the user (see `errorHandler.js` and `ApiService._friendlyMessage`).

## 5. Technical architecture

See ARCHITECTURE.md for the full diagram and request-flow walkthrough. In
short: Flutter app → (HTTPS, multipart/JSON) → Express API on Vercel →
(Postgres wire protocol) → Neon, and → (HTTPS) → Anthropic Claude Vision.

## 6. Database schema

Implemented in Postgres (adapted from the SQLite shape given in the
assignment — see `backend/migrations/schema.sql` for the authoritative,
commented version and rationale):

```sql
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  last_seen_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE image_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  image_thumbnail TEXT,
  description TEXT NOT NULL,
  detected_objects JSONB NOT NULL DEFAULT '[]',
  detected_text TEXT,
  user_questions JSONB NOT NULL DEFAULT '[]',
  confidence_score REAL,
  confidence_band TEXT,
  is_demo_mode BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
```

This schema has been applied to the live Neon database referenced in
`backend/.env` (kept out of git) and verified by inserting, querying,
updating (JSONB append), and deleting rows over HTTP against both the local
dev server and the production Vercel deployment.

## 7. AI documentation summary

See AI_DOCUMENTATION.md in full. Key points: Anthropic Claude Vision chosen
for a single coherent provider; three documented prompts (analysis, VQA, and
a documented-but-unimplemented bounding-box extension); confidence bands are
explicitly labeled as self-assessed heuristics, not calibrated statistics;
demo mode lets the entire pipeline run and be graded without incurring AI
costs or requiring a key to be provided with this submission.

## 8. Testing report summary

See TESTING.md in full. All backend plumbing (auth, upload, persistence,
retrieval, deletion, rate limiting, error mapping) was executed against the
live production stack. Live AI-model behavior on specific edge-case photos
(blurry, dark, abstract, text-heavy, etc.) is documented as an *expected*
matrix derived from the prompt contract, pending a real API key being
configured for final grading/demo.

## 9. UI/UX documentation

Covered in §4.3 and in `app/README.md`. Screens: Analyze/Home, Result,
History, Settings. Widgets: `ImageCard`, `ObjectTag`, `ConfidenceBadge`,
`AnalysisSkeleton`/`InlineLoadingLabel`. Full Dart source is complete;
capturing the requested 8–10 screenshots requires a Flutter SDK install
(not present in this build environment) — see §12 for the exact commands to
produce them.

## 10. Deployment

- **Backend**: deployed to Vercel as a serverless function
  (`backend/api/index.js` wraps the Express app; `backend/vercel.json`
  routes all paths to it). Production URL:
  `https://ai-image-analyst-backend.vercel.app`. Environment variables
  (`DATABASE_URL`, `JWT_SECRET`, `APP_API_KEY`, `ANTHROPIC_MODEL`,
  `CORS_ORIGINS`) are set as encrypted Vercel project variables for
  Production and Development; `ANTHROPIC_API_KEY` is intentionally left
  unset (demo mode) pending the team providing a real key.
- **Database**: Neon Postgres, migrated via `npm run migrate`
  (`backend/src/migrate.js` applies `migrations/schema.sql` idempotently).
- **Source control**: pushed to GitHub (see repository link provided
  alongside this report). `.gitignore` excludes `.env`, `node_modules`,
  `.vercel`, and Flutter build artifacts.
- **Mobile app**: not yet built to an installable binary in this
  environment (no Flutter SDK available here). See §12 for the exact
  one-time setup.

## 11. Team readiness — architecture & limitations talking points

Two documented limitations the team should be ready to discuss, per the
assignment's success criteria:

1. **Object detection is a labeled list, not geometric bounding boxes**,
   because we chose a single multimodal LLM (Claude Vision) over the
   Cloud-Vision-plus-LLM combination for operational simplicity. Adding true
   bounding boxes is a scoped, isolated change to `visionProvider.js`.
2. **Confidence bands are self-reported by the model, not a calibrated
   accuracy metric.** They're presented as a 3-level qualitative badge
   specifically to avoid the false precision of a fabricated "97%
   confident" figure, and this is documented for anyone extending the
   system.

A third worth mentioning proactively: **anonymous JWT auth**, not full user
accounts, was used to keep the MVP's friction and privacy footprint low,
while still satisfying the assignment's "simple JWT or API key" requirement
via both layered together.

## 12. What remains for a fully graded live demo

This delivery is complete and verified at the infrastructure/backend level.
Two steps remain, both requiring resources not available in the environment
this was built in:

1. **Add a real `ANTHROPIC_API_KEY`** (`vercel env add ANTHROPIC_API_KEY
   production`, then `vercel deploy --prod --yes` from `backend/`) to move
   off demo mode, then re-run TESTING.md's edge-case matrix with real photos
   and record actual model outputs.
2. **Install the Flutter SDK, then**:
   ```bash
   cd app
   flutter create .
   flutter pub get
   flutter run --dart-define=API_BASE_URL=https://ai-image-analyst-backend.vercel.app \
               --dart-define=APP_API_KEY=<the APP_API_KEY value from backend/.env>
   ```
   This generates the platform folders, resolves dependencies, and launches
   the app end-to-end against the live, deployed backend — after which the
   8–10 required screenshots can be captured directly from the running app.

## 13. Nice-to-have features not implemented in this delivery

PDF export, image crop/rotate before analysis, batch analysis, cloud photo
library integration, an adjustable confidence threshold setting, and
multi-language UI were scoped as bonus items in the assignment and were not
built in this pass, to prioritize a fully working, tested core pipeline
(capture → analyze → ask → history → delete/share) end-to-end. Dark mode,
offline history viewing, and multiple questions per image — also listed as
bonuses — **were** implemented, since they required no additional
infrastructure beyond what the MVP already needed.
