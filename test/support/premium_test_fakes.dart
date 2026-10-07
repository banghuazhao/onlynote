import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:onlynote/services/premium_access.dart';
import 'package:onlynote/services/purchase_service.dart';

/// Uses the real entitlement service with an in-memory App Store.
class PremiumTestFixture {
  PremiumTestFixture({bool premium = false, bool supported = true}) {
    storage = TestEntitlementStorage(premium);
    purchases =
        PurchaseService(store: store, storage: storage, isIOS: supported);
    access = PremiumAccess(purchases: purchases);
  }

  final store = TestPremiumPurchaseStore();
  late final TestEntitlementStorage storage;
  late final PurchaseService purchases;
  late final PremiumAccess access;

  Future<void> init() => purchases.init();

  Future<void> dispose() async {
    purchases.dispose();
    await store.dispose();
  }
}

class TestEntitlementStorage implements EntitlementStorage {
  TestEntitlementStorage([this.value = false]);
  bool value;

  @override
  Future<bool> readAdsRemoved() async => value;

  @override
  Future<void> writeAdsRemoved(bool value) async => this.value = value;
}

class TestPremiumPurchaseStore implements PurchaseStore {
  final _transactions = StreamController<List<PurchaseDetails>>.broadcast();
  bool available = true;
  bool grantOnBuy = true;
  bool grantOnRestore = false;
  bool buyStarts = true;
  int buyCalls = 0;
  int completedPurchases = 0;
  final product = ProductDetails(
      id: removeAdsProductId,
      title: 'OnlyNote Premium',
      description: 'Unlock Premium.',
      price: r'$2.99',
      rawPrice: 2.99,
      currencyCode: 'USD');

  void grant() => emit(PurchaseStatus.purchased);

  void emit(PurchaseStatus status) => _transactions.add([
        PurchaseDetails(
          purchaseID: 'premium-test',
          productID: removeAdsProductId,
          verificationData: PurchaseVerificationData(
              localVerificationData: 'test',
              serverVerificationData: 'test',
              source: 'test'),
          transactionDate: '0',
          status: status,
        )..pendingCompletePurchase = true
      ]);

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => _transactions.stream;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<ProductDetailsResponse> queryProductDetails(
          Set<String> identifiers) async =>
      ProductDetailsResponse(productDetails: [product], notFoundIDs: const []);

  @override
  Future<bool> buyNonConsumable(PurchaseParam purchaseParam) async {
    buyCalls++;
    if (!buyStarts) return false;
    if (grantOnBuy) grant();
    return true;
  }

  @override
  Future<void> restorePurchases() async {
    if (grantOnRestore) emit(PurchaseStatus.restored);
  }

  @override
  Future<void> completePurchase(PurchaseDetails purchase) async {
    completedPurchases++;
  }

  Future<void> dispose() => _transactions.close();
}
