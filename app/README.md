# AI Image Analyst — Flutter app

This directory contains only the Dart source (`lib/`), `pubspec.yaml`, and
assets. The Flutter SDK was not available on the machine this was built on,
so the platform scaffolding (`android/`, `ios/`, `web/`, etc.) has **not**
been generated yet. Generating it is a one-time, automatic step — no manual
platform code is required.

## First-time setup

1. Install the Flutter SDK (3.24+) if you haven't: https://docs.flutter.dev/get-started/install
2. From this directory, generate the platform folders:
   ```bash
   cd app
   flutter create .
   ```
   This detects the existing `pubspec.yaml` and `lib/`, and only adds the
   missing `android/`, `ios/`, etc. folders — it will not overwrite your code.
3. Install dependencies:
   ```bash
   flutter pub get
   ```
4. (Optional) Generate the native splash screen:
   ```bash
   dart run flutter_native_splash:create
   ```

## Running against the backend

Point the app at your backend deployment with `--dart-define`:

```bash
# Local backend (Android emulator uses 10.0.2.2 to reach your machine's localhost)
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080 --dart-define=APP_API_KEY=dev-only-app-key-change-me

# Deployed backend (Vercel)
flutter run --dart-define=API_BASE_URL=https://<your-vercel-app>.vercel.app --dart-define=APP_API_KEY=<value of APP_API_KEY on the backend>
```

`APP_API_KEY` here must match the `APP_API_KEY` environment variable
configured on the backend (see `backend/.env.example`). It is a coarse
anti-abuse gate, not a secret AI provider key — no AI provider key is ever
present in this app.

Defaults (see `lib/utils/constants.dart`) point at `http://10.0.2.2:8080`
with a placeholder key, purely so the app builds and runs out of the box for
local development.

## Project structure

```
lib/
├── main.dart                  # App entrypoint, theming, Provider setup
├── theme.dart                 # Light/dark theme definitions
├── screens/
│   ├── home_screen.dart       # Bottom-nav shell
│   ├── image_upload_screen.dart
│   ├── result_screen.dart
│   ├── history_screen.dart
│   └── settings_screen.dart
├── widgets/
│   ├── image_card.dart
│   ├── loading_indicator.dart
│   ├── object_tag.dart
│   └── confidence_badge.dart
├── models/
│   ├── image_analysis.dart
│   ├── detected_object.dart
│   └── qa_pair.dart
├── services/
│   ├── api_service.dart       # REST client + anonymous auth
│   ├── image_service.dart     # Camera/gallery capture + compression
│   └── database_service.dart  # SQLite local cache
├── providers/
│   ├── image_provider.dart    # Capture -> analyze -> ask flow
│   └── history_provider.dart  # Persisted history list
└── utils/
    ├── constants.dart
    └── validators.dart
```

## Notes on design choices

- **State management**: `provider`, chosen for its low ceremony and wide
  familiarity; the app has two focused `ChangeNotifier`s rather than a large
  global store.
- **Local history**: SQLite (`sqflite`) mirrors the backend's Postgres table
  so History loads instantly from disk and still shows previously-synced
  items when offline.
- **No `cached_network_image`**: thumbnails come back from the backend as
  small embedded base64 JPEGs (not hosted URLs), so there's no remote image
  to cache — `Image.memory` is used directly. If you later serve images from
  a CDN/URL, reintroduce `cached_network_image` for that path.
- **Pinch-to-zoom**: `photo_view` on the freshly-captured image in the result
  screen.
