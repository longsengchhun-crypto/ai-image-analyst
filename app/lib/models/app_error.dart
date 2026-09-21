/// A closed set of user-facing failure reasons. Kept as an enum — never a
/// raw `String` — specifically so every failure path can be localized:
/// screens map a code to translated text via `localizedApiError()`
/// (see `utils/error_messages.dart`) instead of storing pre-built English
/// sentences that could never be shown in Khmer.
enum AppErrorCode {
  timeout,
  connectionError,
  sessionExpired,
  imageTooLarge,
  rateLimited,
  serverError,
  imageEmpty,
  imageTooLargeClient,
  analysisFailed,
  questionFailed,
  historyRefreshFailed,
  unknown,
}
