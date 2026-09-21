import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/history_provider.dart';
import '../utils/constants.dart';

/// Settings / API Management screen: shows the configured backend endpoint,
/// privacy/consent information, dark-mode toggle, and destructive actions
/// (clear history). No third-party API keys are ever shown here — those
/// live only on the backend server.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(Spacing.md),
        children: [
          _sectionHeader('Connection'),
          _infoTile(
            icon: Icons.dns_outlined,
            title: 'Backend API',
            subtitle: AppConfig.apiBaseUrl,
          ),
          _infoTile(
            icon: Icons.security_outlined,
            title: 'AI processing',
            subtitle: 'Images are analyzed by a third-party AI vision service, called '
                'only through our backend. Your API keys are never stored on this device.',
          ),
          const SizedBox(height: Spacing.lg),
          _sectionHeader('Privacy'),
          _infoTile(
            icon: Icons.privacy_tip_outlined,
            title: 'What we store',
            subtitle: 'We keep a small thumbnail, the AI-generated description, detected '
                'objects, and your questions — not the original full-resolution photo.',
          ),
          _infoTile(
            icon: Icons.groups_outlined,
            title: 'Images with people',
            subtitle: 'The AI is instructed to describe people factually (count, activity) '
                'and never attempt facial identification or biometric inference.',
          ),
          const SizedBox(height: Spacing.lg),
          _sectionHeader('Data'),
          Consumer<HistoryProvider>(
            builder: (context, provider, _) => ListTile(
              leading: const Icon(Icons.delete_outline, color: AppColors.danger),
              title: const Text('Clear all history'),
              subtitle: const Text('Removes every saved analysis from this device and the server.'),
              onTap: provider.items.isEmpty ? null : () => _confirmClear(context, provider),
            ),
          ),
          const SizedBox(height: Spacing.lg),
          _sectionHeader('About'),
          const _InfoTile(
            icon: Icons.info_outline,
            title: 'AI Image Analyst',
            subtitle: 'v1.0.0 — description, object detection, and visual Q&A powered by '
                'Claude Vision, with a documented demo mode for offline development.',
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) => Padding(
        padding: const EdgeInsets.fromLTRB(Spacing.sm, Spacing.sm, 0, Spacing.xs),
        child: Text(
          title.toUpperCase(),
          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.grey, letterSpacing: 0.6),
        ),
      );

  Widget _infoTile({required IconData icon, required String title, required String subtitle}) {
    return _InfoTile(icon: icon, title: title, subtitle: subtitle);
  }

  void _confirmClear(BuildContext context, HistoryProvider provider) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Clear all history?'),
        content: const Text('This cannot be undone.'),
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

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _InfoTile({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: Spacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(Spacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: GoogleFonts.inter(fontSize: 12.5, color: Colors.grey.shade600, height: 1.4)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
