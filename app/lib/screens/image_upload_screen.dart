import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../l10n/generated/app_localizations.dart';
import '../providers/image_provider.dart';
import '../utils/app_fonts.dart';
import '../utils/constants.dart';
import '../utils/error_messages.dart';
import '../widgets/loading_indicator.dart';
import 'result_screen.dart';

/// Home / Image Upload screen — the app's primary entry point.
/// Walks through: initial guidance -> pick image -> preview -> analyze ->
/// (on success) push to ResultScreen. Loading and error states are shown
/// inline before we ever navigate away.
class ImageUploadScreen extends StatelessWidget {
  const ImageUploadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.appTitle)),
      body: Consumer<ImageAnalysisProvider>(
        builder: (context, provider, _) {
          switch (provider.status) {
            case AnalysisStatus.initial:
              return _InitialState(onCamera: provider.pickFromCamera, onGallery: provider.pickFromGallery);
            case AnalysisStatus.imageSelected:
              return _PreviewState(provider: provider, onAnalyze: () => _analyze(context, provider));
            case AnalysisStatus.loading:
              return _LoadingState(provider: provider);
            case AnalysisStatus.error:
              return _ErrorState(provider: provider, onRetry: () => _analyze(context, provider));
            case AnalysisStatus.success:
              // Transient: the button handler below navigates away and then
              // resets, so this case is essentially never rendered.
              return const _LoadingState(provider: null);
          }
        },
      ),
      floatingActionButton: Consumer<ImageAnalysisProvider>(
        builder: (context, provider, _) {
          if (provider.status != AnalysisStatus.initial) {
            return const SizedBox.shrink();
          }
          return FloatingActionButton.extended(
            onPressed: () => _showSourceSheet(context, provider),
            icon: const Icon(Icons.add_a_photo_outlined),
            label: Text(l10n.fabNewAnalysis),
          );
        },
      ),
    );
  }

  static Future<void> _analyze(BuildContext context, ImageAnalysisProvider provider) async {
    HapticFeedback.lightImpact();
    await provider.submitForAnalysis();
    if (!context.mounted) return;
    if (provider.status == AnalysisStatus.success) {
      HapticFeedback.mediumImpact();
      await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ResultScreen()));
      if (context.mounted) provider.reset();
    }
  }

  static void _showSourceSheet(BuildContext context, ImageAnalysisProvider provider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.sheet)),
      ),
      builder: (sheetContext) => _SourceSheet(provider: provider),
    );
  }
}

