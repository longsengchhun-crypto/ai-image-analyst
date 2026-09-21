import '../l10n/generated/app_localizations.dart';
import '../models/app_error.dart';

/// Renders a closed [AppErrorCode] as user-facing text in whichever
/// language is active. This is the only place an [AppErrorCode] gets turned
/// into a sentence — screens never build error strings themselves, so every
/// failure path is guaranteed to be translated.
String localizedError(AppLocalizations l10n, AppErrorCode code) {
  switch (code) {
    case AppErrorCode.timeout:
      return l10n.errorTimeout;
    case AppErrorCode.connectionError:
      return l10n.errorConnection;
    case AppErrorCode.sessionExpired:
      return l10n.errorSessionExpired;
    case AppErrorCode.imageTooLarge:
      return l10n.errorImageTooLarge;
    case AppErrorCode.rateLimited:
      return l10n.errorRateLimited;
    case AppErrorCode.serverError:
      return l10n.errorServerError;
    case AppErrorCode.imageEmpty:
      return l10n.errorImageEmpty;
    case AppErrorCode.imageTooLargeClient:
      return l10n.errorImageTooLargeClient;
    case AppErrorCode.analysisFailed:
      return l10n.errorAnalysisFailed;
    case AppErrorCode.questionFailed:
      return l10n.errorQuestionFailed;
    case AppErrorCode.historyRefreshFailed:
      return l10n.errorHistoryRefreshFailed;
    case AppErrorCode.unknown:
      return l10n.errorGeneric;
  }
}
