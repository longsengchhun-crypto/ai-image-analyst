import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/image_provider.dart';
import '../utils/constants.dart';
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
    return Scaffold(
      appBar: AppBar(title: const Text('AI Image Analyst')),
      body: Consumer<ImageAnalysisProvider>(
        builder: (context, provider, _) {
          switch (provider.status) {
            case AnalysisStatus.initial:
              return _InitialState(
                  onCamera: provider.pickFromCamera,
                  onGallery: provider.pickFromGallery);
            case AnalysisStatus.imageSelected:
              return _PreviewState(
                  provider: provider,
                  onAnalyze: () => _analyze(context, provider));
            case AnalysisStatus.loading:
              return _LoadingState(provider: provider);
            case AnalysisStatus.error:
              return _ErrorState(
                  provider: provider,
                  onRetry: () => _analyze(context, provider));
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
            label: const Text('New analysis'),
          );
        },
      ),
    );
  }

  static Future<void> _analyze(
      BuildContext context, ImageAnalysisProvider provider) async {
    await provider.submitForAnalysis();
    if (!context.mounted) return;
    if (provider.status == AnalysisStatus.success) {
      await Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const ResultScreen()));
      if (context.mounted) provider.reset();
    }
  }

  static void _showSourceSheet(
      BuildContext context, ImageAnalysisProvider provider) {
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
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Add a photo',
                style: GoogleFonts.inter(
                    fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: Spacing.md),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined,
                  color: AppColors.primary),
              title: const Text('Take a photo'),
              onTap: () {
                Navigator.pop(context);
                provider.pickFromCamera();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined,
                  color: AppColors.primary),
              title: const Text('Choose from gallery'),
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
    // A SingleChildScrollView + ConstrainedBox (rather than a bare Column
    // inside a Center) keeps this guidance screen from overflowing on short
    // viewports (small phones in landscape, or a resized desktop/web window)
    // while still centering the content vertically when there's room to.
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.all(Spacing.xl),
        child: ConstrainedBox(
          constraints:
              BoxConstraints(minHeight: constraints.maxHeight - Spacing.xl * 2),
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
                child: const Icon(Icons.visibility_outlined,
                    size: 44, color: AppColors.primary),
              ),
              const SizedBox(height: Spacing.lg),
              Text(
                'Understand any image instantly',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                    fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: Spacing.sm),
              Text(
                'Capture or upload a photo to get an AI description, detected '
                'objects, and answers to your questions about it.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                    fontSize: 14, color: Colors.grey.shade600, height: 1.4),
              ),
              const SizedBox(height: Spacing.xl),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onCamera,
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: const Text('Take a photo'),
                ),
              ),
              const SizedBox(height: Spacing.sm),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onGallery,
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Choose from gallery'),
                ),
              ),
              const SizedBox(height: Spacing.lg),
              Text(
                'By continuing, images you submit are sent to our server and a '
                'third-party AI service for analysis. See Settings for privacy details.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 11, color: Colors.grey),
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
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(Spacing.md),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(Radii.card),
              child: Image.memory(provider.selectedImageBytes!,
                  fit: BoxFit.cover, width: double.infinity),
            ),
          ),
        ),
        Padding(
          padding:
              const EdgeInsets.fromLTRB(Spacing.md, 0, Spacing.md, Spacing.lg),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: provider.reset,
                  child: const Text('Retake'),
                ),
              ),
              const SizedBox(width: Spacing.md),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: onAnalyze,
                  icon: const Icon(Icons.auto_awesome_outlined),
                  label: const Text('Analyze image'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LoadingState extends StatelessWidget {
  final ImageAnalysisProvider? provider;
  const _LoadingState({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (provider?.selectedImageBytes != null)
          Padding(
            padding: const EdgeInsets.all(Spacing.md),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(Radii.card),
              child: Image.memory(provider!.selectedImageBytes!,
                  height: 220, fit: BoxFit.cover, width: double.infinity),
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
          child: Row(
            children: [
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.accent),
              ),
              const SizedBox(width: Spacing.sm),
              Text('Analyzing your image...',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.danger),
            const SizedBox(height: Spacing.md),
            Text(
              provider.selectedImageBytes == null
                  ? 'That image can\'t be used'
                  : 'We couldn\'t analyze that image',
              style:
                  GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: Spacing.sm),
            Text(
              provider.errorMessage ?? 'Please try again.',
              textAlign: TextAlign.center,
              style:
                  GoogleFonts.inter(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: Spacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(
                    onPressed: provider.reset, child: const Text('Start over')),
                // A validation failure (bad/empty image) has no image to
                // retry analyzing — only offer "Try again" once one is picked.
                if (provider.selectedImageBytes != null) ...[
                  const SizedBox(width: Spacing.md),
                  ElevatedButton(
                      onPressed: onRetry, child: const Text('Try again')),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
