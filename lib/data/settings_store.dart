import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsStore {
  SettingsStore(this._prefs);
  final SharedPreferences _prefs;

  static const _kWork = 'work_seconds';
  static const _kRest = 'rest_seconds';
  static const _kStartCard = 'show_start_card';
  static const _kCooldown = 'cooldown_enabled';
  static const _kDark = 'dark_mode';
  static const _kWarmup = 'warmup_enabled';
  static const _kTestMode = 'test_mode';

  /// Live cooldown/warm-up switches so the routine chip and Settings stay in
  /// sync while both are on screen.
  static final cooldown = ValueNotifier<bool>(false);
  static final warmup = ValueNotifier<bool>(true);

  /// App-wide dark mode, listened to by the MaterialApp. Dark by default.
  static final darkMode = ValueNotifier<bool>(true);

  /// Dark unless the user switched to light in Settings.
  bool get darkModeEnabled => _prefs.getBool(_kDark) ?? true;
  Future<void> setDarkMode(bool v) {
    darkMode.value = v;
    return _prefs.setBool(_kDark, v);
  }

  int get workSeconds => _prefs.getInt(_kWork) ?? 40;
  int get restSeconds => _prefs.getInt(_kRest) ?? 20;

  /// The "Before you start" card, shown on Start until the user opts out.
  bool get showStartCard => _prefs.getBool(_kStartCard) ?? true;
  Future<void> setShowStartCard(bool v) => _prefs.setBool(_kStartCard, v);

  /// Breathing cooldown after a workout. Off until the user turns it on.
  bool get cooldownEnabled => _prefs.getBool(_kCooldown) ?? false;
  Future<void> setCooldownEnabled(bool v) {
    cooldown.value = v;
    return _prefs.setBool(_kCooldown, v);
  }

  /// Warm-up moves before the workout. On until the user skips them.
  bool get warmupEnabled => _prefs.getBool(_kWarmup) ?? true;
  Future<void> setWarmupEnabled(bool v) {
    warmup.value = v;
    return _prefs.setBool(_kWarmup, v);
  }

  /// Debug builds only: every timer starts at 5 s left. Always off in release.
  bool get testMode => kDebugMode && (_prefs.getBool(_kTestMode) ?? false);
  Future<void> setTestMode(bool v) => _prefs.setBool(_kTestMode, v);

  Future<void> setWorkSeconds(int v) => _prefs.setInt(_kWork, v);
  Future<void> setRestSeconds(int v) => _prefs.setInt(_kRest, v);

  static Future<SettingsStore> open() async {
    final s = SettingsStore(await SharedPreferences.getInstance());
    cooldown.value = s.cooldownEnabled;
    warmup.value = s.warmupEnabled;
    return s;
  }
}
