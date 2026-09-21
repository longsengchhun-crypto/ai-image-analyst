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
— with all AI provider credentials isolated to the backend, and a free
Google Gemini API key as the recommended way to turn on live AI results
(Anthropic Claude Vision works identically as a drop-in alternative). The
backend is deployed and live on Vercel, migrated against the production Neon
database, and verified end-to-end (auth, upload, persistence, retrieval,
deletion). The Flutter client was not just written but built and tested:
`flutter analyze` is clean, the widget test suite passes, and both a release
Android APK and a release web build compile successfully — the web build was
then driven headlessly against the live backend to capture real screenshots
of the running app (see `docs/screenshots/` and §9). The one thing this
delivery could not do on its own is provide a paid or free-tier AI account
credential, since that requires the project owner's own sign-up — see §12
for the two-minute, no-cost step to finish that.

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

See AI_DOCUMENTATION.md in full. Key points: two pluggable multimodal
providers — **Google Gemini (free tier, recommended)** and Anthropic Claude
Vision as a drop-in alternative — selected automatically by which API key is
configured; three documented prompts (analysis, VQA, and a
documented-but-unimplemented bounding-box extension); confidence bands are
explicitly labeled as self-assessed heuristics, not calibrated statistics;
demo mode lets the entire pipeline run and be graded without incurring AI
costs or requiring a key to be provided with this submission.

## 8. Testing report summary

See TESTING.md in full. All backend plumbing (auth, upload, persistence,
retrieval, deletion, rate limiting, error mapping) was executed against the
live production stack — both locally and against the deployed Vercel URL.
On the Flutter side, `flutter analyze` is clean, the widget test suite
passes, and both a release Android APK and a release web build compile
successfully. Live AI-model behavior on specific edge-case photos (blurry,
dark, abstract, text-heavy, etc.) is documented as an *expected* matrix
derived from the prompt contract, pending a real Gemini/Anthropic key being
configured — the one thing genuinely outside this delivery's control (see
§12).

## 9. UI/UX documentation — verified against the running app

Screens: Analyze/Home, Result, History, Settings. Widgets: `ImageCard`,
`ObjectTag`, `ConfidenceBadge`, `AnalysisSkeleton`/`InlineLoadingLabel`.

Rather than leave this as source-only, the app was actually built, deployed,
and driven end to end. `flutter build web --release` is **live and publicly
clickable at https://ai-image-analyst-web.vercel.app** — the real compiled
app, not a mockup, talking to the real production backend. Two history
entries were also seeded through the live API (auth → analyze →
ask-question) so the History screen has real, populated data rather than an
empty state. Real screenshots (not mockups) are in `docs/screenshots/`:

| File | Shows |
|---|---|
| `01-analyze-initial.png` | Home/Analyze screen's initial guidance state, consent notice, FAB |
| `02-history-list.png` | History screen populated with two seeded analyses (thumbnail, confidence badge, timestamp, Q&A count) |
| `03-result-detail.png` | Full analysis detail (opened from History): image, demo-mode banner, description with confidence badge, detected-object chips with per-object confidence |
| `04-settings.png` | Settings screen showing the live backend URL, privacy notices, clear-history action |
| `05-source-sheet.png` | The camera/gallery bottom-sheet modal, with scrim and rounded-top-corner animation |
| `06-analyze-dark-mode.png` | The same Analyze screen under the dark theme, confirming dark-mode support actually renders correctly |
| `07-fresh-capture-preview.png` | **A genuinely fresh run, no seeded data**: an image just picked through the browser's real file chooser, shown in the Retake/Analyze preview state |
| `08-fresh-capture-loading.png` | The shimmer skeleton loading state, captured mid-flight while the real `POST /api/analyze-image` call to the live backend was in progress |
| `09-fresh-capture-result.png` | The result of that same real network call, rendered on screen — proving the full capture → upload → analyze → display pipeline works through the actual UI, not just via `curl` |

**What this replaced**: an earlier pass of this delivery discovered that
`ImageService`/`ApiService` used `dart:io File`, which does not exist on
Flutter's web target — every attempt to pick an image in a browser silently
failed with no visible error (Flutter's web error zone swallows it). Rather
than accept that as "web isn't supported, only mobile is" and move on, both
services were rewritten to operate on raw bytes (`Uint8List`) end to end —
`image_picker`'s `XFile.readAsBytes()` → `FlutterImageCompress.compressWithList()`
→ `MultipartFile.fromBytes()` — which is simpler than the original file-path
based code and works identically on mobile, desktop, and web with zero
platform branching. Screenshots 07–09 above are the proof this now works.

**A more serious bug surfaced in the same pass**: `submitForAnalysis()` set
the UI to "success" and then wrote a copy to the local SQLite cache inside
the same try block. A cache-write failure — which is exactly what happens
on a platform with no SQLite, like the web build used to test this — was
silently downgrading a **correct, successful AI analysis** into a
user-facing error screen, discarding a result the user had already
correctly received. This is not web-specific in principle; a rare sqflite
hiccup on a real device could have triggered the same silent data loss.
Fixed by isolating the cache write into its own non-fatal try/catch that can
never override a successful result. See `app/lib/providers/image_provider.dart`.

A fourth real bug was also caught: on a short viewport, the Analyze screen's
initial-state `Column` overflowed by 7px (visible only via the automated
widget test, not by inspection). Fixed by wrapping it in a
`SingleChildScrollView` + `ConstrainedBox` — see
`app/lib/screens/image_upload_screen.dart` and the test in
`app/test/widget_test.dart` that caught it.

**The one interaction not confirmed by automation**: typing a follow-up
question into the "Ask about this image" field and tapping Send. The
backend endpoint behind it (`POST /api/ask-question`) was independently
verified correct via direct requests (see TESTING.md), but simulating
keystrokes into Flutter web's text-input layer from a headless browser
proved unreliable across three different automation approaches — a known
class of flakiness specific to automating Flutter's web semantics bridge,
not a defect in this app's code (`TextField` + `TextEditingController` is
standard, unmodified Flutter API, and every other button/tab in the app
responded correctly to the same automation). A real tap on a device or in
an interactive browser session is the one check worth doing by hand.

