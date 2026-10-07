import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/Tools/locator.dart';
import 'package:onlynote/data/dto/folder_dto.dart';
import 'package:onlynote/data/dto/note_dto.dart';
import 'package:onlynote/domain/repository/folder_repository.dart';
import 'package:onlynote/domain/repository/note_repository.dart';
import 'package:onlynote/domain/usecase/usecase.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/screens/home/bloc/home_bloc.dart';
import 'package:onlynote/services/premium_access.dart';

import '../support/premium_test_fakes.dart';

class _Folders implements FolderRepository {
  final folders = <String, FolderDto>{};
  Completer<void>? gate;
  bool fail = false;
  int writes = 0;

  @override
  Future<void> addUpdateFolder(FolderDto folder) async {
    writes++;
    await gate?.future;
    if (fail) throw StateError('Storage unavailable');
    folders[folder.id!] = folder;
  }

  @override
  List<FolderDto> getAllFolders() => folders.values.toList();

  @override
  Future<void> deleteFolder(String id) async => folders.remove(id);
}

class _Notes implements NoteRepository {
  @override
  List<NoteDto> getAllNotes() => [];
  @override
  Future<NoteDto> getNote(String id) async => throw StateError('No note');
  @override
  Future<void> addUpdateNote(NoteDto note) async {}
  @override
  Future<void> deleteNote(String id) async {}
  @override
  Future<void> deleteMultiNotes(List<String> ids) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() {
    if (!locator.isRegistered<S>()) locator.registerSingleton(S());
  });
  late PremiumTestFixture entitlement;
  late _Folders folders;
  late _Notes notes;
  late HomeBloc bloc;

  Future<void> createBloc({bool premium = false}) async {
    entitlement = PremiumTestFixture(premium: premium);
    await entitlement.init();
    folders = _Folders();
    notes = _Notes();
    bloc = HomeBloc(
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
      premiumAccess: entitlement.access,
    );
  }

  tearDown(() async {
    await bloc.close();
    await entitlement.dispose();
  });

  void importFolders(int count) {
    for (var i = 0; i < count; i++) {
      folders.folders['import-$i'] =
          FolderDto(id: 'import-$i', name: 'Imported $i');
    }
  }

  test(
      'free users can create three folders, fourth opens a typed upgrade result',
      () async {
    await createBloc();
    for (var i = 0; i < PremiumAccess.freeFolderLimit; i++) {
      expect(await bloc.createFolder('Folder $i'), isNull);
    }
    await expectLater(
        bloc.createFolder('Fourth'),
        throwsA(isA<PremiumRequired>().having(
            (error) => error.feature, 'feature', PremiumFeature.folders)));
    expect(folders.folders, hasLength(3));
    expect(folders.writes, 3);
  });

  test('queued rapid folder creation uses the last saved count', () async {
    await createBloc();
    importFolders(2);
    folders.gate = Completer<void>();
    final first = bloc
        .createFolder('Third')
        .then<Object?>((error) => error, onError: (Object error) => error);
    final second = bloc
        .createFolder('Fourth')
        .then<Object?>((error) => error, onError: (Object error) => error);
    await pumpEventQueue();
    expect(folders.writes, 1);
    expect(folders.folders, hasLength(2));
    folders.gate!.complete();
    expect(await first, isNull);
    expect(await second, isA<PremiumRequired>());
    expect(folders.folders, hasLength(3));
    expect(folders.writes, 1);
  });

  test('Premium can create folders beyond the free limit', () async {
    await createBloc(premium: true);
    for (var i = 0; i < 8; i++) {
      expect(await bloc.createFolder('Folder $i'), isNull);
    }
    expect(folders.folders, hasLength(8));
  });

  test('existing imported folders remain readable, renameable and removable',
      () async {
    await createBloc();
    bloc.add(const HomeEvent.getAllNotes());
    await pumpEventQueue();
    // These arrive after Home loaded. Its cached empty list is not authoritative.
    importFolders(5);
    await expectLater(
        bloc.createFolder('New'), throwsA(isA<PremiumRequired>()));
    expect(folders.folders, hasLength(5));
    expect(
        (await RenameFolderUsecase(folders)(id: 'import-0', name: 'Renamed'))
            .isRight(),
        isTrue);
    expect(folders.folders['import-0']!.name, 'Renamed');
    expect((await DeleteFolderUsecase(folders, notes)('import-4')).isRight(),
        isTrue);
    expect(folders.folders, hasLength(4));
    expect(folders.folders.keys,
        containsAll(['import-0', 'import-1', 'import-2', 'import-3']));
  });

  test('a failed folder write leaves capacity available for a retry', () async {
    await createBloc();
    importFolders(2);
    folders.fail = true;
    expect(
        await bloc.createFolder('Third'), locator<S>().Failed_to_save_folder);
    expect(folders.folders, hasLength(2));
    folders.fail = false;
    expect(await bloc.createFolder('Third'), isNull);
    expect(folders.folders, hasLength(3));
  });
}
