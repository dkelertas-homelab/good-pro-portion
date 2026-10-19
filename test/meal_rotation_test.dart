import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:good_pro_portion/data/content_loader.dart';
import 'package:good_pro_portion/data/meal_rotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final meals = ContentLoader.parse(
    File('assets/content.json').readAsStringSync(),
  ).meals;

  test('30 ideas, about 10 snacks, unique ids', () {
    expect(meals, hasLength(30));
    expect(meals.map((m) => m.id).toSet(), hasLength(30));
    expect(
      meals.where((m) => m.title.startsWith('Snack:')).length,
      inInclusiveRange(8, 12),
    );
  });

  test(
    'every idea once per cycle, no back-to-back repeat, survives restart',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final seen = <String>[];
      for (var i = 0; i < 90; i++) {
        // New instance each time, like reopening the app.
        final r = MealRotation(prefs, random: Random(i));
        seen.add((await r.next(meals)).id);
      }
      for (var c = 0; c < 3; c++) {
        expect(seen.sublist(c * 30, c * 30 + 30).toSet(), hasLength(30));
      }
      for (var i = 1; i < seen.length; i++) {
        expect(seen[i], isNot(seen[i - 1]));
      }
    },
  );
}
