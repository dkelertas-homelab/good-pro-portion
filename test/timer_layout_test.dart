import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:good_pro_portion/data/content_loader.dart';
import 'package:good_pro_portion/screens/timer_screen.dart';
import 'package:good_pro_portion/theme/app_theme.dart';

/// The countdown must stay in the same spot across work, rest and the
/// warm-up next-up preview (issue #22).
void main() {
  testWidgets('countdown ring keeps its position across phases', (t) async {
    final content = ContentLoader.parse(File('assets/content.json').readAsStringSync());
    t.view.physicalSize = const Size(412, 915);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(MaterialApp(
      theme: buildLightTheme(),
      home: TimerScreen(
          content: content, routine: content.routines.first, workSeconds: 40, restSeconds: 20),
    ));
    final ring = find.byKey(const ValueKey('countdown'));
    final warmup = t.getRect(ring);
    await t.pump(const Duration(seconds: 23)); // last 25% of warm-up: next-up preview
    expect(find.text('NEXT UP · GET READY'), findsOneWidget);
    final preview = t.getRect(ring);
    for (var i = 0; i < 4; i++) {
      await t.tap(find.text('Skip ›'));
      await t.pump();
    }
    final work = t.getRect(ring); // first work move
    await t.tap(find.text('Skip ›'));
    await t.pump();
    expect(find.text('Rest'), findsWidgets);
    final rest = t.getRect(ring);
    expect(preview, warmup);
    expect(work, warmup);
    expect(rest, warmup);
    expect(warmup.left, lessThan(60), reason: 'bottom-left');
    expect(warmup.top, greaterThan(915 / 2), reason: 'bottom half');
    await t.pumpWidget(const SizedBox());
  });
}
