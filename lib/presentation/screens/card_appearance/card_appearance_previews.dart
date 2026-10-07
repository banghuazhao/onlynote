import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/domain/model/note_card_style.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/paper_note.dart';
import 'package:onlynote/presentation/screens/home/widgets/note_card.dart';
import 'package:onlynote/presentation/theme/theme.dart';

import 'card_appearance_screen.dart';

@Preview(name: 'Default card style', group: 'Card style', size: Size(390, 844))
Widget defaultCardStylePreview() => const _CardStylePreview(defaults: true);

@Preview(
  name: 'Customize current card, dark',
  group: 'Card style',
  size: Size(390, 844),
  brightness: Brightness.dark,
)
Widget darkCardStylePreview() => const _CardStylePreview(dark: true);

@Preview(
  name: 'Customize card, narrow Chinese 2×',
  group: 'Card style',
  size: Size(320, 760),
)
Widget chineseCardStylePreview() =>
    const _CardStylePreview(chinese: true, textScale: 2);

class _CardStylePreview extends StatefulWidget {
  const _CardStylePreview({
    this.defaults = false,
    this.dark = false,
    this.chinese = false,
    this.textScale = 1,
  });

  final bool defaults;
  final bool dark;
  final bool chinese;
  final double textScale;

  @override
  State<_CardStylePreview> createState() => _CardStylePreviewState();
}

class _CardStylePreviewState extends State<_CardStylePreview> {
  late final ValueNotifier<Note> _note = ValueNotifier(Note(
    id: 'preview-card-style',
    title: widget.chinese ? '週末的靈感' : 'Weekend inspiration',
    description: widget.chinese
        ? '沿海邊走走，記下新的想法，為下週留一點期待。'
        : 'Follow the coast, collect new ideas, and make a little time to write.',
    dateTime: DateTime(2026, 10, 7),
    color: const Color(0xFFD3EDE4),
    todo: [
      Todo(id: 'walk', title: widget.chinese ? '去海邊散步' : 'Walk by the sea'),
      Todo(
          id: 'journal',
          title: widget.chinese ? '寫一頁日記' : 'Write a page',
          completed: true),
    ],
    cardStyle: const NoteCardStyle(
      fontFamily: 'Roboto',
      fontSize: AppFontSize.medium,
      cardSize: NoteCardSize.medium,
      paperStyle: NoteCardPaperStyle.textured,
      showDate: true,
    ),
  ));

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  // Previews keep their edits in memory and never write device preferences.
  Future<void> _save(NoteCardStyle style) async {
    _note.value = _note.value.copyWith(cardStyle: style);
  }

  Future<void> _saveAppearance(NoteCardStyle style, Color? color) async {
    _note.value = _note.value.copyWith(cardStyle: style, color: color);
  }

  Widget _editor(BuildContext context) => CardAppearanceScreen(
        note: widget.defaults ? null : _note.value,
        initialStyle: widget.defaults ? _note.value.cardStyle : null,
        onSave: widget.defaults ? _save : null,
        onSaveAppearance: widget.defaults ? null : _saveAppearance,
      );

  Widget _entry(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(S.of(context).Card_Style)),
        body: DeskSurface(
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  ValueListenableBuilder<Note>(
                    valueListenable: _note,
                    builder: (context, note, child) => NoteCard(note: note),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => Navigator.of(context)
                        .push(MaterialPageRoute<void>(builder: _editor)),
                    icon: const Icon(Icons.style_outlined),
                    label: Text(widget.defaults
                        ? S.of(context).Default_Card_Style
                        : S.of(context).Card_Style),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: widget.dark ? AppTheme.dark : AppTheme.light,
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
            disableAnimations: widget.chinese,
          ),
          child: child!,
        ),
        // Keep a route beneath the editor so Save and Back remain interactive.
        onGenerateRoute: (_) => MaterialPageRoute<void>(builder: _entry),
        onGenerateInitialRoutes: (_) => [
          MaterialPageRoute<void>(builder: _entry),
          MaterialPageRoute<void>(builder: _editor),
        ],
      );
}
