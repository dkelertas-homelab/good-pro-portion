import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:good_pro_portion/audio/sound.dart';
import 'package:good_pro_portion/data/content_loader.dart';
import 'package:good_pro_portion/data/settings_store.dart';
import 'package:good_pro_portion/screens/routine_screen.dart';
import 'package:good_pro_portion/screens/settings_screen.dart';
import 'package:good_pro_portion/screens/timer_screen.dart';
import 'package:good_pro_portion/theme/app_theme.dart';
import 'package:good_pro_portion/widgets/workout_parts_chip.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _CountingBackend extends PlatformSoundBackend {
  int plays = 0;
  @override
  Future<void> load(Map<String, String> assets) async {}
  @override
  Future<void> play(String name, double volume) async => plays++;
}

void main() {
  final content = ContentLoader.parse(
    File('assets/content.json').readAsStringSync(),
  );
  final routine = content.routines.first;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SettingsStore.warmup.value = true;
    SettingsStore.cooldown.value = false;
  });

  Widget app(Widget home) => MaterialApp(theme: buildDarkTheme(), home: home);

  Future<void> big(WidgetTester t) async {
    t.view.physicalSize = const Size(412, 915);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
  }

  test('four states in order, mapping to warm-up/cool-down', () {
    expect(WorkoutParts.values.map((p) => p.label), [
      'Warm-up + cool-down',
      'No warm-up',
      'No cool-down',
      'Both off',
    ]);
    for (final p in WorkoutParts.values) {
      expect(WorkoutParts.of(warmup: p.warmup, cooldown: p.cooldown), p);
    }
    expect(WorkoutParts.neither.next, WorkoutParts.both);
  });

  testWidgets('chip cycles, persists, silent, and syncs with Settings', (
    t,
  ) async {
    await big(t);
    final backend = _CountingBackend();
    Sound.instance = Sound(backend: backend, enabled: true);
    await t.pumpWidget(app(RoutineScreen(content: content, routine: routine)));
    await t.pumpAndSettle();
    // Default: cooldown off, warm-up on.
    expect(find.text('No cool-down'), findsOneWidget);
    final label = t.widget<Text>(find.text('No cool-down'));
    expect(label.style!.fontSize, greaterThanOrEqualTo(16));
    final chip = find.byKey(const ValueKey('workout-parts-chip'));
    final seen = <String>[];
    for (var i = 0; i < 4; i++) {
      await t.tap(chip);
      await t.pumpAndSettle();
      seen.add(
        WorkoutParts.of(
          warmup: SettingsStore.warmup.value,
          cooldown: SettingsStore.cooldown.value,
        ).label,
      );
      expect(find.text(seen.last), findsOneWidget);
    }
    expect(seen, [
      'Both off',
      'Warm-up + cool-down',
      'No warm-up',
      'No cool-down',
    ]);
    expect(backend.plays, 0);
    // Saved.
    await t.tap(chip); // -> Both off
    await t.pumpAndSettle();
    final prefs = await SharedPreferences.getInstance();
    expect(SettingsStore(prefs).warmupEnabled, isFalse);
    expect(SettingsStore(prefs).cooldownEnabled, isFalse);
    expect(find.text('Warm-up · skipped'), findsOneWidget);

    // Settings cooldown switch on -> chip shows a state with cool-down.
    await t.pumpWidget(app(SettingsScreen(content: content)));
    await t.pumpAndSettle();
    final sw = find.byKey(const ValueKey('cooldown-switch'));
    await t.scrollUntilVisible(sw, 200);
    await t.ensureVisible(sw);
    await t.pumpAndSettle();
    await t.tap(sw);
    await t.pumpAndSettle();
    expect(SettingsStore.cooldown.value, isTrue, reason: 'switch tapped');
    await t.pumpWidget(app(RoutineScreen(content: content, routine: routine)));
    await t.pumpAndSettle();
    expect(find.text('No warm-up'), findsOneWidget);
  });

  testWidgets('warm-up off skips the warm-up moves', (t) async {
    await big(t);
    Sound.instance = Sound(enabled: false);
    await t.pumpWidget(
      app(
        TimerScreen(
          content: content,
          routine: routine,
          workSeconds: 10,
          restSeconds: 6,
          warmup: false,
        ),
      ),
    );
    await t.pump();
    expect(find.textContaining('Warm-up'), findsNothing);
    expect(find.textContaining('Move 1/'), findsWidgets);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('test mode: 5 s left, badge shown; off: full time', (t) async {
    await big(t);
    Sound.instance = Sound(enabled: false);
    for (final on in [true, false]) {
      await t.pumpWidget(
        app(
          TimerScreen(
            content: content,
            routine: routine,
            workSeconds: 40,
            restSeconds: 20,
            testMode: on,
          ),
        ),
      );
      await t.pump();
      expect(find.byType(TestModeBadge), on ? findsOneWidget : findsNothing);
      if (on) {
        final b = t.widget<Text>(find.text('TEST MODE'));
        expect(b.style!.fontSize, greaterThanOrEqualTo(16));
      }
      expect(find.text(on ? '5' : '${routine.warmupSeconds}'), findsWidgets);
      await t.pumpWidget(const SizedBox());
    }
    expect(TimerScreen.startSeconds(40, true), 5);
    expect(TimerScreen.startSeconds(3, true), 3);
    expect(TimerScreen.startSeconds(40, false), 40);
  });

  test('test mode setting is debug-only and persists', () async {
    final prefs = await SharedPreferences.getInstance();
    final s = SettingsStore(prefs);
    expect(s.testMode, isFalse);
    await s.setTestMode(true);
    // Tests run in debug mode, so it reads back on.
    expect(SettingsStore(prefs).testMode, isTrue);
  });

  testWidgets('Settings shows Test mode switch in debug builds', (t) async {
    await t.pumpWidget(app(SettingsScreen(content: content)));
    await t.pumpAndSettle();
    final sw = find.byKey(const ValueKey('test-mode-switch'));
    await t.scrollUntilVisible(sw, 200);
    expect(sw, findsOneWidget);
  });
}
