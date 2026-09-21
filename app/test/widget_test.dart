// Smoke tests: the app boots to the Analyze screen's initial guidance state
// with all three bottom-navigation destinations present, and switching the
// language in Settings actually re-renders the UI in Khmer (Kantumruy Pro
// Bold) — a real end-to-end check of the localization wiring, not just that
// the ARB files parse.
//
// Deliberately avoids `pumpAndSettle()` and avoids exercising History/Settings
// network or local-storage side effects beyond the language toggle: those
// screens depend on plugins (sqflite, shared_preferences, dio sockets) that
// aren't wired up in a plain `flutter test` run. `HistoryProvider.loadInitial()`
// is defensively try/catch-guarded (see providers/history_provider.dart)
// specifically so this boot sequence never crashes even when those plugins
// are unavailable.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ai_image_analyst/main.dart';

void main() {
  testWidgets('App boots to the Analyze screen with bottom navigation', (WidgetTester tester) async {
    await tester.pumpWidget(const AiImageAnalystApp());
    // Let the first frame and any post-frame callbacks run, without waiting
    // for background network/plugin calls to settle.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('AI Image Analyst'), findsOneWidget);
    expect(find.text('Understand any image instantly'), findsOneWidget);
    expect(find.text('Take a photo'), findsWidgets);
    expect(find.text('Analyze'), findsOneWidget);
    expect(find.text('History'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });

  testWidgets('Switching to Khmer in Settings re-renders the UI in Khmer', (WidgetTester tester) async {
    await tester.pumpWidget(const AiImageAnalystApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    // Go to Settings (bottom nav index 2).
    await tester.tap(find.text('Settings'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    // Tap the "ខ្មែរ" language option.
    await tester.tap(find.text('ខ្មែរ'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Bottom nav labels should now be Khmer. "Settings" matches twice (the
    // bottom nav label and the Settings screen's own AppBar title share the
    // same string), so this uses findsWidgets rather than findsOneWidget.
    expect(find.text('ការកំណត់'), findsWidgets); // "Settings"
    expect(find.text('ប្រវត្តិ'), findsOneWidget); // "History"
    expect(find.text('វិភាគ'), findsOneWidget); // "Analyze"

    // Jump back to Analyze and confirm its headline is Khmer too, proving
    // the switch propagates beyond just the bottom nav bar.
    await tester.tap(find.text('វិភាគ'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('យល់ដឹងអំពីរូបភាពណាមួយភ្លាមៗ'), findsOneWidget);

    // The Kantumruy Pro Bold requirement: every rendered Khmer Text widget
    // must be using that font family, at FontWeight.bold, regardless of
    // what weight the original design specified.
    final khmerHeadline = tester.widget<Text>(find.text('យល់ដឹងអំពីរូបភាពណាមួយភ្លាមៗ'));
    final style = khmerHeadline.style;
    expect(style, isNotNull);
    expect(style!.fontFamily, contains('KantumruyPro'));
    expect(style.fontWeight, FontWeight.bold);
  });
}
