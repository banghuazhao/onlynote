import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:onlynote/services/premium_access.dart';
import 'package:onlynote/services/purchase_service.dart';

void main() {
  late FakePurchaseStore store;
  late MemoryEntitlementStorage storage;

  setUp(() {
    store = FakePurchaseStore();
    storage = MemoryEntitlementStorage();
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
  });

  test('macOS loads and restores Premium without enabling mobile ads',
      () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    final service = PurchaseService(store: store, storage: storage);

    await service.init();

    expect(service.isSupported, isTrue);
    expect(store.availabilityChecks, 1);
    expect(store.restoreCalls, 1);
    expect(service.premiumProduct?.id, removeAdsProductId);
    expect(service.shouldShowAds, isFalse);
    expect(PremiumAccess(purchases: service).limitsApply, isTrue);

    store.emit(_purchase(PurchaseStatus.restored));
    await pumpEventQueue();

    expect(service.isPremium, isTrue);
    expect(storage.value, isTrue);
    expect(store.completedPurchases, 1);
    expect(service.shouldShowAds, isFalse);
    service.dispose();
  });

  test('macOS keeps the legacy purchase support override available', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    final service =
        PurchaseService(store: store, storage: storage, isIOS: false);

    await service.init();

    expect(service.isSupported, isFalse);
    expect(store.availabilityChecks, 0);
    expect(store.restoreCalls, 0);
    expect(service.shouldShowAds, isFalse);
    service.dispose();
  });

  test('loads persisted entitlement for offline ad gating', () async {
    storage.value = true;
    store.available = false;
    final service =
        PurchaseService(store: store, storage: storage, isIOS: true);

    await service.init();

    expect(service.isAdsRemoved, isTrue);
    expect(service.isPremium, isTrue);
    service.dispose();
  });

  test('free limits and Premium unlock use the legacy entitlement', () async {
    final service =
        PurchaseService(store: store, storage: storage, isIOS: true);
    await service.init();
    final access = PremiumAccess(purchases: service);

    for (final feature in [PremiumFeature.folders, PremiumFeature.templates]) {
      expect(access.allows(feature, currentCount: 0), isTrue);
      expect(access.allows(feature, currentCount: 2), isTrue);
      expect(access.allows(feature, currentCount: 3), isFalse);
      expect(access.allows(feature, currentCount: 10), isFalse);
      expect(() => access.require(feature, currentCount: 3),
          throwsA(isA<PremiumRequired>()));
    }
    expect(access.allows(PremiumFeature.repeatingReminders), isFalse);
    expect(access.allows(PremiumFeature.individualCardStyle), isFalse);

    store.emit(_purchase(PurchaseStatus.restored));
    await pumpEventQueue();
    expect(access.isPremium, isTrue);
    for (final feature in PremiumFeature.values) {
      expect(access.allows(feature, currentCount: 100), isTrue);
    }
    service.dispose();
  });

  test('unsupported purchase platforms retain every feature', () async {
    final service =
        PurchaseService(store: store, storage: storage, isIOS: false);
    await service.init();
    final access = PremiumAccess(purchases: service);
    for (final feature in PremiumFeature.values) {
      expect(access.allows(feature, currentCount: 100), isTrue);
    }
    expect(access.isPremium, isFalse);
    service.dispose();
  });

  test('rapid Premium taps start only one transaction until cancelled',
      () async {
    final service =
        PurchaseService(store: store, storage: storage, isIOS: true);
    await service.init();
    store.buyGate = Completer<bool>();

    final first = service.buyPremium();
    await service.buyPremium();
    expect(service.state, PurchaseState.loading);
    expect(store.buyCalls, 1);
    store.buyGate!.complete(true);
    await first;
    expect(service.state, PurchaseState.pending);
    await service.buyPremium();
    await service.restorePurchases();
    expect(store.buyCalls, 1);
    expect(store.restoreCalls, 1);

    store.emit(_purchase(PurchaseStatus.canceled));
    await pumpEventQueue();
    expect(service.isPremium, isFalse);
    store.buyGate = null;
    await service.buyPremium();
    expect(store.buyCalls, 2);
    service.dispose();
  });

  test('purchase stream result survives a late store response', () async {
    final service =
        PurchaseService(store: store, storage: storage, isIOS: true);
    await service.init();
    store.buyGate = Completer<bool>();
    final buying = service.buyPremium();
    store.emit(_purchase(PurchaseStatus.purchased));
    await pumpEventQueue();
    store.buyGate!.complete(true);
    await buying;
    expect(service.state, PurchaseState.purchased);
    expect(service.isPremium, isTrue);
    await service.buyPremium();
    expect(store.buyCalls, 1);
    service.dispose();
  });

  test('declined store launch leaves free access available for retry',
      () async {
    final service =
        PurchaseService(store: store, storage: storage, isIOS: true);
    await service.init();
    store.buyStarted = false;
    await service.buyPremium();
    expect(service.state, PurchaseState.failed);
    expect(service.isPremium, isFalse);
    store.buyStarted = true;
    await service.buyPremium();
    expect(service.state, PurchaseState.pending);
    expect(store.buyCalls, 2);
    service.dispose();
  });

  test('Android does not contact the purchase store', () async {
    final service =
        PurchaseService(store: store, storage: storage, isIOS: false);

    await service.init();

    expect(service.isSupported, isFalse);
    expect(service.shouldShowAds, isTrue);
    expect(store.availabilityChecks, 0);
    expect(store.restoreCalls, 0);
    service.dispose();
  });

  test('verified purchase persists entitlement and completes transaction',
      () async {
    final service =
        PurchaseService(store: store, storage: storage, isIOS: true);
    await service.init();

    store.emit(_purchase(PurchaseStatus.purchased));
    await pumpEventQueue();

    expect(service.state, PurchaseState.purchased);
    expect(service.isAdsRemoved, isTrue);
    expect(service.shouldShowAds, isFalse);
    expect(storage.value, isTrue);
    expect(store.completedPurchases, 1);
    service.dispose();
  });

  test('cancel leaves entitlement unchanged', () async {
    final service =
        PurchaseService(store: store, storage: storage, isIOS: true);
    await service.init();

    store.emit(_purchase(PurchaseStatus.canceled));
    await pumpEventQueue();

    expect(service.state, PurchaseState.cancelled);
    expect(service.isAdsRemoved, isFalse);
    service.dispose();
  });

  test('restored transaction grants entitlement', () async {
    final service =
        PurchaseService(store: store, storage: storage, isIOS: true);
    await service.init();

    store.emit(_purchase(PurchaseStatus.restored));
    await pumpEventQueue();

    expect(service.state, PurchaseState.restored);
    expect(service.isAdsRemoved, isTrue);
    service.dispose();
  });

  test('unavailable store leaves ads enabled', () async {
    store.available = false;
    final service =
        PurchaseService(store: store, storage: storage, isIOS: true);

    await service.init();

    expect(service.state, PurchaseState.unavailable);
    expect(service.shouldShowAds, isTrue);
    service.dispose();
  });

  test('missing product reports unavailable without changing entitlement',
      () async {
    store.productAvailable = false;
    final service =
        PurchaseService(store: store, storage: storage, isIOS: true);

    await service.init();

    expect(service.state, PurchaseState.unavailable);
    expect(service.isAdsRemoved, isFalse);
    service.dispose();
  });

  test('pending purchase leaves entitlement and ad gate unchanged', () async {
    final service =
        PurchaseService(store: store, storage: storage, isIOS: true);
    await service.init();

    store.emit(_purchase(PurchaseStatus.pending));
    await pumpEventQueue();

    expect(service.state, PurchaseState.pending);
    expect(service.isAdsRemoved, isFalse);
    expect(service.shouldShowAds, isTrue);
    service.dispose();
  });

  test('purchase failure leaves entitlement and ad gate unchanged', () async {
    final service =
        PurchaseService(store: store, storage: storage, isIOS: true);
    await service.init();

    store.emit(_purchase(PurchaseStatus.error));
    await pumpEventQueue();

    expect(service.state, PurchaseState.failed);
    expect(service.isAdsRemoved, isFalse);
    expect(service.shouldShowAds, isTrue);
    service.dispose();
  });

  test('restore with no transaction reports nothing to restore', () async {
    final service =
        PurchaseService(store: store, storage: storage, isIOS: true);
    await service.init();

    await service.restorePurchases();

    expect(service.state, PurchaseState.nothingToRestore);
    expect(service.isAdsRemoved, isFalse);
    expect(store.restoreCalls, 2);
    service.dispose();
  });
}