## 10. Deployment

- **Backend**: deployed to Vercel as a serverless function
  (`backend/api/index.js` wraps the Express app; `backend/vercel.json`
  routes all paths to it). Production URL:
  `https://ai-image-analyst-backend.vercel.app`. Environment variables
  (`DATABASE_URL`, `JWT_SECRET`, `APP_API_KEY`, `GEMINI_MODEL`,
  `ANTHROPIC_MODEL`, `CORS_ORIGINS`) are set as encrypted Vercel project
  variables for Production and Development. GitHub↔Vercel auto-deploy was
  tried and deliberately turned back off (`vercel git disconnect`): with the
  project's Root Directory unset (a monorepo setting only available in the
  Vercel dashboard, not the CLI), the first push after connecting it
  triggered a build from the repo root instead of `backend/`, which broke
  the live URL for a few minutes until caught and fixed with a manual
  `vercel deploy --prod --yes`. Until someone sets Root Directory to
  `backend` in the dashboard, deploys are manual and reliable
  (`cd backend && vercel deploy --prod --yes`) rather than automatic and
  fragile. Neither `GEMINI_API_KEY` nor `ANTHROPIC_API_KEY` is set yet
  (demo mode) — see §12.
- **Database**: Neon Postgres, migrated via `npm run migrate`
  (`backend/src/migrate.js` applies `migrations/schema.sql` idempotently).
- **Source control**: pushed to GitHub. `.gitignore` excludes `.env`,
  `node_modules`, `.vercel`, and machine-local Flutter/Gradle build
  artifacts — but the Android and web platform folders themselves **are**
  committed, since both were generated and verified to build successfully
  in this delivery (see below).
- **Mobile app — built, not just written**: `flutter analyze` (0 issues),
  `flutter test` (passing), `flutter build apk --release` (produces a
  working 51MB release APK), and `flutter build web --release` all ran
  successfully against this exact codebase. Two real, environment-specific
  fixes were required and are documented inline: a Windows Kotlin
  incremental-compiler bug when the project and Pub cache are on different
  drive letters (worked around in `android/gradle.properties`), and a
  `compileSdk`/`share_plus` version mismatch (resolved by bumping
  `compileSdk` to 36 and `share_plus` to 13.3.0, and migrating the one
  call site from the deprecated `Share.share()` to `SharePlus.instance.share()`).
- **Web build — deployed and public**: the same Flutter codebase compiled
  for web is deployed as a separate static Vercel project at
  **https://ai-image-analyst-web.vercel.app**, talking to the same live
  backend. This gives anyone a single click to actually use the app —
  pick a photo, get a description and detected objects, browse history — no
  install, no emulator, no APK sideloading required. It's a genuine build of
  the same `lib/` source, not a separate demo.

## 11. Team readiness — architecture & limitations talking points

Two documented limitations the team should be ready to discuss, per the
assignment's success criteria:

1. **Object detection is a labeled list, not geometric bounding boxes**,
   because we chose a single multimodal LLM (Gemini or Claude Vision) over
   the Cloud-Vision-plus-LLM combination for operational simplicity (and, for
   Gemini, genuinely free access). Adding true bounding boxes is a scoped,
   isolated change to `visionProvider.js`.
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

This delivery is complete and verified at the infrastructure, backend, and
Flutter-build level — the Flutter SDK was installed and used to actually
build and test the app, not just write its source. One step remains, and it
requires a credential only the project owner can obtain (a free Google
account is enough — no payment involved):

1. **Add a free `GEMINI_API_KEY`**: get one at
   [aistudio.google.com/apikey](https://aistudio.google.com/apikey) (or use
   `ANTHROPIC_API_KEY` if you already have Anthropic access), then:
   ```bash
   vercel env add GEMINI_API_KEY production
   cd backend && vercel deploy --prod --yes
   ```
   then re-run TESTING.md's edge-case matrix with real photos and record
   actual model outputs.

Everything else — installing Flutter, running `flutter create .`
(unnecessary now; already committed), building the release APK, capturing
UI screenshots — has already been done in this delivery, not left as a
follow-up step. To install the built APK on a device:
`app/build/app/outputs/flutter-apk/app-release.apk` (rebuild locally with
`flutter build apk --release --dart-define=API_BASE_URL=... --dart-define=APP_API_KEY=...`
if that build directory isn't present, since `build/` is gitignored as a
regenerable artifact).

## 13. Nice-to-have features not implemented in this delivery

PDF export, image crop/rotate before analysis, batch analysis, cloud photo
library integration, an adjustable confidence threshold setting, and
multi-language UI were scoped as bonus items in the assignment and were not
built in this pass, to prioritize a fully working, tested core pipeline
(capture → analyze → ask → history → delete/share) end-to-end. Dark mode,
offline history viewing, and multiple questions per image — also listed as
bonuses — **were** implemented, since they required no additional
infrastructure beyond what the MVP already needed.
