import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

const removeAdsProductId = 'com.appsbay.onlynote.remove_ads';

enum PurchaseState {
  idle,
  loading,
  unavailable,
  pending,
  cancelled,
  failed,
  purchased,
  restored,
  nothingToRestore,
}

abstract class PurchaseStore {
  Stream<List<PurchaseDetails>> get purchaseStream;
  Future<bool> isAvailable();
  Future<ProductDetailsResponse> queryProductDetails(Set<String> identifiers);
  Future<bool> buyNonConsumable(PurchaseParam purchaseParam);
  Future<void> restorePurchases();
  Future<void> completePurchase(PurchaseDetails purchase);
}

class AppStorePurchaseStore implements PurchaseStore {
  const AppStorePurchaseStore();

  InAppPurchase get _store => InAppPurchase.instance;

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => _store.purchaseStream;

  @override
  Future<bool> isAvailable() => _store.isAvailable();

  @override
  Future<ProductDetailsResponse> queryProductDetails(Set<String> identifiers) =>
      _store.queryProductDetails(identifiers);

  @override
  Future<bool> buyNonConsumable(PurchaseParam purchaseParam) =>
      _store.buyNonConsumable(purchaseParam: purchaseParam);

  @override
  Future<void> restorePurchases() => _store.restorePurchases();

  @override
  Future<void> completePurchase(PurchaseDetails purchase) =>
      _store.completePurchase(purchase);
}

abstract class EntitlementStorage {
  Future<bool> readAdsRemoved();
  Future<void> writeAdsRemoved(bool value);
}

class SharedPreferencesEntitlementStorage implements EntitlementStorage {
  static const _key = 'remove_ads_entitlement';

  @override
  Future<bool> readAdsRemoved() async =>
      (await SharedPreferences.getInstance()).getBool(_key) ?? false;

  @override
  Future<void> writeAdsRemoved(bool value) async =>
      (await SharedPreferences.getInstance()).setBool(_key, value);
}

/// Owns the app's single ad-removal entitlement.
///
/// Purchase verification is isolated in [_isVerified] so receipt/server
/// verification can replace the current App Store transaction check later.
class PurchaseService extends ChangeNotifier {
  PurchaseService({
    PurchaseStore? store,
    EntitlementStorage? storage,
    bool? isIOS,
  })  : _store = store ?? const AppStorePurchaseStore(),
        _storage = storage ?? SharedPreferencesEntitlementStorage(),
        isSupported = isIOS ?? defaultTargetPlatform == TargetPlatform.iOS;

  static final PurchaseService instance = PurchaseService();

  final PurchaseStore _store;
  final EntitlementStorage _storage;
  final bool isSupported;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  ProductDetails? _removeAdsProduct;
  bool _isAdsRemoved = false;
  bool _restoreInProgress = false;
  bool _restoreFoundPurchase = false;
  PurchaseState _state = PurchaseState.idle;

  bool get isAdsRemoved => _isAdsRemoved;
  ProductDetails? get removeAdsProduct => _removeAdsProduct;
  String? get localizedPrice => _removeAdsProduct?.price;
  PurchaseState get state => _state;

  Future<void> init() async {
    _isAdsRemoved = await _storage.readAdsRemoved();
    notifyListeners();
    if (!isSupported) return;

    _subscription ??= _store.purchaseStream.listen(
      _handlePurchases,
      onError: (_) => _setState(PurchaseState.failed),
    );
    await loadProducts();

    // Reconcile with App Store transactions. A cached true entitlement is
    // retained if the device is offline; a verified restored transaction is
    // authoritative when one arrives.
    try {
      await _store.restorePurchases();
    } catch (_) {
      // Offline launches continue using the locally persisted entitlement.
    }
  }

  Future<void> loadProducts() async {
    if (!isSupported) return;
    _setState(PurchaseState.loading);
    try {
      if (!await _store.isAvailable()) {
        _setState(PurchaseState.unavailable);
        return;
      }
      final response = await _store.queryProductDetails({removeAdsProductId});
      if (response.error != null || response.productDetails.isEmpty) {
        _setState(PurchaseState.unavailable);
        return;
      }
      _removeAdsProduct = response.productDetails.first;
      _setState(PurchaseState.idle);
    } catch (_) {
      _setState(PurchaseState.unavailable);
    }
  }

  Future<void> buyRemoveAds() async {
    final product = _removeAdsProduct;
    if (!isSupported || product == null || _isAdsRemoved) {
      _setState(PurchaseState.unavailable);
      return;
    }
    try {
      final started =
          await _store.buyNonConsumable(PurchaseParam(productDetails: product));
      if (!started) _setState(PurchaseState.failed);
    } catch (_) {
      _setState(PurchaseState.failed);
    }
  }

  Future<void> restorePurchases() async {
    if (!isSupported) return;
    _restoreInProgress = true;
    _restoreFoundPurchase = false;
    _setState(PurchaseState.loading);
    try {
      await _store.restorePurchases();
      // StoreKit may emit restored transactions asynchronously.
      await Future<void>.delayed(const Duration(milliseconds: 500));
      if (_restoreInProgress && !_restoreFoundPurchase) {
        _restoreInProgress = false;
        _setState(PurchaseState.nothingToRestore);
      }
    } catch (_) {
      _restoreInProgress = false;
      _setState(PurchaseState.failed);
    }
  }

  Future<void> _handlePurchases(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.productID != removeAdsProductId) continue;
      switch (purchase.status) {
        case PurchaseStatus.pending:
          _setState(PurchaseState.pending);
        case PurchaseStatus.canceled:
          _setState(PurchaseState.cancelled);
        case PurchaseStatus.error:
          _setState(PurchaseState.failed);
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          if (await _isVerified(purchase)) {
            await _grantEntitlement();
            _restoreFoundPurchase = purchase.status == PurchaseStatus.restored;
            _restoreInProgress = false;
            _setState(
              purchase.status == PurchaseStatus.restored
                  ? PurchaseState.restored
                  : PurchaseState.purchased,
            );
          } else {
            _setState(PurchaseState.failed);
          }
      }
      if (purchase.pendingCompletePurchase) {
        await _store.completePurchase(purchase);
      }
    }
  }

  Future<bool> _isVerified(PurchaseDetails purchase) async {
    // StoreKit delivered this transaction through the official purchase
    // stream. Add server-side receipt validation here when a backend exists.
    return purchase.productID == removeAdsProductId &&
        (purchase.status == PurchaseStatus.purchased ||
            purchase.status == PurchaseStatus.restored);
  }

  Future<void> _grantEntitlement() async {
    if (_isAdsRemoved) return;
    _isAdsRemoved = true;
    await _storage.writeAdsRemoved(true);
    notifyListeners();
  }

  void _setState(PurchaseState value) {
    _state = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
