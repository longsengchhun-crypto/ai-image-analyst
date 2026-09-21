import 'dart:typed_data';

import '../models/app_error.dart';

/// Client-side guardrails before we ever spend bandwidth / API calls uploading
/// an image. The backend re-validates everything server-side too — never
/// trust the client alone.
///
/// Operates on the already-compressed bytes (see `ImageService`) rather than
/// a `dart:io File`/path, since the picked image is normalized to JPEG bytes
/// before this ever runs, and bytes work identically on web and mobile.
class ImageValidationResult {
  final bool isValid;
  final AppErrorCode? errorCode;
  const ImageValidationResult.valid() : isValid = true, errorCode = null;
  const ImageValidationResult.invalid(this.errorCode) : isValid = false;
}

class Validators {
  Validators._();

  static const int maxFileSizeBytes = 8 * 1024 * 1024; // 8MB, matches backend cap

  static ImageValidationResult validateImageBytes(Uint8List bytes) {
    if (bytes.isEmpty) {
      return const ImageValidationResult.invalid(AppErrorCode.imageEmpty);
    }
    if (bytes.lengthInBytes > maxFileSizeBytes) {
      return const ImageValidationResult.invalid(AppErrorCode.imageTooLargeClient);
    }
    return const ImageValidationResult.valid();
  }

  static bool isQuestionValid(String question) => question.trim().length >= 3;
}
