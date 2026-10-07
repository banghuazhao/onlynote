import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:onlynote/Tools/app_appearance_settings.dart';
import 'package:onlynote/Tools/app_card_style_settings.dart';
import 'package:onlynote/Tools/app_typography_settings.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/domain/model/note_card_style.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/app_sheet.dart';
import 'package:onlynote/presentation/components/paper_note.dart';
import 'package:onlynote/presentation/components/premium_feature_gate.dart';
import 'package:onlynote/presentation/components/section_card.dart';
import 'package:onlynote/presentation/components/settings_choice.dart';
import 'package:onlynote/presentation/components/toast.dart';
import 'package:onlynote/presentation/screens/home/widgets/note_card.dart';
import 'package:onlynote/presentation/theme/note_card_typography.dart';
import 'package:onlynote/presentation/theme/note_grid_layout.dart';
import 'package:onlynote/presentation/theme/spacing.dart';
import 'package:onlynote/services/premium_access.dart';

/// One appearance editor for saved cards and the library's default style.
class CardAppearanceScreen extends StatefulWidget {
  const CardAppearanceScreen({
    super.key,
    this.note,
    this.onSave,
    this.initialStyle,
    this.thumbnailBuilder,
    this.premiumAccess,
  }) : assert(note == null || onSave != null);

  final Note? note;
  final Future<void> Function(NoteCardStyle style)? onSave;
  final NoteCardStyle? initialStyle;
  final Widget Function(BuildContext context, String path)? thumbnailBuilder;
  final PremiumAccess? premiumAccess;

  @override
  State<CardAppearanceScreen> createState() => _CardAppearanceScreenState();
}

class _CardAppearanceScreenState extends State<CardAppearanceScreen> {
  late final NoteCardStyle _initial = widget.initialStyle ??
      widget.note?.cardStyle ??
      AppCardStyleSettings.instance.defaults.copyWith(
          clearPaperStyle: AppCardStyleSettings.instance.paperStyle == null);
  late NoteCardStyle _style = _initial;
  final _previewScroll = ScrollController();
  bool _saving = false;
  bool _failed = false;
  bool _allowPop = false;
  bool _confirming = false;
  bool _popping = false;

  bool get _defaults => widget.note == null;
  bool get _dirty => _style != _initial;
  NoteCardStyle get _resolved {
    final style = resolveNoteCardStyle(_style);
    if (!_defaults || _style.paperStyle != null) return style;
    return style.copyWith(
        paperStyle: AppAppearanceSettings.instance.plainPaper
            ? NoteCardPaperStyle.plain
            : NoteCardPaperStyle.textured);
  }

  @override
  void dispose() {
    _previewScroll.dispose();
    super.dispose();
  }

  void _change(NoteCardStyle style) {
    if (_saving || _popping) return;
    setState(() {
      _style = style;
      _failed = false;
    });
  }

  Future<void> _pop([NoteCardStyle? result]) async {
    if (_popping || !mounted) return;
    _popping = true;
    setState(() => _allowPop = true);
    await WidgetsBinding.instance.endOfFrame;
    if (mounted && ModalRoute.of(context)?.isCurrent != false) {
      Navigator.of(context).pop(result);
    }
  }

