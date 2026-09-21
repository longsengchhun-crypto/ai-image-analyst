import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import 'history_screen.dart';
import 'image_upload_screen.dart';
import 'settings_screen.dart';

/// Root shell: bottom navigation between Upload, History, and Settings.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  static const _screens = [
    ImageUploadScreen(),
    HistoryScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: [
          BottomNavigationBarItem(icon: const Icon(Icons.add_photo_alternate_outlined), label: l10n.navAnalyze),
          BottomNavigationBarItem(icon: const Icon(Icons.history_outlined), label: l10n.navHistory),
          BottomNavigationBarItem(icon: const Icon(Icons.settings_outlined), label: l10n.navSettings),
        ],
      ),
    );
  }
}
