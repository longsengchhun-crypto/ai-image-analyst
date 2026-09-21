import 'dart:io';

import 'package:flutter/foundation.dart';

import '../models/image_analysis.dart';
import '../services/api_service.dart';
import '../services/database_service.dart';
import '../services/image_service.dart';

enum AnalysisStatus { initial, imageSelected, loading, success, error }

/// Drives the capture -> analyze -> ask-question flow for a single image.
/// This is intentionally scoped to "the image currently being worked on";
/// [HistoryProvider] owns the persisted list of past analyses.
class ImageAnalysisProvider extends ChangeNotifier {
  final ImageService _imageService = ImageService();
  final ApiService _apiService = ApiService.instance;

  AnalysisStatus status = AnalysisStatus.initial;
  File? selectedImage;
  ImageAnalysis? result;
  String? errorMessage;
  bool isAskingQuestion = false;

  Future<void> pickFromCamera() async {
    final file = await _imageService.pickFromCamera();
    _onImagePicked(file);
  }

  Future<void> pickFromGallery() async {
    final file = await _imageService.pickFromGallery();
    _onImagePicked(file);
  }

  void _onImagePicked(File? file) {
    if (file == null) return;
    selectedImage = file;
    result = null;
    errorMessage = null;
    status = AnalysisStatus.imageSelected;
    notifyListeners();
  }

  /// Loads a previously-saved analysis for read-only viewing (e.g. tapping an
  /// item in History). There is no local image file for these — the original
  /// was never retained past the moment of analysis (see privacy notes) — so
  /// the result screen falls back to the saved thumbnail and hides the
  /// ask-a-question composer, which needs a live image to ground new answers.
  void loadFromHistory(ImageAnalysis analysis) {
    selectedImage = null;
    result = analysis;
    errorMessage = null;
    status = AnalysisStatus.success;
    notifyListeners();
  }

  void reset() {
    selectedImage = null;
    result = null;
    errorMessage = null;
    status = AnalysisStatus.initial;
    notifyListeners();
  }

  Future<void> submitForAnalysis() async {
    if (selectedImage == null) return;
    status = AnalysisStatus.loading;
    errorMessage = null;
    notifyListeners();

    try {
      final analysis = await _apiService.analyzeImage(selectedImage!);
      result = analysis.copyWith(localImagePath: selectedImage!.path);
      status = AnalysisStatus.success;
      await DatabaseService.instance.upsert(result!);
    } on ApiException catch (e) {
      errorMessage = e.message;
      status = AnalysisStatus.error;
    } catch (_) {
      errorMessage = 'Something went wrong analyzing your image. Please try again.';
      status = AnalysisStatus.error;
    }
    notifyListeners();
  }

  Future<void> askQuestion(String question) async {
    if (result == null || selectedImage == null) return;
    isAskingQuestion = true;
    notifyListeners();

    try {
      final qa = await _apiService.askQuestion(
        imageFile: selectedImage!,
        question: question,
        historyId: result!.id,
      );
      result = result!.copyWith(questions: [...result!.questions, qa]);
      await DatabaseService.instance.upsert(result!);
    } on ApiException catch (e) {
      errorMessage = e.message;
    } catch (_) {
      errorMessage = 'Could not get an answer right now. Please try again.';
    }

    isAskingQuestion = false;
    notifyListeners();
  }
}
