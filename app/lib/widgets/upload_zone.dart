import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../utils/app_fonts.dart';
import '../utils/constants.dart';

/// The primary upload surface — visually the center of the Analyze screen,
/// not a small button below a headline. Tapping anywhere in the zone opens
/// the gallery/file picker (the "choose a file" path); a distinct camera
/// action sits below it for the mobile-specific capture flow.
///
/// Real OS-level drag-and-drop-from-desktop is not implemented — that
/// requires either a native Flutter web JS-interop package or a platform
/// channel, both out of scope here — but the hover state below is real and
/// responds to genuine pointer-enter/exit events, not a decoration.
class UploadZone extends StatefulWidget {
  final VoidCallback onBrowse;
  final VoidCallback onCamera;

  const UploadZone({super.key, required this.onBrowse, required this.onCamera});

  @override
  State<UploadZone> createState() => _UploadZoneState();
}

class _UploadZoneState extends State<UploadZone> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        MouseRegion(
          onEnter: (_) => setState(() => _hovering = true),
          onExit: (_) => setState(() => _hovering = false),
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: widget.onBrowse,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOut,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: Spacing.xxl, horizontal: Spacing.lg),
              decoration: BoxDecoration(
                color: _hovering
                    ? AppColors.primarySoft.withValues(alpha: isDark ? 0.12 : 1)
                    : (isDark ? AppColors.cardDark : AppColors.cardLight),
                borderRadius: BorderRadius.circular(Radii.card),
              ),
              child: CustomPaint(
                painter: _DashedBorderPainter(
                  color: _hovering ? AppColors.primary : subtleBorder(context),
                  strokeWidth: _hovering ? 1.6 : 1.2,
                  radius: Radii.card,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft.withValues(alpha: isDark ? 0.16 : 1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.add_photo_alternate_outlined,
                        size: 26,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: Spacing.md),
                    Text(
                      l10n.uploadZoneTitle,
                      textAlign: TextAlign.center,
                      style: appFont(context, fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: Spacing.xxs),
                    Text(
                      l10n.uploadZoneSubtitle,
                      textAlign: TextAlign.center,
                      style: appFont(context, fontSize: 13.5, color: mutedText(context)),
                    ),
                    const SizedBox(height: Spacing.sm),
                    Text(
                      l10n.uploadZoneFormats,
                      textAlign: TextAlign.center,
                      style: appFont(
                        context,
                        fontSize: 11.5,
                        color: mutedText(context),
                        letterSpacing: 0.4,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: Spacing.sm),
        TextButton.icon(
          onPressed: widget.onCamera,
          icon: const Icon(Icons.photo_camera_outlined, size: 18),
          label: Text(l10n.sheetTakePhoto),
        ),
      ],
    );
  }
}

/// Simple dashed rounded-rect border — Flutter has no built-in dashed
/// border, and this is the one visual detail that actually signals "drop
/// zone" at a glance instead of just looking like an empty card.
class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double radius;
  static const double _dashWidth = 6;
  static const double _dashGap = 5;

  _DashedBorderPainter({required this.color, required this.strokeWidth, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(strokeWidth / 2, strokeWidth / 2, size.width - strokeWidth, size.height - strokeWidth),
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      double distance = 0;
      while (distance < metric.length) {
        final next = distance + _dashWidth;
        canvas.drawPath(metric.extractPath(distance, next.clamp(0, metric.length)), paint);
        distance = next + _dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth || oldDelegate.radius != radius;
}
