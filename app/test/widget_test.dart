// Basic smoke test: the app boots to the Analyze screen's initial guidance
// state with all three bottom-navigation destinations present.
//
// Deliberately avoids `pumpAndSettle()` and avoids exercising History/Settings
// network or local-storage side effects: those screens depend on plugins
// (sqflite, shared_preferences, dio sockets) that aren't wired up in a plain
// `flutter test` run. `HistoryProvider.loadInitial()` is defensively
// try/catch-guarded (see providers/history_provider.dart) specifically so
// this boot sequence never crashes even when those plugins are unavailable.
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
}
