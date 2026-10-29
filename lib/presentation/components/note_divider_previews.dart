import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/theme/colors.dart';
import 'package:onlynote/presentation/theme/theme.dart';
import 'note_body_editor.dart';
import 'paper_note.dart';
import 'simple_formatting_controller.dart';

@Preview(name: 'Divider blocks — writing', size: Size(390, 650))
Widget noteDividerWritingPreview() => _preview();

@Preview(name: 'Divider blocks — large text', size: Size(320, 650))
Widget noteDividerLargeTextPreview() => _preview(largeText: true);

@Preview(
    name: 'Divider blocks — Chinese dark',
    size: Size(390, 650),
    brightness: Brightness.dark)
Widget noteDividerChinesePreview() => _preview(chinese: true, dark: true);

Widget _preview(
        {bool largeText = false, bool chinese = false, bool dark = false}) =>
    MaterialApp(
      locale: chinese ? const Locale('zh', 'HK') : const Locale('en'),
      supportedLocales: S.delegate.supportedLocales,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate
      ],
      theme: dark ? AppTheme.dark : AppTheme.light,
      builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(largeText ? 1.8 : 1)),
          child: child!),
      home: _DividerPreview(chinese: chinese),
    );

class _DividerPreview extends StatefulWidget {
  const _DividerPreview({required this.chinese});
  final bool chinese;
  @override
  State<_DividerPreview> createState() => _DividerPreviewState();
}

class _DividerPreviewState extends State<_DividerPreview> {
  late final SimpleFormattingController _controller;
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    final before = widget.chinese
        ? '週末計劃\n找一條安靜的步道。'
        : 'Weekend plan\nFind a quiet walking trail.';
    final after = widget.chinese ? '記得帶水和零食。' : 'Remember water and snacks.';
    _controller = SimpleFormattingController(text: '$before\n$after');
    _controller.selection = TextSelection.collapsed(offset: before.length + 1);
    _controller.insertDivider();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: DeskSurface(
            child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: PaperNote(
              color: AppColors.parchment,
              kind: PaperNoteKind.sheet,
              child: NoteBodyEditor(
                  controller: _controller,
                  focusNode: _focus,
                  imagePaths: const [],
                  imageLayouts: const [],
                  onImageLayoutsChanged: (_) {},
                  onRemoveImage: (_) {})),
        )),
      );
}
