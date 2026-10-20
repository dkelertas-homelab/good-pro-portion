import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

/// A shuffled no-repeat cycle saved on the phone: every id comes up once
/// before any repeats, and the last one of a cycle never opens the next.
class ShuffleRotation {
  ShuffleRotation(this._prefs, {required String key, Random? random})
    : _kQueue = '${key}_queue',
      _kLast = '${key}_last',
      _random = random ?? Random();

  final SharedPreferences _prefs;
  final String _kQueue;
  final String _kLast;
  final Random _random;

  Future<String> nextId(Iterable<String> ids) async {
    final all = ids.toSet();
    if (all.isEmpty) throw StateError('nothing to rotate');
    var queue = (_prefs.getStringList(_kQueue) ?? [])
        .where(all.contains)
        .toList();
    if (queue.isEmpty) {
      queue = all.toList()..shuffle(_random);
      final last = _prefs.getString(_kLast);
      if (queue.length > 1 && queue.first == last) {
        queue.add(queue.removeAt(0));
      }
    }
    final id = queue.removeAt(0);
    await _prefs.setStringList(_kQueue, queue);
    await _prefs.setString(_kLast, id);
    return id;
  }
}
