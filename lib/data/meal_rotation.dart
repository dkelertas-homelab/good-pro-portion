import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/content.dart';

/// Hands out meal ideas from a shuffled cycle saved on the phone, so every
/// idea shows once before any repeats (and no repeat across a reshuffle).
class MealRotation {
  MealRotation(this._prefs, {Random? random}) : _random = random ?? Random();

  final SharedPreferences _prefs;
  final Random _random;

  static const _kQueue = 'meal_queue';
  static const _kLast = 'meal_last';

  static Future<MealRotation> open() async =>
      MealRotation(await SharedPreferences.getInstance());

  Future<MealIdea> next(List<MealIdea> meals) async {
    final byId = {for (final m in meals) m.id: m};
    var queue = (_prefs.getStringList(_kQueue) ?? [])
        .where(byId.containsKey)
        .toList();
    if (queue.isEmpty) {
      queue = byId.keys.toList()..shuffle(_random);
      final last = _prefs.getString(_kLast);
      if (queue.length > 1 && queue.first == last) {
        queue.add(queue.removeAt(0));
      }
    }
    final id = queue.removeAt(0);
    await _prefs.setStringList(_kQueue, queue);
    await _prefs.setString(_kLast, id);
    return byId[id]!;
  }
}
