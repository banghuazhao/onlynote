import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:onlynote/Tools/app_appearance_settings.dart';
import 'package:onlynote/Tools/app_card_style_settings.dart';
import 'package:onlynote/Tools/app_typography_settings.dart';
import 'package:onlynote/common/constants.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/domain/model/note_card_style.dart';
import 'package:onlynote/domain/model/note_theme.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/app_sheet.dart';
import 'package:onlynote/presentation/components/card_style_sections.dart';
import 'package:onlynote/presentation/components/note_theme_choices.dart';
import 'package:onlynote/presentation/components/note_theme_surface.dart';
import 'package:onlynote/presentation/components/paper_note.dart';
import 'package:onlynote/presentation/components/premium_feature_gate.dart';
import 'package:onlynote/presentation/components/section_card.dart';
import 'package:onlynote/presentation/components/toast.dart';
import 'package:onlynote/presentation/screens/home/widgets/note_card.dart';
import 'package:onlynote/presentation/theme/colors.dart';
import 'package:onlynote/presentation/theme/note_card_typography.dart';
import 'package:onlynote/presentation/theme/note_grid_layout.dart';
import 'package:onlynote/presentation/theme/spacing.dart';
import 'package:onlynote/services/premium_access.dart';
import 'package:onlynote/services/note_theme_access.dart';

/// One appearance editor for saved cards and the library's default style.
class CardAppearanceScreen extends StatefulWidget {
  const CardAppearanceScreen({
    super.key,
    this.note,
    this.onSave,
    this.onSaveAppearance,
    this.initialStyle,
    this.thumbnailBuilder,
    this.premiumAccess,
  }) : assert(note == null || onSave != null || onSaveAppearance != null);

  final Note? note;
  final Future<void> Function(NoteCardStyle style)? onSave;
  final Future<void> Function(NoteCardStyle style, Color? color)?
      onSaveAppearance;
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
  late final Color? _initialColor = widget.note?.color;
  late Color? _color = _initialColor;
  final _previewScroll = ScrollController();
  CardStyleSection _section = CardStyleSection.theme;
  bool _saving = false;
  bool _failed = false;
  bool _allowPop = false;
  bool _confirming = false;
  bool _popping = false;

  bool get _defaults => widget.note == null;
  bool get _hasColor => !_defaults && widget.onSaveAppearance != null;
  bool get _styleChanged => _style != _initial;
  bool get _dirty => _styleChanged || (_hasColor && _color != _initialColor);
  PremiumFeature? get _requiredFeature =>
      requiredNoteStyleFeature(_initial, _style, isGlobalDefault: _defaults);
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

  void _changeColor(Color? color) {
    if (_saving || _popping) return;
    setState(() {
      _color = color;
      _failed = false;
    });
  }

