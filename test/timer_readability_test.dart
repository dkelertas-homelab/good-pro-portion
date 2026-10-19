import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:good_pro_portion/data/content_loader.dart';
import 'package:good_pro_portion/screens/timer_screen.dart';
import 'package:good_pro_portion/theme/app_theme.dart';

/// The workout screen gets read from the floor mid-set, so no text on it may
/// be smaller than 16sp, in any phase.
void main() {
  testWidgets('no timer text under 16sp', (t) async {
    final content = ContentLoader.parse(
      File('assets/content.json').readAsStringSync(),
    );
    t.view.physicalSize = const Size(412, 915);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(
      MaterialApp(
        theme: buildLightTheme(),
        home: TimerScreen(
          content: content,
          routine: content.routines.first,
          workSeconds: 40,
          restSeconds: 20,
        ),
      ),
    );

    void check(String phase) {
      for (final e in find.byType(RichText).evaluate()) {
        final w = e.widget as RichText;
        void walk(InlineSpan s, double inherited) {
          final size = s.style?.fontSize ?? inherited;
          if (s is TextSpan && (s.text ?? '').trim().isNotEmpty) {
            expect(
              size,
              greaterThanOrEqualTo(16),
              reason: '"${s.text}" is ${size}sp during $phase',
            );
          }
          s.visitDirectChildren((c) {
            walk(c, size);
            return true;
          });
        }

        walk(w.text, 14);
      }
    }

    check('warm-up');
    await t.pump(const Duration(seconds: 23));
    check('warm-up preview');
    for (var i = 0; i < 4; i++) {
      await t.tap(find.text('Skip ›'));
      await t.pump();
    }
    check('work');
    await t.tap(find.text('Skip ›'));
    await t.pump();
    check('rest');
    // Through to the swap-sides rest and the left side.
    for (var i = 0; i < 6; i++) {
      await t.tap(find.text('Skip ›'));
      await t.pump();
      check('step ${i + 6}');
    }
    await t.pumpWidget(const SizedBox());
  });
}
