import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/image_analysis.dart';
import '../providers/history_provider.dart';
import '../providers/image_provider.dart';
import '../utils/constants.dart';
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: [
          Consumer<HistoryProvider>(
            builder: (context, provider, _) => IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: 'Clear all',
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
            return _errorState(provider);
          }
          if (provider.items.isEmpty) {
            return _emptyState();
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
                  onDelete: () => provider.deleteItem(item.id),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _emptyState() => Center(
        child: Padding(
          padding: const EdgeInsets.all(Spacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.photo_library_outlined, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: Spacing.md),
              Text('No analyses yet', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: Spacing.xs),
              Text(
                'Photos you analyze will show up here.',
                style: GoogleFonts.inter(color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );

  Widget _errorState(HistoryProvider provider) => Center(
        child: Padding(
          padding: const EdgeInsets.all(Spacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_outlined, size: 48, color: AppColors.danger),
              const SizedBox(height: Spacing.md),
              Text(provider.errorMessage ?? 'Could not load history.', textAlign: TextAlign.center),
              const SizedBox(height: Spacing.md),
              ElevatedButton(onPressed: provider.refresh, child: const Text('Retry')),
            ],
          ),
        ),
      );

  void _openDetail(BuildContext context, ImageAnalysis item) {
    // Load the past analysis into the working provider (read-only view: the
    // original file isn't on disk anymore, so the image preview uses the
    // saved thumbnail and the Q&A input is hidden implicitly by there being
    // no fresh file to re-send — asking new questions requires a live image).
    context.read<ImageAnalysisProvider>().loadFromHistory(item);
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ResultScreen()));
  }

  void _confirmClearAll(BuildContext context, HistoryProvider provider) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Clear all history?'),
        content: const Text('This deletes every saved analysis on this device and on the server. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              provider.clearAll();
            },
            child: const Text('Clear all', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }
}
