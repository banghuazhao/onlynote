import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:onlynote/Tools/locator.dart';
import 'package:onlynote/data/dto/folder_dto.dart';
import 'package:onlynote/data/dto/note_dto.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/domain/repository/folder_repository.dart';
import 'package:onlynote/domain/repository/note_repository.dart';
import 'package:onlynote/domain/usecase/usecase.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/note_link_picker_sheet.dart';
import 'package:onlynote/presentation/screens/home/bloc/home_bloc.dart';
import 'package:onlynote/services/note_search.dart';
import 'package:onlynote/services/photo_search_index.dart';
import 'package:onlynote/services/photo_text_result.dart';

class _Notes implements NoteRepository {
  _Notes(this.box);
  final Box box;
  int writes = 0;

  @override
  List<NoteDto> getAllNotes() => box.values.cast<NoteDto>().toList();
  @override
  Future<NoteDto> getNote(String id) async => box.get(id) as NoteDto;
  @override
  Future<void> addUpdateNote(NoteDto note) async {
    writes++;
    await box.put(note.id, note);
  }

  @override
  Future<void> deleteNote(String id) => box.delete(id);
  @override
  Future<void> deleteMultiNotes(List<String> ids) => box.deleteAll(ids);
}

class _Folders implements FolderRepository {
  @override
  List<FolderDto> getAllFolders() => [
        FolderDto(id: 'work', name: 'Work'),
        FolderDto(id: 'personal', name: 'Personal'),
      ];
  @override
  Future<void> addUpdateFolder(FolderDto folder) async {}
  @override
  Future<void> deleteFolder(String id) async {}
}

List<Note> _visible(HomeBloc bloc) => bloc.state.maybeMap(
    loaded: (state) => state.notes,
    orElse: () => throw StateError('Home has not loaded'));

/// Advance bounded event-loop turns; each awaited OCR result is controlled by
/// its test rather than a platform plugin or a wall-clock delay.
Future<void> _until(bool Function() condition) async {
  for (var turn = 0; turn < 80 && !condition(); turn++) {
    await Future<void>.delayed(Duration.zero);
  }
  expect(condition(), isTrue, reason: 'Expected asynchronous change to finish');
}