class _SourceSheet extends StatelessWidget {
  final ImageAnalysisProvider provider;
  const _SourceSheet({required this.provider});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.sheetAddPhoto, style: appFont(context, fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: Spacing.md),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined, color: AppColors.primary),
              title: Text(l10n.sheetTakePhoto),
              onTap: () {
                Navigator.pop(context);
                provider.pickFromCamera();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: AppColors.primary),
              title: Text(l10n.sheetChooseGallery),
              onTap: () {
                Navigator.pop(context);
                provider.pickFromGallery();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _InitialState extends StatelessWidget {
  final VoidCallback onCamera;
  final VoidCallback onGallery;
  const _InitialState({required this.onCamera, required this.onGallery});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // A SingleChildScrollView + ConstrainedBox (rather than a bare Column
    // inside a Center) keeps this guidance screen from overflowing on short
    // viewports (small phones in landscape, or a resized desktop/web window)
    // while still centering the content vertically when there's room to.
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.all(Spacing.xl),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight - Spacing.xl * 2),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.visibility_outlined, size: 44, color: AppColors.primary),
              ),
              const SizedBox(height: Spacing.lg),
              Text(
                l10n.initialHeadline,
                textAlign: TextAlign.center,
                style: appFont(context, fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: Spacing.sm),
              Text(
                l10n.initialSubtitle,
                textAlign: TextAlign.center,
                style: appFont(context, fontSize: 14, color: mutedText(context), height: 1.4),
              ),
              const SizedBox(height: Spacing.xl),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onCamera,
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: Text(l10n.sheetTakePhoto),
                ),
              ),
              const SizedBox(height: Spacing.sm),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onGallery,
                  icon: const Icon(Icons.photo_library_outlined),
                  label: Text(l10n.sheetChooseGallery),
                ),
              ),
              const SizedBox(height: Spacing.lg),
              Text(
                l10n.consentNotice,
                textAlign: TextAlign.center,
                style: appFont(context, fontSize: 11, color: mutedText(context)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreviewState extends StatelessWidget {
  final ImageAnalysisProvider provider;
  final VoidCallback onAnalyze;
  const _PreviewState({required this.provider, required this.onAnalyze});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(Spacing.md),
            child: Hero(
              tag: 'active-image',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(Radii.card),
                child: Image.memory(provider.selectedImageBytes!, fit: BoxFit.cover, width: double.infinity),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
          child: _ImageInfoLine(bytes: provider.selectedImageBytes!),
        ),
        const SizedBox(height: Spacing.sm),
        Padding(
          padding: const EdgeInsets.fromLTRB(Spacing.md, 0, Spacing.md, Spacing.lg),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: provider.reset,
                  child: Text(l10n.previewRetake),
                ),
              ),
              const SizedBox(width: Spacing.md),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: onAnalyze,
                  icon: const Icon(Icons.auto_awesome_outlined),
                  label: Text(l10n.previewAnalyze),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Shows the selected image's real dimensions and file size — decoded from
/// the actual bytes being sent, not invented — so the user knows what
/// they're about to submit before tapping Analyze.
class _ImageInfoLine extends StatelessWidget {
  final Uint8List bytes;
  const _ImageInfoLine({required this.bytes});

  static Future<ui.Image> _decode(Uint8List bytes) {
    final completer = Completer<ui.Image>();
    ui.decodeImageFromList(bytes, completer.complete);
    return completer.future;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sizeKb = (bytes.lengthInBytes / 1024).round();
    return FutureBuilder<ui.Image>(
      future: _decode(bytes),
      builder: (context, snapshot) {
        final dims = snapshot.data;
        final parts = <String>[
          if (dims != null) l10n.imageDetailsDimensions(dims.width, dims.height),
          l10n.imageDetailsSize(sizeKb),
        ];
        return Row(
          children: [
            Icon(Icons.image_outlined, size: 14, color: mutedText(context)),
            const SizedBox(width: Spacing.xs),
            Text(
              parts.join('  ·  '),
              style: appFont(context, fontSize: 12, color: mutedText(context)),
            ),
          ],
        );
      },
    );
  }
}

class _LoadingState extends StatelessWidget {
  final ImageAnalysisProvider? provider;
  const _LoadingState({required this.provider});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        if (provider?.selectedImageBytes != null)
          Padding(
            padding: const EdgeInsets.all(Spacing.md),
            child: Hero(
              tag: 'active-image',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(Radii.card),
                child: Image.memory(provider!.selectedImageBytes!, height: 220, fit: BoxFit.cover, width: double.infinity),
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent),
                  ),
                  const SizedBox(width: Spacing.sm),
                  Text(l10n.loadingAnalyzing, style: appFont(context, fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 2),
              Padding(
                padding: const EdgeInsets.only(left: 26),
                child: Text(
                  l10n.loadingAnalyzingSubtitle,
                  style: appFont(context, fontSize: 12.5, color: mutedText(context)),
                ),
              ),
            ],
          ),
        ),
        const Expanded(child: AnalysisSkeleton()),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  final ImageAnalysisProvider provider;
  final VoidCallback onRetry;
  const _ErrorState({required this.provider, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.danger),
            const SizedBox(height: Spacing.md),
            Text(
              provider.selectedImageBytes == null ? l10n.errorImageInvalidTitle : l10n.errorAnalyzeFailedTitle,
              style: appFont(context, fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: Spacing.sm),
            Text(
              provider.errorCode != null ? localizedError(l10n, provider.errorCode!) : l10n.errorGeneric,
              textAlign: TextAlign.center,
              style: appFont(context, fontSize: 14, color: mutedText(context)),
            ),
            const SizedBox(height: Spacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(onPressed: provider.reset, child: Text(l10n.btnStartOver)),
                // A validation failure (bad/empty image) has no image to
                // retry analyzing — only offer "Try again" once one is picked.
                if (provider.selectedImageBytes != null) ...[
                  const SizedBox(width: Spacing.md),
                  ElevatedButton(onPressed: onRetry, child: Text(l10n.btnTryAgain)),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