  void _changeSection(CardStyleSection section) {
    if (!mounted ||
        _saving ||
        _popping ||
        ModalRoute.of(context)?.isCurrent == false ||
        section == _section ||
        (section == CardStyleSection.color && !_hasColor)) {
      return;
    }
    setState(() => _section = section);
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
    if (!mounted ||
        _saving ||
        _popping ||
        ModalRoute.of(context)?.isCurrent == false) {
      return;
    }
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
      final feature = _requiredFeature;
      if (feature != null &&
          !await ensurePremiumAccess(context, feature,
              access: widget.premiumAccess)) {
        if (mounted) setState(() => _saving = false);
        return;
      }
      if (!mounted) return;
      if (ModalRoute.of(context)?.isCurrent == false) {
        setState(() => _saving = false);
        return;
      }
      if (widget.onSaveAppearance != null) {
        await widget.onSaveAppearance!(_style, _color);
      } else if (widget.onSave != null) {
        await widget.onSave!(_style);
      } else {
        await AppCardStyleSettings.instance
            .saveDefaults(_style, premiumAccess: widget.premiumAccess);
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
                      if (_requiredFeature != null &&
                          !(widget.premiumAccess ?? PremiumAccess.instance)
                              .allows(_requiredFeature!)) ...[
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
            final landscape = (constraints.maxWidth >= 600 &&
                    constraints.maxHeight < 500) ||
                (constraints.maxWidth >= 480 && constraints.maxHeight < 300);
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
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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
                                      note: _hasColor
                                          ? example.copyWith(color: _color)
                                          : example,
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
                  child: Column(children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: CardStyleSections(
                        sections: [
                          CardStyleSection.theme,
                          if (_hasColor) CardStyleSection.color,
                          CardStyleSection.text,
                          CardStyleSection.layout,
                        ],
                        selected: _section,
                        enabled: !_saving && !_popping,
                        onSelected: _changeSection,
                      ),
                    ),
                    Expanded(
                      child: KeyedSubtree(
                        key: ValueKey('card-style-panel-${_section.name}'),
                        child: ListView(
                          key: const ValueKey('card-style-controls'),
                          primary: false,
                          padding: const EdgeInsets.all(16),
                          children: [
                            if (_defaults) ...[
                              Text(s.Card_Style_Default_Hint),
                              const SizedBox(height: 16),
                            ],
                            if (_section == CardStyleSection.theme)
                              SectionCard(
                                key: const ValueKey('card-style-theme-group'),
                                title: s.Note_Theme,
                                subtitle: s.Note_Theme_Description,
                                children: [
                                  NoteThemeChoices(
                                    selected: _defaults
                                        ? _style.noteTheme ?? NoteTheme.classic
                                        : _style.noteTheme,
                                    inheritedTheme: AppCardStyleSettings
                                            .instance.defaults.noteTheme ??
                                        NoteTheme.classic,
                                    showInherited: !_defaults,
                                    premiumAvailable: (widget.premiumAccess ??
                                            PremiumAccess.instance)
                                        .allows(PremiumFeature.noteThemes),
                                    enabled: !_saving && !_popping,
                                    onSelected: (theme) => _change(
                                        _style.copyWith(
                                            noteTheme: theme,
                                            clearNoteTheme: theme == null)),
                                  ),
                                ],
                              ),
                            if (_section == CardStyleSection.color &&
                                _hasColor) ...[
                              SectionCard(
                                key: const ValueKey('card-style-color-group'),
                                title: s.Card_Style_Color,
                                children: [
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      _ColorChoice(
                                        key: const ValueKey(
                                            'card-style-color-default'),
                                        color: noteThemePaperColor(
                                            resolved.noteTheme ??
                                                NoteTheme.classic),
                                        label: s.Card_Style_Default_Color,
                                        selected: _color == null,
                                        onPressed: _saving || _popping
                                            ? null
                                            : () => _changeColor(null),
                                      ),
                                      if (_initialColor != null &&
                                          !colors.contains(_initialColor))
                                        _ColorChoice(
                                          key: ValueKey(
                                              'card-style-color-${_initialColor.toARGB32()}'),
                                          color: _initialColor,
                                          label: s.Card_Style_Original_Color,
                                          selected: _color == _initialColor,
                                          onPressed: _saving || _popping
                                              ? null
                                              : () =>
                                                  _changeColor(_initialColor),
                                        ),
                                      for (var index = 0;
                                          index < colors.length;
                                          index++)
                                        _ColorChoice(
                                          key: ValueKey(
                                              'card-style-color-${colors[index].toARGB32()}'),
                                          color: colors[index],
                                          label: s.Note_Color(index + 1),
                                          selected: _color == colors[index],
                                          onPressed: _saving || _popping
                                              ? null
                                              : () =>
                                                  _changeColor(colors[index]),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                            if (_section == CardStyleSection.text)
                              SectionCard(
                                key: const ValueKey('card-style-text'),
                                title: s.Card_Style_Text,
                                children: [
                                  ListTile(
                                    key: const ValueKey('card-style-font'),
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(s.Font_Style),
                                    subtitle: Text(_style.fontFamily ??
                                        '${s.Card_Style_Use_Default} · ${resolved.fontFamily}'),
                                    trailing:
                                        const Icon(Icons.expand_more_rounded),
                                    onTap: _saving || _popping
                                        ? null
                                        : _chooseFont,
                                  ),
                                  const Divider(),
                                  _ChoiceGroup(
                                    key: const ValueKey('card-style-font-size'),
                                    label: s.Font_Size,
                                    child: _StyleChoices<AppFontSize?>(
                                      keyFor: (value) => ValueKey(
                                          'card-style-text-${value?.name ?? "default"}'),
                                      enabled: !_saving && !_popping,
                                      values: [
                                        if (!_defaults) null,
                                        ...AppFontSize.values
                                      ],
                                      selected: _style.fontSize,
                                      label: (value) => value == null
                                          ? s.Card_Style_Use_Default
                                          : _sizeLabel(value.index),
                                      onSelected: (value) => _change(
                                          _style.copyWith(
                                              fontSize: value,
                                              clearFontSize: value == null)),
                                    ),
                                  ),
                                ],
                              ),
                            if (_section == CardStyleSection.layout)
                              SectionCard(
                                key: const ValueKey('card-style-layout'),
                                title: s.Card_Style_Layout,
                                children: [
                                  _ChoiceGroup(
                                    key: const ValueKey('card-style-size'),
                                    label: s.Card_Size,
                                    child: _StyleChoices<NoteCardSize?>(
                                      keyFor: (value) => ValueKey(
                                          'card-style-card-${value?.name ?? "default"}'),
                                      enabled: !_saving && !_popping,
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
                                      onSelected: (value) => _change(
                                          _style.copyWith(
                                              cardSize: value,
                                              clearCardSize: value == null)),
                                    ),
                                  ),
                                  const Divider(height: 32),
                                  _ChoiceGroup(
                                    key: const ValueKey('card-style-paper'),
                                    label: s.Card_Style_Paper,
                                    child: _StyleChoices<NoteCardPaperStyle?>(
                                      keyFor: (value) => ValueKey(
                                          'card-style-paper-${value?.name ?? "default"}'),
                                      enabled: !_saving && !_popping,
                                      values: const [
                                        null,
                                        ...NoteCardPaperStyle.values
                                      ],
                                      selected: _style.paperStyle,
                                      label: (value) => switch (value) {
                                        null => _defaults
                                            ? s.Card_Style_Follow_App
                                            : s.Card_Style_Use_Default,
                                        NoteCardPaperStyle.textured =>
                                          s.Card_Style_Textured,
                                        NoteCardPaperStyle.plain =>
                                          s.Card_Style_Plain,
                                      },
                                      onSelected: (value) => _change(
                                          _style.copyWith(
                                              paperStyle: value,
                                              clearPaperStyle: value == null)),
                                    ),
                                  ),
                                  const Divider(height: 32),
                                  SwitchListTile(
                                    key: const ValueKey('card-style-date'),
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(s.Card_Style_Show_Date),
                                    subtitle:
                                        !_defaults && _style.showDate == null
                                            ? Text(s.Card_Style_Use_Default)
                                            : null,
                                    value: resolved.showDate!,
                                    onChanged: _saving || _popping
                                        ? null
                                        : (value) => _change(
                                            _style.copyWith(showDate: value)),
                                  ),
                                  if (!_defaults && _style.showDate != null)
                                    TextButton.icon(
                                      key: const ValueKey(
                                          'card-style-date-default'),
                                      onPressed: _saving || _popping
                                          ? null
                                          : () => _change(_style.copyWith(
                                              clearShowDate: true)),
                                      icon: const Icon(
                                          Icons.restart_alt_rounded,
                                          size: 18),
                                      label: Text(s.Card_Style_Use_Default),
                                    ),
                                ],
                              ),
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
                                          noteTheme: NoteTheme.classic,
                                          showDate: true)
                                      : const NoteCardStyle()),
                            ),
                            if (_failed) ...[
                              const SizedBox(height: 12),
                              Semantics(
                                liveRegion: true,
                                child: Text(s.Card_Style_Save_Failed,
                                    style:
                                        TextStyle(color: context.colors.error)),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ]),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

class _ChoiceGroup extends StatelessWidget {
  const _ChoiceGroup({super.key, required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: context.textStyles.labelLarge),
          const SizedBox(height: 8),
          child,
        ],
      );
}

class _ColorChoice extends StatelessWidget {
  const _ColorChoice({
    super.key,
    required this.color,
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final Color color;
  final String label;
  final bool selected;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => SizedBox.square(
        dimension: 48,
        child: IconButton(
          tooltip: label,
          isSelected: selected,
          onPressed: onPressed,
          style: IconButton.styleFrom(
            backgroundColor: color,
            foregroundColor:
                ThemeData.estimateBrightnessForColor(color) == Brightness.dark
                    ? Colors.white
                    : AppColors.ink,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            side: BorderSide(
              color: (ThemeData.estimateBrightnessForColor(color) ==
                          Brightness.dark
                      ? Colors.white
                      : AppColors.ink)
                  .withValues(alpha: selected ? .85 : .25),
              width: selected ? 2 : 1,
            ),
          ).copyWith(
            animationDuration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 160),
          ),
          icon: const SizedBox.square(dimension: 20),
          selectedIcon: const Icon(Icons.check_rounded, size: 20),
        ),
      );
}

class _StyleChoices<T> extends StatelessWidget {
  const _StyleChoices({
    required this.values,
    required this.selected,
    required this.label,
    required this.keyFor,
    required this.onSelected,
    required this.enabled,
  });

  final List<T> values;
  final T selected;
  final String Function(T) label;
  final Key Function(T) keyFor;
  final ValueChanged<T> onSelected;
  final bool enabled;

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final value in values)
            ChoiceChip(
              key: keyFor(value),
              label: Text(label(value)),
              selected: value == selected,
              showCheckmark: true,
              materialTapTargetSize: MaterialTapTargetSize.padded,
              onSelected: enabled ? (_) => onSelected(value) : null,
            ),
        ],
      );
}
