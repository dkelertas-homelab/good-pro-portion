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

  // K1: intro 8s, slide 4s, then in 5s / out 7s.
  for (final (name, dark, ms) in [
    ('intro-centred', false, 3000),
    ('mid-slide', false, 10000),
    ('breathe-in-large', false, 16900),
    ('breathe-out-small', false, 23900),
    ('prompt-dark', true, 140000),
  ]) {
    testWidgets('cooldown2-$name', skip: dir == null, (t) async {
      await setUp(t, dark, 0);
      for (var i = 0; i < ms ~/ 100; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile(Uri.file('$dir/cooldown2-$name.png')),
      );
      await t.pumpWidget(const SizedBox());
    });
  }

  // GIF frames (assembled outside the test), 0–36s at 2.5 fps.
  testWidgets('cooldown2 gif frames', skip: gifDir == null, (t) async {
    await setUp(t, false, 0);
    for (var f = 0; f <= 90; f++) {
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
