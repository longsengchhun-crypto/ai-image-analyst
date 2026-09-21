import 'package:flutter/foundation.dart';

import '../models/app_error.dart';
import '../models/image_analysis.dart';
import '../services/api_service.dart';
import '../services/database_service.dart';
import '../services/image_service.dart';
import '../utils/validators.dart';
import 'history_provider.dart';

enum AnalysisStatus { initial, imageSelected, loading, success, error }

/// Drives the capture -> analyze -> ask-question flow for a single image.
/// This is intentionally scoped to "the image currently being worked on";
/// [HistoryProvider] owns the persisted list of past analyses.
///
/// The picked image is held as raw bytes (`Uint8List`), not a `dart:io File`,
/// so the entire capture -> preview -> analyze -> ask flow works unchanged
/// on web (no filesystem) as well as mobile and desktop.
///
/// Failures are stored as an [AppErrorCode], never a pre-built English
/// string, so the UI can render them in whichever language is active (see
/// `utils/error_messages.dart`).
class ImageAnalysisProvider extends ChangeNotifier {
  final ImageService _imageService = ImageService();
  final ApiService _apiService = ApiService.instance;

  /// Set by the app's provider wiring (see `main.dart`) so a completed
  /// analysis or answered question can be reflected in History the instant
  /// it happens, rather than waiting for History's own next network refresh.
  HistoryProvider? historyProvider;

  AnalysisStatus status = AnalysisStatus.initial;
  Uint8List? selectedImageBytes;
  ImageAnalysis? result;
  AppErrorCode? errorCode;
  bool isAskingQuestion = false;

  Future<void> pickFromCamera() async {
    final bytes = await _imageService.pickFromCamera();
    _onImagePicked(bytes);
  }

  Future<void> pickFromGallery() async {
    final bytes = await _imageService.pickFromGallery();
    _onImagePicked(bytes);
  }

  void _onImagePicked(Uint8List? bytes) {
    if (bytes == null) return;
    final validation = Validators.validateImageBytes(bytes);
    if (!validation.isValid) {
      errorCode = validation.errorCode;
      status = AnalysisStatus.error;
      notifyListeners();
      return;
    }
    selectedImageBytes = bytes;
    result = null;
    errorCode = null;
    status = AnalysisStatus.imageSelected;
    notifyListeners();
  }

  /// Loads a previously-saved analysis for read-only viewing (e.g. tapping an
  /// item in History). There is no local image data for these — the original
  /// was never retained past the moment of analysis (see privacy notes) — so
  /// the result screen falls back to the saved thumbnail and hides the
  /// ask-a-question composer, which needs a live image to ground new answers.
  void loadFromHistory(ImageAnalysis analysis) {
    selectedImageBytes = null;
    result = analysis;
    errorCode = null;
    status = AnalysisStatus.success;
    notifyListeners();
  }

  void reset() {
    selectedImageBytes = null;
    result = null;
    errorCode = null;
    status = AnalysisStatus.initial;
    notifyListeners();
  }

  Future<void> submitForAnalysis() async {
    if (selectedImageBytes == null) return;
    status = AnalysisStatus.loading;
    errorCode = null;
    notifyListeners();

    try {
      final analysis = await _apiService.analyzeImage(selectedImageBytes!);
      result = analysis;
      status = AnalysisStatus.success;
    } on ApiException catch (e) {
      errorCode = e.code;
      status = AnalysisStatus.error;
    } catch (_) {
      errorCode = AppErrorCode.analysisFailed;
      status = AnalysisStatus.error;
    }

    // Caching to the local SQLite mirror is a nice-to-have (fast History
    // reloads, offline browsing) — never let a cache-write failure (e.g.
    // sqflite has no web implementation) downgrade an otherwise-successful
    // analysis into an error state. This is intentionally isolated from the
    // try/catch above.
    if (status == AnalysisStatus.success && result != null) {
      try {
        await DatabaseService.instance.upsert(result!);
      } catch (_) {
        // Non-fatal: the result is still shown; it just won't be cached
        // locally on this platform/run.
      }
      historyProvider?.prependOrUpdate(result!);
    }
    notifyListeners();
  }

  Future<void> askQuestion(String question) async {
    if (result == null || selectedImageBytes == null) return;
    isAskingQuestion = true;
    errorCode = null;
    notifyListeners();

    try {
      final qa = await _apiService.askQuestion(
        imageBytes: selectedImageBytes!,
        question: question,
        historyId: result!.id,
      );
      result = result!.copyWith(questions: [...result!.questions, qa]);
    } on ApiException catch (e) {
      errorCode = e.code;
    } catch (_) {
      errorCode = AppErrorCode.questionFailed;
    }

    // Same non-fatal caching rule as submitForAnalysis() above.
    if (result != null) {
      try {
        await DatabaseService.instance.upsert(result!);
      } catch (_) {
        // Non-fatal.
      }
      historyProvider?.prependOrUpdate(result!);
    }

    isAskingQuestion = false;
    notifyListeners();
  }
}
