import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/theme/colors.dart';
import 'package:onlynote/presentation/theme/theme.dart';
import 'app_sheet.dart';
import 'note_editing_actions.dart';
import 'note_editor_tip.dart';
import 'note_insert_sheet.dart';
import 'note_writing_toolbar.dart';
import 'paper_note.dart';
import 'simple_formatting_controller.dart';

@Preview(name: 'Writing tools — light', group: 'Writing', size: Size(320, 740))
Widget editorWritingLightPreview() => const _WritingPreviewApp();

@Preview(name: 'Writing tools — dark', group: 'Writing', size: Size(320, 740))
Widget editorWritingDarkPreview() => const _WritingPreviewApp(dark: true);

@Preview(
    name: 'Writing tools — large Chinese',
    group: 'Writing',
    size: Size(320, 740))
Widget editorWritingChinesePreview() => const _WritingPreviewApp(
      locale: Locale('zh', 'HK'),
      textScale: 1.8,
    );

@Preview(
    name: 'Writing tools — compact', group: 'Writing', size: Size(180, 740))
Widget editorWritingCompactPreview() => const _WritingPreviewApp();

@Preview(name: 'Insert into a note', group: 'Writing', size: Size(390, 620))
Widget noteInsertPreview() => const _WritingPreviewApp(insertOnly: true);

@Preview(name: 'Insert — large Chinese', group: 'Writing', size: Size(320, 740))
Widget noteInsertChinesePreview() => const _WritingPreviewApp(
      locale: Locale('zh', 'HK'),
      textScale: 1.8,
      insertOnly: true,
    );

@Preview(
    name: 'Photo layout tip — dark', group: 'Writing', size: Size(320, 180))
Widget noteImageTipPreview() => const _WritingPreviewApp(
      dark: true,
      imageTipOnly: true,
    );

class _WritingPreviewApp extends StatelessWidget {
  const _WritingPreviewApp({
    this.dark = false,
    this.locale = const Locale('en'),
    this.textScale = 1,
    this.insertOnly = false,
    this.imageTipOnly = false,
  });

  final bool dark;
  final Locale locale;
  final double textScale;
  final bool insertOnly;
  final bool imageTipOnly;

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: dark ? AppTheme.dark : AppTheme.light,
        locale: locale,
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: S.delegate.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
          ),
          child: child!,
        ),
        home: insertOnly
            ? const Scaffold(
                body: Align(
                  alignment: Alignment.bottomCenter,
                  child: NoteInsertSheet(),
                ),
              )
            : _WritingPreview(
                imageTipOnly: imageTipOnly,
                chinese: locale.languageCode == 'zh',
              ),
      );
}

/// Uses only in-memory text and UI components. The preview never records,
/// picks photos, persists tips or invokes a platform keyboard API.
class _WritingPreview extends StatefulWidget {
  const _WritingPreview({this.imageTipOnly = false, this.chinese = false});
  final bool imageTipOnly;
  final bool chinese;

  @override
  State<_WritingPreview> createState() => _WritingPreviewState();
}

class _WritingPreviewState extends State<_WritingPreview> {
  late final SimpleFormattingController body;
  late final TextEditingController title;
  final bodyFocus = FocusNode();
  bool showTip = true;
  bool writingFocused = false;

  @override
  void initState() {
    super.initState();
    final chinese = widget.chinese;
    title = TextEditingController(text: chinese ? '週末計劃' : 'Weekend plans');
    body = SimpleFormattingController(
      text: chinese
          ? '帶上零食和水。\n\n記下你想做的事。'
          : 'Pack snacks and water.\n\nWrite down what you would like to do.',
    )..selection = const TextSelection(baseOffset: 0, extentOffset: 4);
  }

  @override
  void dispose() {
    body.dispose();
    title.dispose();
    bodyFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = S.of(context);
    if (widget.imageTipOnly) {
      return Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: showTip
              ? NoteEditorTip(
                  message: strings.Editor_Tip_Image_Layout,
                  onDismiss: () => setState(() => showTip = false),
                )
              : const SizedBox.shrink(),
        ),
      );
    }
    return Scaffold(
      body: Column(
        children: [
          NoteEditingActions(
            onUndo: null,
            onRedo: null,
            onInsert: () => showAppSheet<NoteInsertAction>(
              context: context,
              builder: (_) => const NoteInsertSheet(),
            ),
            writingFocused: writingFocused,
            onToggleFocus: () =>
                setState(() => writingFocused = !writingFocused),
          ),
          Expanded(
            child: DeskSurface(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: PaperNote(
                  color: AppColors.parchment,
                  kind: PaperNoteKind.sheet,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      TextField(
                        controller: title,
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontSize: 23,
                          fontWeight: FontWeight.w700,
                        ),
                        decoration: const InputDecoration(
                          filled: false,
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const SizedBox(height: 12),
                      RuledWritingArea(
                        paperColor: AppColors.parchment,
                        child: TextField(
                          controller: body,
                          focusNode: bodyFocus,
                          minLines: 8,
                          maxLines: null,
                          style: const TextStyle(
                            color: AppColors.ink,
                            fontSize: 17,
                            height: 1.55,
                          ),
                          decoration: const InputDecoration(
                            filled: false,
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: NoteWritingToolbar(
        controller: body,
        focusNode: bodyFocus,
        tip: showTip ? strings.Editor_Tip_Formatting : null,
        onDismissTip: () => setState(() => showTip = false),
      ),
    );
  }
}
