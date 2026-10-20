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
  setUpAll(loadAppFonts);

  for (final (name, dark, seconds, set) in [
    ('breathe-in', false, 2, 0),
    ('box-hold-dark', true, 6, 1),
    ('cue', false, 52, 2),
    ('prompt-dark', true, 90, 4),
  ]) {
    testWidgets('cooldown-$name', skip: dir == null, (t) async {
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
      for (var i = 0; i < seconds; i++) {
        await t.pump(const Duration(seconds: 1));
      }
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile(Uri.file('$dir/cooldown-$name.png')),
      );
      await t.pumpWidget(const SizedBox());
    });
  }
}
