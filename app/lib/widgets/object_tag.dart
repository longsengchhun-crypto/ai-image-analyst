import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/detected_object.dart';
import '../utils/constants.dart';
import 'confidence_badge.dart';

/// A chip representing one detected object, with an inline confidence badge.
class ObjectTag extends StatelessWidget {
  final DetectedObject object;

  const ObjectTag({super.key, required this.object});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(Radii.chip),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.25 : 0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            object.name,
            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: Spacing.sm),
          ConfidenceBadge(band: object.band, compact: true),
        ],
      ),
    );
  }
}
