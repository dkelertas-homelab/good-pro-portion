import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'data/content_loader.dart';
import 'models/content.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Android 15+ forces edge-to-edge; opt in everywhere so layouts behave the
  // same on older versions (insets handled in widgets/insets.dart).
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarContrastEnforced: false,
    ),
  );

  Object? loadError;
  AppContent? content;
  try {
    content = await ContentLoader.load();
  } catch (e, st) {
    loadError = e;
    debugPrint('ContentLoader failed: $e\n$st');
  }

  runApp(
    content != null
        ? GoodProPortionApp(content: content)
        : LoadFailedApp(error: loadError),
  );
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

/// Shown instead of a hard crash if bundled content fails to load.
class LoadFailedApp extends StatelessWidget {
  const LoadFailedApp({super.key, this.error});

  final Object? error;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildLightTheme(),
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Couldn’t start',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Something went wrong loading the workout content. '
                  'Try force-stopping the app and opening it again. '
                  'If it keeps happening, reinstall from the APK.',
                ),
                if (error != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    '$error',
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
