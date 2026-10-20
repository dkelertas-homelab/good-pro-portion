import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ads_config.dart';
import 'purchases.dart';

/// The bits of the store [PlayPurchaseService] uses. The real one wraps
/// [InAppPurchase]; tests pass a fake.
abstract class BillingStore {
  Future<bool> isAvailable();
  Future<ProductDetailsResponse> queryProductDetails(Set<String> ids);
  Stream<List<PurchaseDetails>> get purchaseStream;
  Future<bool> buyNonConsumable(ProductDetails product);
  Future<void> completePurchase(PurchaseDetails purchase);
  Future<void> restorePurchases();
}

class InAppPurchaseStore implements BillingStore {
  InAppPurchaseStore([InAppPurchase? iap])
    : _iap = iap ?? InAppPurchase.instance;
  final InAppPurchase _iap;

  @override
  Future<bool> isAvailable() => _iap.isAvailable();
  @override
  Future<ProductDetailsResponse> queryProductDetails(Set<String> ids) =>
      _iap.queryProductDetails(ids);
  @override
  Stream<List<PurchaseDetails>> get purchaseStream => _iap.purchaseStream;
  @override
  Future<bool> buyNonConsumable(ProductDetails product) => _iap
      .buyNonConsumable(purchaseParam: PurchaseParam(productDetails: product));
  @override
  Future<void> completePurchase(PurchaseDetails purchase) =>
      _iap.completePurchase(purchase);
  @override
  Future<void> restorePurchases() => _iap.restorePurchases();
}

/// Remove ads through Google Play Billing (one-off, non-consumable
/// `remove_ads`).
///
/// - Ownership is cached in SharedPreferences so ads stay off offline and on
///   start-up before Play answers.
/// - Every purchase update is acknowledged with `completePurchase` (Play
///   refunds purchases that aren't acknowledged within 3 days).
/// - No server-side verification: this is a cosmetic entitlement.
class PlayPurchaseService implements PurchaseService {
  PlayPurchaseService({
    BillingStore? store,
    SharedPreferences? prefs,
    this.restoreTimeout = const Duration(seconds: 8),
  }) {
    _store = store;
    _prefs = prefs;
  }

  static const ownedKey = 'remove_ads_owned';

  BillingStore? _store;
  SharedPreferences? _prefs;
  final Duration restoreTimeout;

  final _adFree = ValueNotifier<bool>(false);
  final _available = ValueNotifier<bool>(false);
  ProductDetails? _product;
  StreamSubscription<List<PurchaseDetails>>? _sub;
  Future<void>? _initFuture;
  Completer<PurchaseOutcome>? _buying;
  Completer<void>? _restoring;

  @override
  ValueListenable<bool> get adFree => _adFree;

  @override
  ValueListenable<bool> get available => _available;

  @override
  String? get priceLabel => _product?.price;

  @override
  Future<void> init() => _initFuture ??= _init();

  Future<void> _init() async {
    _prefs ??= await SharedPreferences.getInstance();
    _adFree.value = _prefs!.getBool(ownedKey) ?? false;
    final store = _store ??= InAppPurchaseStore();
    // Listen before anything else so purchases finished while the app was
    // closed (or pending ones that cleared) are delivered and acknowledged.
    _sub = store.purchaseStream.listen(
      _onPurchases,
      onError: (Object e) => debugPrint('Purchase stream error: $e'),
    );
    try {
      if (!await store.isAvailable()) return;
      final r = await store.queryProductDetails({removeAdsProductId});
      if (r.error != null) debugPrint('Product query: ${r.error!.message}');
      _product = r.productDetails
          .where((p) => p.id == removeAdsProductId)
          .firstOrNull;
      _available.value = _product != null;
    } catch (e) {
      debugPrint('Billing unavailable: $e');
    }
  }

  Future<void> _onPurchases(List<PurchaseDetails> list) async {
    for (final p in list.where((p) => p.productID == removeAdsProductId)) {
      switch (p.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await _setOwned(true);
          _buying?.complete(PurchaseOutcome.purchased);
          _buying = null;
        case PurchaseStatus.pending:
          _buying?.complete(PurchaseOutcome.pending);
          _buying = null;
        case PurchaseStatus.canceled:
          _buying?.complete(PurchaseOutcome.cancelled);
          _buying = null;
        case PurchaseStatus.error:
          debugPrint('Purchase error: ${p.error?.message}');
          _buying?.complete(PurchaseOutcome.failed);
          _buying = null;
      }
      if (p.pendingCompletePurchase) {
        try {
          await _store!.completePurchase(p);
        } catch (e) {
          debugPrint('completePurchase failed: $e');
        }
      }
    }
    if (_restoring != null && !_restoring!.isCompleted) _restoring!.complete();
  }

  Future<void> _setOwned(bool owned) async {
    _adFree.value = owned;
    await _prefs!.setBool(ownedKey, owned);
  }

  @override
  Future<PurchaseOutcome> buyRemoveAds() async {
    await init();
    final product = _product;
    if (product == null) return PurchaseOutcome.unavailable;
    if (_adFree.value) return PurchaseOutcome.purchased;
    final c = _buying = Completer<PurchaseOutcome>();
    try {
      if (!await _store!.buyNonConsumable(product)) {
        _buying = null;
        return PurchaseOutcome.failed;
      }
    } catch (e) {
      // e.g. "already owned": a restore sorts it out.
      debugPrint('buyNonConsumable: $e');
      _buying = null;
      return await restore()
          ? PurchaseOutcome.purchased
          : PurchaseOutcome.failed;
    }
    return c.future;
  }

  @override
  Future<bool> restore() async {
    await init();
    final c = _restoring = Completer<void>();
    try {
      await _store!.restorePurchases();
      await c.future.timeout(restoreTimeout, onTimeout: () {});
    } catch (e) {
      debugPrint('restorePurchases: $e');
    } finally {
      _restoring = null;
    }
    return _adFree.value;
  }

  Future<void> dispose() async => _sub?.cancel();
}
