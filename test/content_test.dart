import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:good_pro_portion/data/content_loader.dart';

void main() {
  test('bundled content.json loads with the locked moves and Day A/B', () {
    final raw = File('assets/content.json').readAsStringSync();
    final content = ContentLoader.parse(raw);

    expect(content.appName, 'Nice Pro Portions');
    expect(content.moves.length, greaterThanOrEqualTo(15));
    expect(content.meals.length, 5);

    final dayA = content.routines.firstWhere((r) => r.id == 'day_a');
    expect(dayA.warmup.length, 4);
    expect(dayA.work.length, 7);
    expect(dayA.workSeconds, 40);
    expect(dayA.restSeconds, 20);

    final dayB = content.routines.firstWhere((r) => r.id == 'day_b');
    expect(dayB.work.length, 7);
  });
}
