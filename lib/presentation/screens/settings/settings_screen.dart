import 'package:onlynote/presentation/components/appearance_section.dart';
import 'package:flutter/material.dart';
import 'package:onlynote/Tools/app_layout_settings.dart';
import 'package:onlynote/Tools/app_typography_settings.dart';
import 'package:onlynote/Tools/consent_gate.dart';
import 'package:onlynote/common/constants.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/components.dart';
import 'package:onlynote/presentation/screens/home/more_apps_page.dart';
import 'package:onlynote/presentation/theme/spacing.dart';
import 'package:onlynote/presentation/theme/colors.dart';
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
    final typography = AppTypographySettings.instance;
    final layout = AppLayoutSettings.instance;
    final purchase = PurchaseService.instance;
    final tokens = context.tokens;

    return Scaffold(
      backgroundColor: DeskSurface.colorOf(context),
      appBar: AppBar(title: Text(S.of(context).Settings)),
      body: DeskSurface(
          child: SafeArea(
              top: false,
              child: ListenableBuilder(
                listenable: Listenable.merge(
                    [typography, layout, purchase, ConsentGate.instance]),
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
                              SectionCard(
                                title: S.of(context).Font_Style,
                                icon: Icons.text_fields_rounded,
                                children: [
                                  ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 12),
                                    tileColor: context.colors.surfaceContainer,
                                    title: Text(typography.fontFamily),
                                    trailing:
                                        const Icon(Icons.unfold_more_rounded),
                                    onTap: () => _chooseFont(context),
                                  ),
                                  SizedBox(height: tokens.space3),
                                  PaperNote(
                                    color: AppColors.parchment,
                                    tilt: false,
                                    padding: const EdgeInsets.all(20),
                                    child: SizedBox(
                                      width: double.infinity,
                                      child: Text(
                                        S.of(context).Font_Preview,
                                        style: typography
                                            .fontBuilder(
                                              color: AppColors.ink,
                                              fontSize: 18 * typography.scale,
                                            )
                                            .copyWith(height: 1.5),
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: tokens.space4),
                                  Text(S.of(context).Font_Size,
                                      style: context.textStyles.titleMedium),
                                  SizedBox(height: tokens.space2),
                                  SettingsChoice<AppFontSize>(
                                    values: AppFontSize.values,
                                    selected: typography.fontSize,
                                    label: (value) =>
                                        _sizeLabel(context, value.index),
                                    onSelected: typography.setFontSize,
                                  ),
                                ],
                              ),
                              SizedBox(height: tokens.space4),
                              SectionCard(
                                title: S.of(context).Card_Size,
                                icon: Icons.grid_view_rounded,
                                children: [
                                  SettingsChoice<NoteCardSize>(
                                    values: const [
                                      NoteCardSize.small,
                                      NoteCardSize.medium,
                                      NoteCardSize.large
                                    ],
                                    selected: layout.cardSize,
                                    label: (value) =>
                                        _sizeLabel(context, 2 - value.index),
                                    onSelected: layout.setCardSize,
                                  ),
                                  const SizedBox(height: 16),
                                  _CardSizePreview(size: layout.cardSize),
                                ],
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

  String _sizeLabel(BuildContext context, int index) => [
        S.of(context).Small,
        S.of(context).Medium,
        S.of(context).Large,
      ][index];

  Future<void> _chooseFont(BuildContext context) => showAppActionSheet(
        context: context,
        title: S.of(context).Font_Style,
        actions: [
          for (final family in kAppFontFamilies.keys)
            AppSheetAction(
              leading: const Icon(Icons.text_fields_rounded),
              title:
                  Text(family, style: kAppFontFamilies[family]!(fontSize: 18)),
              selected: AppTypographySettings.instance.fontFamily == family,
              onPressed: (sheetContext) {
                Navigator.pop(sheetContext);
                AppTypographySettings.instance.setFontFamily(family);
              },
            ),
        ],
      );

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

class _CardSizePreview extends StatelessWidget {
  const _CardSizePreview({required this.size});
  final NoteCardSize size;

  @override
  Widget build(BuildContext context) {
    final count = switch (size) {
      NoteCardSize.small => 3,
      NoteCardSize.medium => 2,
      NoteCardSize.large => 1,
    };
    return Semantics(
      label: S.of(context).Card_Size,
      image: true,
      child: ExcludeSemantics(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: DeskSurface(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < count; i++) ...[
                    if (i > 0) const SizedBox(width: 10),
                    Expanded(
                      child: PaperNote(
                        color: const [
                          Color(0xFFFFF4C2),
                          Color(0xFFDDEACB),
                          Color(0xFFF3D9CB)
                        ][i],
                        tilt: false,
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                                height: 5,
                                width: 36,
                                color: AppColors.ink.withValues(alpha: .5)),
                            const SizedBox(height: 12),
                            for (var line = 0; line < 3; line++) ...[
                              Container(
                                  height: 3,
                                  color: AppColors.ink.withValues(alpha: .15)),
                              const SizedBox(height: 8),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
