import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/domain/model/note_text_style.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/services/note_edit_history.dart';
import 'package:onlynote/services/note_outline.dart';
import 'package:onlynote/presentation/theme/colors.dart';

import 'note_editing_actions.dart';
import 'note_formatting_toolbar.dart';
import 'note_outline_navigation_controller.dart';
import 'note_outline_sheet.dart';
import 'paper_note.dart';
import 'simple_formatting_controller.dart';

@Preview(name: 'Editing actions — light', group: 'Note', size: Size(390, 640))
Widget noteEditingActionsLightPreview() => const _EditingActionsPreview();

@Preview(
  name: 'Editing actions — dark',
  group: 'Note',
  size: Size(390, 640),
  brightness: Brightness.dark,
)
Widget noteEditingActionsDarkPreview() =>
    const _EditingActionsPreview(dark: true);

@Preview(
    name: 'Editing actions — large Chinese text',
    group: 'Note',
    size: Size(320, 640))
Widget noteEditingActionsChinesePreview() =>
    const _EditingActionsPreview(chinese: true, textScale: 2);

/// All text, formatting and undo steps remain in memory. No native plugins or
/// file-backed note editor dependencies are used by the web preview.
class _EditingActionsPreview extends StatefulWidget {
  const _EditingActionsPreview({
    this.dark = false,
    this.chinese = false,
    this.textScale = 1,
  });

  final bool dark;
  final bool chinese;
  final double textScale;

  @override
  State<_EditingActionsPreview> createState() => _EditingActionsPreviewState();
}

class _EditingActionsPreviewState extends State<_EditingActionsPreview> {
  late Note _note;
  late final TextEditingController _title;
  late final SimpleFormattingController _body;
  late final NoteEditHistory _history;
  final _titleFocus = FocusNode();
  final _bodyFocus = FocusNode();
  final _bodyKey = GlobalKey();
  bool _restoring = false;

  @override
  void initState() {
    super.initState();
    final first = widget.chinese ? '今天的想法' : 'Ideas for today';
    final detail =
        widget.chinese ? '記下值得保留的細節。' : 'Keep the details worth remembering.';
    final second = widget.chinese ? '下一步' : 'Next steps';
    final before = '$first\n$detail\n\n$second';
    final styles = [
      NoteTextStyleRange(
          start: 0, end: first.length, kind: NoteTextStyleKind.heading),
      NoteTextStyleRange(
          start: before.indexOf(second),
          end: before.length,
          kind: NoteTextStyleKind.heading),
    ];
    _note = Note(
      id: 'editing-actions-preview',
      title: widget.chinese ? '週末計劃' : 'Weekend plans',
      description: before,
      textStyles: styles,
    );
    _history = NoteEditHistory(initial: NoteEditSnapshot(note: _note));
    final after =
        '$before\n${widget.chinese ? '帶上零食和外套。' : 'Pack snacks and a warm layer.'}';
    _note = _note.copyWith(description: after);
    _title = TextEditingController(text: _note.title);
    _body = SimpleFormattingController(text: after, styles: styles)
      ..selection = TextSelection.collapsed(offset: after.length);
    // A starter step lets Undo/Redo be tried immediately, before typing.
    _history.record(_snapshot());
    _title.addListener(_titleChanged);
    _body.addListener(_bodyChanged);
    _titleFocus.addListener(_focusChanged);
    _bodyFocus.addListener(_focusChanged);
  }

  NoteEditSnapshot _snapshot() => NoteEditSnapshot(
        note: _note,
        titleSelection: _title.selection,
        bodySelection: _body.selection,
        focusedField: _titleFocus.hasFocus ? 'title' : 'body',
      );

  void _titleChanged() => _changed(NoteEditKind.titleTyping);
  void _bodyChanged() => _changed(NoteEditKind.bodyTyping);
  void _focusChanged() => _changed(NoteEditKind.discrete);

