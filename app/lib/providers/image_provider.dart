import 'package:flutter/foundation.dart';

import '../models/image_analysis.dart';
import '../services/api_service.dart';
import '../services/database_service.dart';
import '../services/image_service.dart';
import '../utils/validators.dart';

enum AnalysisStatus { initial, imageSelected, loading, success, error }

/// Drives the capture -> analyze -> ask-question flow for a single image.
/// This is intentionally scoped to "the image currently being worked on";
/// [HistoryProvider] owns the persisted list of past analyses.
///
/// The picked image is held as raw bytes (`Uint8List`), not a `dart:io File`,
/// so the entire capture -> preview -> analyze -> ask flow works unchanged
/// on web (no filesystem) as well as mobile and desktop.
class ImageAnalysisProvider extends ChangeNotifier {
  final ImageService _imageService = ImageService();
  final ApiService _apiService = ApiService.instance;

  AnalysisStatus status = AnalysisStatus.initial;
  Uint8List? selectedImageBytes;
  ImageAnalysis? result;
  String? errorMessage;
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
      errorMessage = validation.errorMessage;
      status = AnalysisStatus.error;
      notifyListeners();
      return;
    }
    selectedImageBytes = bytes;
    result = null;
    errorMessage = null;
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
    errorMessage = null;
    status = AnalysisStatus.success;
    notifyListeners();
  }

  void reset() {
    selectedImageBytes = null;
    result = null;
    errorMessage = null;
    status = AnalysisStatus.initial;
    notifyListeners();
  }

  Future<void> submitForAnalysis() async {
    if (selectedImageBytes == null) return;
    status = AnalysisStatus.loading;
    errorMessage = null;
    notifyListeners();

    try {
      final analysis = await _apiService.analyzeImage(selectedImageBytes!);
      result = analysis;
      status = AnalysisStatus.success;
    } on ApiException catch (e) {
      errorMessage = e.message;
      status = AnalysisStatus.error;
    } catch (_) {
      errorMessage = 'Something went wrong analyzing your image. Please try again.';
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
    }
    notifyListeners();
  }

  Future<void> askQuestion(String question) async {
    if (result == null || selectedImageBytes == null) return;
    isAskingQuestion = true;
    notifyListeners();

    try {
      final qa = await _apiService.askQuestion(
        imageBytes: selectedImageBytes!,
        question: question,
        historyId: result!.id,
      );
      result = result!.copyWith(questions: [...result!.questions, qa]);
    } on ApiException catch (e) {
      errorMessage = e.message;
    } catch (_) {
      errorMessage = 'Could not get an answer right now. Please try again.';
    }

    // Same non-fatal caching rule as submitForAnalysis() above.
    if (result != null) {
      try {
        await DatabaseService.instance.upsert(result!);
      } catch (_) {
        // Non-fatal.
      }
    }

    isAskingQuestion = false;
    notifyListeners();
  }
}
