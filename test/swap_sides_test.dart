import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:good_pro_portion/data/content_loader.dart';
import 'package:good_pro_portion/screens/timer_screen.dart';
import 'package:good_pro_portion/theme/app_theme.dart';
import 'package:good_pro_portion/widgets/figure_view.dart';
import 'package:good_pro_portion/widgets/swap_sides_badge.dart';

/// One-sided moves are drawn for the right side only. At the change to the
/// left side the timer says "Swap sides" instead of mirroring the figure.
void main() {
  testWidgets('swap sides shows on the rest before and on the left side', (
    t,
  ) async {
    final content = ContentLoader.parse(
      File('assets/content.json').readAsStringSync(),
    );
    final r = content.routines.firstWhere((r) => r.id == 'day_a');
    t.view.physicalSize = const Size(412, 915);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(
      MaterialApp(
        theme: buildLightTheme(),
        home: TimerScreen(
          content: content,
          routine: r,
          workSeconds: 40,
          restSeconds: 20,
        ),
      ),
    );

    Future<void> skipTo(String text) async {
      for (var i = 0; i < 30 && find.text(text).evaluate().isEmpty; i++) {
        await t.tap(find.text('Skip ›'));
        await t.pump();
      }
    }

    // Right side: no swap cue.
    await skipTo('Move 3/8');
    expect(find.byType(SwapSidesBadge), findsNothing);

    // During the plank, the next-up chip already warns.
    await skipTo('Move 4/8');
    expect(find.text('NEXT UP · SWAP SIDES'), findsOneWidget);

    // Rest before the left side: the next-up card says swap sides.
    await t.tap(find.text('Skip ›'));
    await t.pump();
    expect(find.text('Rest'), findsWidgets);
    expect(find.byType(SwapSidesBadge), findsOneWidget);

    // The left side itself keeps the cue, and the figure isn't flipped.
    await t.tap(find.text('Skip ›'));
    await t.pump();
    expect(find.text('Reverse lunge (left)'), findsOneWidget);
    expect(find.byType(SwapSidesBadge), findsOneWidget);
    expect(find.byType(FigureView), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(FigureView),
        matching: find.byWidgetPredicate(
          (w) => w is Transform && w.transform.storage[0] < 0,
        ),
      ),
      findsNothing,
    );

    final badge = t.widget<Text>(
      find.descendant(
        of: find.byType(SwapSidesBadge),
        matching: find.byType(Text),
      ),
    );
    expect(badge.data, 'SWAP SIDES');
    expect(badge.style!.fontSize, greaterThanOrEqualTo(16));
    await t.pumpWidget(const SizedBox());
  });
}
