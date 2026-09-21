import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'l10n/generated/app_localizations.dart';
import 'providers/history_provider.dart';
import 'providers/image_provider.dart';
import 'providers/locale_provider.dart';
import 'screens/home_screen.dart';
import 'theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Loads locale-specific date symbols (month/day names, etc.) for every
  // supported language up front, so `DateFormat(pattern, 'km')` in
  // image_card.dart doesn't throw the first time a Khmer-locale date is
  // formatted.
  await initializeDateFormatting('en');
  await initializeDateFormatting('km');
  runApp(const AiImageAnalystApp());
}

class AiImageAnalystApp extends StatelessWidget {
  const AiImageAnalystApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => HistoryProvider()),
        ChangeNotifierProxyProvider<HistoryProvider, ImageAnalysisProvider>(
          create: (_) => ImageAnalysisProvider(),
          // Gives the image-analysis flow a live reference to History so a
          // finished analysis (or newly-answered question) shows up there
          // the instant it happens, not just after History's own refresh.
          update: (_, history, image) => (image ?? ImageAnalysisProvider())..historyProvider = history,
        ),
        ChangeNotifierProvider(create: (_) => LocaleProvider()..load()),
      ],
      child: Consumer<LocaleProvider>(
        builder: (context, localeProvider, _) {
          final khmer = localeProvider.isKhmer;
          return MaterialApp(
            onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(khmer: khmer),
            darkTheme: AppTheme.dark(khmer: khmer),
            themeMode: ThemeMode.system,
            locale: localeProvider.locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: const HomeScreen(),
          );
        },
      ),
    );
  }
}
