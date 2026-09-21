import 'dart:convert';

import '../utils/constants.dart';
import 'detected_object.dart';
import 'qa_pair.dart';

/// The full result of analyzing one image: description, detected objects,
/// OCR text (if any), overall confidence, and the running list of Q&A pairs
/// the user has asked about it. This is also the shape used for local history
/// (SQLite) and for what comes back from the backend.
class ImageAnalysis {
  final String id;
  final String? thumbnailBase64; // data URI, from backend or cached locally
  final String description;
  final List<DetectedObject> objects;
  final String? detectedText;
  final double confidenceScore;
  final ConfidenceBand confidenceBand;
  final String? uncertaintyNote;
  final bool isDemoMode;
  final List<QaPair> questions;
  final DateTime createdAt;

  const ImageAnalysis({
    required this.id,
    required this.description,
    required this.objects,
    required this.confidenceScore,
    required this.confidenceBand,
    required this.questions,
    required this.createdAt,
    this.thumbnailBase64,
    this.detectedText,
    this.uncertaintyNote,
    this.isDemoMode = false,
  });

  ImageAnalysis copyWith({
    List<QaPair>? questions,
  }) {
    return ImageAnalysis(
      id: id,
      thumbnailBase64: thumbnailBase64,
      description: description,
      objects: objects,
      detectedText: detectedText,
      confidenceScore: confidenceScore,
      confidenceBand: confidenceBand,
      uncertaintyNote: uncertaintyNote,
      isDemoMode: isDemoMode,
      questions: questions ?? this.questions,
      createdAt: createdAt,
    );
  }

  factory ImageAnalysis.fromApiJson(Map<String, dynamic> json) {
    return ImageAnalysis(
      id: json['id'] as String,
      thumbnailBase64: json['thumbnail'] as String?,
      description: json['description'] as String? ?? '',
      objects: ((json['objects'] as List?) ?? [])
          .map((o) => DetectedObject.fromJson(o as Map<String, dynamic>))
          .toList(),
      detectedText: json['detectedText'] as String?,
      confidenceScore: (json['confidenceScore'] as num?)?.toDouble() ?? 0.5,
      confidenceBand: confidenceBandFromString(json['confidenceBand'] as String?),
      uncertaintyNote: json['uncertaintyNote'] as String?,
      isDemoMode: json['isDemoMode'] as bool? ?? false,
      questions: ((json['questions'] as List?) ?? [])
          .map((q) => QaPair.fromJson(q as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }

  /// Serialize for the local SQLite cache (see database_service.dart).
  Map<String, dynamic> toDbMap() => {
        'id': id,
        'image_thumbnail': thumbnailBase64,
        'description': description,
        'detected_objects': jsonEncode(objects.map((o) => o.toJson()).toList()),
        'detected_text': detectedText,
        'user_questions': jsonEncode(questions.map((q) => q.toJson()).toList()),
        'confidence_score': confidenceScore,
        'confidence_band': confidenceBand.name,
        'is_demo_mode': isDemoMode ? 1 : 0,
        'created_at': createdAt.toIso8601String(),
      };

  /// Deserialize from the local SQLite cache.
  factory ImageAnalysis.fromDbMap(Map<String, dynamic> map) {
    final objectsJson = (map['detected_objects'] as String?) ?? '[]';
    final questionsJson = (map['user_questions'] as String?) ?? '[]';
    return ImageAnalysis(
      id: map['id'] as String,
      thumbnailBase64: map['image_thumbnail'] as String?,
      description: map['description'] as String? ?? '',
      objects: (jsonDecode(objectsJson) as List)
          .map((o) => DetectedObject.fromJson(o as Map<String, dynamic>))
          .toList(),
      detectedText: map['detected_text'] as String?,
      confidenceScore: (map['confidence_score'] as num?)?.toDouble() ?? 0.5,
      confidenceBand: confidenceBandFromString(map['confidence_band'] as String?),
      isDemoMode: (map['is_demo_mode'] as int? ?? 0) == 1,
      questions: (jsonDecode(questionsJson) as List)
          .map((q) => QaPair.fromJson(q as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
