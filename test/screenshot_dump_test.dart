import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:good_pro_portion/data/content_loader.dart';
import 'package:good_pro_portion/models/content.dart';
import 'package:good_pro_portion/screens/done_screen.dart';
import 'package:good_pro_portion/screens/home_screen.dart';
import 'package:good_pro_portion/screens/routine_screen.dart';
import 'package:good_pro_portion/screens/timer_screen.dart';
import 'package:good_pro_portion/theme/app_theme.dart';

import 'font_loader.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppContent content;

  setUpAll(() async {
    content = ContentLoader.parse(File('assets/content.json').readAsStringSync());
    await loadAppFonts();
    // Preload the SVGs used on the shot screens.
    final keys = <String>{
      for (final r in content.routines) ...[
        content.moveById(r.work.first.moveId).figure,
        ...r.warmup.map((s) => content.moveById(s.moveId).figure),
        ...r.work.map((s) => content.moveById(s.moveId).figure),
      ],
    };
    final assets = [
      for (final k in keys) ...['assets/figures/$k.svg', 'assets/figures/${k}_dark.svg'],
    ];
    await precacheSvgs(assets);
  });

  Future<void> prep(WidgetTester t) async {
    t.view.physicalSize = const Size(824, 1830);
    t.view.devicePixelRatio = 2;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
  }

  Future<void> settleSvgs(WidgetTester tester) async {
    // Give SvgPicture a couple of frames after assets are warm.
    await tester.pump();
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }

  testWidgets('01-home', (tester) async {
    await prep(tester);
    await tester.pumpWidget(MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildLightTheme(),
      home: HomeScreen(content: content),
    ));
    await tester.pumpAndSettle();
    await settleSvgs(tester);
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/01-home.png'));
  });

  testWidgets('02-routine', (tester) async {
    await prep(tester);
    await tester.pumpWidget(MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildLightTheme(),
      home: RoutineScreen(content: content, routine: content.routines.first),
    ));
    await tester.pumpAndSettle();
    await settleSvgs(tester);
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/02-routine.png'));
  });

  testWidgets('04-timer-work', (tester) async {
    await prep(tester);
    await tester.pumpWidget(MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildLightTheme(),
      home: TimerScreen(
        content: content,
        routine: content.routines.first,
        workSeconds: 40,
        restSeconds: 20,
      ),
    ));
    // Timer.periodic never settles — pump frames instead.
    await settleSvgs(tester);
    await settleSvgs(tester);
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/04-timer-work.png'));
  });

  testWidgets('06-done', (tester) async {
    await prep(tester);
    await tester.pumpWidget(MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildLightTheme(),
      home: DoneScreen(
        content: content,
        routine: content.routines.first,
        elapsed: const Duration(minutes: 8, seconds: 52),
      ),
    ));
    await tester.pumpAndSettle();
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/06-done.png'));
  });

  testWidgets('01-home-dark', (tester) async {
    await prep(tester);
    await tester.pumpWidget(MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: ThemeMode.dark,
      home: HomeScreen(content: content),
    ));
    await tester.pumpAndSettle();
    await settleSvgs(tester);
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/01-home-dark.png'));
  });
}
