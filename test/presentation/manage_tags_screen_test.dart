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
import 'package:onlynote/domain/usecase/usecase.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/folder_name_dialog.dart';
import 'package:onlynote/presentation/screens/home/bloc/home_bloc.dart';
import 'package:onlynote/presentation/screens/settings/manage_tags_screen.dart';
import 'package:onlynote/presentation/theme/theme.dart';
import 'package:onlynote/services/custom_note_template_store.dart';
import 'package:onlynote/services/note_tag_editor.dart';
import 'package:onlynote/services/saved_note_views.dart';

import '../support/memory_preferences.dart';
import '../support/template_images.dart';

/// Stores notes in memory and reports every write, so the screen rebuilds
/// without the real file writes that widget-test frames cannot advance.
class _Notes extends ChangeNotifier implements NoteRepository {
  final saved = <String, NoteDto>{};

  void seed(Map<String, NoteDto> notes) {
    saved
      ..clear()
      ..addAll(notes);
  }

  @override
  List<NoteDto> getAllNotes() => saved.values.toList();
  @override
  Future<NoteDto> getNote(String id) async {
    final note = saved[id];
    if (note == null) throw StateError('missing note');
    return note;
  }

  @override
  Future<void> addUpdateNote(NoteDto note) async {
    saved[note.id!] = note;
    notifyListeners();
  }

  @override
  Future<void> deleteNote(String id) async {
    saved.remove(id);
    notifyListeners();
  }

  @override
  Future<void> deleteMultiNotes(List<String> ids) async {
    for (final id in ids) {
      saved.remove(id);
    }
    notifyListeners();
  }
}

class _Folders implements FolderRepository {
  @override
  List<FolderDto> getAllFolders() => <FolderDto>[];
  @override
  Future<void> addUpdateFolder(FolderDto folder) async {}
  @override
  Future<void> deleteFolder(String id) async {}
}

Finder _key(String key) => find.byKey(ValueKey(key));

