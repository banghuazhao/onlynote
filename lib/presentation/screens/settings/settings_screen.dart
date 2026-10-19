import 'package:onlynote/presentation/components/appearance_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:onlynote/Tools/consent_gate.dart';
import 'package:onlynote/common/constants.dart';
import 'package:onlynote/common/platform_capabilities.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/components.dart';
import 'package:onlynote/presentation/screens/card_appearance/card_appearance_screen.dart';
import 'package:onlynote/presentation/screens/home/more_apps_page.dart';
import 'package:onlynote/presentation/theme/spacing.dart';
import 'package:onlynote/services/purchase_service.dart';
import 'package:url_launcher/url_launcher.dart';

import 'manage_folders_screen.dart';
import 'backup_screen.dart';
import 'keyboard_shortcuts_screen.dart';
import 'premium_screen.dart';
import 'widget_guide_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    this.purchases,
    this.returnFolderSelection = false,
  });

  final PurchaseService? purchases;
  final bool returnFolderSelection;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  PurchaseState? _shownState;
  bool _purchaseActionStarted = false;
  bool _restoringPurchase = false;
  bool _openingFolders = false;

  Future<void> _openManageFolders() async {
    if (!mounted ||
        _openingFolders ||
        ModalRoute.of(context)?.isCurrent != true) {
      return;
    }
    _openingFolders = true;
    try {
      final folderId = await Navigator.push<String>(
        context,
        MaterialPageRoute<String>(builder: (_) => const ManageFoldersScreen()),
      );
      if (!mounted ||
          folderId == null ||
          !widget.returnFolderSelection ||
          ModalRoute.of(context)?.isCurrent != true) {
        return;
      }
      final navigator = Navigator.of(context);
      if (navigator.canPop()) await navigator.maybePop<String>(folderId);
    } finally {
      if (mounted) _openingFolders = false;
    }
  }

  PurchaseService get _purchases =>
      widget.purchases ?? PurchaseService.instance;

  @override
  Widget build(BuildContext context) {
    final purchase = _purchases;
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
                              if (PlatformCapabilities.homeWidgets) ...[
                                SizedBox(height: tokens.space4),
                                Card(
                                  child: ListTile(
                                    leading: const Icon(Icons.widgets_outlined),
                                    title: Text(defaultTargetPlatform ==
                                            TargetPlatform.macOS
                                        ? S.of(context).Widget_macOS_Title
                                        : S.of(context).Widget),
                                    subtitle: Text(defaultTargetPlatform ==
                                            TargetPlatform.macOS
                                        ? S.of(context).Widget_Description_macOS
                                        : S.of(context).Widget_Description),
                                    trailing:
                                        const Icon(Icons.chevron_right_rounded),
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute<void>(
                                        builder: (_) =>
                                            const WidgetGuideScreen(),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                              if (!kIsWeb &&
                                  defaultTargetPlatform ==
                                      TargetPlatform.macOS) ...[
                                SizedBox(height: tokens.space4),
                                Card(
                                  child: ListTile(
                                    key: const ValueKey(
                                        'settings-keyboard-shortcuts'),
                                    leading:
                                        const Icon(Icons.keyboard_outlined),
                                    title:
                                        Text(S.of(context).Keyboard_Shortcuts),
                                    subtitle: Text(S
                                        .of(context)
                                        .Keyboard_Shortcuts_Description),
                                    trailing:
                                        const Icon(Icons.chevron_right_rounded),
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute<void>(
                                        builder: (_) =>
                                            const KeyboardShortcutsScreen(),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                              SizedBox(height: tokens.space4),
                              Card(
                                child: ListTile(
                                  key:
                                      const ValueKey('settings-manage-folders'),
                                  leading: const Icon(Icons.folder_outlined),
                                  title: Text(S.of(context).Manage_Folders),
                                  trailing:
                                      const Icon(Icons.chevron_right_rounded),
                                  onTap: _openManageFolders,
                                ),
                              ),
                              SizedBox(height: tokens.space4),
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
                              if (purchase.isSupported) ...[
                                SizedBox(height: tokens.space4),
                                SectionCard(
                                  title: S.of(context).Premium,
                                  icon: Icons.workspace_premium_outlined,
                                  children: [
                                    ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      leading: Icon(purchase.isPremium
                                          ? Icons.verified_rounded
                                          : Icons.workspace_premium_outlined),
                                      title: Text(purchase.isPremium
                                          ? S.of(context).Premium_Active
                                          : S.of(context).Upgrade_To_Premium),
                                      subtitle: Text(purchase.isPremium
                                          ? PlatformCapabilities.mobileAds
                                              ? S
                                                  .of(context)
                                                  .Premium_Description
                                              : S
                                                  .of(context)
                                                  .Premium_Desktop_Description
                                          : S.of(context).Premium_Free_Core),
                                      trailing: const Icon(
                                          Icons.chevron_right_rounded),
                                      onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute<void>(
                                          builder: (_) => PremiumScreen(
                                              purchases: purchase),
                                        ),
                                      ),
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
                              if (PlatformCapabilities.mobileAds) ...[
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

  void _showPurchaseFeedback(BuildContext context) {
    if (!_purchaseActionStarted) return;
    final state = _purchases.state;
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
    _shownState = null;
    await action();
  }
}
