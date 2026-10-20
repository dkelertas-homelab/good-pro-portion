import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:good_pro_portion/data/content_loader.dart';
import 'package:good_pro_portion/data/settings_store.dart';
import 'package:good_pro_portion/main.dart';
import 'package:good_pro_portion/screens/settings_screen.dart';
import 'package:good_pro_portion/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final content = ContentLoader.parse(
    File('assets/content.json').readAsStringSync(),
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SettingsStore.darkMode.value = true;
  });

  test('fresh install defaults to dark mode', () async {
    final prefs = await SharedPreferences.getInstance();
    expect(SettingsStore(prefs).darkModeEnabled, isTrue);
    await SettingsStore(prefs).setDarkMode(false);
    expect(SettingsStore(prefs).darkModeEnabled, isFalse);
    expect(SettingsStore.darkMode.value, isFalse);
  });

  testWidgets('app starts dark, switch to light from Settings', (t) async {
    await t.pumpWidget(GoodProPortionApp(content: content));
    await t.pump();
    final app = t.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.dark);
    expect(
      Theme.of(t.element(find.byType(Scaffold).first)).brightness,
      Brightness.dark,
    );

    await t.pumpWidget(
      MaterialApp(
        theme: buildDarkTheme(),
        home: SettingsScreen(content: content),
      ),
    );
    await t.pumpAndSettle();
    final sw = find.byKey(const ValueKey('dark-mode-switch'));
    await t.scrollUntilVisible(sw, 200);
    expect(t.widget<SwitchListTile>(sw).value, isTrue);
    await t.tap(sw);
    await t.pumpAndSettle();
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('dark_mode'), isFalse);
    expect(SettingsStore.darkMode.value, isFalse);
  });
}
