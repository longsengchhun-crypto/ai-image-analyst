import '../utils/constants.dart';

/// One question the user asked about an image, and the AI's grounded answer.
class QaPair {
  final String question;
  final String answer;
  final ConfidenceBand band;
  final String? uncertaintyNote;
  final DateTime askedAt;

  const QaPair({
    required this.question,
    required this.answer,
    required this.band,
    required this.askedAt,
    this.uncertaintyNote,
  });

  factory QaPair.fromJson(Map<String, dynamic> json) {
    return QaPair(
      question: json['question'] as String? ?? '',
      answer: json['answer'] as String? ?? '',
      band: confidenceBandFromString(json['confidenceBand'] as String?),
      uncertaintyNote: json['uncertaintyNote'] as String?,
      askedAt: DateTime.tryParse(json['askedAt'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'question': question,
        'answer': answer,
        'confidenceBand': band.name,
        'uncertaintyNote': uncertaintyNote,
        'askedAt': askedAt.toIso8601String(),
      };
}