/// Lets a transient message finish so its dismissal timer is not still
/// pending when the test ends.
Future<void> _drainMessages(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 3));
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, Finder target) async {
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

void main() {
  final fonts = Map<String, GoogleFontBuilder>.of(kAppFontFamilies);
  late _Notes notes;
  HomeBloc? openHome;
  SavedNoteViewStore? openViews;
  CustomNoteTemplateStore? openTemplates;

  setUpAll(() async {
    await initializeDateFormatting();
    if (!locator.isRegistered<S>()) locator.registerSingleton(S());
  });

  setUp(() async {
    for (final family in fonts.keys) {
      kAppFontFamilies[family] = (
              {textStyle, color, fontSize, fontWeight, fontStyle}) =>
          (textStyle ?? const TextStyle()).copyWith(
              color: color,
              fontSize: fontSize,
              fontWeight: fontWeight,
              fontStyle: fontStyle);
    }
    notes = _Notes();
    notes.seed({
      'first': NoteDto.fromNote(Note(
          id: 'first', title: 'Release plan', tags: ['Work', 'Research'])),
      'second': NoteDto.fromNote(
          Note(id: 'second', title: 'Standup', tags: ['work'])),
      'archived': NoteDto.fromNote(Note(
          id: 'archived',
          title: 'Last release',
          isArchived: true,
          tags: ['Research'])),
      // Trash keeps its own catalog in the library, so it is not listed.
      'trashed': NoteDto.fromNote(Note(
          id: 'trashed',
          title: 'Dropped',
          tags: ['Dropped'],
          deletedAt: DateTime.utc(2026, 10, 6))),
    });
  });

  tearDown(() async {
    kAppFontFamilies.addAll(fonts);
    await openHome?.close();
    openHome = null;
    openViews?.dispose();
    openViews = null;
    openTemplates?.dispose();
    openTemplates = null;
    notes.dispose();
  });

  /// Everything with an internal future queue is built inside the test body.
  /// A bloc or store created in setUp lives outside the widget test's clock,
  /// so its queued work never runs and the screen waits on it forever.
  HomeBloc home() => openHome!;

  Future<void> pump(WidgetTester tester) async {
    openViews = SavedNoteViewStore(preferences: MemoryPreferences());
    openTemplates = CustomNoteTemplateStore(
        preferences: MemoryPreferences(), images: MemoryTemplateImages());
    final folders = _Folders();
    openHome = HomeBloc(
      ShowAllNotesUsecase(notes, folders),
      AddNoteUsecase(notes),
      ReorderNotesUsecase(notes),
      TogglePinUsecase(notes),
      RestoreNotesUsecase(notes),
      PermanentDeleteNotesUsecase(notes),
      CreateFolderUsecase(folders),
      RenameFolderUsecase(folders),
      DeleteFolderUsecase(folders, notes),
      MoveNoteToFolderUsecase(notes),
      GetNoteUsecase(notes),
      UpdateNoteUsecase(notes),
    );
    await tester.pumpWidget(BlocProvider<HomeBloc>.value(
      value: home(),
      child: MaterialApp(
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: S.delegate.supportedLocales,
        theme: AppTheme.light,
        home: ManageTagsScreen(
          editor: NoteTagEditor(
              notes: notes, views: openViews!, templates: openTemplates!),
          notes: notes.getAllNotes,
          revisions: notes,
        ),
      ),
    ));
    home().add(const HomeEvent.getAllNotes());
    await tester.pumpAndSettle();
    expect(home().state.mapOrNull(loaded: (state) => true), isTrue);
    expect(tester.takeException(), isNull);
  }

  List<String> storedTags(String id) => notes.saved[id]!.tags ?? const [];

  testWidgets('lists active and archived tags with their note counts',
      (tester) async {
    await pump(tester);

    expect(_key('managed-tag-work'), findsOneWidget);
    expect(_key('managed-tag-research'), findsOneWidget);
    // Trash has its own catalog in the library, so it is not listed here.
    expect(_key('managed-tag-dropped'), findsNothing);
    expect(_key('managed-tags-hint'), findsOneWidget);

    // The repeated 'work' spelling must count its note once, not twice.
    expect(
        find.descendant(
            of: _key('managed-tag-work'), matching: find.text('2 notes')),
        findsOneWidget);
    expect(
        find.descendant(
            of: _key('managed-tag-research'), matching: find.text('2 notes')),
        findsOneWidget);

    await _drainMessages(tester);
  });

  testWidgets('search narrows the list and reports an empty result',
      (tester) async {
    await pump(tester);

    await tester.enterText(_key('managed-tags-search'), 'rese');
    await tester.pumpAndSettle();
    expect(_key('managed-tag-research'), findsOneWidget);
    expect(_key('managed-tag-work'), findsNothing);

    await tester.enterText(_key('managed-tags-search'), 'nothing matches');
    await tester.pumpAndSettle();
    expect(_key('managed-tags-search-empty'), findsOneWidget);

    await _tap(tester, _key('managed-tags-clear-search'));
    expect(_key('managed-tag-work'), findsOneWidget);

    await _drainMessages(tester);
  });

  testWidgets('renaming a tag rewrites every note that carries it',
      (tester) async {
    await pump(tester);

    await _tap(tester, _key('managed-tag-work-menu'));
    await _tap(tester, find.text('Rename tag').last);
    expect(find.byType(FolderNameDialog), findsOneWidget);
    await tester.enterText(find.byType(TextField).last, 'Job');
    await _tap(tester, find.text('OK'));

    expect(storedTags('first'), ['Job', 'Research']);
    expect(storedTags('second'), ['Job']);
    expect(_key('managed-tag-job'), findsOneWidget);
    expect(_key('managed-tag-work'), findsNothing);

    await _drainMessages(tester);
  });

  testWidgets('renaming onto an existing tag asks before merging',
      (tester) async {
    await pump(tester);

    await _tap(tester, _key('managed-tag-work-menu'));
    await _tap(tester, find.text('Rename tag').last);
    await tester.enterText(find.byType(TextField).last, 'research');
    await _tap(tester, find.text('OK'));

    expect(find.text('Merge tags'), findsOneWidget);
    // Cancelling the merge must leave both tags exactly as they were.
    await _tap(tester, find.text('Cancel'));
    expect(storedTags('first'), ['Work', 'Research']);

    await _tap(tester, _key('managed-tag-work-menu'));
    await _tap(tester, find.text('Rename tag').last);
    await tester.enterText(find.byType(TextField).last, 'research');
    await _tap(tester, find.text('OK'));
    await _tap(tester, find.text('Merge'));

    expect(storedTags('first'), ['research']);
    expect(storedTags('second'), ['research']);

    await _drainMessages(tester);
  });

  testWidgets('an over-long name is refused and changes nothing',
      (tester) async {
    await pump(tester);

    await _tap(tester, _key('managed-tag-work-menu'));
    await _tap(tester, find.text('Rename tag').last);
    await tester.enterText(find.byType(TextField).last, 'a' * 41);
    await _tap(tester, find.text('OK'));

    expect(storedTags('first'), ['Work', 'Research']);
    expect(_key('managed-tag-work'), findsOneWidget);

    await _drainMessages(tester);
  });

  testWidgets('removing a tag clears it from notes but keeps their content',
      (tester) async {
    await pump(tester);

    await _tap(tester, _key('managed-tag-work-menu'));
    await _tap(tester, find.text('Remove tag').last);
    expect(find.textContaining('No note content is deleted.'), findsOneWidget);
    await _tap(tester, find.text('Remove tag').last);

    expect(storedTags('first'), ['Research']);
    expect(storedTags('second'), isEmpty);
    expect(notes.saved['second']!.title, 'Standup');
    expect(_key('managed-tag-work'), findsNothing);

    await _drainMessages(tester);
  });

  testWidgets('cancelling a removal keeps the tag', (tester) async {
    await pump(tester);

    await _tap(tester, _key('managed-tag-work-menu'));
    await _tap(tester, find.text('Remove tag').last);
    await _tap(tester, find.text('Cancel'));

    expect(storedTags('first'), ['Work', 'Research']);
    expect(_key('managed-tag-work'), findsOneWidget);

    await _drainMessages(tester);
  });

  testWidgets('a library tag filter follows the rename', (tester) async {
    await pump(tester);
    home().add(const HomeEvent.tagsChanged({'Work'}));
    await tester.pumpAndSettle();
    expect(home().state.mapOrNull(loaded: (state) => state.notes.length), 2);

    await _tap(tester, _key('managed-tag-work-menu'));
    await _tap(tester, find.text('Rename tag').last);
    await tester.enterText(find.byType(TextField).last, 'Job');
    await _tap(tester, find.text('OK'));
    await _drainMessages(tester);

    // The filter follows the new name instead of emptying the library.
    expect(home().state.mapOrNull(loaded: (state) => state.selectedTags),
        {'Job'});
    expect(home().state.mapOrNull(loaded: (state) => state.notes.length), 2);
  });

  testWidgets('removing a filtered tag clears it from the library filter',
      (tester) async {
    await pump(tester);
    home().add(const HomeEvent.tagsChanged({'Work', 'Research'}));
    await tester.pumpAndSettle();

    await _tap(tester, _key('managed-tag-work-menu'));
    await _tap(tester, find.text('Remove tag').last);
    await _tap(tester, find.text('Remove tag').last);
    await _drainMessages(tester);

    expect(home().state.mapOrNull(loaded: (state) => state.selectedTags),
        {'Research'});
  });

  testWidgets('a filter on another tag is left alone', (tester) async {
    await pump(tester);
    home().add(const HomeEvent.tagsChanged({'Research'}));
    await tester.pumpAndSettle();

    await _tap(tester, _key('managed-tag-work-menu'));
    await _tap(tester, find.text('Rename tag').last);
    await tester.enterText(find.byType(TextField).last, 'Job');
    await _tap(tester, find.text('OK'));
    await _drainMessages(tester);

    expect(home().state.mapOrNull(loaded: (state) => state.selectedTags),
        {'Research'});
  });

  testWidgets('an empty library explains itself instead of listing nothing',
      (tester) async {
    notes.seed(const {});
    await pump(tester);

    expect(_key('managed-tags-empty'), findsOneWidget);
    expect(_key('managed-tags-search'), findsNothing);

    await _drainMessages(tester);
  });
}