  void _changed(NoteEditKind kind) {
    if (_restoring || !mounted) return;
    if (_note.description == _body.text &&
        !listEquals(_note.textStyles, _body.styles)) {
      kind = NoteEditKind.discrete;
    }
    _note = _note.copyWith(
      title: _title.text,
      description: _body.text,
      textStyles: _body.styles,
    );
    _history.record(_snapshot(), kind: kind);
    setState(() {});
  }

  void _restore({required bool redo}) {
    final snapshot = redo ? _history.redo() : _history.undo();
    if (snapshot == null) return;
    _restoring = true;
    _note = snapshot.applyTo(_note);
    _title.value = TextEditingValue(
      text: _note.title ?? '',
      selection: snapshot.titleSelection?.isValid == true
          ? snapshot.titleSelection!
          : TextSelection.collapsed(offset: (_note.title ?? '').length),
    );
    _body.setDocument(_note.description ?? '', _note.textStyles);
    _body.selection = snapshot.bodySelection?.isValid == true
        ? snapshot.bodySelection!
        : TextSelection.collapsed(offset: _body.text.length);
    _restoring = false;
    setState(() {});
  }

  Future<void> _openOutline(BuildContext context) async {
    _history.breakCoalescing();
    final entry = await showNoteOutlineSheet(
      context: context,
      entries: buildNoteOutline(_body.text, _body.styles),
      currentOffset: _body.selection.extentOffset,
    );
    if (!mounted || entry == null) return;
    _body.selection = TextSelection.collapsed(offset: entry.start);
    _bodyFocus.requestFocus();
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    final textContext = _bodyKey.currentContext;
    if (textContext != null && textContext.mounted) {
      revealNoteTextOffset(textContext, entry.start);
    }
  }

  @override
  void dispose() {
    _titleFocus.removeListener(_focusChanged);
    _bodyFocus.removeListener(_focusChanged);
    _title.dispose();
    _body.dispose();
    _titleFocus.dispose();
    _bodyFocus.dispose();
    _history.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
        theme: ThemeData(
          brightness: widget.dark ? Brightness.dark : Brightness.light,
          colorSchemeSeed: const Color(0xFF685947),
        ),
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
              .copyWith(textScaler: TextScaler.linear(widget.textScale)),
          child: child!,
        ),
        home: Builder(builder: (context) {
          final composing = (_body.value.composing.isValid &&
                  !_body.value.composing.isCollapsed) ||
              (_title.value.composing.isValid &&
                  !_title.value.composing.isCollapsed);
          final entries = buildNoteOutline(_body.text, _body.styles);
          return Scaffold(
            body: SafeArea(
              child: Column(
                children: [
                  NoteEditingActions(
                    onUndo: !composing && _history.canUndo
                        ? () => _restore(redo: false)
                        : null,
                    onRedo: !composing && _history.canRedo
                        ? () => _restore(redo: true)
                        : null,
                    onOutline:
                        !composing && shouldShowNoteOutline(_body.text, entries)
                            ? () => _openOutline(context)
                            : null,
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: PaperNote(
                        color: AppColors.parchment,
                        kind: PaperNoteKind.sheet,
                        tilt: false,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextField(
                              key: const ValueKey('preview-note-title'),
                              controller: _title,
                              focusNode: _titleFocus,
                              style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.ink),
                              maxLines: null,
                              decoration:
                                  const InputDecoration.collapsed(hintText: ''),
                            ),
                            const SizedBox(height: 20),
                            NoteFormattingToolbar(
                                controller: _body, focusNode: _bodyFocus),
                            const SizedBox(height: 8),
                            TextField(
                              key: _bodyKey,
                              controller: _body,
                              focusNode: _bodyFocus,
                              style: const TextStyle(
                                  fontSize: 17,
                                  height: 1.55,
                                  color: AppColors.ink),
                              maxLines: null,
                              decoration:
                                  const InputDecoration.collapsed(hintText: ''),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      );
}
