import 'dart:io';

/// Client-side guardrails before we ever spend bandwidth / API calls uploading
/// an image. The backend re-validates everything server-side too — never
/// trust the client alone.
class ImageValidationResult {
  final bool isValid;
  final String? errorMessage;
  const ImageValidationResult.valid() : isValid = true, errorMessage = null;
  const ImageValidationResult.invalid(this.errorMessage) : isValid = false;
}

class Validators {
  Validators._();

  static const Set<String> supportedExtensions = {'.jpg', '.jpeg', '.png', '.webp'};
  static const int maxFileSizeBytes = 8 * 1024 * 1024; // 8MB, matches backend cap

  static ImageValidationResult validateImageFile(File file) {
    final lowerPath = file.path.toLowerCase();
    final hasSupportedExt = supportedExtensions.any((ext) => lowerPath.endsWith(ext));
    if (!hasSupportedExt) {
      return const ImageValidationResult.invalid(
        'Unsupported file type. Please choose a JPEG, PNG, or WebP image.',
      );
    }

    final sizeBytes = file.lengthSync();
    if (sizeBytes > maxFileSizeBytes) {
      return const ImageValidationResult.invalid(
        'That image is larger than 8MB. Please choose a smaller image.',
      );
    }
    if (sizeBytes == 0) {
      return const ImageValidationResult.invalid('That file appears to be empty or corrupted.');
    }

    return const ImageValidationResult.valid();
  }

  static bool isQuestionValid(String question) => question.trim().length >= 3;
}
