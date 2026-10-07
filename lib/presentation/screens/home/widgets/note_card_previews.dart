import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/domain/model/note_image_layout.dart';
import 'package:onlynote/domain/model/voice_memo.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/paper_note.dart';
import 'package:onlynote/presentation/theme/note_grid_layout.dart';
import 'package:onlynote/presentation/theme/theme.dart';

import 'note_card.dart';

@Preview(name: 'Notes with mixed content', group: 'Home', size: Size(390, 850))
Widget mixedNoteCardsPreview() => const _NoteCardsPreview();

@Preview(
  name: 'Notes with mixed content, dark',
  group: 'Home',
  size: Size(390, 850),
  brightness: Brightness.dark,
)
Widget mixedNoteCardsDarkPreview() => const _NoteCardsPreview(dark: true);

@Preview(
  name: 'Notes, Chinese 2× narrow',
  group: 'Home',
  size: Size(280, 800),
)
Widget mixedNoteCardsChinesePreview() =>
    const _NoteCardsPreview(chinese: true, textScale: 2);

class _NoteCardsPreview extends StatefulWidget {
  const _NoteCardsPreview({
    this.dark = false,
    this.chinese = false,
    this.textScale = 1,
  });
  final bool dark;
  final bool chinese;
  final double textScale;

  @override
  State<_NoteCardsPreview> createState() => _NoteCardsPreviewState();
}

class _NoteCardsPreviewState extends State<_NoteCardsPreview> {
  late final List<Note> _notes = [
    Note(
      id: 'preview-weekend',
      title: widget.chinese ? '週末的點子' : 'Weekend ideas',
      description: widget.chinese
          ? '沿海邊走走，再找一家小咖啡店。'
          : 'Follow the coast, then find a little café.',
      isPinned: true,
      dateTime: DateTime(2026, 10, 7),
      todo: [
        Todo(id: 'book', title: widget.chinese ? '訂好午餐' : 'Book lunch'),
        Todo(
          id: 'route',
          title: widget.chinese ? '找散步路線' : 'Find a walking route',
          completed: true,
        ),
      ],
      imagePaths: ['preview/coast.jpg'],
      linkedNoteIds: ['places'],
      tags: [widget.chinese ? '生活' : 'Personal'],
    ),
    Note(
      id: 'preview-shopping',
      title: widget.chinese ? '買菜' : 'Shopping',
      dateTime: DateTime(2026, 10, 6),
      color: const Color(0xFFDAEADD),
      todo: [
        Todo(id: 'tea', title: widget.chinese ? '茶葉' : 'Tea'),
        Todo(id: 'bread', title: widget.chinese ? '麵包' : 'Bread'),
        Todo(
          id: 'milk',
          title: widget.chinese ? '牛奶' : 'Milk',
          completed: true,
        ),
      ],
    ),
    Note(
      id: 'preview-voice',
      color: const Color(0xFFF2DFCD),
      dateTime: DateTime(2026, 10, 5),
      voiceMemos: [
        VoiceMemo(
          id: 'idea',
          path: 'note_audio/preview.m4a',
          durationMs: 45000,
          createdAt: DateTime(2026, 10, 5),
          transcript: widget.chinese
              ? '想試做一個小書架，放在窗邊。'
              : 'Try a small bookshelf by the window.',
        ),
      ],
    ),
    Note(
      id: 'preview-scan',
      title: widget.chinese ? '手寫食譜' : 'Handwritten recipe',
      dateTime: DateTime(2026, 10, 4),
      imagePaths: ['preview/recipe.jpg', 'preview/recipe-2.jpg'],
      imageLayouts: const [
        NoteImageLayout(
          path: 'preview/recipe.jpg',
          textOffset: 0,
          isDocumentPage: true,
        ),
        NoteImageLayout(
          path: 'preview/recipe-2.jpg',
          textOffset: 0,
          isDocumentPage: true,
        ),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        locale: widget.chinese ? const Locale('zh', 'HK') : const Locale('en'),
        supportedLocales: S.delegate.supportedLocales,
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: widget.dark ? AppTheme.dark : AppTheme.light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(widget.textScale),
            disableAnimations: true,
          ),
          child: child!,
        ),
        home: Scaffold(
          body: DeskSurface(
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) => MasonryGridView.count(
                  padding: const EdgeInsets.all(16),
                  crossAxisCount: noteGridColumns(
                    width: constraints.maxWidth,
                    textScaler: MediaQuery.textScalerOf(context),
                    preferredColumns: 2,
                  ),
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 12,
                  itemCount: _notes.length,
                  itemBuilder: (context, index) => NoteCard(
                    key: ValueKey(_notes[index].id),
                    note: _notes[index],
                    // The entire fixture stays in memory on the web previewer.
                    onShare: () {},
                    onTap: () {},
                    thumbnailBuilder: (_, path) => ColoredBox(
                      color: path.contains('recipe')
                          ? const Color(0xFFF0E4CA)
                          : const Color(0xFFA9C4BA),
                      child: Center(
                        child: Icon(
                          path.contains('recipe')
                              ? Icons.description_outlined
                              : Icons.landscape_outlined,
                          color: const Color(0xFF3E594F),
                        ),
                      ),
                    ),
                    onTodoToggle: (id) => setState(() {
                      final note = _notes[index];
                      _notes[index] = note.copyWith(todo: [
                        for (final todo in note.todo)
                          todo.id == id
                              ? todo.copyWith(completed: !todo.completed)
                              : todo,
                      ]);
                    }),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}
