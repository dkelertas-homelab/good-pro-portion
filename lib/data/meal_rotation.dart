import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/content.dart';
import 'rotation.dart';

/// Hands out meal ideas from a shuffled cycle saved on the phone, so every
/// idea shows once before any repeats (and no repeat across a reshuffle).
class MealRotation {
  MealRotation(SharedPreferences prefs, {Random? random})
    : _rotation = ShuffleRotation(prefs, key: 'meal', random: random);

  final ShuffleRotation _rotation;

  static Future<MealRotation> open() async =>
      MealRotation(await SharedPreferences.getInstance());

  Future<MealIdea> next(List<MealIdea> meals) async {
    final id = await _rotation.nextId(meals.map((m) => m.id));
    return meals.firstWhere((m) => m.id == id);
  }
}

/// Same idea for the post-workout cooldown sets (K1–K5).
class CooldownRotation {
  CooldownRotation(SharedPreferences prefs, {Random? random})
    : _rotation = ShuffleRotation(prefs, key: 'cooldown', random: random);

  final ShuffleRotation _rotation;

  static Future<CooldownRotation> open() async =>
      CooldownRotation(await SharedPreferences.getInstance());

  Future<CooldownSet> next(List<CooldownSet> sets) async {
    final id = await _rotation.nextId(sets.map((s) => s.id));
    return sets.firstWhere((s) => s.id == id);
  }
}
