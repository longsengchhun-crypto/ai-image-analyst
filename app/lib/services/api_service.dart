import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/image_analysis.dart';
import '../models/qa_pair.dart';
import '../utils/constants.dart';

/// Thin wrapper around the backend REST API. Owns the anonymous auth token
/// lifecycle (issued once, cached in SharedPreferences, sent as a Bearer
/// token thereafter) so callers never think about auth.
///
/// IMPORTANT: no third-party AI API key ever lives in this app. The Flutter
/// client only ever talks to our own backend, which holds the Gemini/Anthropic
/// key server-side (see backend/src/services/visionProvider.js).
///
/// Images are sent as raw bytes (`Uint8List`), not `dart:io File` paths, so
/// this service works unchanged on web (where there is no filesystem) as
/// well as mobile and desktop.
class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}

class ApiService {
  ApiService._internal()
      : _dio = Dio(BaseOptions(
          baseUrl: AppConfig.apiBaseUrl,
          connectTimeout: AppConfig.requestTimeout,
          receiveTimeout: AppConfig.requestTimeout,
          sendTimeout: AppConfig.requestTimeout,
          headers: {'x-api-key': AppConfig.appApiKey},
        ));

  static final ApiService instance = ApiService._internal();

  final Dio _dio;
  String? _token;

  static const _tokenPrefKey = 'auth_token';

  /// Ensures we have a valid session token, creating an anonymous one if needed.
  Future<void> ensureAuthenticated() async {
    if (_token != null) return;
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_tokenPrefKey);
    if (cached != null) {
      _token = cached;
      return;
    }
    try {
      final resp = await _dio.post('/api/auth/anonymous');
      _token = resp.data['token'] as String;
      await prefs.setString(_tokenPrefKey, _token!);
    } on DioException catch (e) {
      throw ApiException(_friendlyMessage(e));
    }
  }

  Options get _authedOptions => Options(headers: {'Authorization': 'Bearer $_token'});

  /// POST /api/analyze-image
  Future<ImageAnalysis> analyzeImage(Uint8List imageBytes) async {
    await ensureAuthenticated();
    try {
      final formData = FormData.fromMap({
        'image': MultipartFile.fromBytes(imageBytes, filename: 'upload.jpg'),
      });
      final resp = await _dio.post(
        '/api/analyze-image',
        data: formData,
        options: _authedOptions,
      );
      return ImageAnalysis.fromApiJson(resp.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException(_friendlyMessage(e));
    }
  }

  /// POST /api/ask-question
  Future<QaPair> askQuestion({
    required Uint8List imageBytes,
    required String question,
    required String historyId,
  }) async {
    await ensureAuthenticated();
    try {
      final formData = FormData.fromMap({
        'image': MultipartFile.fromBytes(imageBytes, filename: 'upload.jpg'),
        'question': question,
        'historyId': historyId,
      });
      final resp = await _dio.post(
        '/api/ask-question',
        data: formData,
        options: _authedOptions,
      );
      return QaPair.fromJson(resp.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException(_friendlyMessage(e));
    }
  }

  /// GET /api/history
  Future<List<ImageAnalysis>> fetchHistory({int limit = 50, int offset = 0}) async {
    await ensureAuthenticated();
    try {
      final resp = await _dio.get(
        '/api/history',
        queryParameters: {'limit': limit, 'offset': offset},
        options: _authedOptions,
      );
      final items = (resp.data['items'] as List).cast<Map<String, dynamic>>();
      return items.map(ImageAnalysis.fromApiJson).toList();
    } on DioException catch (e) {
      throw ApiException(_friendlyMessage(e));
    }
  }

  /// DELETE /api/history/:id
  Future<void> deleteHistoryItem(String id) async {
    await ensureAuthenticated();
    try {
      await _dio.delete('/api/history/$id', options: _authedOptions);
    } on DioException catch (e) {
      throw ApiException(_friendlyMessage(e));
    }
  }

  /// DELETE /api/history (clear all)
  Future<void> clearHistory() async {
    await ensureAuthenticated();
    try {
      await _dio.delete('/api/history', options: _authedOptions);
    } on DioException catch (e) {
      throw ApiException(_friendlyMessage(e));
    }
  }

  /// Never surface raw backend/provider error text to the user — map to a
  /// small set of safe, actionable messages instead.
  String _friendlyMessage(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return "This is taking longer than expected. Check your connection and try again.";
    }
    if (e.type == DioExceptionType.connectionError) {
      return "Couldn't reach the server. Check your internet connection.";
    }
    final status = e.response?.statusCode;
    final serverMessage = (e.response?.data is Map) ? e.response?.data['error'] as String? : null;
    if (status == 401) return "Your session expired. Please try again.";
    if (status == 413) return "That image is too large. Please use an image under 8MB.";
    if (status == 429) return "Too many requests right now. Please wait a moment and try again.";
    if (status != null && status >= 500) return "The server had a problem analyzing your image. Please try again.";
    return serverMessage ?? "Something went wrong. Please try again.";
  }
}
