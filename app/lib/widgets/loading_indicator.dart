import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../utils/constants.dart';

/// Skeleton loader shown while an image is being analyzed, instead of a bare
/// spinner — mirrors the eventual result card layout so the transition into
/// the real content feels continuous rather than jarring.
class AnalysisSkeleton extends StatelessWidget {
  const AnalysisSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? Colors.grey.shade800 : Colors.grey.shade300;
    final highlight = isDark ? Colors.grey.shade700 : Colors.grey.shade100;

    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      child: Padding(
        padding: const EdgeInsets.all(Spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _bar(width: 160, height: 16),
            const SizedBox(height: Spacing.sm),
            _bar(width: double.infinity, height: 14),
            const SizedBox(height: 6),
            _bar(width: double.infinity, height: 14),
            const SizedBox(height: 6),
            _bar(width: 220, height: 14),
            const SizedBox(height: Spacing.lg),
            _bar(width: 120, height: 16),
            const SizedBox(height: Spacing.sm),
            Wrap(
              spacing: Spacing.sm,
              runSpacing: Spacing.sm,
              children: List.generate(5, (i) => _bar(width: 70 + (i * 10.0), height: 32, radius: 20)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bar({required double width, required double height, double radius = 6}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// Small inline loading row used for buttons ("Analyzing...", "Asking...").
class InlineLoadingLabel extends StatelessWidget {
  final String label;
  const InlineLoadingLabel({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
        ),
        const SizedBox(width: Spacing.sm),
        Text(label),
      ],
    );
  }
}
