import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../l10n/generated/app_localizations.dart';
import '../providers/history_provider.dart';
import '../providers/locale_provider.dart';
import '../utils/app_fonts.dart';
import '../utils/constants.dart';

/// Settings / API Management screen: shows the configured backend endpoint,
/// privacy/consent information, language switcher, and destructive actions
/// (clear history). No third-party API keys are ever shown here — those
/// live only on the backend server.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navSettings)),
      body: ListView(
        padding: const EdgeInsets.all(Spacing.md),
        children: [
          _sectionHeader(context, l10n.settingsSectionLanguage),
          const _LanguageSwitcher(),
          const SizedBox(height: Spacing.lg),
          _sectionHeader(context, l10n.settingsSectionConnection),
          _InfoTile(
            icon: Icons.dns_outlined,
            title: l10n.settingsBackendApiTitle,
            subtitle: AppConfig.apiBaseUrl,
          ),
          _InfoTile(
            icon: Icons.security_outlined,
            title: l10n.settingsAiProcessingTitle,
            subtitle: l10n.settingsAiProcessingSubtitle,
          ),
          const SizedBox(height: Spacing.lg),
          _sectionHeader(context, l10n.settingsSectionPrivacy),
          _InfoTile(
            icon: Icons.privacy_tip_outlined,
            title: l10n.settingsWhatWeStoreTitle,
            subtitle: l10n.settingsWhatWeStoreSubtitle,
          ),
          _InfoTile(
            icon: Icons.groups_outlined,
            title: l10n.settingsPeopleTitle,
            subtitle: l10n.settingsPeopleSubtitle,
          ),
          const SizedBox(height: Spacing.lg),
          _sectionHeader(context, l10n.settingsSectionData),
          Consumer<HistoryProvider>(
            builder: (context, provider, _) => ListTile(
              leading: const Icon(Icons.delete_outline, color: AppColors.danger),
              title: Text(l10n.settingsClearHistoryTitle),
              subtitle: Text(l10n.settingsClearHistorySubtitle),
              onTap: provider.items.isEmpty ? null : () => _confirmClear(context, provider),
            ),
          ),
          const SizedBox(height: Spacing.lg),
          _sectionHeader(context, l10n.settingsSectionAbout),
          _InfoTile(
            icon: Icons.info_outline,
            title: l10n.settingsAboutTitle,
            subtitle: l10n.settingsAboutSubtitle,
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String title) => Padding(
        padding: const EdgeInsets.fromLTRB(Spacing.sm, Spacing.sm, 0, Spacing.xs),
        child: Text(
          title.toUpperCase(),
          style: appFont(context, fontSize: 12, fontWeight: FontWeight.w700, color: Colors.grey, letterSpacing: 0.6),
        ),
      );

  void _confirmClear(BuildContext context, HistoryProvider provider) {
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

/// Segmented English/Khmer switch. Persisted via [LocaleProvider], which
/// also drives the app-wide font choice (Inter vs. bold Kantumruy Pro) —
/// see `theme.dart`.
class _LanguageSwitcher extends StatelessWidget {
  const _LanguageSwitcher();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Consumer<LocaleProvider>(
      builder: (context, localeProvider, _) {
        return Card(
          margin: const EdgeInsets.only(bottom: Spacing.sm),
          child: Padding(
            padding: const EdgeInsets.all(Spacing.sm),
            child: Row(
              children: [
                Expanded(
                  child: _LanguageOption(
                    label: l10n.settingsLanguageEnglish,
                    khmerScript: false,
                    selected: !localeProvider.isKhmer,
                    onTap: () => localeProvider.setLocale(const Locale('en')),
                  ),
                ),
                const SizedBox(width: Spacing.sm),
                Expanded(
                  child: _LanguageOption(
                    label: l10n.settingsLanguageKhmer,
                    khmerScript: true,
                    selected: localeProvider.isKhmer,
                    onTap: () => localeProvider.setLocale(const Locale('km')),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LanguageOption extends StatelessWidget {
  final String label;
  final bool khmerScript;
  final bool selected;
  final VoidCallback onTap;
  const _LanguageOption({
    required this.label,
    required this.khmerScript,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // This label names the language itself (e.g. always shows "English" in
    // Latin script, and "ខ្មែរ" in Khmer script) regardless of which
    // language the app is currently displaying — so it always renders in
    // its own font, never the ambient `appFont(context, ...)` theme font
    // (which would otherwise force Kantumruy Pro onto the Latin word
    // "English" while the app is set to Khmer, or vice versa).
    final labelStyle = khmerScript
        ? GoogleFonts.kantumruyPro(fontWeight: FontWeight.bold, color: selected ? AppColors.accent : null)
        : GoogleFonts.inter(fontWeight: FontWeight.w700, color: selected ? AppColors.accent : null);

    return InkWell(
      borderRadius: BorderRadius.circular(Radii.button),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
        decoration: BoxDecoration(
          color: selected ? AppColors.accent.withValues(alpha: 0.14) : Colors.transparent,
          borderRadius: BorderRadius.circular(Radii.button),
          border: Border.all(color: selected ? AppColors.accent : Colors.grey.shade300),
        ),
        alignment: Alignment.center,
        child: Text(label, style: labelStyle),
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
                  Text(title, style: appFont(context, fontSize: 14, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: appFont(context, fontSize: 12.5, color: Colors.grey.shade600, height: 1.4)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
