import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../utils/constants.dart';

/// Small pill showing a qualitative confidence level, color-coded so users
/// can scan results at a glance (green/amber/red).
class ConfidenceBadge extends StatelessWidget {
  final ConfidenceBand band;
  final bool compact;

  const ConfidenceBadge({super.key, required this.band, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final color = confidenceBandColor(band);
    final label = compact ? confidenceBandShortLabel(l10n, band) : confidenceBandLabel(l10n, band);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(Radii.chip),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(right: 6),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: compact ? 11 : 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
