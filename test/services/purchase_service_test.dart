import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:onlynote/services/purchase_service.dart';

void main() {
  late FakePurchaseStore store;
  late MemoryEntitlementStorage storage;

  setUp(() {
    store = FakePurchaseStore();
    storage = MemoryEntitlementStorage();
  });

  test('loads persisted entitlement for offline ad gating', () async {
    storage.value = true;
    store.available = false;
    final service =
        PurchaseService(store: store, storage: storage, isIOS: true);

    await service.init();

    expect(service.isAdsRemoved, isTrue);
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
  Future<bool> buyNonConsumable(PurchaseParam purchaseParam) async => true;

  @override
  Future<void> restorePurchases() async => restoreCalls++;

  @override
  Future<void> completePurchase(PurchaseDetails purchase) async =>
      completedPurchases++;
}
