# AI Image Analyst — Flutter app

Android and web platform folders are committed and **verified working**:
`flutter analyze` is clean, the widget test suite passes (including an
end-to-end test that switches the app to Khmer and asserts the UI actually
re-renders in Khmer), `flutter build apk --release` produces a working
release APK, and `flutter build web --release` produces a working web build
— all confirmed in this repository's own build history (see
`PROJECT_REPORT.md` §9 and `docs/screenshots/` for real screenshots
captured from the running app, in both English and Khmer). An iOS scaffold
(`ios/`) is committed too, generated via `flutter create --platforms=ios .`,
but it has **not** been built or code-signed — that requires Xcode on a
Mac, which was not available in this build environment. Anyone with a Mac
can open `ios/Runner.xcworkspace` in Xcode and build/run immediately; no
other setup is needed. macOS/Linux/Windows desktop scaffolding was not
generated.

## Languages

English and Khmer are both fully supported via `flutter_localizations` +
generated ARB translations (`lib/l10n/`). Khmer text renders in **Kantumruy
Pro Bold** everywhere (`utils/app_fonts.dart` forces the bold weight for
every Khmer string, regardless of what weight an individual widget
requests — Khmer script needs a heavier stroke than Latin text to stay
legible at UI sizes); English renders in Inter, unchanged. Switch languages
from the Settings screen — the choice is persisted and also drives which
font the whole app theme uses (see `theme.dart`), not just the translated
strings.

Every error message shown to the user is also translated: failures are
carried around the app as a closed `AppErrorCode` enum
(`models/app_error.dart`), never a pre-built English sentence, and only
turned into text at the point of display via `utils/error_messages.dart` —
so there is no code path that can leak an untranslated string.

## First-time setup

1. Install the Flutter SDK (3.24+) if you haven't: https://docs.flutter.dev/get-started/install
2. Install dependencies:
   ```bash
   cd app
   flutter pub get
   ```
3. (Optional) Generate the native splash screen:
   ```bash
   dart run flutter_native_splash:create
   ```

### Windows note

If you build on Windows with the project on a different drive letter than
your Pub cache (e.g. project on `E:`, Pub cache on `C:`), you may hit a
known Kotlin incremental-compiler bug during `flutter build apk`. It's
already worked around in `android/gradle.properties`
(`kotlin.incremental=false`); no action needed unless you've deleted that
file.

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
├── main.dart                  # App entrypoint, theming, localization, Provider setup
├── theme.dart                 # Light/dark theme definitions (locale-aware font choice)
├── l10n/
│   ├── app_en.arb             # English source strings
│   ├── app_km.arb             # Khmer translations
│   └── generated/             # AppLocalizations classes (flutter gen-l10n output)
├── screens/
│   ├── home_screen.dart       # Bottom-nav shell
│   ├── image_upload_screen.dart
│   ├── result_screen.dart
│   ├── history_screen.dart
│   └── settings_screen.dart   # Includes the language switcher
├── widgets/
│   ├── image_card.dart
│   ├── loading_indicator.dart
│   ├── object_tag.dart
│   └── confidence_badge.dart
├── models/
│   ├── image_analysis.dart
│   ├── detected_object.dart
│   ├── qa_pair.dart
│   └── app_error.dart         # Closed error-code enum (never a raw string)
├── services/
│   ├── api_service.dart       # REST client + anonymous auth
│   ├── image_service.dart     # Camera/gallery capture + compression
│   └── database_service.dart  # SQLite local cache
├── providers/
│   ├── image_provider.dart    # Capture -> analyze -> ask flow
│   ├── history_provider.dart  # Persisted history list
│   └── locale_provider.dart   # Persisted English/Khmer choice
└── utils/
    ├── constants.dart
    ├── validators.dart
    ├── app_fonts.dart         # Inter (en) vs. bold Kantumruy Pro (km)
    └── error_messages.dart    # AppErrorCode -> localized string
```

## Notes on design choices

- **State management**: `provider`, chosen for its low ceremony and wide
  familiarity; the app has three focused `ChangeNotifier`s (image analysis,
  history, locale) rather than a large global store.
- **Local history**: SQLite (`sqflite`) mirrors the backend's Postgres table
  so History loads instantly from disk and still shows previously-synced
  items when offline.
- **No `cached_network_image`**: thumbnails come back from the backend as
  small embedded base64 JPEGs (not hosted URLs), so there's no remote image
  to cache — `Image.memory` is used directly. If you later serve images from
  a CDN/URL, reintroduce `cached_network_image` for that path.
- **Pinch-to-zoom**: `photo_view` on the freshly-captured image in the result
  screen.
