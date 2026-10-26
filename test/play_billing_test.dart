import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:good_pro_portion/monetisation/ads_config.dart';
import 'package:good_pro_portion/monetisation/play_billing.dart';
import 'package:good_pro_portion/monetisation/purchases.dart';
import 'package:good_pro_portion/monetisation/remove_ads_card.dart';
import 'package:good_pro_portion/theme/app_theme.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A fake Play store: answers queries and replays purchase updates.
class FakeStore implements BillingStore {
  FakeStore({this.hasProduct = true, this.storeUp = true});

  bool hasProduct;
  bool storeUp;
  bool owned = false;

  /// What the next buy should produce on the stream.
  PurchaseStatus buyResult = PurchaseStatus.purchased;
  final completed = <PurchaseDetails>[];
  final _ctrl = StreamController<List<PurchaseDetails>>.broadcast();

  static final product = ProductDetails(
    id: removeAdsProductId,
    title: 'Remove ads',
    description: '',
    price: r'A$4.99',
    rawPrice: 4.99,
    currencyCode: 'AUD',
  );

  PurchaseDetails _p(PurchaseStatus s) =>
      PurchaseDetails(
          productID: removeAdsProductId,
          verificationData: PurchaseVerificationData(
            localVerificationData: '',
            serverVerificationData: '',
            source: 'fake',
          ),
          transactionDate: null,
          status: s,
        )
        ..pendingCompletePurchase =
            s == PurchaseStatus.purchased || s == PurchaseStatus.restored;

  void emit(PurchaseStatus s) => _ctrl.add([_p(s)]);

  @override
  Future<bool> isAvailable() async => storeUp;

  @override
  Future<ProductDetailsResponse> queryProductDetails(Set<String> ids) async =>
      ProductDetailsResponse(
        productDetails: hasProduct ? [product] : [],
        notFoundIDs: hasProduct ? [] : ids.toList(),
      );

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => _ctrl.stream;

  @override
  Future<bool> buyNonConsumable(ProductDetails product) async {
    scheduleMicrotask(() {
      if (buyResult == PurchaseStatus.purchased) owned = true;
      emit(buyResult);
    });
    return true;
  }

  @override
  Future<void> completePurchase(PurchaseDetails purchase) async =>
      completed.add(purchase);

  /// What Play's purchase cache returns; null makes the query fail.
  List<PurchaseStatus>? ownedStatuses;

  @override
  Future<List<PurchaseDetails>> queryOwnedPurchases() async {
    final st = ownedStatuses ?? (owned ? [PurchaseStatus.purchased] : []);
    if (queryFails) throw StateError('Play unavailable');
    return [for (final x in st) _p(x)];
  }

  bool queryFails = false;

  @override
  Future<void> restorePurchases() async => scheduleMicrotask(
    () => _ctrl.add(owned ? [_p(PurchaseStatus.restored)] : []),
  );
}

