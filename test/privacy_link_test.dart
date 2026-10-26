import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:good_pro_portion/data/content_loader.dart';
import 'package:good_pro_portion/screens/settings_screen.dart';
import 'package:good_pro_portion/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final content = ContentLoader.parse(
    File('assets/content.json').readAsStringSync(),
  );
  final original = openExternalUrl;

  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(() => openExternalUrl = original);

  Future<Finder> openSettings(WidgetTester t) async {
    await t.pumpWidget(
      MaterialApp(
        theme: buildDarkTheme(),
        home: SettingsScreen(content: content),
      ),
    );
    await t.pumpAndSettle();
    final tile = find.widgetWithText(ListTile, 'Privacy policy');
    await t.scrollUntilVisible(tile, 200);
    return tile;
  }

  testWidgets('Privacy policy opens the hosted page', (t) async {
    final opened = <Uri>[];
    openExternalUrl = (u) async {
      opened.add(u);
      return true;
    };
    final tile = await openSettings(t);
    expect(find.textContaining('Hosted page coming'), findsNothing);
    await t.tap(tile);
    await t.pumpAndSettle();
    expect(opened, [Uri.parse('https://d11s.space/privacy/nice-pro-portions')]);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('shows the address when no browser opens', (t) async {
    openExternalUrl = (_) async => false;
    await t.tap(await openSettings(t));
    await t.pumpAndSettle();
    expect(find.textContaining("Couldn't open a browser"), findsOneWidget);
  });
}
