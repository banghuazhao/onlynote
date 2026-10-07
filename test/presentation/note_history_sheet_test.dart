import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/data/dto/note_dto.dart';
import 'package:onlynote/domain/model/note_image_layout.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/app_sheet.dart';
import 'package:onlynote/presentation/components/note_history_sheet.dart';
import 'package:onlynote/services/note_history.dart';

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
                            restoreVersion: restore));
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
    bool? result;
    await _open(tester,
        versions: [_version(id: 'chosen')],
        onClosed: (value) => result = value,
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
    expect(find.byType(NoteHistorySheet), findsNothing);
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
