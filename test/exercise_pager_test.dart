import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:good_pro_portion/data/content_loader.dart';
import 'package:good_pro_portion/models/content.dart';
import 'package:good_pro_portion/screens/exercise_screen.dart';
import 'package:good_pro_portion/screens/routine_screen.dart';
import 'package:good_pro_portion/theme/app_theme.dart';
import 'package:good_pro_portion/widgets/figure_view.dart';
import 'package:good_pro_portion/widgets/swap_sides_badge.dart';

/// Issue #25: swipe between exercise instruction screens.
void main() {
  late AppContent content;

  setUpAll(() {
    content = ContentLoader.parse(
      File('assets/content.json').readAsStringSync(),
    );
  });

  String title(WidgetTester t) {
    final bar = t.widget<AppBar>(find.byType(AppBar));
    return (bar.title as Text).data!;
  }

  // The figures animate on a timer, so step time forward rather than settle.
  Future<void> settle(WidgetTester t) async {
    for (var i = 0; i < 6; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
  }

  testWidgets('swipes through the routine in list order', (t) async {
    final r = content.routines.first;
    await t.pumpWidget(
      MaterialApp(
        theme: buildLightTheme(),
        home: RoutineScreen(content: content, routine: r),
      ),
    );
    await t.tap(find.text('1. Squat'));
    await settle(t);

    final total = r.warmup.length + r.work.length;
    expect(title(t), 'Squat');
    expect(find.text('${r.warmup.length + 1} / $total'), findsOneWidget);

    await t.fling(find.byType(PageView), const Offset(-400, 0), 1500);
    await settle(t);
    expect(title(t), 'Push-up');

    await t.fling(find.byType(PageView), const Offset(-400, 0), 1500);
    await settle(t);
    expect(title(t), 'Reverse lunge (right)');
    expect(find.byType(SwapSidesBadge), findsNothing);

    await t.fling(find.byType(PageView), const Offset(400, 0), 1500);
    await settle(t);
    expect(title(t), 'Push-up');
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('Previous and Next buttons, swap sides on the left side', (
    t,
  ) async {
    final r = content.routines.first;
    final entries = [
      for (final s in r.work)
        ExerciseEntry(
          move: content.moveById(s.moveId),
          label: s.label,
          swapSides: s.swapSides,
        ),
    ];
    final left = r.work.indexWhere((s) => s.label == 'Reverse lunge (left)');
    await t.pumpWidget(
      MaterialApp(
        theme: buildLightTheme(),
        home: ExerciseScreen.pager(entries: entries, initialIndex: left),
      ),
    );
    await settle(t);
    expect(title(t), 'Reverse lunge (left)');
    expect(find.byType(SwapSidesBadge), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(FigureView),
        matching: find.byWidgetPredicate(
          (w) => w is Transform && w.transform.storage[0] < 0,
        ),
      ),
      findsNothing,
      reason: 'figures are never mirrored',
    );

    await t.tap(find.text('Next'));
    await settle(t);
    expect(title(t), content.moveById(r.work[left + 1].moveId).name);

    await t.tap(find.text('Previous'));
    await settle(t);
    await t.tap(find.text('Previous'));
    await settle(t);
    expect(title(t), 'Plank');
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('ends of the list disable the buttons', (t) async {
    final moves = content.moves.take(2).toList();
    await t.pumpWidget(
      MaterialApp(
        theme: buildLightTheme(),
        home: ExerciseScreen.pager(
          entries: [for (final m in moves) ExerciseEntry(move: m)],
        ),
      ),
    );
    await settle(t);
    TextButton button(String label) => t.widget<TextButton>(
      find.ancestor(of: find.text(label), matching: find.byType(TextButton)),
    );
    expect(button('Previous').onPressed, isNull);
    expect(button('Next').onPressed, isNotNull);
    await t.tap(find.text('Next'));
    await settle(t);
    expect(button('Next').onPressed, isNull);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('a single move has no pager chrome', (t) async {
    await t.pumpWidget(
      MaterialApp(
        theme: buildLightTheme(),
        home: ExerciseScreen(move: content.moves.first),
      ),
    );
    await settle(t);
    expect(find.text('Next'), findsNothing);
    expect(find.textContaining(' / '), findsNothing);
    await t.pumpWidget(const SizedBox());
  });
}
