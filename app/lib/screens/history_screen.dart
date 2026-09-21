import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/image_analysis.dart';
import '../providers/history_provider.dart';
import '../providers/image_provider.dart';
import '../utils/app_fonts.dart';
import '../utils/constants.dart';
import '../utils/error_messages.dart';
import '../widgets/image_card.dart';
import 'result_screen.dart';

/// History / Gallery screen: past analyses with pull-to-refresh, delete, and
/// clear-all. Backed by [HistoryProvider], which reads local SQLite first
/// (so this never shows a blank loader for previously-synced data) then
/// refreshes from the backend.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HistoryProvider>().loadInitial();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.navHistory),
        actions: [
          Consumer<HistoryProvider>(
            builder: (context, provider, _) => IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: l10n.tooltipClearAllHistory,
              onPressed: provider.items.isEmpty ? null : () => _confirmClearAll(context, provider),
            ),
          ),
        ],
      ),
      body: Consumer<HistoryProvider>(
        builder: (context, provider, _) {
          if (provider.status == HistoryStatus.loading && provider.items.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.status == HistoryStatus.error && provider.items.isEmpty) {
            return _errorState(context, provider);
          }
          if (provider.items.isEmpty) {
            return _emptyState(context);
          }
          return RefreshIndicator(
            onRefresh: provider.refresh,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
              itemCount: provider.items.length,
              itemBuilder: (context, index) {
                final item = provider.items[index];
                return ImageCard(
                  analysis: item,
                  onTap: () => _openDetail(context, item),
                  onDelete: () {
                    HapticFeedback.lightImpact();
                    provider.deleteItem(item.id);
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.photo_library_outlined, size: 48, color: mutedText(context)),
            const SizedBox(height: Spacing.md),
            Text(l10n.emptyHistoryTitle, style: appFont(context, fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: Spacing.xs),
            Text(l10n.emptyHistorySubtitle, style: appFont(context, color: mutedText(context))),
          ],
        ),
      ),
    );
  }

  Widget _errorState(BuildContext context, HistoryProvider provider) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_outlined, size: 48, color: AppColors.danger),
            const SizedBox(height: Spacing.md),
            Text(
              provider.errorCode != null ? localizedError(l10n, provider.errorCode!) : l10n.errorGeneric,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Spacing.md),
            ElevatedButton(onPressed: provider.refresh, child: Text(l10n.btnRetry)),
          ],
        ),
      ),
    );
  }

  void _openDetail(BuildContext context, ImageAnalysis item) {
    // Load the past analysis into the working provider (read-only view: the
    // original file isn't on disk anymore, so the image preview uses the
    // saved thumbnail and the Q&A input is hidden implicitly by there being
    // no fresh file to re-send — asking new questions requires a live image).
    context.read<ImageAnalysisProvider>().loadFromHistory(item);
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ResultScreen()));
  }

  void _confirmClearAll(BuildContext context, HistoryProvider provider) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.dialogClearAllTitle),
        content: Text(l10n.dialogClearAllContent),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(l10n.btnCancel)),
          TextButton(
            onPressed: () {
              HapticFeedback.mediumImpact();
              Navigator.pop(dialogContext);
              provider.clearAll();
            },
            child: Text(l10n.btnClearAll, style: const TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }
}
