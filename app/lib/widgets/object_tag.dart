import 'package:flutter/material.dart';

import '../models/detected_object.dart';
import '../utils/app_fonts.dart';
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
        // Bordered, not shadowed — matches ConfidenceBadge and the rest of
        // the app's flat, elevation-0 card style instead of introducing a
        // one-off drop shadow for this component alone.
        border: Border.all(color: subtleBorder(context)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            object.name,
            style: appFont(context, fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: Spacing.sm),
          ConfidenceBadge(band: object.band, compact: true),
        ],
      ),
    );
  }
}
