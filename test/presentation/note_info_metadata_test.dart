import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:onlynote/Tools/app_typography_settings.dart';
import 'package:onlynote/Tools/locator.dart';
import 'package:onlynote/data/dto/folder_dto.dart';
import 'package:onlynote/data/dto/note_dto.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/domain/repository/folder_repository.dart';
import 'package:onlynote/domain/repository/note_repository.dart';
import 'package:onlynote/domain/usecase/add_note_usecase.dart';
import 'package:onlynote/domain/usecase/get_note_usecase.dart';
import 'package:onlynote/domain/usecase/update_note_usecase.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/note_info_sheet.dart';
import 'package:onlynote/presentation/routes/routes.dart';
import 'package:onlynote/presentation/screens/add_update_note/add_update_note_screen.dart';
import 'package:onlynote/presentation/screens/add_update_note/bloc/add_update_bloc.dart';
import 'package:onlynote/presentation/screens/note_detail/bloc/detail/note_detail_bloc.dart';
import 'package:onlynote/presentation/screens/note_detail/note_detail_screen.dart';
import 'package:onlynote/presentation/theme/theme.dart';
import 'package:onlynote/services/note_autosave.dart';
import 'package:onlynote/services/note_dates.dart';
import 'package:onlynote/services/note_position_store.dart';
import 'package:onlynote/services/note_templates.dart';

class _Notes implements NoteRepository {
  final values = <String, NoteDto>{};
  int writes = 0;

  @override
  Future<void> addUpdateNote(NoteDto note) async {
    writes++;
    values[note.id!] = note;
  }

  @override
  Future<NoteDto> getNote(String id) async => values[id]!;
  @override
  List<NoteDto> getAllNotes() => values.values.toList();
  @override
  Future<void> deleteNote(String id) async => values.remove(id);
  @override
  Future<void> deleteMultiNotes(List<String> ids) async {
    ids.forEach(values.remove);
  }
}

class _Folders implements FolderRepository {
  final values = <FolderDto>[];
  bool fail = false;
  int writes = 0;

  @override
  List<FolderDto> getAllFolders() {
    if (fail) throw StateError('Folder storage unavailable');
    return values;
  }

  @override
  Future<void> addUpdateFolder(FolderDto folder) async {
    writes++;
  }

  @override
  Future<void> deleteFolder(String id) async {
    writes++;
  }
}

class _FailingStore implements NoteAutosaveStore {
  final drafts = <Note>[];
  int saveAttempts = 0;

  @override
  Future<void> writeDraft(Note note) async => drafts.add(note);
  @override
  Future<void> removeDraft(String id) async {}
  @override
  Future<void> saveNote(Note note) async {
    saveAttempts++;
    throw StateError('Temporarily unavailable');
  }
}

class _ReaderRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
        AutoRoute(
          initial: true,
          page: PageInfo(
            'NoteInfoMetadataReaderRoute',
            builder: (_) => NoteDetailScreen(
              noteId: 'note',
              positionStore: NotePositionStore.memory(),
            ),
          ),
        ),
      ];
}

Widget _app(Widget home) => MaterialApp(
      theme: AppTheme.light,
      locale: const Locale('en'),
      supportedLocales: S.delegate.supportedLocales,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: home,
    );

Future<NoteInfoSheet> _editorInfo(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('editor-more-note')));
  await tester.pumpAndSettle();
  await tester.tap(find.text(S.current.Note_Info));
  await tester.pumpAndSettle();
  return tester.widget<NoteInfoSheet>(find.byType(NoteInfoSheet));
}

Future<void> _closeInfo(WidgetTester tester) async {
  final context = tester.element(find.byType(NoteInfoSheet));
  await tester.tap(
      find.byTooltip(MaterialLocalizations.of(context).closeButtonTooltip));
  await tester.pumpAndSettle();
}

Future<NoteInfoSheet> _readerInfo(WidgetTester tester,
    {required bool trashed}) async {
  if (trashed) {
    await tester.tap(find.byTooltip(S.current.Note_Info));
  } else {
    await tester.tap(find.byTooltip(S.current.More_Options));
    await tester.pumpAndSettle();
    final action = find.text(S.current.Note_Info);
    await tester.ensureVisible(action);
    await tester.tap(action);
  }
  await tester.pumpAndSettle();
  return tester.widget<NoteInfoSheet>(find.byType(NoteInfoSheet));
}

