import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/theme/theme.dart';
import 'package:onlynote/services/premium_access.dart';
import 'package:onlynote/services/purchase_service.dart';

import 'premium_screen.dart';

@Preview(name: 'Upgrade', group: 'Premium', size: Size(390, 844))
Widget premiumUpgradePreview() => const _PremiumPreview();

@Preview(
    name: 'Premium unlocked, dark',
    group: 'Premium',
    size: Size(390, 844),
    brightness: Brightness.dark)
Widget premiumUnlockedPreview() =>
    const _PremiumPreview(premium: true, dark: true);

@Preview(
    name: 'Upgrade, narrow Chinese 2×', group: 'Premium', size: Size(320, 760))
Widget premiumChinesePreview() =>
    const _PremiumPreview(chinese: true, scale: 2);

@Preview(name: 'Mac upgrade', group: 'Premium', size: Size(1100, 720))
Widget premiumDesktopPreview() => const _PremiumPreview(desktop: true);

@Preview(name: 'Mac Premium unlocked', group: 'Premium', size: Size(1100, 720))
Widget premiumDesktopUnlockedPreview() =>
    const _PremiumPreview(desktop: true, premium: true);

class _PremiumPreview extends StatefulWidget {
  const _PremiumPreview(
      {this.premium = false,
      this.dark = false,
      this.chinese = false,
      this.desktop = false,
      this.scale = 1});

  final bool premium;
  final bool dark;
  final bool chinese;
  final bool desktop;
  final double scale;

  @override
  State<_PremiumPreview> createState() => _PremiumPreviewState();
}

class _PremiumPreviewState extends State<_PremiumPreview> {
  late final _PreviewPurchases _purchases =
      _PreviewPurchases(premium: widget.premium);

  @override
  void dispose() {
    _purchases.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: widget.desktop
            ? (widget.dark ? AppTheme.dark : AppTheme.light)
                .copyWith(platform: TargetPlatform.macOS)
            : widget.dark
                ? AppTheme.dark
                : AppTheme.light,
        locale: widget.chinese ? const Locale('zh', 'HK') : const Locale('en'),
        supportedLocales: S.delegate.supportedLocales,
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(widget.scale)),
          child: child!,
        ),
        home: PremiumScreen(
            purchases: _purchases,
            showAdRemovalBenefit: !widget.desktop,
            feature: widget.premium ? null : PremiumFeature.voiceMemos),
      );
}

/// Preview buttons change local state without opening a store or preferences.
class _PreviewPurchases extends PurchaseService {
  _PreviewPurchases({required bool premium})
      : _premium = premium,
        super(isIOS: true);

  bool _premium;
  PurchaseState _previewState = PurchaseState.idle;
  final _product = ProductDetails(
      id: removeAdsProductId,
      title: 'Premium preview',
      description: 'Preview only',
      price: r'$2.99',
      rawPrice: 2.99,
      currencyCode: 'USD');

  @override
  bool get isPremium => _premium;

  @override
  ProductDetails get premiumProduct => _product;

  @override
  String get localizedPrice => _product.price;

  @override
  PurchaseState get state => _previewState;

  @override
  Future<void> buyPremium() async {
    _premium = true;
    _previewState = PurchaseState.purchased;
    notifyListeners();
  }

  @override
  Future<void> restorePurchases() async {
    _premium = true;
    _previewState = PurchaseState.restored;
    notifyListeners();
  }
}
