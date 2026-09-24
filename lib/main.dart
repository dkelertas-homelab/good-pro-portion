import 'package:flutter/material.dart';

import 'data/content_loader.dart';
import 'models/content.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final content = await ContentLoader.load();
  runApp(GoodProPortionApp(content: content));
}

class GoodProPortionApp extends StatelessWidget {
  const GoodProPortionApp({super.key, required this.content});

  final AppContent content;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: content.appName,
      debugShowCheckedModeBanner: false,
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: ThemeMode.system,
      home: HomeScreen(content: content),
    );
  }
}
