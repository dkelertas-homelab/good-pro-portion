import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:good_pro_portion/data/content_loader.dart';
import 'package:good_pro_portion/screens/cooldown_screen.dart';
import 'package:good_pro_portion/theme/app_theme.dart';

import 'font_loader.dart';

/// Writes preview PNGs of the cooldown screen. Off unless
/// COOLDOWN_PREVIEW_DIR is set (run with --update-goldens).
void main() {
  final dir = Platform.environment['COOLDOWN_PREVIEW_DIR'];
  final content = ContentLoader.parse(
    File('assets/content.json').readAsStringSync(),
  );
  final gifDir = Platform.environment['COOLDOWN_GIF_DIR'];
  setUpAll(loadAppFonts);

  Future<void> setUp(WidgetTester t, bool dark, int set) async {
    t.view.physicalSize = const Size(824, 1830);
    t.view.devicePixelRatio = 2;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    await t.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: dark ? buildDarkTheme() : buildLightTheme(),
        home: CooldownScreen(set: content.cooldowns[set], onFinished: () {}),
      ),
    );
  }

  // K1: heading 4s + move 3s, cue 8s + slide 4s, then in 5s / out 7s.
  for (final (name, dark, ms) in [
    ('heading-centred', true, 2000),
    ('heading-top-cue-centred', true, 11000),
    ('cue-bottom-circle', true, 23900),
  ]) {
    testWidgets('cooldown3-$name', skip: dir == null, (t) async {
      await setUp(t, dark, 0);
      for (var i = 0; i < ms ~/ 100; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile(Uri.file('$dir/cooldown3-$name.png')),
      );
      await t.pumpWidget(const SizedBox());
    });
  }

  // GIF frames (assembled outside the test), 0–44s at 2.5 fps (intro + first two breaths).
  testWidgets('cooldown3 gif frames', skip: gifDir == null, (t) async {
    await setUp(t, true, 0);
    for (var f = 0; f <= 110; f++) {
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile(
          Uri.file('$gifDir/f${f.toString().padLeft(3, '0')}.png'),
        ),
      );
      for (var i = 0; i < 4; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
    }
    await t.pumpWidget(const SizedBox());
  });
}
