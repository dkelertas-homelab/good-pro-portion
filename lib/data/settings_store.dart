import 'package:shared_preferences/shared_preferences.dart';

class SettingsStore {
  SettingsStore(this._prefs);
  final SharedPreferences _prefs;

  static const _kWork = 'work_seconds';
  static const _kRest = 'rest_seconds';

  int get workSeconds => _prefs.getInt(_kWork) ?? 40;
  int get restSeconds => _prefs.getInt(_kRest) ?? 20;

  Future<void> setWorkSeconds(int v) => _prefs.setInt(_kWork, v);
  Future<void> setRestSeconds(int v) => _prefs.setInt(_kRest, v);

  static Future<SettingsStore> open() async =>
      SettingsStore(await SharedPreferences.getInstance());
}