void main() {
  late SharedPreferences prefs;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  PlayPurchaseService svc(FakeStore s) => PlayPurchaseService(
    store: s,
    prefs: prefs,
    restoreTimeout: const Duration(milliseconds: 200),
  );

  test('queries the product and shows its price', () async {
    final s = svc(FakeStore());
    await s.init();
    expect(s.available.value, isTrue);
    expect(s.priceLabel, r'A$4.99');
    expect(s.adFree.value, isFalse);
  });

  test('buy: owned, acknowledged and persisted across restarts', () async {
    final store = FakeStore();
    final s = svc(store);
    expect(await s.buyRemoveAds(), PurchaseOutcome.purchased);
    expect(s.adFree.value, isTrue);
    expect(store.completed, hasLength(1), reason: 'must acknowledge');
    expect(prefs.getBool(PlayPurchaseService.ownedKey), isTrue);

    final again = svc(FakeStore(storeUp: false));
    await again.init();
    expect(again.adFree.value, isTrue, reason: 'cached entitlement offline');
  });

  test('cancel, error and pending leave ads on', () async {
    for (final (status, outcome) in [
      (PurchaseStatus.canceled, PurchaseOutcome.cancelled),
      (PurchaseStatus.error, PurchaseOutcome.failed),
      (PurchaseStatus.pending, PurchaseOutcome.pending),
    ]) {
      final s = svc(FakeStore()..buyResult = status);
      expect(await s.buyRemoveAds(), outcome);
      expect(s.adFree.value, isFalse);
    }
  });

  test('a pending purchase that clears later turns ads off', () async {
    final store = FakeStore()..buyResult = PurchaseStatus.pending;
    final s = svc(store);
    expect(await s.buyRemoveAds(), PurchaseOutcome.pending);
    store.emit(PurchaseStatus.purchased);
    await Future<void>.delayed(Duration.zero);
    expect(s.adFree.value, isTrue);
    expect(store.completed, hasLength(1));
  });

  test('restore finds an earlier purchase, or reports none', () async {
    final none = svc(FakeStore());
    expect(await none.restore(), isFalse);

    final store = FakeStore()..owned = true;
    final s = svc(store);
    expect(await s.restore(), isTrue);
    expect(s.adFree.value, isTrue);
    // Acknowledged by the restore and the start-up check.
    expect(store.completed, isNotEmpty);
  });

  test('missing product or no Play: unavailable, nothing charged', () async {
    for (final store in [
      FakeStore(hasProduct: false),
      FakeStore(storeUp: false),
    ]) {
      final s = svc(store);
      await s.init();
      expect(s.available.value, isFalse);
      expect(await s.buyRemoveAds(), PurchaseOutcome.unavailable);
      expect(s.adFree.value, isFalse);
    }
  });

  test('start-up check: reinstall hides ads without tapping Restore', () async {
    final store = FakeStore()..owned = true;
    final s = svc(store);
    await s.init();
    await s.ownershipCheck;
    expect(s.adFree.value, isTrue);
    expect(prefs.getBool(PlayPurchaseService.ownedKey), isTrue);
    expect(store.completed, hasLength(1), reason: 'acknowledged if needed');
  });

  test(
    'start-up check: refunded or revoked purchase brings ads back',
    () async {
      await prefs.setBool(PlayPurchaseService.ownedKey, true);
      final s = svc(FakeStore());
      await s.init();
      expect(s.adFree.value, isTrue, reason: 'cached until Play answers');
      await s.ownershipCheck;
      expect(s.adFree.value, isFalse);
      expect(prefs.getBool(PlayPurchaseService.ownedKey), isFalse);
    },
  );

  test(
    'start-up check: a failed query or pending payment changes nothing',
    () async {
      await prefs.setBool(PlayPurchaseService.ownedKey, true);
      final failing = svc(FakeStore()..queryFails = true);
      await failing.init();
      await failing.ownershipCheck;
      expect(failing.adFree.value, isTrue);

      final pending = svc(
        FakeStore()..ownedStatuses = [PurchaseStatus.pending],
      );
      await pending.init();
      await pending.ownershipCheck;
      expect(pending.adFree.value, isTrue);
    },
  );

  test('start-up check skipped when Play is down', () async {
    final s = svc(FakeStore(storeUp: false)..owned = true);
    await s.init();
    expect(s.ownershipCheck, isNull);
    expect(s.adFree.value, isFalse);
  });

  Widget wrap(Widget child) => MaterialApp(
    theme: buildLightTheme(),
    home: Scaffold(body: ListView(children: [child])),
  );

  testWidgets('card: price button, then thanks after buying', (t) async {
    final s = svc(FakeStore());
    await t.runAsync(s.init);
    await t.pumpWidget(wrap(RemoveAdsCard(enabled: true, service: s)));
    expect(find.widgetWithText(FilledButton, r'A$4.99'), findsOneWidget);
    await t.runAsync(s.buyRemoveAds);
    await t.pump();
    expect(find.textContaining('Ads are off'), findsOneWidget);
  });

  testWidgets('card: graceful when the product is missing', (t) async {
    final s = svc(FakeStore(hasProduct: false));
    await t.runAsync(s.init);
    await t.pumpWidget(wrap(RemoveAdsCard(enabled: true, service: s)));
    expect(find.text('Not available right now'), findsOneWidget);
    expect(find.byType(FilledButton), findsNothing);
    expect(find.text('Restore purchase'), findsOneWidget);
  });
}
