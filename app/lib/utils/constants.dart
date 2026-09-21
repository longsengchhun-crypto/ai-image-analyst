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

/// 8px spacing grid used consistently across the UI.
class Spacing {
  Spacing._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

class Radii {
  Radii._();
  static const double card = 16;
  static const double button = 14;
  static const double chip = 20;
  static const double sheet = 24;
}

/// Cohesive deep-blue palette with a warm accent, as specified in the brief.
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF14335C); // deep blue
  static const Color primaryDark = Color(0xFF0B1E3E);
  static const Color accent = Color(0xFFFF7A45); // warm coral accent for CTAs
  static const Color success = Color(0xFF2E9E6B);
  static const Color warning = Color(0xFFE0A72E);
  static const Color danger = Color(0xFFD94F4F);
  static const Color info = Color(0xFF3B6EA8); // calm blue for neutral/contextual notes

  static const Color surfaceLight = Color(0xFFF7F9FC);
  static const Color surfaceDark = Color(0xFF10182A);
  static const Color cardLight = Colors.white;
  static const Color cardDark = Color(0xFF1B2740);

  // Muted text / borders. Defined once here (rather than ad hoc
  // `Colors.grey.shadeXXX` per file) so every screen reads the same shade for
  // the same purpose, and so it actually adapts in dark mode instead of
  // going low-contrast against a dark surface.
  static const Color textMutedLight = Color(0xFF5B6472);
  static const Color textMutedDark = Color(0xFFA6ADBB);
  static const Color borderLight = Color(0xFFDDE2E8);
  static const Color borderDark = Color(0xFF2B384F);

  // Confidence bands
  static const Color confidenceHigh = Color(0xFF2E9E6B);
  static const Color confidenceMedium = Color(0xFFE0A72E);
  static const Color confidenceLow = Color(0xFFD94F4F);
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