  Future<void> _requestBack() async {
    if (_saving || _popping || _confirming) return;
    if (!_dirty) {
      await _pop();
      return;
    }
    _confirming = true;
    final s = S.of(context);
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        title: Text(s.Card_Style_Discard_Title),
        content: Text(s.Card_Style_Discard_Message),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(s.Cancel)),
          FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(s.Card_Style_Discard)),
        ],
      ),
    );
    _confirming = false;
    if (mounted && discard == true) await _pop();
  }

  Future<void> _save() async {
    if (_saving || _popping) return;
    if (!_dirty) {
      await _pop(_style);
      return;
    }
    if (_failed) ScaffoldMessenger.of(context).hideCurrentSnackBar();
    setState(() {
      _saving = true;
      _failed = false;
    });
    try {
      if (!_defaults &&
          !_style.isDefault &&
          !await ensurePremiumAccess(
              context, PremiumFeature.individualCardStyle,
              access: widget.premiumAccess)) {
        if (mounted) setState(() => _saving = false);
        return;
      }
      if (!mounted) return;
      if (widget.onSave != null) {
        await widget.onSave!(_style);
      } else {
        await AppCardStyleSettings.instance.saveDefaults(_style);
      }
      if (mounted) await _pop(_style);
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _failed = true;
        });
        showTransientSnackBar(context,
            SnackBar(content: Text(S.of(context).Card_Style_Save_Failed)));
      }
    }
  }

  Future<void> _chooseFont() => showAppActionSheet(
        context: context,
        title: S.of(context).Font_Style,
        actions: [
          if (!_defaults)
            AppSheetAction(
              title: Text(S.of(context).Card_Style_Use_Default),
              selected: _style.fontFamily == null,
              onPressed: (context) {
                Navigator.pop(context);
                _change(_style.copyWith(clearFontFamily: true));
              },
            ),
          for (final entry in kAppFontFamilies.entries)
            AppSheetAction(
              title: Text(entry.key, style: entry.value(fontSize: 18)),
              selected: _style.fontFamily == entry.key,
              onPressed: (context) {
                Navigator.pop(context);
                _change(_style.copyWith(fontFamily: entry.key));
              },
            ),
        ],
      );

  String _sizeLabel(int index) {
    final s = S.of(context);
    return [s.Small, s.Medium, s.Large][index];
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final resolved = _resolved;
    final example = widget.note ??
        Note(
          id: 'card-style-example',
          title: s.Card_Style_Preview_Title,
          description: s.Card_Style_Preview_Body,
          dateTime: DateTime.now(),
          todo: [Todo(id: 'example-task', title: s.Card_Style_Preview_Task)],
        );
    return PopScope<Object?>(
      canPop: _allowPop || (!_dirty && !_saving),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _requestBack();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_defaults ? s.Default_Card_Style : s.Card_Style,
              maxLines: 1, overflow: TextOverflow.ellipsis),
          actions: [
            TextButton(
              key: const ValueKey('card-style-save'),
              onPressed: _saving || _popping ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Row(mainAxisSize: MainAxisSize.min, children: [
                      if (!_defaults &&
                          _dirty &&
                          !_style.isDefault &&
                          !(widget.premiumAccess ?? PremiumAccess.instance)
                              .allows(PremiumFeature.individualCardStyle)) ...[
                        Tooltip(
                            message: s.Premium,
                            child: const Icon(Icons.workspace_premium_outlined,
                                size: 16)),
                        const SizedBox(width: 6),
                      ],
                      Text(s.save),
                    ]),
            ),
          ],
        ),
        body: SafeArea(
          top: false,
          child: LayoutBuilder(builder: (context, constraints) {
            final landscape =
                constraints.maxWidth >= 600 && constraints.maxHeight < 500;
            final previewWidth =
                landscape ? constraints.maxWidth * .4 : constraints.maxWidth;
            final columns = noteGridColumns(
              width: previewWidth,
              textScaler: MediaQuery.textScalerOf(context),
              preferredColumns: resolved.cardSize!.columns,
              appFontScale: resolved.fontSize!.scale,
            );
            final cardWidth = math.max(0.0,
                (previewWidth - 32 - (columns - 1) * AppSpacings.l) / columns);
            final previewHeight = math.min(280.0, constraints.maxHeight * .38);
            final previewFlex =
                (previewHeight / math.max(1.0, constraints.maxHeight) * 1000)
                    .round()
                    .clamp(1, 999);
            return Flex(
              direction: landscape ? Axis.horizontal : Axis.vertical,
              children: [
                Expanded(
                  flex: landscape ? 2 : previewFlex,
                  child: DeskSurface(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.Card_Style_Preview,
                              style: context.textStyles.labelLarge),
                          const SizedBox(height: 8),
                          Expanded(
                            child: Scrollbar(
                              controller: _previewScroll,
                              child: SingleChildScrollView(
                                key:
                                    const ValueKey('card-style-preview-scroll'),
                                controller: _previewScroll,
                                child: Align(
                                  alignment: Alignment.topCenter,
                                  child: AnimatedContainer(
                                    key: const ValueKey(
                                        'card-style-preview-width'),
                                    width: cardWidth,
                                    duration:
                                        MediaQuery.disableAnimationsOf(context)
                                            ? Duration.zero
                                            : const Duration(milliseconds: 180),
                                    curve: Curves.easeOutCubic,
                                    child: NoteCard(
                                      key: const ValueKey('card-style-preview'),
                                      note: example,
                                      cardStyle: resolved,
                                      thumbnailBuilder: widget.thumbnailBuilder,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: landscape ? 3 : 1000 - previewFlex,
                  child: ListView(
                    key: const ValueKey('card-style-controls'),
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text(_defaults
                          ? s.Card_Style_Default_Hint
                          : s.Card_Style_Note_Hint),
                      const SizedBox(height: 16),
                      SectionCard(title: s.Font_Style, children: [
                        ListTile(
                          key: const ValueKey('card-style-font'),
                          contentPadding: EdgeInsets.zero,
                          title: Text(_style.fontFamily ??
                              '${s.Card_Style_Use_Default} · ${resolved.fontFamily}'),
                          trailing: const Icon(Icons.expand_more_rounded),
                          onTap: _saving ? null : _chooseFont,
                        ),
                      ]),
                      const SizedBox(height: 16),
                      SectionCard(title: s.Font_Size, children: [
                        SettingsChoice<AppFontSize?>(
                          values: [if (!_defaults) null, ...AppFontSize.values],
                          selected: _style.fontSize,
                          label: (value) => value == null
                              ? s.Card_Style_Use_Default
                              : _sizeLabel(value.index),
                          onSelected: (value) => _change(_style.copyWith(
                              fontSize: value, clearFontSize: value == null)),
                        ),
                      ]),
                      const SizedBox(height: 16),
                      SectionCard(title: s.Card_Size, children: [
                        SettingsChoice<NoteCardSize?>(
                          values: [
                            if (!_defaults) null,
                            NoteCardSize.small,
                            NoteCardSize.medium,
                            NoteCardSize.large,
                          ],
                          selected: _style.cardSize,
                          label: (value) => value == null
                              ? s.Card_Style_Use_Default
                              : _sizeLabel(2 - value.index),
                          onSelected: (value) => _change(_style.copyWith(
                              cardSize: value, clearCardSize: value == null)),
                        ),
                      ]),
                      const SizedBox(height: 16),
                      SectionCard(title: s.Card_Style_Paper, children: [
                        SettingsChoice<NoteCardPaperStyle?>(
                          values: const [null, ...NoteCardPaperStyle.values],
                          selected: _style.paperStyle,
                          label: (value) => switch (value) {
                            null => _defaults
                                ? s.Card_Style_Follow_App
                                : s.Card_Style_Use_Default,
                            NoteCardPaperStyle.textured =>
                              s.Card_Style_Textured,
                            NoteCardPaperStyle.plain => s.Card_Style_Plain,
                          },
                          onSelected: (value) => _change(_style.copyWith(
                              paperStyle: value,
                              clearPaperStyle: value == null)),
                        ),
                      ]),
                      const SizedBox(height: 16),
                      SectionCard(title: s.Card_Style_Show_Date, children: [
                        if (_defaults)
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(s.Card_Style_Show_Date),
                            value: resolved.showDate!,
                            onChanged: _saving
                                ? null
                                : (value) =>
                                    _change(_style.copyWith(showDate: value)),
                          )
                        else
                          SettingsChoice<bool?>(
                            values: const [null, true, false],
                            selected: _style.showDate,
                            label: (value) => switch (value) {
                              null => s.Card_Style_Use_Default,
                              true => s.Card_Style_Show_Date,
                              false => s.Card_Style_Hide_Date,
                            },
                            onSelected: (value) => _change(_style.copyWith(
                                showDate: value, clearShowDate: value == null)),
                          ),
                      ]),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        key: const ValueKey('card-style-reset'),
                        icon: const Icon(Icons.restart_alt_rounded),
                        label: Text(_defaults
                            ? s.Card_Style_Reset
                            : s.Card_Style_Use_Default_All),
                        onPressed: _saving
                            ? null
                            : () => _change(_defaults
                                ? const NoteCardStyle(
                                    fontFamily: 'Montserrat',
                                    fontSize: AppFontSize.medium,
                                    cardSize: NoteCardSize.medium,
                                    showDate: true)
                                : const NoteCardStyle()),
                      ),
                      if (_failed) ...[
                        const SizedBox(height: 12),
                        Semantics(
                          liveRegion: true,
                          child: Text(s.Card_Style_Save_Failed,
                              style: TextStyle(color: context.colors.error)),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}
