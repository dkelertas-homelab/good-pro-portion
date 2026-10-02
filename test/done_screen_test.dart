import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:good_pro_portion/data/content_loader.dart';
import 'package:good_pro_portion/models/content.dart';
import 'package:good_pro_portion/screens/done_screen.dart';
import 'package:good_pro_portion/screens/timer_screen.dart';
import 'package:good_pro_portion/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late AppContent content;
  setUpAll(() {
    content = ContentLoader.parse(File('assets/content.json').readAsStringSync());
  });

  Future<void> pumpDone(WidgetTester t, Routine r) async {
    t.view.physicalSize = const Size(412, 915);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(MaterialApp(
      theme: buildLightTheme(),
      home: DoneScreen(content: content, routine: r, elapsed: const Duration(minutes: 9)),
    ));
    await t.pump();
  }

  test('A and B are each other\'s partner', () {
    final a = content.routines.firstWhere((r) => r.name == 'Quiet morning A');
    final b = content.routines.firstWhere((r) => r.name == 'Quiet morning B');
    expect(content.partnerOf(a), same(b));
    expect(content.partnerOf(b), same(a));
  });

  testWidgets('finishing A offers B, and Start B starts it', (t) async {
    SharedPreferences.setMockInitialValues({'show_start_card': false});
    await pumpDone(t, content.routines.firstWhere((r) => r.name == 'Quiet morning A'));
    expect(find.text('Got more time?'), findsOneWidget);
    expect(find.text('Why not start Quiet morning B?'), findsOneWidget);
    expect(find.text('Done for today'), findsOneWidget);
    await t.tap(find.text('Start B'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 500));
    final timer = t.widget<TimerScreen>(find.byType(TimerScreen));
    expect(timer.routine.name, 'Quiet morning B');
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('finishing B offers A', (t) async {
    await pumpDone(t, content.routines.firstWhere((r) => r.name == 'Quiet morning B'));
    expect(find.text('Why not start Quiet morning A?'), findsOneWidget);
    expect(find.text('Start A'), findsOneWidget);
  });
}