void main() {
  final fonts = Map<String, GoogleFontBuilder>.of(kAppFontFamilies);
  setUpAll(() async {
    await initializeDateFormatting();
    if (!locator.isRegistered<S>()) locator.registerSingleton(S());
  });
  setUp(() {
    for (final family in fonts.keys) {
      kAppFontFamilies[family] = (
              {textStyle, color, fontSize, fontWeight, fontStyle}) =>
          (textStyle ?? const TextStyle()).copyWith(
              color: color,
              fontSize: fontSize,
              fontWeight: fontWeight,
              fontStyle: fontStyle);
    }
  });
  tearDown(() => kAppFontFamilies.addAll(fonts));

  for (final (name, existing) in [
    ('new blank', null),
    ('legacy', Note(id: 'note', title: 'Original', folderId: 'saved-folder')),
    (
      'existing',
      Note(
          id: 'note',
          title: 'Original',
          folderId: 'saved-folder',
          dateTime: DateTime(2020, 1, 2, 13, 45)),
    ),
    (
      'renamed daily note',
      Note(
          id: 'note',
          title: 'A renamed daily note',
          folderId: 'saved-folder',
          dateTime: DateTime(2020, 1, 2, 13, 45),
          dailyNoteDateKey: '2024-02-29'),
    ),
  ]) {
    testWidgets(
        '$name editor retains initial metadata and reports a real unsaved draft edit',
        (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.reset);
      final notes = _Notes();
      final folders = _Folders()
        ..values.addAll([
          FolderDto(id: 'saved-folder', name: 'Saved folder'),
          FolderDto(id: 'new-folder', name: 'New draft folder'),
        ]);
      locator.registerSingleton<FolderRepository>(folders);
      addTearDown(() => locator.unregister<FolderRepository>());
      final store = _FailingStore();
      final bloc =
          AddUpdateBloc(AddNoteUsecase(notes), UpdateNoteUsecase(notes));
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        await bloc.close();
      });
      await tester.pumpWidget(_app(BlocProvider.value(
        value: bloc,
        child: AddUpdateNoteScreen(
          note: existing,
          folderId: 'new-folder',
          autosaveStore: store,
          positionStore: NotePositionStore.memory(),
        ),
      )));
      await tester.pumpAndSettle();

      final initial = await _editorInfo(tester);
      expect(initial.modifiedAt, existing?.dateTime);
      expect(initial.dailyNoteDateKey, existing?.dailyNoteDateKey);
      final dailyDate =
          find.byKey(const ValueKey('note-info-daily-note-date-value'));
      if (existing?.dailyNoteDateKey == null) {
        expect(dailyDate, findsNothing);
      } else {
        expect(tester.widget<Text>(dailyDate).data, 'Feb 29, 2024');
      }
      expect(initial.folderName,
          existing == null ? 'New draft folder' : 'Saved folder');
      expect(store.drafts, isEmpty);
      expect(store.saveAttempts, 0);
      if (existing?.dateTime == null) {
        expect(find.byKey(const ValueKey('note-info-last-modified-value')),
            findsNothing);
      }
      await _closeInfo(tester);
      final folderId = existing?.folderId ?? 'new-folder';
      folders.values[existing == null ? 1 : 0] =
          FolderDto(id: folderId, name: 'Renamed folder');

      await tester.enterText(find.byKey(const ValueKey('note-title-input')),
          'Actual draft change');
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(store.drafts, isNotEmpty);
      expect(store.saveAttempts, 1);
      final draft = store.drafts.last;
      final edited = await _editorInfo(tester);
      expect(edited.modifiedAt, draft.dateTime);
      expect(draft.dailyNoteDateKey, existing?.dailyNoteDateKey);
      expect(edited.dailyNoteDateKey, existing?.dailyNoteDateKey);
      if (existing?.dailyNoteDateKey != null) {
        expect(tester.widget<Text>(dailyDate).data, 'Feb 29, 2024');
      } else {
        expect(dailyDate, findsNothing);
      }
      expect(edited.folderName, 'Renamed folder');
      expect(edited.modifiedAt, isNotNull);
      expect(edited.modifiedAt, isNot(existing?.dateTime));
      expect(edited.statistics.wordCount, 3);
      expect(
          tester
              .widget<Text>(
                  find.byKey(const ValueKey('note-info-last-modified-value')))
              .data,
          noteReaderDateTimeLabel(
              dateTime: draft.dateTime, locale: 'en', use24HourFormat: false));
      expect(store.saveAttempts, 1);
      expect(notes.writes, 0);
      await _closeInfo(tester);
      folders.values.clear();
      final missingFolder = await _editorInfo(tester);
      expect(missingFolder.folderName, isNull);
      expect(
          find.byKey(const ValueKey('note-info-folder-value')), findsNothing);
      await _closeInfo(tester);
      folders.fail = true;
      final unavailableFolder = await _editorInfo(tester);
      expect(unavailableFolder.folderName, isNull);
      expect(store.saveAttempts, 1);
      expect(notes.writes, 0);
      expect(folders.writes, 0);
      expect(tester.takeException(), isNull);
    });
  }

  for (final custom in [false, true]) {
    testWidgets(
        '${custom ? 'custom' : 'starter'} template editor has no inferred daily association',
        (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.reset);
      final notes = _Notes();
      locator.registerSingleton<NoteRepository>(notes);
      addTearDown(() => locator.unregister<NoteRepository>());
      final store = _FailingStore();
      final bloc =
          AddUpdateBloc(AddNoteUsecase(notes), UpdateNoteUsecase(notes));
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        await bloc.close();
      });
      await tester.pumpWidget(_app(BlocProvider.value(
        value: bloc,
        child: AddUpdateNoteScreen(
          template: custom ? null : NoteTemplate.dailyPlan,
          customTemplateNote: custom
              ? Note(
                  id: 'template-seed',
                  title: 'February 29, 2024',
                  dateTime: DateTime(2024, 2, 29))
              : null,
          autosaveStore: store,
          positionStore: NotePositionStore.memory(),
        ),
      )));
      await tester.pumpAndSettle();
      // Selected template content already has its own initial autosave.
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      final draftCount = store.drafts.length;
      final saveAttempts = store.saveAttempts;
      final info = await _editorInfo(tester);
      expect(info.dailyNoteDateKey, isNull);
      expect(find.byKey(const ValueKey('note-info-daily-note-date-value')),
          findsNothing);
      expect(store.drafts.length, draftCount);
      expect(store.saveAttempts, saveAttempts);
      expect(notes.writes, 0);
      expect(tester.takeException(), isNull);
    });
  }

  for (final (library, trashed, archived) in [
    ('active', false, false),
    ('archived', false, true),
    ('Trash', true, false),
  ]) {
    testWidgets(
        '$library reader passes current folder and modification metadata without saving',
        (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.reset);
      final modified = DateTime(2020, 1, 2, 13, 45);
      final deleted = trashed ? DateTime(2026, 10, 11, 14, 30) : null;
      final note = Note(
        id: 'note',
        title: 'Saved note',
        dateTime: modified,
        deletedAt: deleted,
        isArchived: archived,
        folderId: 'reader-folder',
        dailyNoteDateKey: '2024-02-29',
      );
      final notes = _Notes()..values['note'] = NoteDto.fromNote(note);
      final folders = _Folders()
        ..values.add(FolderDto(id: 'reader-folder', name: 'Reader folder'));
      locator.registerSingleton<FolderRepository>(folders);
      addTearDown(() => locator.unregister<FolderRepository>());
      final detail =
          NoteDetailBloc(GetNoteUsecase(notes), UpdateNoteUsecase(notes));
      final router = _ReaderRouter();
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        router.dispose();
        await detail.close();
      });
      await tester.pumpWidget(BlocProvider.value(
        value: detail,
        child: MaterialApp.router(
          theme: AppTheme.light,
          routerConfig: router.config(),
          locale: const Locale('en'),
          supportedLocales: S.delegate.supportedLocales,
          localizationsDelegates: const [
            S.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
        ),
      ));
      await tester.pumpAndSettle();
      final sheet = await _readerInfo(tester, trashed: trashed);
      expect(sheet.modifiedAt, modified);
      expect(sheet.deletedAt, deleted);
      expect(sheet.folderName, 'Reader folder');
      expect(sheet.dailyNoteDateKey, '2024-02-29');
      expect(
          tester
              .widget<Text>(
                  find.byKey(const ValueKey('note-info-daily-note-date-value')))
              .data,
          'Feb 29, 2024');
      expect(
          tester
              .widget<Text>(
                  find.byKey(const ValueKey('note-info-last-modified-value')))
              .data,
          noteReaderDateTimeLabel(
              dateTime: modified, locale: 'en', use24HourFormat: false));
      expect(notes.writes, 0);
      expect(notes.values['note']!.toDomain(), note);
      await _closeInfo(tester);
      folders.values[0] =
          FolderDto(id: 'reader-folder', name: 'Renamed reader folder');
      expect((await _readerInfo(tester, trashed: trashed)).folderName,
          'Renamed reader folder');
      await _closeInfo(tester);
      folders.values.clear();
      expect((await _readerInfo(tester, trashed: trashed)).folderName, isNull);
      expect(
          find.byKey(const ValueKey('note-info-folder-value')), findsNothing);
      await _closeInfo(tester);
      folders.fail = true;
      expect((await _readerInfo(tester, trashed: trashed)).folderName, isNull);
      expect(notes.writes, 0);
      expect(notes.values['note']!.toDomain(), note);
      expect(folders.writes, 0);
      expect(tester.takeException(), isNull);
    });
  }
}