PurchaseDetails _purchase(PurchaseStatus status) => PurchaseDetails(
      purchaseID: 'test-purchase',
      productID: removeAdsProductId,
      verificationData: PurchaseVerificationData(
        localVerificationData: 'test',
        serverVerificationData: 'test',
        source: 'test',
      ),
      transactionDate: '0',
      status: status,
    )..pendingCompletePurchase = true;

class MemoryEntitlementStorage implements EntitlementStorage {
  bool value = false;

  @override
  Future<bool> readAdsRemoved() async => value;

  @override
  Future<void> writeAdsRemoved(bool value) async => this.value = value;
}

class FakePurchaseStore implements PurchaseStore {
  final _controller = StreamController<List<PurchaseDetails>>.broadcast();
  bool available = true;
  bool productAvailable = true;
  int availabilityChecks = 0;
  int restoreCalls = 0;
  int completedPurchases = 0;
  int buyCalls = 0;
  bool buyStarted = true;
  Completer<bool>? buyGate;

  final product = ProductDetails(
    id: removeAdsProductId,
    title: 'Remove Ads',
    description: 'Remove ads permanently from this app.',
    price: r'$2.99',
    rawPrice: 2.99,
    currencyCode: 'USD',
  );

  void emit(PurchaseDetails purchase) => _controller.add([purchase]);

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => _controller.stream;

  @override
  Future<bool> isAvailable() async {
    availabilityChecks++;
    return available;
  }

  @override
  Future<ProductDetailsResponse> queryProductDetails(
          Set<String> identifiers) async =>
      ProductDetailsResponse(
        productDetails: productAvailable ? [product] : const [],
        notFoundIDs: productAvailable ? const [] : [removeAdsProductId],
      );

  @override
  Future<bool> buyNonConsumable(PurchaseParam purchaseParam) async {
    buyCalls++;
    return buyGate?.future ?? buyStarted;
  }

  @override
  Future<void> restorePurchases() async => restoreCalls++;

  @override
  Future<void> completePurchase(PurchaseDetails purchase) async =>
      completedPurchases++;
}
