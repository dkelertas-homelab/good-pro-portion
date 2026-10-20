import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:good_pro_portion/data/content_loader.dart';
import 'package:good_pro_portion/data/meal_rotation.dart';
import 'package:good_pro_portion/data/settings_store.dart';
import 'package:good_pro_portion/models/content.dart';
import 'package:good_pro_portion/screens/cooldown_screen.dart';
import 'package:good_pro_portion/screens/settings_screen.dart';
import 'package:good_pro_portion/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final content = ContentLoader.parse(
    File('assets/content.json').readAsStringSync(),
  );
  final sets = content.cooldowns;

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'five cooldown sets K1–K5, each about two slow minutes of breathing',
    () {
      expect(sets.map((s) => s.id), ['K1', 'K2', 'K3', 'K4', 'K5']);
      for (final s in sets) {
        expect(s.breathingSeconds, inInclusiveRange(100, 130), reason: s.id);
        expect(s.rounds, greaterThanOrEqualTo(6), reason: s.id);
        expect(CooldownScreen.secondsToPrompt(s), inInclusiveRange(120, 150));
        expect(s.cue, isNotEmpty);
        expect(s.prompt, endsWith('?'));
      }
      final k2 = sets[1];
      expect(k2.steps.map((s) => s.motion), [
        BreathMotion.breatheIn,
        BreathMotion.hold,
        BreathMotion.breatheOut,
        BreathMotion.hold,
      ]);
    },
  );

  test('cooldown setting defaults to off and persists', () async {
    final prefs = await SharedPreferences.getInstance();
    expect(SettingsStore(prefs).cooldownEnabled, isFalse);
    await SettingsStore(prefs).setCooldownEnabled(true);
    expect(SettingsStore(prefs).cooldownEnabled, isTrue);
  });

  testWidgets('Settings shows the Cooldown switch, off', (t) async {
    await t.pumpWidget(
      MaterialApp(
        theme: buildLightTheme(),
        home: SettingsScreen(content: content),
      ),
    );
    await t.pumpAndSettle();
    final sw = find.byKey(const ValueKey('cooldown-switch'));
    await t.scrollUntilVisible(sw, 200);
    expect(t.widget<SwitchListTile>(sw).value, isFalse);
    await t.tap(sw);
    await t.pumpAndSettle();
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('cooldown_enabled'), isTrue);
  });

  test('rotation: all 5 once per cycle, no back-to-back repeat', () async {
    final prefs = await SharedPreferences.getInstance();
    final seen = <String>[];
    for (var i = 0; i < 20; i++) {
      seen.add(
        (await CooldownRotation(prefs, random: Random(i)).next(sets)).id,
      );
    }
    for (var c = 0; c < 4; c++) {
      expect(seen.sublist(c * 5, c * 5 + 5).toSet(), hasLength(5));
    }
    for (var i = 1; i < seen.length; i++) {
      expect(seen[i], isNot(seen[i - 1]));
    }
    // Separate from the meal rotation.
    expect(prefs.getStringList('meal_queue'), isNull);
  });

  Widget screen(CooldownSet s, VoidCallback onDone) => MaterialApp(
    theme: buildLightTheme(),
    home: CooldownScreen(set: s, onFinished: onDone),
  );

  double circle(WidgetTester t) =>
      t.getSize(find.byKey(const ValueKey('breath-circle'))).width;
  double cueY(WidgetTester t) =>
      t.getCenter(find.byKey(const ValueKey('cooldown-cue'))).dy;

  testWidgets('Skip is there from the start and finishes once', (t) async {
    var done = 0;
    await t.pumpWidget(screen(sets.first, () => done++));
    expect(find.text(sets.first.cue), findsOneWidget);
    expect(find.byKey(const ValueKey('cooldown-skip')), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('cooldown-skip')));
    await t.pump();
    expect(done, 1);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('cue starts centred, then slides to the bottom', (t) async {
    await t.pumpWidget(screen(sets.first, () {}));
    final mid = t.getSize(find.byType(Scaffold)).height / 2;
    final start = cueY(t);
    expect((start - mid).abs(), lessThan(80));
    await t.pump(const Duration(seconds: 7));
    expect(cueY(t), closeTo(start, 0.5)); // still centred during intro
    await t.pump(const Duration(seconds: 1)); // slide begins
    await t.pump(const Duration(seconds: 2));
    final half = cueY(t);
    expect(half, greaterThan(start + 20));
    await t.pump(const Duration(seconds: 2));
    await t.pump(const Duration(milliseconds: 100));
    expect(cueY(t), greaterThan(half));
    expect(find.text('Breathe in'), findsOneWidget);
    // Cue stays visible at the bottom while breathing.
    await t.pump(const Duration(seconds: 30));
    expect(find.text(sets.first.cue), findsOneWidget);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('circle grows over the whole in-breath, shrinks over out, '
      'and holds still', (t) async {
    final k2 = sets[1]; // box: in 4, hold 4, out 4, hold 4
    await t.pumpWidget(screen(k2, () {}));
    await t.pump(const Duration(seconds: 12)); // intro 8 + slide 4
    await t.pump(const Duration(milliseconds: 1));
    final s0 = circle(t);
    await t.pump(const Duration(seconds: 2));
    final s2 = circle(t);
    await t.pump(const Duration(milliseconds: 1999));
    final s4 = circle(t);
    expect(s2, greaterThan(s0));
    expect(s4, greaterThan(s2)); // still growing near end of the 4s phase
    await t.pump(const Duration(seconds: 2));
    expect(find.text('Hold'), findsOneWidget);
    expect(circle(t), closeTo(s4, 1)); // hold = same size
    await t.pump(const Duration(seconds: 2));
    await t.pump(const Duration(seconds: 2));
    expect(find.text('Breathe out'), findsOneWidget);
    final o2 = circle(t);
    await t.pump(const Duration(milliseconds: 1999));
    expect(circle(t), lessThan(o2));
    expect(circle(t), lessThan(s4));
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('reduce motion: circle stays one size', (t) async {
    await t.pumpWidget(
      MaterialApp(
        theme: buildLightTheme(),
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: CooldownScreen(set: sets.first, onFinished: () {}),
        ),
      ),
    );
    await t.pump(const Duration(seconds: 13));
    final a = circle(t);
    await t.pump(const Duration(seconds: 3));
    expect(circle(t), a);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('intro → slide → breathe → prompt, which waits for Finish', (
    t,
  ) async {
    final k1 = sets.first;
    var done = 0;
    await t.pumpWidget(screen(k1, () => done++));
    final toPrompt = CooldownScreen.secondsToPrompt(k1);
    for (var i = 0; i < toPrompt - 1; i++) {
      await t.pump(const Duration(seconds: 1));
    }
    expect(find.byKey(const ValueKey('cooldown-prompt')), findsOneWidget);
    expect(find.byKey(const ValueKey('cooldown-finish')), findsOneWidget);
    await t.pump(const Duration(seconds: 1));
    await t.pump(const Duration(minutes: 5));
    expect(find.text(k1.prompt), findsOneWidget); // no auto-close
    expect(done, 0);
    await t.tap(find.byKey(const ValueKey('cooldown-finish')));
    expect(done, 1);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('no text under 16sp on the cooldown screen', (t) async {
    await t.pumpWidget(screen(sets[1], () {}));
    for (final e in find.byType(Text).evaluate()) {
      final w = e.widget as Text;
      final size =
          (w.style == null
                  ? DefaultTextStyle.of(e).style
                  : DefaultTextStyle.of(e).style.merge(w.style))
              .fontSize;
      expect(size, greaterThanOrEqualTo(16), reason: w.data);
    }
    await t.pumpWidget(const SizedBox());
  });
}
