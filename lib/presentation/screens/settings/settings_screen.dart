import 'package:onlynote/presentation/components/appearance_section.dart';
import 'package:flutter/material.dart';
import 'package:onlynote/Tools/consent_gate.dart';
import 'package:onlynote/common/constants.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/components.dart';
import 'package:onlynote/presentation/screens/card_appearance/card_appearance_screen.dart';
import 'package:onlynote/presentation/screens/home/more_apps_page.dart';
import 'package:onlynote/presentation/theme/spacing.dart';
import 'package:onlynote/services/purchase_service.dart';
import 'package:url_launcher/url_launcher.dart';

import 'manage_folders_screen.dart';
import 'backup_screen.dart';
import 'widget_guide_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  PurchaseState? _shownState;
  bool _purchaseActionStarted = false;
  bool _restoringPurchase = false;

  @override
  Widget build(BuildContext context) {
    final purchase = PurchaseService.instance;
    final tokens = context.tokens;

    return Scaffold(
      backgroundColor: DeskSurface.colorOf(context),
      appBar: AppBar(title: Text(S.of(context).Settings)),
      body: DeskSurface(
          child: SafeArea(
              top: false,
              child: ListenableBuilder(
                listenable: Listenable.merge([purchase, ConsentGate.instance]),
                builder: (context, _) {
                  _showPurchaseFeedback(context);
                  return ListView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: EdgeInsets.fromLTRB(
                      tokens.space4,
                      tokens.space2,
                      tokens.space4,
                      tokens.space6,
                    ),
                    children: [
                      Center(
                        child: ConstrainedBox(
                          constraints:
                              BoxConstraints(maxWidth: tokens.contentMaxWidth),
                          child: Column(
                            children: [
                              const AppearanceSection(),
                              SizedBox(height: tokens.space4),
                              Card(
                                child: ListTile(
                                  leading: const Icon(Icons.style_outlined),
                                  title: Text(S.of(context).Default_Card_Style),
                                  subtitle: Text(S
                                      .of(context)
                                      .Default_Card_Style_Description),
                                  trailing:
                                      const Icon(Icons.chevron_right_rounded),
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute<void>(
                                      builder: (_) =>
                                          const CardAppearanceScreen(),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: tokens.space4),
                              Card(
                                child: ListTile(
                                  leading: const Icon(Icons.widgets_outlined),
                                  title: Text(S.of(context).Widget),
                                  subtitle:
                                      Text(S.of(context).Widget_Description),
                                  trailing:
                                      const Icon(Icons.chevron_right_rounded),
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute<void>(
                                      builder: (_) => const WidgetGuideScreen(),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: tokens.space4),
                              Card(
                                child: ListTile(
                                  leading: const Icon(Icons.folder_outlined),
                                  title: Text(S.of(context).Manage_Folders),
                                  trailing:
                                      const Icon(Icons.chevron_right_rounded),
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute<void>(
                                      builder: (_) =>
                                          const ManageFoldersScreen(),
                                    ),
                                  ),
                                ),
                              ),
                              Card(
                                child: ListTile(
                                  leading:
                                      const Icon(Icons.inventory_2_outlined),
                                  title: Text(S.of(context).Backup_Title),
                                  trailing:
                                      const Icon(Icons.chevron_right_rounded),
                                  onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute<void>(
                                          builder: (_) =>
                                              const BackupScreen())),
                                ),
                              ),
                              const SizedBox(height: 16),
                              if (purchase.isSupported) ...[
                                SizedBox(height: tokens.space4),
                                SectionCard(
                                  title: S.of(context).Purchases,
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
                                      subtitle:
                                          Text(_purchaseSubtitle(context)),
                                      trailing: purchase.state ==
                                                  PurchaseState.loading &&
                                              !_restoringPurchase
                                          ? const SizedBox.square(
                                              dimension: 20,
                                              child: CircularProgressIndicator(
                                                  strokeWidth: 2))
                                          : purchase.isAdsRemoved
                                              ? Icon(Icons.check_circle_rounded,
                                                  color: context.colors.primary)
                                              : const Icon(
                                                  Icons.chevron_right_rounded),
                                      enabled: !purchase.isAdsRemoved &&
                                          purchase.removeAdsProduct != null &&
                                          purchase.state !=
                                              PurchaseState.loading &&
                                          purchase.state !=
                                              PurchaseState.pending,
                                      onTap: () => _runPurchaseAction(
                                          purchase.buyRemoveAds),
                                    ),
                                    const Divider(),
                                    ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      leading:
                                          const Icon(Icons.restore_rounded),
                                      title:
                                          Text(S.of(context).Restore_Purchases),
                                      trailing: purchase.state ==
                                                  PurchaseState.loading &&
                                              _restoringPurchase
                                          ? const SizedBox.square(
                                              dimension: 20,
                                              child: CircularProgressIndicator(
                                                  strokeWidth: 2),
                                            )
                                          : const Icon(
                                              Icons.chevron_right_rounded),
                                      enabled: purchase.state !=
                                              PurchaseState.loading &&
                                          purchase.state !=
                                              PurchaseState.pending,
                                      onTap: () => _runPurchaseAction(
                                          purchase.restorePurchases,
                                          restoring: true),
                                    ),
                                  ],
                                ),
                              ],
                              SizedBox(height: tokens.space4),
                              SectionCard(
                                title: S.of(context).Privacy,
                                icon: Icons.privacy_tip_outlined,
                                children: [
                                  ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading:
                                        const Icon(Icons.description_outlined),
                                    title: Text(S.of(context).Privacy_Policy),
                                    trailing:
                                        const Icon(Icons.open_in_new_rounded),
                                    onTap: _openPrivacyPolicy,
                                  ),
                                  // Only offered where Google reports a withdrawal path
                                  // is owed; elsewhere the form has nothing to show.
                                  if (ConsentGate
                                      .instance.isPrivacyOptionsRequired) ...[
                                    const Divider(),
                                    ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      leading: const Icon(Icons.tune_rounded),
                                      title:
                                          Text(S.of(context).Privacy_Settings),
                                      subtitle: Text(S
                                          .of(context)
                                          .Privacy_Settings_Description),
                                      trailing: const Icon(
                                          Icons.chevron_right_rounded),
                                      onTap: ConsentGate
                                          .instance.showPrivacyOptionsForm,
                                    ),
                                  ],
                                ],
                              ),
                              SizedBox(height: tokens.space4),
                              Card(
                                child: ListTile(
                                  leading: const Icon(Icons.apps_rounded),
                                  title: Text(S.of(context).More_Apps),
                                  trailing:
                                      const Icon(Icons.chevron_right_rounded),
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute<void>(
                                      builder: (_) => const MoreAppsPage(),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ))),
    );
  }

  Future<void> _openPrivacyPolicy() async {
    final opened = await launchUrl(
      Uri.parse(kPrivacyPolicyUrl),
      mode: LaunchMode.externalApplication,
    );
    if (!opened && mounted) {
      showTransientSnackBar(
        context,
        SnackBar(content: Text(S.of(context).Privacy_Policy_Failed)),
      );
    }
  }

  String _purchaseSubtitle(BuildContext context) {
    final service = PurchaseService.instance;
    if (service.isAdsRemoved) return S.of(context).Ads_Removed_Description;
    if (service.state == PurchaseState.loading) {
      return S.of(context).Purchase_Loading;
    }
    if (service.state == PurchaseState.pending) {
      return S.of(context).Purchase_Pending;
    }
    final price = service.localizedPrice;
    return price == null
        ? S.of(context).Purchase_Unavailable
        : S.of(context).Remove_Ads_Price(price);
  }

  void _showPurchaseFeedback(BuildContext context) {
    if (!_purchaseActionStarted) return;
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
    if (state != PurchaseState.pending) {
      _purchaseActionStarted = false;
    }
    if (message != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        showTransientSnackBar(context, SnackBar(content: Text(message)));
      });
    }
  }

  Future<void> _runPurchaseAction(Future<void> Function() action,
      {bool restoring = false}) async {
    _restoringPurchase = restoring;
    _purchaseActionStarted = true;
    _shownState = PurchaseService.instance.state;
    await action();
  }
}
