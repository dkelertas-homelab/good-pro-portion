import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:good_pro_portion/audio/sound.dart';
import 'package:good_pro_portion/data/content_loader.dart';
import 'package:good_pro_portion/screens/routine_screen.dart';
import 'package:good_pro_portion/screens/settings_screen.dart';
import 'package:good_pro_portion/screens/timer_screen.dart';
import 'package:good_pro_portion/theme/app_theme.dart';
import 'package:good_pro_portion/widgets/workout_parts_chip.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'font_loader.dart';

/// Dark preview PNGs of the warm-up/cool-down chip and test mode. Off unless
/// PARTS_PREVIEW_DIR is set (run with --update-goldens).
void main() {
  final dir = Platform.environment['PARTS_PREVIEW_DIR'];
  final content = ContentLoader.parse(
    File('assets/content.json').readAsStringSync(),
  );
  setUpAll(loadAppFonts);

  Future<void> shot(WidgetTester t, Widget home, String name) async {
    t.view.physicalSize = const Size(824, 1830);
    t.view.devicePixelRatio = 2;
    addTearDown(t.view.reset);
    Sound.instance = Sound(enabled: false);
    await t.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildDarkTheme(),
        home: home,
      ),
    );
    for (var i = 0; i < 10; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
    if (name == 'testmode-settings') {
      final sw = find.byKey(const ValueKey('test-mode-switch'));
      await t.scrollUntilVisible(sw, 200);
      await t.tap(sw);
      for (var i = 0; i < 5; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
    }
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile(Uri.file('$dir/$name.png')),
    );
    await t.pumpWidget(const SizedBox());
  }

  for (final p in WorkoutParts.values) {
    testWidgets('cycle-${p.name}', skip: dir == null, (t) async {
      SharedPreferences.setMockInitialValues({
        'warmup_enabled': p.warmup,
        'cooldown_enabled': p.cooldown,
      });
      await shot(
        t,
        RoutineScreen(content: content, routine: content.routines.first),
        'cycle-${p.index + 1}-${p.name}',
      );
    });
  }

  testWidgets('testmode-settings', skip: dir == null, (t) async {
    SharedPreferences.setMockInitialValues({});
    await shot(t, SettingsScreen(content: content), 'testmode-settings');
  });

  testWidgets('testmode-timer', skip: dir == null, (t) async {
    SharedPreferences.setMockInitialValues({});
    await shot(
      t,
      TimerScreen(
        content: content,
        routine: content.routines.first,
        workSeconds: 40,
        restSeconds: 20,
        testMode: true,
      ),
      'testmode-timer',
    );
  });
}
