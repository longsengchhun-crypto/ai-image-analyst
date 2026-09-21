import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/history_provider.dart';
import 'providers/image_provider.dart';
import 'screens/home_screen.dart';
import 'theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AiImageAnalystApp());
}

class AiImageAnalystApp extends StatelessWidget {
  const AiImageAnalystApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ImageAnalysisProvider()),
        ChangeNotifierProvider(create: (_) => HistoryProvider()),
      ],
      child: MaterialApp(
        title: 'AI Image Analyst',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.system,
        home: const HomeScreen(),
      ),
    );
  }
}
