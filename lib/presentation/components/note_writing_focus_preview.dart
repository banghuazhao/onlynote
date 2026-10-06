import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:onlynote/domain/model/note_text_style.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/theme/colors.dart';
import 'package:onlynote/services/note_outline.dart';

import 'note_editing_actions.dart';
import 'note_formatting_toolbar.dart';
import 'note_outline_sheet.dart';
import 'simple_formatting_controller.dart';

@Preview(name: 'Writing focus — light', group: 'Note', size: Size(390, 700))
Widget noteWritingFocusLightPreview() => const _WritingFocusPreview();

@Preview(
  name: 'Writing focus — dark',
  group: 'Note',
  size: Size(390, 700),
  brightness: Brightness.dark,
)
Widget noteWritingFocusDarkPreview() =>
    const _WritingFocusPreview(dark: true, initiallyFocused: true);

@Preview(
  name: 'Writing focus — large Chinese text',
  group: 'Note',
  size: Size(320, 700),
)
Widget noteWritingFocusChinesePreview() =>
    const _WritingFocusPreview(chinese: true, textScale: 2);

@Preview(
  name: 'Writing focus — reduced motion',
  group: 'Note',
  size: Size(390, 700),
)
Widget noteWritingFocusReducedMotionPreview() =>
    const _WritingFocusPreview(reduceMotion: true);

/// A web-safe writing fixture. Its draft and layout state stay in memory.
class _WritingFocusPreview extends StatefulWidget {
  const _WritingFocusPreview({
    this.dark = false,
    this.chinese = false,
    this.textScale = 1,
    this.initiallyFocused = false,
    this.reduceMotion = false,
  });

  final bool dark;
  final bool chinese;
  final double textScale;
  final bool initiallyFocused;
  final bool reduceMotion;

  @override
  State<_WritingFocusPreview> createState() => _WritingFocusPreviewState();
}

class _WritingFocusPreviewState extends State<_WritingFocusPreview> {
  late bool _writingFocused;
  late final TextEditingController _title;
  late final SimpleFormattingController _body;
  final _titleFocus = FocusNode();
  final _bodyFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _writingFocused = widget.initiallyFocused;
    _title =
        TextEditingController(text: widget.chinese ? '週末筆記' : 'Weekend notes');
    final first = widget.chinese ? '今天的想法' : 'Ideas for today';
    final second = widget.chinese ? '下一步' : 'Next steps';
    final body = widget.chinese
        ? '$first\n記下值得保留的細節。\n\n$second\n帶上茶和外套，沿著海邊走走。'
        : '$first\nKeep the details worth remembering.\n\n$second\nPack tea and a warm layer for a walk by the water.';
    _body = SimpleFormattingController(text: body, styles: [
      NoteTextStyleRange(
          start: 0, end: first.length, kind: NoteTextStyleKind.heading),
      NoteTextStyleRange(
          start: body.indexOf(second),
          end: body.indexOf(second) + second.length,
          kind: NoteTextStyleKind.heading),
    ]);
  }

  Future<void> _openOutline(BuildContext context) async {
    final entry = await showNoteOutlineSheet(
      context: context,
      entries: buildNoteOutline(_body.text, _body.styles),
      currentOffset: _body.selection.extentOffset,
    );
    if (!mounted || entry == null) return;
    _body.selection = TextSelection.collapsed(offset: entry.start);
    _bodyFocus.requestFocus();
  }

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    _titleFocus.dispose();
    _bodyFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
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
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(widget.textScale),
            disableAnimations: widget.reduceMotion,
          ),
          child: child!,
        ),
        home: Builder(builder: (context) {
          final strings = S.of(context);
          return Scaffold(
            appBar: AppBar(
              title: Text(widget.chinese ? '筆記' : 'Note'),
              actions: [
                TextButton(onPressed: () {}, child: Text(strings.Done))
              ],
            ),
            body: SafeArea(
              child: Column(
                children: [
                  NoteEditingActions(
                    onUndo: null,
                    onRedo: null,
                    onOutline: () => _openOutline(context),
                    writingFocused: _writingFocused,
                    onToggleFocus: () =>
                        setState(() => _writingFocused = !_writingFocused),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (!_writingFocused) ...[
                            Wrap(
                              key: const ValueKey('preview-writing-tools'),
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _tool(Icons.check_box_outlined,
                                    widget.chinese ? '待辦事項' : 'Checklist'),
                                _tool(Icons.photo_outlined,
                                    widget.chinese ? '照片' : 'Photo'),
                                _tool(Icons.mic_none_rounded,
                                    widget.chinese ? '語音' : 'Voice'),
                                _tool(Icons.palette_outlined,
                                    widget.chinese ? '顏色' : 'Color'),
                                _tool(Icons.sell_outlined,
                                    widget.chinese ? '標籤' : 'Tags'),
                                _tool(Icons.link_rounded,
                                    widget.chinese ? '連結' : 'Links'),
                                _tool(Icons.alarm_rounded,
                                    widget.chinese ? '提醒' : 'Reminder'),
                              ],
                            ),
                            const SizedBox(height: 16),
                          ],
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.parchment,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                TextField(
                                  key: const ValueKey('preview-focus-title'),
                                  controller: _title,
                                  focusNode: _titleFocus,
                                  maxLines: null,
                                  style: const TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.ink),
                                  decoration: const InputDecoration.collapsed(
                                      hintText: ''),
                                ),
                                const SizedBox(height: 16),
                                NoteFormattingToolbar(
                                    controller: _body, focusNode: _bodyFocus),
                                const SizedBox(height: 12),
                                TextField(
                                  key: const ValueKey('preview-focus-body'),
                                  controller: _body,
                                  focusNode: _bodyFocus,
                                  maxLines: null,
                                  style: const TextStyle(
                                      fontSize: 17,
                                      height: 1.55,
                                      color: AppColors.ink),
                                  decoration: const InputDecoration.collapsed(
                                      hintText: ''),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      );

  Widget _tool(IconData icon, String label) => ActionChip(
        avatar: Icon(icon, size: 18),
        label: Text(label),
        onPressed: () {},
      );
}
