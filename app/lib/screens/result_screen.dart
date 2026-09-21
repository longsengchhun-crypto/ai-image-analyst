import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/qa_pair.dart';
import '../providers/image_provider.dart';
import '../utils/app_fonts.dart';
import '../utils/constants.dart';
import '../utils/error_messages.dart';
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
    final l10n = AppLocalizations.of(context)!;
    return Consumer<ImageAnalysisProvider>(
      builder: (context, provider, _) {
        final result = provider.result;
        if (result == null) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.resultAppBarTitle),
            actions: [
              IconButton(
                icon: const Icon(Icons.share_outlined),
                tooltip: l10n.tooltipShare,
                onPressed: () => _shareResult(context, provider),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(Spacing.md),
            children: [
              if (result.isDemoMode) _demoBanner(context),
              if (provider.selectedImageBytes != null)
                _imagePreview(provider)
              else if (result.thumbnailBase64 != null)
                _thumbnailPreview(result.thumbnailBase64!),
              const SizedBox(height: Spacing.md),
              if (result.uncertaintyNote != null) _uncertaintyBanner(context, result.uncertaintyNote!),
              _sectionCard(
                context: context,
                key: 'description',
                title: l10n.sectionDescription,
                trailing: ConfidenceBadge(band: result.confidenceBand),
                child: Text(
                  result.description,
                  style: appFont(context, fontSize: 15, height: 1.5),
                ),
              ),
              const SizedBox(height: Spacing.md),
              _sectionCard(
                context: context,
                key: 'objects',
                title: l10n.sectionObjects,
                child: result.objects.isEmpty
                    ? Text(l10n.noObjectsFound, style: appFont(context, color: Colors.grey.shade600))
                    : Wrap(
                        spacing: Spacing.sm,
                        runSpacing: Spacing.sm,
                        children: result.objects.map((o) => ObjectTag(object: o)).toList(),
                      ),
              ),
              if (result.detectedText != null && result.detectedText!.trim().isNotEmpty) ...[
                const SizedBox(height: Spacing.md),
                _sectionCard(
                  context: context,
                  key: 'text',
                  title: l10n.sectionOcr,
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
                _pastQuestionsReadOnly(context, result.questions),
              const SizedBox(height: Spacing.xxl),
            ],
          ),
        );
      },
    );
  }

  Widget _demoBanner(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
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
              l10n.demoBannerText,
              style: appFont(context, fontSize: 12, color: Colors.grey.shade800),
            ),
          ),
        ],
      ),
    );
  }

  Widget _uncertaintyBanner(BuildContext context, String note) => Container(
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
              child: Text(note, style: appFont(context, fontSize: 12.5, color: Colors.grey.shade800)),
            ),
          ],
        ),
      );

  Widget _imagePreview(ImageAnalysisProvider provider) {
    return Hero(
      tag: 'active-image',
      // PhotoView owns its own gesture/scale controller, which doesn't need
      // to exist mid-flight — swap in a plain static image for the animation
      // itself so PhotoView only ever mounts once the hero lands.
      flightShuttleBuilder: (flightContext, animation, direction, fromContext, toContext) => ClipRRect(
        borderRadius: BorderRadius.circular(Radii.card),
        child: Image.memory(provider.selectedImageBytes!, fit: BoxFit.cover),
      ),
      child: ClipRRect(
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

  Widget _sectionCard({
    required BuildContext context,
    required String key,
    required String title,
    required Widget child,
    Widget? trailing,
  }) {
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
                    child: Text(title, style: appFont(context, fontSize: 15, fontWeight: FontWeight.w700)),
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
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.askAboutImage, style: appFont(context, fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: Spacing.sm),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _questionController,
                    decoration: InputDecoration(
                      labelText: l10n.askAboutImage,
                      hintText: l10n.askHint,
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _submitQuestion(provider),
                  ),
                ),
                const SizedBox(width: Spacing.sm),
                SizedBox(
                  height: 48,
                  child: Tooltip(
                    message: l10n.tooltipSendQuestion,
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
              ...history.reversed.map((qa) => _qaTile(context, qa)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _pastQuestionsReadOnly(BuildContext context, List<QaPair> history) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.previousQuestions, style: appFont(context, fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(
              l10n.previousQuestionsNote,
              style: appFont(context, fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: Spacing.sm),
            const Divider(height: 1),
            const SizedBox(height: Spacing.sm),
            ...history.reversed.map((qa) => _qaTile(context, qa)),
          ],
        ),
      ),
    );
  }

  Widget _qaTile(BuildContext context, QaPair qa) {
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
                child: Text(qa.question, style: appFont(context, fontSize: 13.5, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(qa.answer, style: appFont(context, fontSize: 13.5, height: 1.4)),
                const SizedBox(height: 4),
                ConfidenceBadge(band: qa.band, compact: true),
                if (qa.uncertaintyNote != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      qa.uncertaintyNote!,
                      style: appFont(context, fontSize: 11.5, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
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
    final l10n = AppLocalizations.of(context)!;
    final question = _questionController.text;
    if (!Validators.isQuestionValid(question)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.questionTooShort)),
      );
      return;
    }
    _questionController.clear();
    FocusScope.of(context).unfocus();
    await provider.askQuestion(question);
    if (provider.errorCode != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizedError(l10n, provider.errorCode!))),
      );
    }
  }

  Future<void> _shareResult(BuildContext context, ImageAnalysisProvider provider) async {
    final l10n = AppLocalizations.of(context)!;
    final result = provider.result!;
    final buffer = StringBuffer()
      ..writeln(l10n.shareHeader)
      ..writeln('==================')
      ..writeln(result.description)
      ..writeln()
      ..writeln(l10n.shareDetectedObjectsHeader);
    for (final o in result.objects) {
      buffer.writeln(l10n.shareObjectLine(o.name, confidenceBandShortLabel(l10n, o.band)));
    }
    if (result.detectedText != null) {
      buffer.writeln();
      buffer.writeln(l10n.shareTextFoundHeader);
      buffer.writeln(result.detectedText);
    }
    if (result.questions.isNotEmpty) {
      buffer.writeln();
      buffer.writeln(l10n.shareQaHeader);
      for (final qa in result.questions) {
        buffer.writeln('Q: ${qa.question}');
        buffer.writeln('A: ${qa.answer}');
      }
    }
    await SharePlus.instance.share(
      ShareParams(text: buffer.toString(), subject: l10n.shareHeader),
    );
  }
}
