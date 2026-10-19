import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:good_pro_portion/data/content_loader.dart';
import 'package:good_pro_portion/monetisation/ad_slot.dart';
import 'package:good_pro_portion/monetisation/ads_config.dart';
import 'package:good_pro_portion/monetisation/purchases.dart';
import 'package:good_pro_portion/monetisation/remove_ads_card.dart';
import 'package:good_pro_portion/screens/timer_screen.dart';
import 'package:good_pro_portion/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Issue #27 scaffolding: off by default, test IDs only, never mid-workout.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Widget wrap(Widget child) => MaterialApp(
    theme: buildLightTheme(),
    home: Scaffold(body: ListView(children: [child])),
  );

  test('ads are off unless the build turns them on', () {
    expect(adsEnabled, isFalse);
  });

  test('only Google sample ad IDs are in the code', () {
    const sample = 'ca-app-pub-3940256099942544';
    for (final id in [
      TestAdIds.androidAppId,
      TestAdIds.banner,
      TestAdIds.interstitial,
    ]) {
      expect(id, startsWith(sample));
    }
    final libFiles = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'));
    for (final f in libFiles) {
      for (final m in RegExp(
        r'ca-app-pub-(\d+)',
      ).allMatches(f.readAsStringSync())) {
        expect(m.group(1), '3940256099942544', reason: f.path);
      }
    }
  });

  test('no ad placement exists for workout screens', () {
    expect(AdPlacement.values.map((p) => p.name), ['homeBanner', 'doneBanner']);
  });

  testWidgets('switched off: nothing in release, placeholder in debug', (
    t,
  ) async {
    await t.pumpWidget(
      wrap(
        const AdSlot(
          placement: AdPlacement.homeBanner,
          enabled: false,
          showPlaceholder: false,
        ),
      ),
    );
    expect(find.byKey(const ValueKey('ad-slot-homeBanner')), findsNothing);

    await t.pumpWidget(
      wrap(
        const AdSlot(
          placement: AdPlacement.homeBanner,
          enabled: false,
          showPlaceholder: true,
        ),
      ),
    );
    expect(find.text('Ad placeholder'), findsOneWidget);
  });

  testWidgets('switched on: test slot until Remove ads is bought', (t) async {
    final svc = StubPurchaseService();
    await svc.init();
    await t.pumpWidget(
      wrap(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AdSlot(
              placement: AdPlacement.doneBanner,
              enabled: true,
              service: svc,
            ),
            RemoveAdsCard(enabled: true, service: svc),
          ],
        ),
      ),
    );
    await t.pump();
    expect(find.textContaining('Test ad'), findsOneWidget);
    expect(find.text('Restore purchase'), findsOneWidget);

    await t.tap(find.widgetWithText(FilledButton, 'Test'));
    await t.pump();
    await t.pump();
    expect(find.textContaining('Test ad'), findsNothing);
    expect(find.textContaining('Ads are off'), findsOneWidget);
  });

  test('stub purchase survives a restart and restores', () async {
    final prefs = await SharedPreferences.getInstance();
    final a = StubPurchaseService(prefs);
    await a.init();
    expect(a.adFree.value, isFalse);
    expect(await a.restore(), isFalse);
    expect(await a.buyRemoveAds(), PurchaseOutcome.purchased);

    final b = StubPurchaseService(prefs);
    await b.init();
    expect(b.adFree.value, isTrue);
    expect(await b.restore(), isTrue);
    await b.reset();
    expect(b.adFree.value, isFalse);
  });

  testWidgets('the timer screen never hosts an ad slot', (t) async {
    final content = ContentLoader.parse(
      File('assets/content.json').readAsStringSync(),
    );
    await t.pumpWidget(
      MaterialApp(
        theme: buildLightTheme(),
        home: TimerScreen(
          content: content,
          routine: content.routines.first,
          workSeconds: 40,
          restSeconds: 20,
        ),
      ),
    );
    for (var i = 0; i < 6; i++) {
      expect(find.byType(AdSlot), findsNothing);
      await t.tap(find.text('Skip ›'));
      await t.pump();
    }
    await t.pumpWidget(const SizedBox());
  });
}
