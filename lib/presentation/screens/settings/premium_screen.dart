import 'package:flutter/material.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/components.dart';
import 'package:onlynote/presentation/theme/spacing.dart';
import 'package:onlynote/services/premium_access.dart';
import 'package:onlynote/services/purchase_service.dart';

/// Explains the free plan and the app's existing one-time Premium purchase.
class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key, this.purchases, this.feature});

  final PurchaseService? purchases;
  final PremiumFeature? feature;

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  PurchaseService get _purchases =>
      widget.purchases ?? PurchaseService.instance;
  bool _actionStarted = false;
  bool _performingAction = false;
  bool _restoring = false;
  PurchaseState? _shownState;

  @override
  void initState() {
    super.initState();
    _purchases.addListener(_purchaseChanged);
  }

  @override
  void didUpdateWidget(covariant PremiumScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.purchases != widget.purchases) {
      (oldWidget.purchases ?? PurchaseService.instance)
          .removeListener(_purchaseChanged);
      _purchases.addListener(_purchaseChanged);
    }
  }

  @override
  void dispose() {
    _purchases.removeListener(_purchaseChanged);
    super.dispose();
  }

  void _purchaseChanged() {
    if (!mounted) return;
    setState(() {});
    if (!_actionStarted) return;
    final state = _purchases.state;
    if (state == _shownState ||
        state == PurchaseState.idle ||
        state == PurchaseState.loading) {
      return;
    }
    _shownState = state;
    final strings = S.of(context);
    final message = switch (state) {
      PurchaseState.unavailable => strings.Purchase_Unavailable,
      PurchaseState.pending => strings.Purchase_Pending,
      PurchaseState.cancelled => strings.Purchase_Cancelled,
      PurchaseState.failed => strings.Purchase_Failed,
      PurchaseState.purchased => strings.Purchase_Success,
      PurchaseState.restored => strings.Restore_Success,
      PurchaseState.nothingToRestore => strings.Restore_Nothing,
      _ => null,
    };
    if (state != PurchaseState.pending) _actionStarted = false;
    if (message == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        showTransientSnackBar(context, SnackBar(content: Text(message)));
      }
    });
  }

  Future<void> _runAction(Future<void> Function() action,
      {bool restoring = false}) async {
    if (_busy) return;
    setState(() {
      _performingAction = true;
      _restoring = restoring;
      _actionStarted = true;
      _shownState = null;
    });
    try {
      await action();
    } finally {
      if (mounted) setState(() => _performingAction = false);
    }
  }

  bool get _busy =>
      _performingAction ||
      _purchases.state == PurchaseState.loading ||
      _purchases.state == PurchaseState.pending;

  String? _featureExplanation(S strings) => switch (widget.feature) {
        PremiumFeature.notes =>
          strings.Premium_Note_Limit(PremiumAccess.freeNoteLimit),
        PremiumFeature.folders =>
          strings.Premium_Folder_Limit(PremiumAccess.freeFolderLimit),
        PremiumFeature.templates =>
          strings.Premium_Template_Limit(PremiumAccess.freeTemplateLimit),
        PremiumFeature.repeatingReminders ||
        PremiumFeature.voiceMemos ||
        PremiumFeature.individualCardStyle =>
          strings.Premium_Feature_Required,
        null => null,
      };

  @override
  Widget build(BuildContext context) {
    final strings = S.of(context);
    final tokens = context.tokens;
    final purchase = _purchases;
    final explanation = _featureExplanation(strings);
    final price = purchase.localizedPrice;
    final busy = _busy;
    return Scaffold(
      backgroundColor: DeskSurface.colorOf(context),
      appBar: AppBar(title: Text(strings.Premium)),
      body: DeskSurface(
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
                tokens.space4, tokens.space4, tokens.space4, tokens.space6),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: tokens.contentMaxWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SectionCard(
                      title: purchase.isPremium
                          ? strings.Premium_Active
                          : strings.Upgrade_To_Premium,
                      icon: purchase.isPremium
                          ? Icons.verified_rounded
                          : Icons.workspace_premium_outlined,
                      subtitle: purchase.isPremium
                          ? strings.Premium_Description
                          : explanation ?? strings.Premium_One_Time_Description,
                      children: [
                        _Benefit(
                          feature: PremiumFeature.notes,
                          selected: widget.feature,
                          icon: Icons.note_add_outlined,
                          label: strings.Premium_Notes,
                        ),
                        _Benefit(
                          feature: PremiumFeature.folders,
                          selected: widget.feature,
                          icon: Icons.folder_outlined,
                          label: strings.Premium_Folders,
                        ),
                        _Benefit(
                          feature: PremiumFeature.templates,
                          selected: widget.feature,
                          icon: Icons.dashboard_customize_outlined,
                          label: strings.Premium_Templates,
                        ),
                        _Benefit(
                          feature: PremiumFeature.repeatingReminders,
                          selected: widget.feature,
                          icon: Icons.repeat_rounded,
                          label: strings.Premium_Repeating_Reminders,
                        ),
                        _Benefit(
                          feature: PremiumFeature.individualCardStyle,
                          selected: widget.feature,
                          icon: Icons.style_outlined,
                          label: strings.Premium_Card_Style,
                        ),
                        _Benefit(
                          feature: PremiumFeature.voiceMemos,
                          selected: widget.feature,
                          icon: Icons.mic_none_rounded,
                          label: strings.Premium_Voice_Memos,
                        ),
                        _Benefit(
                          icon: Icons.block_outlined,
                          label: strings.Premium_No_Ads,
                        ),
                      ],
                    ),
                    SizedBox(height: tokens.space4),
                    if (!purchase.isPremium) ...[
                      Text(strings.Premium_Free_Core,
                          style: context.textStyles.bodyMedium),
                      SizedBox(height: tokens.space2),
                      Text(strings.Premium_Free_Limits,
                          style: context.textStyles.bodyMedium?.copyWith(
                              color: context.colors.onSurfaceVariant)),
                      SizedBox(height: tokens.space5),
                      if (purchase.isSupported)
                        FilledButton.icon(
                          key: const ValueKey('premium-buy'),
                          onPressed: busy || purchase.premiumProduct == null
                              ? null
                              : () => _runAction(purchase.buyPremium),
                          icon: busy && !_restoring
                              ? const SizedBox.square(
                                  dimension: 20,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.workspace_premium_outlined),
                          label: Padding(
                            padding:
                                EdgeInsets.symmetric(vertical: tokens.space2),
                            child: Text(
                              price == null
                                  ? strings.Upgrade_To_Premium
                                  : strings.Premium_One_Time_Price(price),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      SizedBox(height: tokens.space2),
                      Text(
                        purchase.state == PurchaseState.pending
                            ? strings.Purchase_Pending
                            : purchase.state == PurchaseState.loading
                                ? strings.Purchase_Loading
                                : price == null
                                    ? strings.Purchase_Unavailable
                                    : strings.Premium_One_Time_Description,
                        textAlign: TextAlign.center,
                        style: context.textStyles.bodySmall
                            ?.copyWith(color: context.colors.onSurfaceVariant),
                      ),
                      if (purchase.isSupported &&
                          purchase.premiumProduct == null &&
                          !busy) ...[
                        SizedBox(height: tokens.space2),
                        TextButton.icon(
                          key: const ValueKey('premium-retry'),
                          onPressed: purchase.loadProducts,
                          icon: const Icon(Icons.refresh_rounded),
                          label: Text(strings.Retry),
                        ),
                      ],
                    ],
                    if (purchase.isSupported) ...[
                      SizedBox(height: tokens.space4),
                      OutlinedButton.icon(
                        key: const ValueKey('premium-restore'),
                        onPressed: busy
                            ? null
                            : () => _runAction(purchase.restorePurchases,
                                restoring: true),
                        icon: busy && _restoring
                            ? const SizedBox.square(
                                dimension: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.restore_rounded),
                        label: Padding(
                          padding:
                              EdgeInsets.symmetric(vertical: tokens.space2),
                          child: Text(strings.Restore_Purchases,
                              textAlign: TextAlign.center),
                        ),
                      ),
                      if (!purchase.isPremium) ...[
                        SizedBox(height: tokens.space3),
                        Text(strings.Premium_Existing_Purchase,
                            textAlign: TextAlign.center,
                            style: context.textStyles.bodySmall?.copyWith(
                                color: context.colors.onSurfaceVariant)),
                      ],
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Benefit extends StatelessWidget {
  const _Benefit({
    required this.icon,
    required this.label,
    this.feature,
    this.selected,
  });

  final IconData icon;
  final String label;
  final PremiumFeature? feature;
  final PremiumFeature? selected;

  @override
  Widget build(BuildContext context) {
    final highlighted = feature != null && feature == selected;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.tokens.space2),
      child: Row(
        children: [
          Icon(icon,
              color: highlighted
                  ? context.colors.primary
                  : context.colors.onSurfaceVariant),
          SizedBox(width: context.tokens.space3),
          Expanded(
            child: Text(label,
                style: context.textStyles.bodyLarge?.copyWith(
                    fontWeight:
                        highlighted ? FontWeight.w600 : FontWeight.normal)),
          ),
        ],
      ),
    );
  }
}
