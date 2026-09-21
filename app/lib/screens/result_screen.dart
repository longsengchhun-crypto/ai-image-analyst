import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:photo_view/photo_view.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/qa_pair.dart';
import '../providers/image_provider.dart';
import '../utils/constants.dart';
import '../utils/validators.dart';
import '../widgets/confidence_badge.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/object_tag.dart';

/// Full analysis result: image preview (pinch-to-zoom), description card,
/// detected objects, OCR text if any, and the ask-a-question flow with a
/// running Q&A history. Reused both right after a fresh analysis and when
/// opening a past item from History.
class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  final _questionController = TextEditingController();
  final _expanded = <String, bool>{'description': true, 'objects': true, 'text': true, 'qa': true};

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ImageAnalysisProvider>(
      builder: (context, provider, _) {
        final result = provider.result;
        if (result == null) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Analysis'),
            actions: [
              IconButton(
                icon: const Icon(Icons.share_outlined),
                tooltip: 'Share',
                onPressed: () => _shareResult(context, provider),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(Spacing.md),
            children: [
              if (result.isDemoMode) _demoBanner(),
              if (provider.selectedImageBytes != null)
                _imagePreview(provider)
              else if (result.thumbnailBase64 != null)
                _thumbnailPreview(result.thumbnailBase64!),
              const SizedBox(height: Spacing.md),
              if (result.uncertaintyNote != null) _uncertaintyBanner(result.uncertaintyNote!),
              _sectionCard(
                key: 'description',
                title: 'Description',
                trailing: ConfidenceBadge(band: result.confidenceBand),
                child: Text(
                  result.description,
                  style: GoogleFonts.inter(fontSize: 15, height: 1.5),
                ),
              ),
              const SizedBox(height: Spacing.md),
              _sectionCard(
                key: 'objects',
                title: 'Detected objects & features',
                child: result.objects.isEmpty
                    ? Text('No distinct objects were confidently identified.',
                        style: GoogleFonts.inter(color: Colors.grey.shade600))
                    : Wrap(
                        spacing: Spacing.sm,
                        runSpacing: Spacing.sm,
                        children: result.objects.map((o) => ObjectTag(object: o)).toList(),
                      ),
              ),
              if (result.detectedText != null && result.detectedText!.trim().isNotEmpty) ...[
                const SizedBox(height: Spacing.md),
                _sectionCard(
                  key: 'text',
                  title: 'Text found in image (OCR)',
                  child: SelectableText(
                    result.detectedText!,
                    style: const TextStyle(fontSize: 14, fontFamily: 'monospace', height: 1.5),
                  ),
                ),
              ],
              const SizedBox(height: Spacing.md),
              if (provider.selectedImageBytes != null)
                _questionSection(context, provider, result.questions)
              else if (result.questions.isNotEmpty)
                _pastQuestionsReadOnly(result.questions),
              const SizedBox(height: Spacing.xxl),
            ],
          ),
        );
      },
    );
  }

  Widget _demoBanner() => Container(
        margin: const EdgeInsets.only(bottom: Spacing.md),
        padding: const EdgeInsets.all(Spacing.sm),
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(Radii.button),
        ),
        child: Row(
          children: [
            const Icon(Icons.science_outlined, size: 18, color: AppColors.warning),
            const SizedBox(width: Spacing.sm),
            Expanded(
              child: Text(
                'Demo mode: this is placeholder analysis. Configure GEMINI_API_KEY (free) or '
                'ANTHROPIC_API_KEY on the backend for live results.',
                style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade800),
              ),
            ),
          ],
        ),
      );

  Widget _uncertaintyBanner(String note) => Container(
        margin: const EdgeInsets.only(bottom: Spacing.md),
        padding: const EdgeInsets.all(Spacing.sm),
        decoration: BoxDecoration(
          color: AppColors.danger.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(Radii.button),
          border: Border.all(color: AppColors.danger.withValues(alpha: 0.25)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline, size: 18, color: AppColors.danger),
            const SizedBox(width: Spacing.sm),
            Expanded(
              child: Text(note, style: GoogleFonts.inter(fontSize: 12.5, color: Colors.grey.shade800)),
            ),
          ],
        ),
      );

  Widget _imagePreview(ImageAnalysisProvider provider) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(Radii.card),
      child: SizedBox(
        height: 260,
        child: PhotoView(
          imageProvider: MemoryImage(provider.selectedImageBytes!),
          minScale: PhotoViewComputedScale.contained,
          maxScale: PhotoViewComputedScale.covered * 3,
          backgroundDecoration: const BoxDecoration(color: Colors.black12),
        ),
      ),
    );
  }

  Widget _thumbnailPreview(String dataUri) {
    final commaIdx = dataUri.indexOf(',');
    final base64Part = commaIdx >= 0 ? dataUri.substring(commaIdx + 1) : dataUri;
    Uint8List? bytes;
    try {
      bytes = base64Decode(base64Part);
    } catch (_) {
      bytes = null;
    }
    if (bytes == null) return const SizedBox.shrink();
    return ClipRRect(
      borderRadius: BorderRadius.circular(Radii.card),
      child: Image.memory(bytes, height: 220, fit: BoxFit.cover, width: double.infinity),
    );
  }

  Widget _sectionCard({required String key, required String title, required Widget child, Widget? trailing}) {
    final isOpen = _expanded[key] ?? true;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () => setState(() => _expanded[key] = !isOpen),
              child: Row(
                children: [
                  Expanded(
                    child: Text(title, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700)),
                  ),
                  if (trailing != null) ...[trailing, const SizedBox(width: Spacing.sm)],
                  AnimatedRotation(
                    turns: isOpen ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.expand_more),
                  ),
                ],
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
              child: isOpen
                  ? Padding(padding: const EdgeInsets.only(top: Spacing.sm), child: child)
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _questionSection(BuildContext context, ImageAnalysisProvider provider, List<QaPair> history) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ask about this image', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: Spacing.sm),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _questionController,
                    decoration: const InputDecoration(
                      labelText: 'Ask about this image',
                      hintText: 'e.g. How many people are in this image?',
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _submitQuestion(provider),
                  ),
                ),
                const SizedBox(width: Spacing.sm),
                SizedBox(
                  height: 48,
                  child: Tooltip(
                    message: 'Send question',
                    child: ElevatedButton(
                      onPressed: provider.isAskingQuestion ? null : () => _submitQuestion(provider),
                      child: provider.isAskingQuestion
                          ? const InlineLoadingLabel(label: '')
                          : const Icon(Icons.send_rounded, size: 18),
                    ),
                  ),
                ),
              ],
            ),
            if (history.isNotEmpty) ...[
              const SizedBox(height: Spacing.md),
              const Divider(height: 1),
              const SizedBox(height: Spacing.sm),
              ...history.reversed.map(_qaTile),
            ],
          ],
        ),
      ),
    );
  }

  Widget _pastQuestionsReadOnly(List<QaPair> history) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Previous questions', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(
              'The original image is no longer available, so new questions can\'t be asked '
              'from history — analyze the photo again to ask more.',
              style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: Spacing.sm),
            const Divider(height: 1),
            const SizedBox(height: Spacing.sm),
            ...history.reversed.map(_qaTile),
          ],
        ),
      ),
    );
  }

  Widget _qaTile(QaPair qa) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.help_outline, size: 16, color: AppColors.primary),
              const SizedBox(width: Spacing.xs),
              Expanded(
                child: Text(qa.question, style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(qa.answer, style: GoogleFonts.inter(fontSize: 13.5, height: 1.4)),
                const SizedBox(height: 4),
                ConfidenceBadge(band: qa.band, compact: true),
                if (qa.uncertaintyNote != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      qa.uncertaintyNote!,
                      style: GoogleFonts.inter(fontSize: 11.5, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitQuestion(ImageAnalysisProvider provider) async {
    final question = _questionController.text;
    if (!Validators.isQuestionValid(question)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a more specific question (3+ characters).')),
      );
      return;
    }
    _questionController.clear();
    FocusScope.of(context).unfocus();
    await provider.askQuestion(question);
    if (provider.errorMessage != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(provider.errorMessage!)));
    }
  }

  Future<void> _shareResult(BuildContext context, ImageAnalysisProvider provider) async {
    final result = provider.result!;
    final buffer = StringBuffer()
      ..writeln('AI Image Analysis')
      ..writeln('==================')
      ..writeln(result.description)
      ..writeln()
      ..writeln('Detected objects:');
    for (final o in result.objects) {
      buffer.writeln('- ${o.name} (${o.band.name} confidence)');
    }
    if (result.detectedText != null) {
      buffer.writeln();
      buffer.writeln('Text found in image:');
      buffer.writeln(result.detectedText);
    }
    if (result.questions.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('Questions & answers:');
      for (final qa in result.questions) {
        buffer.writeln('Q: ${qa.question}');
        buffer.writeln('A: ${qa.answer}');
      }
    }
    await SharePlus.instance.share(
      ShareParams(text: buffer.toString(), subject: 'AI Image Analysis'),
    );
  }
}
