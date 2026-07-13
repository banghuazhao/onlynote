import 'package:flutter/material.dart';
import 'package:onlynote/Tools/app_layout_settings.dart';
import 'package:onlynote/Tools/app_typography_settings.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/components.dart';
import 'package:onlynote/presentation/screens/home/more_apps_page.dart';
import 'package:onlynote/presentation/theme/spacing.dart';
import 'package:onlynote/services/purchase_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  PurchaseState? _shownState;

  @override
  Widget build(BuildContext context) {
    final typography = AppTypographySettings.instance;
    final layout = AppLayoutSettings.instance;
    final purchase = PurchaseService.instance;
    final tokens = context.tokens;

    return Scaffold(
      appBar: AppBar(title: Text(S.of(context).Settings)),
      body: ListenableBuilder(
        listenable: Listenable.merge([typography, layout, purchase]),
        builder: (context, _) {
          _showPurchaseFeedback(context);
          return ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.fromLTRB(
              tokens.space4,
              tokens.space2,
              tokens.space4,
              tokens.space6,
            ),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: tokens.contentMaxWidth),
                  child: Column(
                    children: [
                      SectionCard(
                        title: S.of(context).Font_Style,
                        icon: Icons.text_fields_rounded,
                        children: [
                          DropdownMenu<String>(
                            initialSelection: typography.fontFamily,
                            expandedInsets: EdgeInsets.zero,
                            label: Text(S.of(context).Font_Style),
                            dropdownMenuEntries: [
                              for (final family in kAppFontFamilies.keys)
                                DropdownMenuEntry(value: family, label: family),
                            ],
                            onSelected: (value) {
                              if (value != null) {
                                typography.setFontFamily(value);
                              }
                            },
                          ),
                          SizedBox(height: tokens.space4),
                          Text(S.of(context).Font_Size,
                              style: context.textStyles.titleMedium),
                          SizedBox(height: tokens.space2),
                          SizedBox(
                            width: double.infinity,
                            child: SegmentedButton<AppFontSize>(
                              segments: [
                                ButtonSegment(
                                    value: AppFontSize.small,
                                    label: Text(S.of(context).Small)),
                                ButtonSegment(
                                    value: AppFontSize.medium,
                                    label: Text(S.of(context).Medium)),
                                ButtonSegment(
                                    value: AppFontSize.large,
                                    label: Text(S.of(context).Large)),
                              ],
                              selected: {typography.fontSize},
                              onSelectionChanged: (value) =>
                                  typography.setFontSize(value.first),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: tokens.space4),
                      SectionCard(
                        title: S.of(context).Card_Size,
                        icon: Icons.grid_view_rounded,
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: SegmentedButton<NoteCardSize>(
                              segments: [
                                ButtonSegment(
                                    value: NoteCardSize.small,
                                    label: Text(S.of(context).Small)),
                                ButtonSegment(
                                    value: NoteCardSize.medium,
                                    label: Text(S.of(context).Medium)),
                                ButtonSegment(
                                    value: NoteCardSize.large,
                                    label: Text(S.of(context).Large)),
                              ],
                              selected: {layout.cardSize},
                              onSelectionChanged: (value) =>
                                  layout.setCardSize(value.first),
                            ),
                          ),
                        ],
                      ),
                      if (purchase.isSupported) ...[
                        SizedBox(height: tokens.space4),
                        SectionCard(
                          title: S.of(context).Purchases,
                          subtitle: purchase.isAdsRemoved
                              ? S.of(context).Ads_Removed_Description
                              : _purchaseSubtitle(context),
                          icon: Icons.workspace_premium_outlined,
                          children: [
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(
                                purchase.isAdsRemoved
                                    ? Icons.verified_rounded
                                    : Icons.block_outlined,
                              ),
                              title: Text(purchase.isAdsRemoved
                                  ? S.of(context).Ads_Removed
                                  : S.of(context).Remove_Ads),
                              subtitle: purchase.isAdsRemoved
                                  ? null
                                  : Text(_purchaseSubtitle(context)),
                              trailing: purchase.isAdsRemoved
                                  ? Icon(Icons.check_circle_rounded,
                                      color: context.colors.primary)
                                  : const Icon(Icons.chevron_right_rounded),
                              enabled: !purchase.isAdsRemoved &&
                                  purchase.removeAdsProduct != null &&
                                  purchase.state != PurchaseState.loading,
                              onTap: purchase.buyRemoveAds,
                            ),
                            const Divider(),
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.restore_rounded),
                              title: Text(S.of(context).Restore_Purchases),
                              trailing: purchase.state == PurchaseState.loading
                                  ? const SizedBox.square(
                                      dimension: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    )
                                  : const Icon(Icons.chevron_right_rounded),
                              enabled: purchase.state != PurchaseState.loading,
                              onTap: purchase.restorePurchases,
                            ),
                          ],
                        ),
                      ],
                      SizedBox(height: tokens.space4),
                      SectionCard(
                        title: S.of(context).More_Apps,
                        icon: Icons.apps_rounded,
                        children: [
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(S.of(context).More_Apps),
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                  builder: (_) => const MoreAppsPage()),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
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
    if (service.state == PurchaseState.loading) {
      return S.of(context).Purchase_Loading;
    }
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
