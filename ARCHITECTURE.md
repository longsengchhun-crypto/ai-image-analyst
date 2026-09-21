# Architecture

## System diagram

```
┌──────────────────────────┐         HTTPS (REST, multipart)        ┌───────────────────────────────┐
│      Flutter App          │ ──────────────────────────────────────▶│   Backend API (Node/Express)  │
│  (iOS / Android / Web)    │◀────────────────────────────────────── │   Deployed on Vercel           │
│                            │        JSON responses                  │   (serverless functions)      │
│  screens/ providers/       │                                         │                                │
│  services/ models/         │  - x-api-key header (app gate)          │  middleware/  routes/          │
│  widgets/                  │  - Authorization: Bearer <JWT>          │  services/                     │
│                            │                                         │                                │
│  Local cache: SQLite       │                                         └───────────────┬────────────────┘
│  (sqflite) mirrors server  │                                                         │
│  history for offline view  │                                         ┌───────────────┼────────────────┐
└──────────────┬─────────────┘                                        │               │                │
               │ camera / gallery                                     ▼               ▼                │
               │ (image_picker)                              ┌─────────────┐   ┌───────────────┐        │
               ▼                                             │ Neon        │   │ Anthropic      │        │
     On-device compression                                   │ Postgres    │   │ Claude Vision  │        │
     (flutter_image_compress)                                 │ (pooled     │   │ (multimodal    │        │
                                                               │ connection) │   │ messages API)  │        │
                                                               └─────────────┘   └───────────────┘        │
                                                                                                            │
                                                               image_history table stores:                 │
                                                               thumbnail, description, objects (JSONB),     │
                                                               OCR text, confidence, Q&A history (JSONB)    │
                                                               ──────────────────────────────────────────────
```

## Request flow: analyzing an image

1. User captures/picks a photo in the Flutter app. `ImageService` compresses
   it client-side (downscale + re-encode JPEG) before it ever leaves the
   device.
2. `ApiService.ensureAuthenticated()` obtains (or reuses a cached) anonymous
   JWT from `POST /api/auth/anonymous`. No email, phone, or name is
   collected — the "user" is just a server-generated UUID tied to this
   device's token.
3. `ApiService.analyzeImage()` posts the compressed JPEG as multipart form
   data to `POST /api/analyze-image`, with `x-api-key` (app-level gate) and
   `Authorization: Bearer <jwt>` (per-user identity) headers.
4. On the backend: `multer` receives the upload into memory → `sharp`
   re-normalizes it (EXIF-safe rotate, cap long edge, re-encode JPEG, build a
   256px thumbnail) → `visionProvider.analyzeImage()` sends the normalized
   bytes to Claude with a structured-JSON system prompt → the parsed result
   (description, objects, OCR text, confidence bands, uncertainty note) is
   written to the `image_history` table in Neon Postgres, scoped to the
   caller's `user_id`.
5. The full result is returned to the app, rendered on `ResultScreen`, and
   also cached locally in SQLite via `DatabaseService.upsert()`.
6. Asking a follow-up question (`POST /api/ask-question`) repeats steps 3–4
   for VQA: the client re-sends the same compressed image bytes (the backend
   does not retain full images between requests — see privacy notes) plus
   the question text; the answer is appended to that history row's
   `user_questions` JSONB array.

## Why this shape

- **Backend-mediated AI calls**: the Flutter client never talks to Anthropic
  directly. This keeps the AI provider's API key server-side only, lets us
  rate-limit and validate uploads centrally, and means swapping providers
  (e.g. adding Google Cloud Vision for true bounding boxes) is a change
  confined to `backend/src/services/visionProvider.js`.
- **JWT + API key, not full accounts**: the assignment asks for "simple JWT
  or API key" auth to prevent abuse, not a social product with logins. An
  anonymous per-install JWT plus a shared app-level key satisfies that with
  the least user friction and the smallest privacy footprint.
- **Postgres over a document store**: object lists and Q&A history are
  naturally JSONB, but confidence scores, timestamps, and per-user filtering
  benefit from relational indexing (`idx_image_history_user_created`). Neon
  gives us managed, serverless-friendly Postgres with a pooled connection
  string that works well from short-lived Vercel functions.
- **SQLite cache on-device**: makes History load instantly and remain
  browsable (read-only) without a network connection, satisfying the
  "optional offline mode" nice-to-have cheaply.
