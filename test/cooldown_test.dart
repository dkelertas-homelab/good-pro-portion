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

  test('five cooldown sets K1–K5, each about a minute of breathing', () {
    expect(sets.map((s) => s.id), ['K1', 'K2', 'K3', 'K4', 'K5']);
    for (final s in sets) {
      expect(s.breathingSeconds, inInclusiveRange(40, 60), reason: s.id);
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
  });

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

  testWidgets('Skip is there from the start and finishes once', (t) async {
    var done = 0;
    await t.pumpWidget(screen(sets.first, () => done++));
    expect(find.text('Breathe in'), findsOneWidget);
    expect(find.byKey(const ValueKey('cooldown-skip')), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('cooldown-skip')));
    await t.pump();
    expect(done, 1);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('breathe → cue → prompt, then Finish', (t) async {
    final k1 = sets.first;
    var done = 0;
    await t.pumpWidget(screen(k1, () => done++));
    await t.pump(const Duration(seconds: 4));
    expect(find.text('Breathe out'), findsOneWidget);
    await t.pump(Duration(seconds: k1.breathingSeconds - 4));
    expect(find.byKey(const ValueKey('cooldown-big')), findsOneWidget);
    expect(find.text(k1.cue), findsOneWidget);
    expect(find.byKey(const ValueKey('cooldown-skip')), findsOneWidget);
    await t.pump(const Duration(seconds: 30));
    expect(find.text(k1.prompt), findsOneWidget);
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
