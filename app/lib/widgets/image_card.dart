import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/image_analysis.dart';
import '../utils/app_fonts.dart';
import '../utils/constants.dart';
import 'confidence_badge.dart';

/// Card representing one history entry: thumbnail + description snippet +
/// timestamp + confidence badge. Used in the History screen list.
class ImageCard extends StatelessWidget {
  final ImageAnalysis analysis;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const ImageCard({
    super.key,
    required this.analysis,
    required this.onTap,
    this.onDelete,
  });

  Uint8List? get _thumbnailBytes {
    final raw = analysis.thumbnailBase64;
    if (raw == null) return null;
    final commaIdx = raw.indexOf(',');
    final base64Part = commaIdx >= 0 ? raw.substring(commaIdx + 1) : raw;
    try {
      return base64Decode(base64Part);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bytes = _thumbnailBytes;

    return Dismissible(
      key: ValueKey(analysis.id),
      direction: onDelete == null ? DismissDirection.none : DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: Spacing.lg),
        decoration: BoxDecoration(
          color: AppColors.danger,
          borderRadius: BorderRadius.circular(Radii.card),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) => onDelete?.call(),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: Spacing.xs),
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.card)),
        child: InkWell(
          borderRadius: BorderRadius.circular(Radii.card),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(Spacing.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(Radii.card - 4),
                  child: bytes != null
                      ? Image.memory(bytes, width: 64, height: 64, fit: BoxFit.cover)
                      : Container(
                          width: 64,
                          height: 64,
                          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                          child: Icon(Icons.image_outlined, color: mutedText(context)),
                        ),
                ),
                const SizedBox(width: Spacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        analysis.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: appFont(context, fontSize: 14, fontWeight: FontWeight.w500, height: 1.3),
                      ),
                      const SizedBox(height: Spacing.xs),
                      Row(
                        children: [
                          ConfidenceBadge(band: analysis.confidenceBand, compact: true),
                          const SizedBox(width: Spacing.sm),
                          Text(
                            DateFormat('MMM d, h:mm a', Localizations.localeOf(context).toString())
                                .format(analysis.createdAt),
                            style: appFont(context, fontSize: 11, color: mutedText(context)),
                          ),
                          if (analysis.questions.isNotEmpty) ...[
                            const SizedBox(width: Spacing.sm),
                            Icon(Icons.question_answer_outlined, size: 12, color: mutedText(context)),
                            const SizedBox(width: 2),
                            Text('${analysis.questions.length}',
                                style: appFont(context, fontSize: 11, color: mutedText(context))),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
