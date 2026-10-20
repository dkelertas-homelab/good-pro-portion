import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:good_pro_portion/data/content_loader.dart';

void main() {
  test('bundled content.json loads with the locked moves and both quiet morning routines', () {
    final raw = File('assets/content.json').readAsStringSync();
    final content = ContentLoader.parse(raw);

    expect(content.appName, 'Nice Pro Portions ;-)');
    expect(content.moves.length, greaterThanOrEqualTo(15));
    expect(content.meals.length, 5);

    final dayA = content.routines.firstWhere((r) => r.id == 'day_a');
    expect(dayA.warmup.length, 4);
    expect(dayA.name, 'Quiet morning A');
    expect(dayA.work.length, 8);
    expect(dayA.work[2].label, 'Reverse lunge (right)');
    expect(dayA.work[4].label, 'Reverse lunge (left)');
    expect(dayA.work[4].swapSides, isTrue);
    expect(dayA.workSeconds, 40);
    expect(dayA.restSeconds, 20);

    final dayB = content.routines.firstWhere((r) => r.id == 'day_b');
    expect(dayB.name, 'Quiet morning B');
    expect(dayB.work.length, 8);
    // One-sided moves: right first, then left, never back to back.
    for (final r in [dayA, dayB]) {
      for (var i = 1; i < r.work.length; i++) {
        expect(
          r.work[i].moveId == r.work[i - 1].moveId && r.work[i].swapSides,
          isFalse,
        );
      }
    }
    expect(content.moves.every((m) => m.cue.isNotEmpty), isTrue);

    // Reverse lunge and split squat must read as different moves.
    expect(content.moveById('reverse_lunge').cue, 'Step back, drop, step in.');
    expect(
      content.moveById('split_squat').cue,
      'Feet stay planted, staggered. Straight down and up.',
    );
    for (final r in [dayA, dayB]) {
      for (final s in r.work.where((s) => s.moveId == 'split_squat')) {
        expect(s.cue, contains('Feet stay planted'));
      }
      for (final s in r.work.where((s) => s.moveId == 'reverse_lunge')) {
        expect(s.cue, contains('step back, drop, step in'));
      }
    }
  });
}
