import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/data/dto/note_dto.dart';
import 'package:onlynote/domain/model/note_image_layout.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/app_sheet.dart';
import 'package:onlynote/presentation/components/note_history_sheet.dart';
import 'package:onlynote/presentation/components/note_history_version_tile.dart';
import 'package:onlynote/services/note_history.dart';

class _HistoryChanges extends ChangeNotifier {
  bool get hasHistoryListeners => hasListeners;
}

NoteHistoryVersion _version({String id = 'version'}) => NoteHistoryVersion(
      id: id,
      savedAt: DateTime.utc(2026, 10, 10, 10),
      note: NoteDto(
        id: 'note',
        title: 'Original title',
        description: 'Original body',
        todoList: [
          TodoDto(id: 'task', title: 'Read this checklist', completed: true)
        ],
        imagePaths: ['note_images/one.jpg', 'note_images/two.jpg'],
        voiceMemos: [
          {
            'id': 'memo',
            'path': 'note_audio/memo.m4a',
            'durationMs': 62000,
            'transcript': 'Keep this recorded thought'
          }
        ],
      ),
    );

Future<void> _open(WidgetTester tester,
    {required List<NoteHistoryVersion> versions,
    Future<NoteHistoryRestoreResult> Function(String)? restore,
    void Function(bool?)? onClosed,
    VoidCallback? onRestored,
    Listenable? changes,
    Locale locale = const Locale('en'),
    double textScale = 1}) async {
  await tester.pumpWidget(MaterialApp(
    locale: locale,
    supportedLocales: S.delegate.supportedLocales,
    localizationsDelegates: const [
      S.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!),
    home: Scaffold(
        body: Builder(
            builder: (context) => TextButton(
                  onPressed: () async {
                    final result = await showAppSheet<bool>(
                        context: context,
                        builder: (_) => NoteHistorySheet(
                            noteId: 'note',
                            readVersions: () => versions,
                            restoreVersion: restore,
                            onRestored: onRestored,
                            changes: changes));
                    onClosed?.call(result);
                  },
                  child: const Text('History'),
                ))),
  ));
  await tester.pumpAndSettle();
  await tester.tap(find.text('History'));
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('history search matches saved fields literally without writes',
      (tester) async {
    final versions = [
      NoteHistoryVersion(
        id: 'title',
        savedAt: DateTime.utc(2026, 10, 20),
        note: NoteDto(title: 'Release [draft].*', description: 'Tea plan'),
      ),
      NoteHistoryVersion(
        id: 'body',
        savedAt: DateTime.utc(2026, 10, 19),
        note: NoteDto(title: 'Second', description: 'Meet in 茶室😀 tomorrow'),
      ),
      NoteHistoryVersion(
        id: 'checklist',
        savedAt: DateTime.utc(2026, 10, 18),
        note: NoteDto(
          title: 'Third',
          todoList: [
            TodoDto(title: null),
            TodoDto(title: 'REVIEW the invoice')
          ],
        ),
      ),
      NoteHistoryVersion(
        id: 'transcript',
        savedAt: DateTime.utc(2026, 10, 17),
        note: NoteDto(title: 'Fourth', voiceMemos: const [
          {'transcript': null},
          {'transcript': 42},
          {
            'transcript': <String>['not text']
          },
          {'transcript': 'Recorded voice café'},
        ]),
      ),
    ];
    final originalNotes = [for (final version in versions) version.note];
    var restores = 0;
    await _open(tester, versions: versions, restore: (_) async {
      restores++;
      return NoteHistoryRestoreResult.restored;
    });
    final field = find.byKey(const ValueKey('history-search'));
    for (final (query, id) in [
      (' [DRAFT].* ', 'title'),
      ('茶室😀', 'body'),
      ('review', 'checklist'),
      ('CAFÉ', 'transcript'),
    ]) {
      await tester.enterText(field, query);
      await tester.pumpAndSettle();
      expect(find.byType(NoteHistoryVersionTile), findsOneWidget);
      expect(find.byKey(ValueKey('history-version-$id')), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
    await tester.enterText(field, r'[]()\\^$+?');
    await tester.pumpAndSettle();
    expect(find.text(S.current.History_Search_Empty), findsOneWidget);
    expect(find.text(S.current.History_Empty), findsNothing);
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('history-search-reset')));
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(field).controller!.text, isEmpty);
    expect(find.byType(NoteHistoryVersionTile), findsNWidgets(4));
    await tester.enterText(field, ' \n\t ');
    await tester.pumpAndSettle();
    expect(find.byType(NoteHistoryVersionTile), findsNWidgets(4));
    expect(restores, 0);
    for (var index = 0; index < versions.length; index++) {
      expect(versions[index].note, same(originalNotes[index]));
    }
  });

  testWidgets('search survives preview, data refresh, and failed restore retry',
      (tester) async {
    final changes = _HistoryChanges();
    addTearDown(changes.dispose);
    final chosen = NoteHistoryVersion(
        id: 'chosen-match',
        savedAt: DateTime.utc(2026, 10, 19),
        note: NoteDto(
            title: 'Saved version',
            description: '${'Earlier saved body\n' * 25}Chosen detail'));
    final savedBody = chosen.note.description!;
    final versions = <NoteHistoryVersion>[_version(id: 'other'), chosen];
    final attempts = <String>[];
    await _open(tester, versions: versions, changes: changes,
        restore: (id) async {
      attempts.add(id);
      return attempts.length == 1
          ? NoteHistoryRestoreResult.failed
          : NoteHistoryRestoreResult.restored;
    });
    final field = find.byKey(const ValueKey('history-search'));
    await tester.enterText(field, 'chosen');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    changes.notifyListeners();
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(field).controller!.text, 'chosen');
    final row = find.byKey(const ValueKey('history-version-chosen-match'));
    expect(
        tester.widget<NoteHistoryVersionTile>(row).snippet, '…Chosen detail');
    await tester
        .tap(find.byKey(const ValueKey('history-version-chosen-match')));
    await tester.pumpAndSettle();
    versions.remove(chosen);
    changes.notifyListeners();
    await tester.pumpAndSettle();
    expect(find.text(savedBody), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, S.current.History_Title));
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(field).controller!.text, 'chosen');
    expect(find.text(S.current.History_Search_Empty), findsOneWidget);
    versions.add(chosen);
    changes.notifyListeners();
    await tester.pumpAndSettle();
    await tester
        .tap(find.byKey(const ValueKey('history-version-chosen-match')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('history-restore-action')));
    await tester.pumpAndSettle();
    expect(find.text(S.current.History_Restore_Failed), findsOneWidget);
    expect(find.text(savedBody), findsOneWidget);
    changes.notifyListeners();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('history-restore-action')));
    await tester.pumpAndSettle();
    expect(attempts, ['chosen-match', 'chosen-match']);
    expect(find.byType(NoteHistorySheet), findsNothing);
    changes.notifyListeners();
    await tester.pumpAndSettle();
    expect(changes.hasHistoryListeners, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('query changes only the snippet and clearing restores exact text',
      (tester) async {
    final body = 'Stable body title\n${'Earlier context ' * 30}';
    final version = NoteHistoryVersion(
      id: 'matching-context',
      savedAt: DateTime.utc(2026, 10, 19),
      note: NoteDto(
        description: body,
        todoList: [TodoDto(title: 'Buy literal [tea]')],
        voiceMemos: const [
          {'transcript': false},
          {'transcript': 'Recorded 茶室😀 thought'},
        ],
      ),
    );
    await _open(tester, versions: [version]);
    final row = find.byKey(const ValueKey('history-version-matching-context'));
    final field = find.byKey(const ValueKey('history-search'));
    expect(
        tester.widget<NoteHistoryVersionTile>(row).title, 'Stable body title');
    expect(tester.widget<NoteHistoryVersionTile>(row).snippet, body.trim());
    for (final (query, expected) in [
      ('[TEA]', '…[tea]'),
      ('茶室😀', '…茶室😀 thought'),
      ('stable', 'Stable body title Earlier context'),
    ]) {
      await tester.enterText(field, query);
      await tester.pumpAndSettle();
      final tile = tester.widget<NoteHistoryVersionTile>(row);
      expect(tile.title, 'Stable body title');
      expect(tile.snippet, startsWith(expected));
    }
    await tester.tap(find.byKey(const ValueKey('history-clear-search')));
    await tester.pumpAndSettle();
    expect(tester.widget<NoteHistoryVersionTile>(row).snippet, body.trim());
    expect(version.note.description, body);
    expect(tester.takeException(), isNull);
  });

  testWidgets('active search remains recoverable after all versions disappear',
      (tester) async {
    final changes = _HistoryChanges();
    addTearDown(changes.dispose);
    final versions = [_version()];
    await _open(tester, versions: versions, changes: changes);
    final field = find.byKey(const ValueKey('history-search'));
    await tester.enterText(field, 'missing');
    await tester.pumpAndSettle();
    versions.clear();
    changes.notifyListeners();
    await tester.pumpAndSettle();
    expect(field, findsOneWidget);
    expect(find.text(S.current.History_Search_Empty), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('history-clear-search')));
    await tester.pumpAndSettle();
    expect(find.text(S.current.History_Empty), findsOneWidget);
    expect(find.text(S.current.History_Search_Empty), findsNothing);
    expect(find.byKey(const ValueKey('history-restore-action')), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    changes.notifyListeners();
    await tester.pump();
    expect(changes.hasHistoryListeners, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('search and clear fit a narrow large-text keyboard layout',
      (tester) async {
    tester.view.physicalSize = const Size(280, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    await _open(tester,
        versions: [_version()], locale: const Locale('zh', 'HK'), textScale: 2);
    final field = find.byKey(const ValueKey('history-search'));
    await tester.enterText(field, '不存在[]');
    tester.view.viewInsets = const FakeViewPadding(bottom: 240);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final clear = find.byKey(const ValueKey('history-search-reset'));
    await tester.ensureVisible(clear);
    await tester.pumpAndSettle();
    expect(clear.hitTestable(), findsOneWidget);
    await tester.tap(clear);
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(field).controller!.text, isEmpty);
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('history change listener moves to replacement and detaches',
      (tester) async {
    final first = _HistoryChanges();
    final second = _HistoryChanges();
    addTearDown(first.dispose);
    addTearDown(second.dispose);
    Widget app(Listenable changes) => MaterialApp(
          supportedLocales: S.delegate.supportedLocales,
          localizationsDelegates: const [
            S.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Scaffold(
            body: NoteHistorySheet(
              noteId: 'note',
              readVersions: () => [_version()],
              changes: changes,
            ),
          ),
        );
    await tester.pumpWidget(app(first));
    await tester.pumpAndSettle();
    expect(first.hasHistoryListeners, isTrue);
    final field = find.byKey(const ValueKey('history-search'));
    await tester.enterText(field, 'recorded');
    await tester.pumpAndSettle();
    await tester.pumpWidget(app(second));
    await tester.pumpAndSettle();
    expect(first.hasHistoryListeners, isFalse);
    expect(second.hasHistoryListeners, isTrue);
    expect(tester.widget<TextField>(field).controller!.text, 'recorded');
    first.notifyListeners();
    second.notifyListeners();
    await tester.pumpAndSettle();
    expect(find.byType(NoteHistoryVersionTile), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    expect(second.hasHistoryListeners, isFalse);
    second.notifyListeners();
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'recording-only summaries skip blank and malformed transcripts without writes',
      (tester) async {
    const storedTranscript = ' \n第一行 茶😀\nSecond line 📝\n ';
    const expectedSnippet = '第一行 茶😀\nSecond line 📝';
    final memos = <Map<dynamic, dynamic>>[
      {'id': 'missing'},
      {'id': 'null', 'transcript': null},
      {'id': 'number', 'transcript': 42},
      {
        'id': 'list',
        'transcript': ['not text']
      },
      {'id': 'blank', 'transcript': ' \n\t '},
      {
        'id': 'first',
        'path': 'note_audio/unavailable.m4a',
        'durationMs': 62000,
        'transcript': storedTranscript,
      },
      {'id': 'later', 'transcript': 'Later recorded thought'},
    ];
    final originalMemos = [for (final memo in memos) Map.of(memo)];
    final version = NoteHistoryVersion(
      id: 'transcript',
      savedAt: DateTime.utc(2026, 10, 10),
      note: NoteDto(
        id: 'note',
        title: ' \n ',
        description: '\t ',
        todoList: [TodoDto(title: null), TodoDto(title: ' \n ')],
        voiceMemos: memos,
      ),
    );
    var restores = 0;
    await _open(tester, versions: [version], restore: (_) async {
      restores++;
      return NoteHistoryRestoreResult.restored;
    });
    final row = find.byKey(const ValueKey('history-version-transcript'));
    final summary = tester.widget<NoteHistoryVersionTile>(row);
    expect(summary.title, '第一行 茶😀');
    expect(summary.snippet, expectedSnippet);
    expect(find.text('Later recorded thought'), findsNothing);
    expect(version.note.voiceMemos, originalMemos);
    expect(version.note.title, ' \n ');
    expect(version.note.description, '\t ');
    await tester.tap(row);
    await tester.pumpAndSettle();
    expect(restores, 0);
    expect(find.text(storedTranscript), findsOneWidget);
    expect(find.text('Later recorded thought'), findsOneWidget);
    for (final editable
        in tester.widgetList<EditableText>(find.byType(EditableText))) {
      expect(editable.readOnly, isTrue);
    }
    await tester.tap(find.widgetWithText(TextButton, S.current.History_Title));
    await tester.pumpAndSettle();
    expect(tester.widget<NoteHistoryVersionTile>(row).snippet, expectedSnippet);
    expect(restores, 0);
    expect(version.note.voiceMemos, originalMemos);
    expect(tester.takeException(), isNull);
  });

  for (final scenario in [
    (
      name: 'stored title',
      title: '  Named recording  ',
      body: null,
      tasks: <TodoDto>[],
      expectedTitle: '  Named recording  ',
      expectedSnippet: 'Recorded fallback\nAnother line',
    ),
    (
      name: 'body text',
      title: null,
      body: ' \nBody first line\nBody second line ',
      tasks: [TodoDto(title: 'Checklist text')],
      expectedTitle: 'Body first line',
      expectedSnippet: 'Body first line\nBody second line',
    ),
    (
      name: 'checklist text',
      title: null,
      body: ' \n ',
      tasks: [
        TodoDto(title: ''),
        TodoDto(title: ' First task ', completed: true),
        TodoDto(title: 'Second task'),
      ],
      expectedTitle: ' First task , Second task',
      expectedSnippet: ' First task , Second task',
    ),
  ]) {
    testWidgets('transcript summary preserves ${scenario.name} priority',
        (tester) async {
      final version = NoteHistoryVersion(
        id: 'priority',
        savedAt: DateTime.utc(2026, 10, 10),
        note: NoteDto(
          title: scenario.title,
          description: scenario.body,
          todoList: scenario.tasks,
          voiceMemos: const [
            {'transcript': 'Recorded fallback\nAnother line'},
          ],
        ),
      );
      await _open(tester, versions: [version]);
      final summary = tester.widget<NoteHistoryVersionTile>(
          find.byKey(const ValueKey('history-version-priority')));
      expect(summary.title, scenario.expectedTitle);
      expect(summary.snippet, scenario.expectedSnippet);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('no usable transcript retains the existing generic history title',
      (tester) async {
    final version = NoteHistoryVersion(
      id: 'no-transcript',
      savedAt: DateTime.utc(2026, 10, 10),
      note: NoteDto(voiceMemos: const [
        {'transcript': false},
        {'transcript': <String>[]},
        {'transcript': ' \n\t'},
        {},
      ]),
    );
    await _open(tester, versions: [version]);
    final summary = tester.widget<NoteHistoryVersionTile>(
        find.byKey(const ValueKey('history-version-no-transcript')));
    expect(summary.title, S.current.History_Title);
    expect(summary.snippet, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('transcript-derived title restores the selected version identity',
      (tester) async {
    final selected = NoteHistoryVersion(
      id: 'recording-chosen',
      savedAt: DateTime.utc(2026, 10, 10),
      note: NoteDto(voiceMemos: const [
        {'transcript': 'Chosen recording 茶😀\nReviewed transcript'},
      ]),
    );
    final restored = <String>[];
    bool? result;
    await _open(tester,
        versions: [_version(id: 'different'), selected],
        onClosed: (value) => result = value,
        restore: (id) async {
          restored.add(id);
          return NoteHistoryRestoreResult.restored;
        });
    final row = find.byKey(const ValueKey('history-version-recording-chosen'));
    await tester.ensureVisible(row);
    await tester.tap(row);
    await tester.pumpAndSettle();
    expect(restored, isEmpty);
    await tester.tap(find.byKey(const ValueKey('history-restore-action')));
    await tester.pumpAndSettle();
    expect(restored, ['recording-chosen']);
    expect(result, isTrue);
    expect(find.byType(NoteHistorySheet), findsNothing);
  });

  testWidgets(
      'transcript summary fits Chinese 2x and keeps full text semantics',
      (tester) async {
    tester.view.physicalSize = const Size(280, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final semantics = tester.ensureSemantics();
    try {
      final title = '第一行 茶😀 ${'這是完整的錄音內容 ' * 8}';
      final transcript = '$title\n第二行記錄。';
      final version = NoteHistoryVersion(
        id: 'large-transcript',
        savedAt: DateTime.utc(2026, 10, 10),
        note: NoteDto(voiceMemos: [
          {'transcript': transcript},
        ]),
      );
      await _open(tester,
          versions: [version], locale: const Locale('zh', 'HK'), textScale: 2);
      final row =
          find.byKey(const ValueKey('history-version-large-transcript'));
      await tester.ensureVisible(row);
      expect(tester.getSize(row).height, greaterThanOrEqualTo(48));
      expect(tester.getSemantics(find.text(title)).label, contains(title));
      expect(tester.getSemantics(find.text(transcript)).label,
          contains(transcript));
      expect(tester.takeException(), isNull);
      await tester.tap(row);
      await tester.pumpAndSettle();
      expect(find.text(transcript), findsOneWidget);
      expect(find.byKey(const ValueKey('history-restore-action')).hitTestable(),
          findsOneWidget);
      expect(tester.takeException(), isNull);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('preview is read-only and never restores on selecting a version',
      (tester) async {
    var restores = 0;
    await _open(tester, versions: [_version()], restore: (_) async {
      restores++;
      return NoteHistoryRestoreResult.restored;
    });
    expect(find.text('Original title'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('history-version-version')));
    await tester.pumpAndSettle();
    expect(restores, 0);
    expect(find.text('Original title'), findsOneWidget);
    expect(find.text('Original body'), findsOneWidget);
    expect(find.text('Read this checklist'), findsOneWidget);
    expect(find.text('Keep this recorded thought'), findsOneWidget);
    expect(find.text('1:02'), findsOneWidget);
    expect(find.textContaining('2 photos', findRichText: true), findsOneWidget);
    expect(
        find.textContaining(S.current.History_Recordings(1),
            findRichText: true),
        findsOneWidget);
    expect(find.byType(Checkbox), findsNothing);
    for (final editable
        in tester.widgetList<EditableText>(find.byType(EditableText))) {
      expect(editable.readOnly, isTrue);
    }
  });

  testWidgets('explicit restore uses selected version and reports completion',
      (tester) async {
    final restored = <String>[];
    var refreshes = 0;
    bool? result;
    await _open(tester,
        versions: [_version(id: 'chosen')],
        onClosed: (value) => result = value,
        onRestored: () => refreshes++,
        restore: (id) async {
          restored.add(id);
          return NoteHistoryRestoreResult.restored;
        });
    await tester.tap(find.byKey(const ValueKey('history-version-chosen')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('history-restore-action')));
    await tester.pumpAndSettle();
    expect(restored, ['chosen']);
    expect(result, isTrue);
    expect(refreshes, 1);
    expect(find.byType(NoteHistorySheet), findsNothing);
  });

  testWidgets(
      'pending restore completing during dismissal leaves the reader open',
      (tester) async {
    final completion = Completer<NoteHistoryRestoreResult>();
    final results = <bool?>[];
    final attempted = <String>[];
    var refreshes = 0;
    await _open(tester,
        versions: [_version(id: 'chosen')],
        onRestored: () => refreshes++,
        onClosed: results.add,
        restore: (id) {
          attempted.add(id);
          return completion.future;
        });
    await tester.tap(find.byKey(const ValueKey('history-version-chosen')));
    await tester.pumpAndSettle();
    final restore = tester
        .widget<FilledButton>(
            find.byKey(const ValueKey('history-restore-action')))
        .onPressed!;
    restore();
    restore();
    await tester.pump();
    await tester.tap(find.byTooltip('Close'));
    await tester.pump(const Duration(milliseconds: 20));
    expect(find.byType(NoteHistorySheet), findsOneWidget);
    completion.complete(NoteHistoryRestoreResult.restored);
    await tester.pumpAndSettle();
    restore();
    expect(attempted, ['chosen']);
    expect(refreshes, 1);
    expect(results, [null]);
    expect(find.text('History'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('pending restore completion cannot dismiss a covering dialog',
      (tester) async {
    final completion = Completer<NoteHistoryRestoreResult>();
    final results = <bool?>[];
    final attempted = <String>[];
    var refreshes = 0;
    await _open(tester,
        versions: [_version(id: 'chosen')],
        onRestored: () => refreshes++,
        onClosed: results.add,
        restore: (id) {
          attempted.add(id);
          return completion.future;
        });
    await tester.tap(find.byKey(const ValueKey('history-version-chosen')));
    await tester.pumpAndSettle();
    final restore = tester
        .widget<FilledButton>(
            find.byKey(const ValueKey('history-restore-action')))
        .onPressed!;
    restore();
    await tester.pump();
    showDialog<void>(
        context: tester.element(find.byType(NoteHistorySheet)),
        builder: (_) => const AlertDialog(content: Text('Covered')));
    await tester.pump(const Duration(milliseconds: 300));
    completion.complete(NoteHistoryRestoreResult.restored);
    await tester.pumpAndSettle();
    expect(find.text('Covered'), findsOneWidget);
    restore();
    expect(attempted, ['chosen']);
    expect(refreshes, 1);
    expect(results, isEmpty);
    Navigator.pop(tester.element(find.text('Covered')));
    await tester.pumpAndSettle();
    expect(find.text(S.current.History_Restored), findsOneWidget);
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(results, [null]);
    expect(find.text('History'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('restore notifies its owner once after the sheet is disposed',
      (tester) async {
    final completion = Completer<NoteHistoryRestoreResult>();
    final results = <bool?>[];
    var refreshes = 0;
    await _open(tester,
        versions: [_version(id: 'chosen')],
        onClosed: results.add,
        onRestored: () => refreshes++,
        restore: (_) => completion.future);
    await tester.tap(find.byKey(const ValueKey('history-version-chosen')));
    await tester.pumpAndSettle();
    final restore = tester
        .widget<FilledButton>(
            find.byKey(const ValueKey('history-restore-action')))
        .onPressed!;
    restore();
    await tester.pump();
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(find.byType(NoteHistorySheet), findsNothing);
    expect(results, [null]);
    expect(refreshes, 0);
    completion.complete(NoteHistoryRestoreResult.restored);
    await tester.pumpAndSettle();
    restore();
    expect(refreshes, 1);
    expect(results, [null]);
    expect(find.text('History'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final outcome in [
    NoteHistoryRestoreResult.failed,
    NoteHistoryRestoreResult.unavailable,
    NoteHistoryRestoreResult.unchanged
  ]) {
    testWidgets('$outcome does not notify the owner of a restored note',
        (tester) async {
      var refreshes = 0;
      await _open(tester,
          versions: [_version()],
          onRestored: () => refreshes++,
          restore: (_) async => outcome);
      await tester.tap(find.byKey(const ValueKey('history-version-version')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('history-restore-action')));
      await tester.pumpAndSettle();
      expect(refreshes, 0);
      expect(find.byType(NoteHistorySheet), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
      'owner refresh failure does not turn a completed restore into failure',
      (tester) async {
    final results = <bool?>[];
    var refreshes = 0;
    await _open(tester,
        versions: [_version()],
        onClosed: results.add,
        onRestored: () {
          refreshes++;
          throw StateError('Refresh unavailable');
        },
        restore: (_) async => NoteHistoryRestoreResult.restored);
    await tester.tap(find.byKey(const ValueKey('history-version-version')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('history-restore-action')));
    await tester.pumpAndSettle();
    expect(refreshes, 1);
    expect(results, [true]);
    expect(find.text(S.current.History_Restore_Failed), findsNothing);
    expect(find.text('History'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('failed restore keeps preview and retries the same version',
      (tester) async {
    final attempted = <String>[];
    await _open(tester, versions: [_version()], restore: (id) async {
      attempted.add(id);
      return attempted.length == 1
          ? NoteHistoryRestoreResult.failed
          : NoteHistoryRestoreResult.restored;
    });
    await tester.tap(find.byKey(const ValueKey('history-version-version')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('history-restore-action')));
    await tester.pumpAndSettle();
    expect(find.text(S.current.History_Restore_Failed), findsOneWidget);
    expect(find.text(S.current.Retry), findsOneWidget);
    expect(find.text('Original body'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('history-restore-action')));
    await tester.pumpAndSettle();
    expect(attempted, ['version', 'version']);
    expect(find.byType(NoteHistorySheet), findsNothing);
  });

  testWidgets('unavailable version reports absence without closing preview',
      (tester) async {
    await _open(tester,
        versions: [_version()],
        restore: (_) async => NoteHistoryRestoreResult.unavailable);
    await tester.tap(find.byKey(const ValueKey('history-version-version')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('history-restore-action')));
    await tester.pumpAndSettle();
    expect(find.text(S.current.History_Unavailable), findsOneWidget);
    expect(find.byType(NoteHistorySheet), findsOneWidget);
  });

  testWidgets('restore action is disabled until its current operation finishes',
      (tester) async {
    final completer = Completer<NoteHistoryRestoreResult>();
    var calls = 0;
    await _open(tester, versions: [_version()], restore: (_) {
      calls++;
      return completer.future;
    });
    await tester.tap(find.byKey(const ValueKey('history-version-version')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('history-restore-action')));
    await tester.pump();
    expect(
        tester
            .widget<FilledButton>(
                find.byKey(const ValueKey('history-restore-action')))
            .onPressed,
        isNull);
    expect(calls, 1);
    completer.complete(NoteHistoryRestoreResult.failed);
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<FilledButton>(
                find.byKey(const ValueKey('history-restore-action')))
            .onPressed,
        isNotNull);
  });

  testWidgets('restore footer stays visible while a tall photo preview scrolls',
      (tester) async {
    const path = 'note_images/tall.jpg';
    final version = NoteHistoryVersion(
        id: 'tall',
        savedAt: DateTime.utc(2026, 10, 10),
        note: NoteDto(
            id: 'note',
            title: 'Tall photo preview',
            description: 'Before photo\n${'More text below the photo.\n' * 80}',
            imagePaths: [
              path
            ],
            imageLayouts: [
              const NoteImageLayout(
                      path: path,
                      textOffset: 13,
                      widthFactor: .85,
                      aspectRatio: .1)
                  .toMap(),
            ]));
    var restores = 0;
    await _open(tester, versions: [version], restore: (_) async {
      restores++;
      return NoteHistoryRestoreResult.unchanged;
    });
    await tester.tap(find.byKey(const ValueKey('history-version-tall')));
    await tester.pumpAndSettle();
    final action = find.byKey(const ValueKey('history-restore-action'));
    expect(action.hitTestable(), findsOneWidget);
    final originalRect = tester.getRect(action);
    expect(originalRect.bottom,
        lessThanOrEqualTo(tester.view.physicalSize.height));
    final preview = find.descendant(
        of: find.byType(AppSheet),
        matching: find.byType(SingleChildScrollView));
    await tester.drag(preview, const Offset(0, -250));
    await tester.pumpAndSettle();
    expect(tester.getRect(action), originalRect);
    expect(action.hitTestable(), findsOneWidget);
    await tester.tap(action);
    await tester.pumpAndSettle();
    expect(restores, 1);
    expect(find.byKey(const ValueKey('history-restore-result')).hitTestable(),
        findsOneWidget);
    expect(action.hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('empty history explains when versions are saved', (tester) async {
    await _open(tester, versions: []);
    expect(find.text(S.current.History_Empty), findsOneWidget);
    expect(find.byKey(const ValueKey('history-restore-action')), findsNothing);
  });

  testWidgets('preview scrolls at large Chinese text without overflow',
      (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _open(tester,
        versions: [_version()],
        locale: const Locale('zh'),
        textScale: 2,
        restore: (_) async => NoteHistoryRestoreResult.unchanged);
    await tester.tap(find.byKey(const ValueKey('history-version-version')));
    await tester.pumpAndSettle();
    final action = find.byKey(const ValueKey('history-restore-action'));
    expect(action.hitTestable(), findsOneWidget);
    await tester.tap(action);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('history-restore-result')).hitTestable(),
        findsOneWidget);
    expect(tester.takeException(), isNull);
    expect(
        find.byKey(const ValueKey('history-restore-action')), findsOneWidget);
  });
}
