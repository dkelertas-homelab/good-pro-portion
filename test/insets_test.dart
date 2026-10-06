import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:good_pro_portion/data/content_loader.dart';
import 'package:good_pro_portion/models/content.dart';
import 'package:good_pro_portion/screens/home_screen.dart';
import 'package:good_pro_portion/screens/routine_screen.dart';
import 'package:good_pro_portion/screens/settings_screen.dart';
import 'package:good_pro_portion/theme/app_theme.dart';
import 'package:good_pro_portion/widgets/insets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Edge-to-edge: a 48dp gesture/nav bar overlaps the bottom of the screen.
/// The last list item must scroll fully clear of it (and of any bottom bar),
/// and bottom bars must reach the screen edge with no gap underneath.
void main() {
  const navInset = 48.0;
  late AppContent content;

  setUpAll(() {
    content = ContentLoader.parse(
      File('assets/content.json').readAsStringSync(),
    );
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pumpScreen(WidgetTester t, Widget screen) async {
    t.view.physicalSize = const Size(360, 640);
    t.view.devicePixelRatio = 1;
    t.view.padding = const FakeViewPadding(bottom: navInset);
    t.view.viewPadding = const FakeViewPadding(bottom: navInset);
    addTearDown(t.view.reset);
    await t.pumpWidget(MaterialApp(theme: buildLightTheme(), home: screen));
    await t.pumpAndSettle();
  }

  Future<void> scrollToEnd(WidgetTester t) async {
    await t.drag(find.byType(Scrollable).first, const Offset(0, -5000));
    await t.pumpAndSettle();
  }

  testWidgets('routine: last move clears the Start bar, bar sits flush', (
    t,
  ) async {
    await pumpScreen(
      t,
      RoutineScreen(content: content, routine: content.routines.first),
    );
    await scrollToEnd(t);
    final bar = t.getRect(find.byType(BottomBar));
    expect(
      bar.bottom,
      640,
      reason: 'bar reaches the screen edge (no blank band)',
    );
    final button = t.getRect(find.byType(FilledButton));
    expect(
      button.bottom,
      lessThanOrEqualTo(640 - navInset),
      reason: 'button above the nav bar',
    );
    final last = t.getRect(find.text('8. Glute bridge'));
    expect(last.bottom, lessThanOrEqualTo(bar.top));
  });

  testWidgets('home: last item clears the nav bar', (t) async {
    await pumpScreen(t, HomeScreen(content: content));
    await scrollToEnd(t);
    expect(
      t.getRect(find.text('Ad placeholder')).bottom,
      lessThanOrEqualTo(640 - navInset),
    );
  });

  testWidgets('settings: last item clears the nav bar', (t) async {
    await pumpScreen(t, SettingsScreen(content: content));
    await scrollToEnd(t);
    expect(
      t.getRect(find.text('Health disclaimer')).bottom,
      lessThanOrEqualTo(640 - navInset),
    );
  });
}
