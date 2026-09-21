import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';

/// App-wide constants: API config, spacing grid, and the color palette.
/// Kept in one place so the rest of the app never hardcodes magic numbers.
class AppConfig {
  AppConfig._();

  /// Base URL of the backend API.
  ///
  /// Override at build/run time so you never have to hardcode a different
  /// value per environment, e.g.:
  ///   flutter run --dart-define=API_BASE_URL=https://your-app.vercel.app
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8080', // Android emulator loopback to localhost
  );

  /// Shared app-level key sent as `x-api-key`. This is NOT a secret credential
  /// for a paid AI service — it is a coarse anti-abuse gate matching the value
  /// configured as APP_API_KEY on the backend. It is fine for this to ship in
  /// the client; the real AI provider key lives only on the server.
  static const String appApiKey = String.fromEnvironment(
    'APP_API_KEY',
    defaultValue: 'dev-only-app-key-change-me',
  );

  static const int maxUploadDimension = 1600;
  static const int uploadJpegQuality = 85;
  static const Duration requestTimeout = Duration(seconds: 30);
}

/// 4px spacing grid used consistently across the UI.
class Spacing {
  Spacing._();
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
  static const double xxxl = 64;

  /// Max content width on wide (desktop/web) viewports — the app composes
  /// itself in a centered column instead of stretching full-bleed edge to
  /// edge the way the old layout did above phone width.
  static const double contentMaxWidth = 1120;
  static const double breakpointWide = 900;
}

class Radii {
  Radii._();
  static const double sm = 8;
  static const double card = 12;
  static const double button = 10;
  static const double chip = 8;
  static const double sheet = 20;
  static const double pill = 999;
}

/// A restrained indigo-led palette — one deliberate brand hue (indigo) used
/// for both identity and primary actions, rather than a two-hue
/// brand-color + accent-color split. Neutrals are warm-gray, not pure gray,
/// and the light background carries a faint cool tint rather than being
/// stark white, which is what actually reads as "designed" instead of
/// "default Material app" at a glance.
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF4338CA); // indigo-700
  static const Color primaryStrong = Color(0xFF312E81); // indigo-900, for text-on-tint / dark app bar
  static const Color primarySoft = Color(0xFFEEF0FF); // indigo-50, for tinted surfaces/selection
  static const Color success = Color(0xFF15803D);
  static const Color warning = Color(0xFFB45309);
  static const Color danger = Color(0xFFB91C1C);
  static const Color info = Color(0xFF2563EB);

  static const Color surfaceLight = Color(0xFFF7F7FB); // faint cool-neutral, not stark white
  static const Color surfaceDark = Color(0xFF121218);
  static const Color cardLight = Colors.white;
  static const Color cardDark = Color(0xFF1C1C24);

  // Muted text / borders. Defined once here (rather than ad hoc
  // `Colors.grey.shadeXXX` per file) so every screen reads the same shade for
  // the same purpose, and so it actually adapts in dark mode instead of
  // going low-contrast against a dark surface.
  static const Color textPrimaryLight = Color(0xFF1A1A23);
  static const Color textPrimaryDark = Color(0xFFEDEDF2);
  static const Color textMutedLight = Color(0xFF6B6B7A);
  static const Color textMutedDark = Color(0xFF9797A6);
  static const Color borderLight = Color(0xFFE4E4EC);
  static const Color borderDark = Color(0xFF2C2C36);

  // Confidence bands — reuse the same semantic colors as the rest of the
  // system rather than a separate palette.
  static const Color confidenceHigh = success;
  static const Color confidenceMedium = warning;
  static const Color confidenceLow = danger;
}

/// Theme-aware muted text color — use this instead of a raw `Colors.grey.shadeXXX`
/// so secondary/supporting text stays legible in both light and dark mode.
Color mutedText(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark ? AppColors.textMutedDark : AppColors.textMutedLight;

/// Theme-aware subtle border/divider color, for the same reason as [mutedText].
Color subtleBorder(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark ? AppColors.borderDark : AppColors.borderLight;

/// Maps the backend's qualitative confidence bands to display color/label.
enum ConfidenceBand { high, medium, low }

ConfidenceBand confidenceBandFromString(String? value) {
  switch (value) {
    case 'high':
      return ConfidenceBand.high;
    case 'low':
      return ConfidenceBand.low;
    default:
      return ConfidenceBand.medium;
  }
}

Color confidenceBandColor(ConfidenceBand band) {
  switch (band) {
    case ConfidenceBand.high:
      return AppColors.confidenceHigh;
    case ConfidenceBand.medium:
      return AppColors.confidenceMedium;
    case ConfidenceBand.low:
      return AppColors.confidenceLow;
  }
}

String confidenceBandLabel(AppLocalizations l10n, ConfidenceBand band) {
  switch (band) {
    case ConfidenceBand.high:
      return l10n.confidenceHighFull;
    case ConfidenceBand.medium:
      return l10n.confidenceMediumFull;
    case ConfidenceBand.low:
      return l10n.confidenceLowFull;
  }
}

String confidenceBandShortLabel(AppLocalizations l10n, ConfidenceBand band) {
  switch (band) {
    case ConfidenceBand.high:
      return l10n.confidenceHighShort;
    case ConfidenceBand.medium:
      return l10n.confidenceMediumShort;
    case ConfidenceBand.low:
      return l10n.confidenceLowShort;
  }
}
