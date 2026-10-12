import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/theme/spacing.dart';

import 'note_checklist.dart';

@Preview(
    name: 'Copy unfinished tasks', group: 'Checklist', size: Size(390, 700))
Widget checklistCopyPreview() => const _ChecklistCopyPreview();

@Preview(
  name: 'Copy unfinished tasks dark',
  group: 'Checklist',
  size: Size(390, 700),
  brightness: Brightness.dark,
)
Widget checklistCopyDarkPreview() => const _ChecklistCopyPreview(dark: true);

@Preview(
  name: 'Copy unfinished tasks Chinese 2×',
  group: 'Checklist',
  size: Size(280, 700),
)
Widget checklistCopyChinesePreview() =>
    const _ChecklistCopyPreview(chinese: true, textScale: 2);

/// A local clipboard fixture keeps interaction independent of native APIs.
class _ChecklistCopyPreview extends StatefulWidget {
  const _ChecklistCopyPreview({
    this.dark = false,
    this.chinese = false,
    this.textScale = 1,
  });

  final bool dark;
  final bool chinese;
  final double textScale;

  @override
  State<_ChecklistCopyPreview> createState() => _ChecklistCopyPreviewState();
}

class _ChecklistCopyPreviewState extends State<_ChecklistCopyPreview> {
  late List<Todo> _todos;
  String? _clipboard;

  @override
  void initState() {
    super.initState();
    _todos = [
      Todo(id: 'bag', title: widget.chinese ? '帶上購物袋' : 'Bring shopping bags'),
      Todo(
        id: 'milk',
        title: widget.chinese ? '牛奶' : 'Milk',
        completed: true,
      ),
      Todo(
          id: 'bread',
          title: widget.chinese ? '麵包和新鮮水果' : 'Bread and fresh fruit'),
    ];
  }

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
        theme: ThemeData(
          brightness: widget.dark ? Brightness.dark : Brightness.light,
          colorSchemeSeed: const Color(0xFF685947),
          fontFamilyFallback: const ['DroidSansFallback'],
          extensions: const [AppTokens()],
        ),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(widget.textScale),
            disableAnimations: true,
          ),
          child: child!,
        ),
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF9F0),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: NoteChecklist(
                      todos: _todos,
                      onToggle: (id) => setState(() {
                        _todos = [
                          for (final todo in _todos)
                            todo.id == id
                                ? todo.copyWith(completed: !todo.completed)
                                : todo,
                        ];
                      }),
                      onReset: () => setState(() {
                        _todos = [
                          for (final todo in _todos)
                            todo.copyWith(completed: false),
                        ];
                      }),
                      clipboardWriter: (text) async {
                        setState(() => _clipboard = text);
                      },
                    ),
                  ),
                ),
                if (_clipboard != null) ...[
                  const SizedBox(height: 24),
                  Text(
                    _clipboard!,
                    key: const ValueKey('checklist-preview-clipboard'),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
}
