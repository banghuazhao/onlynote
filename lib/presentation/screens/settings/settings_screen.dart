import 'package:flutter/material.dart';
import 'package:onlynote/Tools/app_layout_settings.dart';
import 'package:onlynote/Tools/app_typography_settings.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/screens/home/more_apps_page.dart';
import 'package:onlynote/presentation/theme/colors.dart';
import 'package:onlynote/presentation/theme/spacing.dart';
import 'package:onlynote/presentation/theme/typography.dart';
import 'package:onlynote/services/purchase_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  PurchaseState? _shownState;

  String _fontSizeLabel(BuildContext context, AppFontSize fontSize) {
    switch (fontSize) {
      case AppFontSize.small:
        return S.of(context).Small;
      case AppFontSize.medium:
        return S.of(context).Medium;
      case AppFontSize.large:
        return S.of(context).Large;
    }
  }

  String _cardSizeLabel(BuildContext context, NoteCardSize cardSize) {
    switch (cardSize) {
      case NoteCardSize.small:
        return S.of(context).Small;
      case NoteCardSize.medium:
        return S.of(context).Medium;
      case NoteCardSize.large:
        return S.of(context).Large;
    }
  }

  @override
  Widget build(BuildContext context) {
    final typographySettings = AppTypographySettings.instance;
    final layoutSettings = AppLayoutSettings.instance;

    return Scaffold(
      appBar: AppBar(title: Text(S.of(context).Settings)),
      body: ListenableBuilder(
        listenable: Listenable.merge([
          typographySettings,
          layoutSettings,
          PurchaseService.instance,
        ]),
        builder: (context, _) {
          _showPurchaseFeedback(context);
          return ListView(
            padding: const EdgeInsets.all(AppSpacings.xl),
            children: [
              Text(S.of(context).Font_Style, style: AppTypography.headline6),
              const SizedBox(height: AppSpacings.m),
              for (final fontFamily in kAppFontFamilies.keys)
                RadioListTile<String>(
                  value: fontFamily,
                  groupValue: typographySettings.fontFamily,
                  title: Text(
                    fontFamily,
                    style: kAppFontFamilies[fontFamily]!(
                        fontSize: 16, color: AppColors.title),
                  ),
                  onChanged: (value) {
                    if (value != null) typographySettings.setFontFamily(value);
                  },
                ),
              const SizedBox(height: AppSpacings.xl),
              Text(S.of(context).Font_Size, style: AppTypography.headline6),
              const SizedBox(height: AppSpacings.m),
              for (final fontSize in AppFontSize.values)
                RadioListTile<AppFontSize>(
                  value: fontSize,
                  groupValue: typographySettings.fontSize,
                  title: Text(
                    _fontSizeLabel(context, fontSize),
                    style: TextStyle(
                        fontSize: 14 * fontSize.scale, color: AppColors.title),
                  ),
                  onChanged: (value) {
                    if (value != null) typographySettings.setFontSize(value);
                  },
                ),
              const SizedBox(height: AppSpacings.xl),
              Text(S.of(context).Card_Size, style: AppTypography.headline6),
              const SizedBox(height: AppSpacings.m),
              for (final cardSize in NoteCardSize.values)
                RadioListTile<NoteCardSize>(
                  value: cardSize,
                  groupValue: layoutSettings.cardSize,
                  title: Text(_cardSizeLabel(context, cardSize)),
                  onChanged: (value) {
                    if (value != null) layoutSettings.setCardSize(value);
                  },
                ),
              const SizedBox(height: AppSpacings.xl),
              if (PurchaseService.instance.isSupported) ...[
                Text(S.of(context).Purchases, style: AppTypography.headline6),
                const SizedBox(height: AppSpacings.m),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.block_outlined),
                  title: Text(
                    PurchaseService.instance.isAdsRemoved
                        ? S.of(context).Ads_Removed
                        : S.of(context).Remove_Ads,
                  ),
                  subtitle: Text(_purchaseSubtitle(context)),
                  enabled: !PurchaseService.instance.isAdsRemoved &&
                      PurchaseService.instance.removeAdsProduct != null &&
                      PurchaseService.instance.state != PurchaseState.loading,
                  onTap: PurchaseService.instance.buyRemoveAds,
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.restore),
                  title: Text(S.of(context).Restore_Purchases),
                  enabled:
                      PurchaseService.instance.state != PurchaseState.loading,
                  onTap: PurchaseService.instance.restorePurchases,
                ),
                const SizedBox(height: AppSpacings.xl),
              ],
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(S.of(context).More_Apps,
                    style: AppTypography.headline6),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (BuildContext context) => MoreAppsPage(),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  String _purchaseSubtitle(BuildContext context) {
    final service = PurchaseService.instance;
    if (service.isAdsRemoved) return S.of(context).Ads_Removed_Description;
    if (service.state == PurchaseState.loading)
      return S.of(context).Purchase_Loading;
    final price = service.localizedPrice;
    return price == null
        ? S.of(context).Purchase_Unavailable
        : S.of(context).Remove_Ads_Price(price);
  }

  void _showPurchaseFeedback(BuildContext context) {
    final state = PurchaseService.instance.state;
    if (state == _shownState ||
        state == PurchaseState.idle ||
        state == PurchaseState.loading) {
      return;
    }
    _shownState = state;
    final message = switch (state) {
      PurchaseState.unavailable => S.of(context).Purchase_Unavailable,
      PurchaseState.pending => S.of(context).Purchase_Pending,
      PurchaseState.cancelled => S.of(context).Purchase_Cancelled,
      PurchaseState.failed => S.of(context).Purchase_Failed,
      PurchaseState.purchased => S.of(context).Purchase_Success,
      PurchaseState.restored => S.of(context).Restore_Success,
      PurchaseState.nothingToRestore => S.of(context).Restore_Nothing,
      _ => null,
    };
    if (message != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(message)));
      });
    }
  }
}