void main() {
  late Directory directory;
  late Box noteBox;
  late Box cacheBox;
  late _Notes notes;
  PhotoSearchIndex? index;
  HomeBloc? home;

  setUpAll(() async {
    if (!locator.isRegistered<S>()) locator.registerSingleton(S());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(NoteDtoAdapter());
    directory = await Directory.systemTemp.createTemp('onlynote-photo-home-');
    Hive.init(directory.path);
    noteBox = await Hive.openBox('photo-home-notes');
    cacheBox = await Hive.openBox('photo-home-cache');
  });

  setUp(() async {
    await noteBox.clear();
    await cacheBox.clear();
    notes = _Notes(noteBox);
    index = null;
    home = null;
  });

  tearDown(() async {
    await home?.close();
    index?.dispose();
    await noteBox.flush();
    await cacheBox.flush();
  });

  tearDownAll(() async {
    await noteBox.close();
    await cacheBox.close();
    await directory.delete(recursive: true);
  });

  Future<HomeBloc> openHome({
    required List<Note> initial,
    required Future<PhotoTextResult> Function(String) recognize,
  }) async {
    await noteBox.putAll({
      for (final note in initial) note.id!: NoteDto.fromNote(note),
    });
    index = PhotoSearchIndex(
        notes: noteBox,
        cache: cacheBox,
        recognize: recognize,
        exists: (_) async => true);
    PhotoSearchIndex.configure(index!);
    await index!.start();
    final folders = _Folders();
    final bloc = HomeBloc(
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
    home = bloc;
    bloc.add(const HomeEvent.getAllNotes());
    await _until(() => bloc.state.mapOrNull(loaded: (_) => true) == true);
    return bloc;
  }

  Future<void> send(HomeBloc bloc, HomeEvent event) async {
    bloc.add(event);
    await Future<void>.delayed(Duration.zero);
  }

  test(
      'pending photo recognition refreshes an active query without note writes',
      () async {
    final pending = Completer<PhotoTextResult>();
    final requests = <String>[];
    final original = Note(
      id: 'receipt',
      title: 'Weekend shopping',
      description: 'Keep for expenses',
      dateTime: DateTime(2026, 10, 6, 9),
      dailyNoteDateKey: '2026-10-06',
      tags: ['Personal'],
      imagePaths: ['note_images/receipt.jpg'],
    );
    final bloc = await openHome(
        initial: [original],
        recognize: (path) {
          requests.add(path);
          return pending.future;
        });
    final before = (noteBox.get('receipt') as NoteDto).toDomain();
    var sourceChanges = 0;
    final subscription = noteBox.watch().listen((_) => sourceChanges++);
    addTearDown(subscription.cancel);
    await send(bloc, const HomeEvent.searchChanged('coffee'));
    expect(_visible(bloc), isEmpty);
    await _until(() => requests.isNotEmpty);

    pending.complete(const PhotoTextResult(PhotoTextStatus.text,
        text: 'Corner shop\nCoffee beans 12.00'));
    await _until(() => _visible(bloc).isNotEmpty);

    expect(_visible(bloc).single.id, 'receipt');
    expect(requests, ['note_images/receipt.jpg']);
    expect((noteBox.get('receipt') as NoteDto).toDomain(), before);
    expect(_visible(bloc).single.dateTime, original.dateTime);
    expect(notes.writes, 0);
    expect(sourceChanges, 0);
    expect(
        bloc.state.mapOrNull(loaded: (state) => state.searchQuery), 'coffee');
  });

  test('photo completion preserves folder tags filters and archive scopes',
      () async {
    final pending = Completer<PhotoTextResult>();
    final bloc = await openHome(initial: [
      Note(
          id: 'active',
          title: 'Current receipt',
          folderId: 'work',
          tags: ['Work'],
          imagePaths: ['note_images/shared.jpg']),
      Note(
          id: 'archive',
          title: 'Past receipt',
          folderId: 'work',
          tags: ['Work'],
          isArchived: true,
          imagePaths: ['note_images/shared.jpg']),
      Note(
          id: 'wrong-folder',
          title: 'Other folder',
          folderId: 'personal',
          tags: ['Work'],
          imagePaths: ['note_images/shared.jpg']),
      Note(
          id: 'wrong-tag',
          title: 'Other tag',
          folderId: 'work',
          tags: ['Personal'],
          imagePaths: ['note_images/shared.jpg']),
      Note(
          id: 'no-photo',
          title: 'Invoice text',
          folderId: 'work',
          tags: ['Work']),
      Note(
          id: 'trash',
          title: 'Deleted receipt',
          folderId: 'work',
          tags: ['Work'],
          deletedAt: DateTime(2026, 10, 6),
          imagePaths: ['note_images/shared.jpg']),
    ], recognize: (_) => pending.future);
    await send(bloc, const HomeEvent.selectFolder('work'));
    await send(bloc, const HomeEvent.tagsChanged({'work'}));
    await send(bloc, const HomeEvent.filtersChanged({NoteSearchFilter.photos}));
    await send(bloc, const HomeEvent.searchChanged('invoice'));
    expect(_visible(bloc), isEmpty);

    pending.complete(
        const PhotoTextResult(PhotoTextStatus.text, text: 'Invoice number 42'));
    await _until(() => _visible(bloc).isNotEmpty);

    expect(_visible(bloc).map((note) => note.id), ['active']);
    bloc.state.mapOrNull(loaded: (state) {
      expect(state.selectedFolderId, 'work');
      expect(state.selectedTags, {'work'});
      expect(state.filters, {NoteSearchFilter.photos});
      expect(state.searchQuery, 'invoice');
      expect(state.includeArchived, isFalse);
      expect(state.showArchive, isFalse);
    });
    await send(bloc, const HomeEvent.includeArchived(true));
    expect(
        _visible(bloc).map((note) => note.id).toSet(), {'active', 'archive'});
    await send(bloc, const HomeEvent.showArchive(true));
    expect(_visible(bloc).single.id, 'archive');
    expect(bloc.state.mapOrNull(loaded: (state) => state.showArchive), isTrue);
    expect(notes.writes, 0);
  });

  test('replacing or removing a photo removes its cached search match',
      () async {
    final replacement = Completer<PhotoTextResult>();
    final requests = <String>[];
    final bloc = await openHome(
        initial: [
          Note(
              id: 'photo',
              title: 'Pictures',
              imagePaths: ['note_images/old.jpg']),
        ],
        recognize: (path) {
          requests.add(path);
          return path == 'note_images/old.jpg'
              ? Future.value(const PhotoTextResult(PhotoTextStatus.text,
                  text: 'Blue mountain cabin'))
              : replacement.future;
        });
    await send(bloc, const HomeEvent.searchChanged('mountain'));
    await _until(() => _visible(bloc).isNotEmpty);

    final original = noteBox.get('photo') as NoteDto;
    await noteBox.put(
        'photo', original.copyWith(imagePaths: ['note_images/new.jpg']));
    await _until(() => requests.contains('note_images/new.jpg'));
    await _until(() => _visible(bloc).isEmpty);
    replacement.complete(const PhotoTextResult(PhotoTextStatus.text,
        text: 'Yellow beach umbrella'));
    await _until(() => index!
        .textsForNote((noteBox.get('photo') as NoteDto).toDomain())
        .isNotEmpty);
    expect(_visible(bloc), isEmpty);
    await send(bloc, const HomeEvent.searchChanged('umbrella'));
    expect(_visible(bloc).single.id, 'photo');

    await noteBox.put('photo', original.copyWith(imagePaths: []));
    await _until(() => _visible(bloc).isEmpty);
    expect(index!.textsForNote((noteBox.get('photo') as NoteDto).toDomain()),
        isEmpty);
    await _until(() => cacheBox.isEmpty);
    expect(notes.writes, 0);
  });

  test('a photo removed during recognition cannot reappear in Home search',
      () async {
    final pending = Completer<PhotoTextResult>();
    var requested = false;
    final bloc = await openHome(
        initial: [
          Note(
              id: 'photo',
              title: 'Pictures',
              imagePaths: ['note_images/old.jpg']),
        ],
        recognize: (_) {
          requested = true;
          return pending.future;
        });
    await send(bloc, const HomeEvent.searchChanged('mountain'));
    await _until(() => requested);
    final original = noteBox.get('photo') as NoteDto;
    await noteBox.put('photo', original.copyWith(imagePaths: []));
    await Future<void>.delayed(Duration.zero);
    pending.complete(const PhotoTextResult(PhotoTextStatus.text,
        text: 'Blue mountain cabin'));
    await _until(() => !index!.isIndexing);
    await Future<void>.delayed(Duration.zero);
    expect(_visible(bloc), isEmpty);
    expect(cacheBox.isEmpty, isTrue);
    expect(index!.textsForNote(original.toDomain()), isEmpty);
    expect(notes.writes, 0);
  });

  testWidgets('link picker updates its active search when photo text arrives',
      (tester) async {
    late Completer<PhotoTextResult> pending;
    var requested = false;
    final note = Note(
        id: 'archive',
        title: 'Archived receipt',
        isArchived: true,
        imagePaths: ['note_images/invoice.jpg']);
    await tester.runAsync(() async {
      pending = Completer<PhotoTextResult>();
      await noteBox.put(note.id, NoteDto.fromNote(note));
      index = PhotoSearchIndex(
          notes: noteBox,
          cache: cacheBox,
          recognize: (_) {
            requested = true;
            return pending.future;
          },
          exists: (_) async => true);
      PhotoSearchIndex.configure(index!);
      await index!.start();
      await _until(() => requested);
    });
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('en'),
      supportedLocales: S.delegate.supportedLocales,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(
        body: NoteLinkPickerSheet(
            currentNoteId: 'current', selectedIds: const [], notes: [note]),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const ValueKey('note-link-search')), 'invoice');
    await tester.pump();
    expect(find.text('Archived receipt'), findsNothing);

    await tester.runAsync(() async {
      pending.complete(const PhotoTextResult(PhotoTextStatus.text,
          text: 'Invoice number 42'));
      await _until(() => index!.textsForNote(note).isNotEmpty);
    });
    await tester.pump();
    expect(index!.textsForNote(note), ['Invoice number 42']);

    final tile = find.byKey(const ValueKey('choose-note-link-archive'));
    expect(tile, findsOneWidget);
    expect(find.text(S.current.Archive), findsOneWidget);
    await tester.tap(tile);
    await tester.pump();
    expect(tester.widget<CheckboxListTile>(tile).value, isTrue);
    expect(tester.takeException(), isNull);
    expect(notes.writes, 0);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
