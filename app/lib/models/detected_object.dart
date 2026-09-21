import '../utils/constants.dart';

/// A single labeled object/entity/feature the AI identified in an image,
/// with a self-reported qualitative confidence band (see AI_DOCUMENTATION.md
/// for why this is a heuristic label rather than a calibrated probability).
class DetectedObject {
  final String name;
  final double confidence; // 0..1, derived from confidenceBand
  final ConfidenceBand band;

  const DetectedObject({
    required this.name,
    required this.confidence,
    required this.band,
  });

  factory DetectedObject.fromJson(Map<String, dynamic> json) {
    return DetectedObject(
      name: json['name'] as String? ?? 'Unknown',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.5,
      band: confidenceBandFromString(json['confidenceBand'] as String?),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'confidence': confidence,
        'confidenceBand': band.name,
      };
}
