import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/Tools/locator.dart';
import 'package:onlynote/data/dto/note_dto.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/domain/repository/note_repository.dart';
import 'package:onlynote/domain/usecase/permanent_delete_notes_usecase.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/services/note_archive.dart';
import 'package:onlynote/services/note_autosave.dart';
import 'package:onlynote/services/note_mutations.dart';
import 'package:onlynote/services/note_trash.dart';
import 'package:onlynote/services/shortcuts_append.dart';

enum _LibraryMutation { trash, permanentDelete, archive }

class _Notes extends Fake implements NoteRepository {
  final saved = <String, NoteDto>{
    'note': NoteDto(id: 'note', title: 'Journal', description: 'Original body'),
  };
  int reads = 0;
  Completer<void>? pauseNextCommit;
  Completer<void>? commitStarted;

  Future<void> _pause() async {
    final pause = pauseNextCommit;
    pauseNextCommit = null;
    if (pause != null) {
      commitStarted!.complete();
      await pause.future;
    }
  }

  @override
  List<NoteDto> getAllNotes() {
    reads++;
    return saved.values.toList();
  }

  @override
  Future<NoteDto> getNote(String id) async {
    reads++;
    return saved[id] ?? (throw StateError('Note unavailable'));
  }

  @override
  Future<void> addUpdateNote(NoteDto note) async {
    await _pause();
    saved[note.id!] = note;
  }

  @override
  Future<void> deleteMultiNotes(List<String> ids) async {
    await _pause();
    for (final id in ids) {
      saved.remove(id);
    }
  }
}

class _Store implements NoteAutosaveStore {
  _Store(this.notes);
  final _Notes notes;
  final drafts = <String, Note>{};
  @override
  Future<void> writeDraft(Note note) async => drafts[note.id!] = note;
  @override
  Future<void> removeDraft(String id) async => drafts.remove(id);
  @override
  Future<void> saveNote(Note note) =>
      notes.addUpdateNote(NoteDto.fromNote(note));
}

class _Journal implements ShortcutAppendJournal {
  final values = <String, Object>{};
  @override
  Iterable<String> get keys => values.keys;
  @override
  Object? read(String key) => values[key];
  @override
  Future<void> write(String key, Object value) async => values[key] = value;
  @override
  Future<void> remove(String key) async => values.remove(key);
}

Future<void> _mutate(_LibraryMutation mutation, _Notes notes) async {
  switch (mutation) {
    case _LibraryMutation.trash:
      await NoteTrash(notes,
          reminders: () => [],
          cancel: (_) async {},
          schedule: (_, __) async => true).setDeleted(['note'], deleted: true);
    case _LibraryMutation.permanentDelete:
      final result = await PermanentDeleteNotesUsecase(notes)(['note']);
      expect(result.isRight(), isTrue);
    case _LibraryMutation.archive:
      await setNoteArchived(notes, 'note', true);
  }
}

void main() {
  setUpAll(() {
    if (!locator.isRegistered<S>()) locator.registerSingleton(S());
  });

  for (final mutation in _LibraryMutation.values) {
    for (final appendFirst in [false, true]) {
      test(
          '${mutation.name} and Siri serialize when '
          '${appendFirst ? 'Siri' : mutation.name} starts first', () async {
        final notes = _Notes();
        final store = _Store(notes);
        final service = ShortcutsAppendService(
            repository: notes,
            store: store,
            journal: _Journal(),
            readDraft: (id) => store.drafts[id]);
        var acknowledgements = 0;
        Future<Object?> append() async {
          try {
            return await service.apply(
                const ShortcutAppendRequest(
                    id: '12345678-1234-1234-1234-000000000001',
                    text: 'Siri capture',
                    destination: ShortcutAppendDestination.note,
                    noteId: 'note',
                    createdAt: 1793221200000),
                acknowledge: (_) async => acknowledgements++,
                titleForDay: (_) => 'Today',
                inboxTitle: 'Inbox');
          } on ShortcutAppendException catch (error) {
            return error.failure;
          }
        }

        final release = Completer<void>();
        notes.pauseNextCommit = release;
        notes.commitStarted = Completer<void>();
        final first = appendFirst ? append() : _mutate(mutation, notes);
        await notes.commitStarted!.future;
        final readsBefore = notes.reads;
        final second = appendFirst ? _mutate(mutation, notes) : append();
        await Future<void>.delayed(Duration.zero);
        final readsWhileFirstCommits = notes.reads;
        release.complete();
        final results = await Future.wait([first, second]);
        expect(readsWhileFirstCommits, readsBefore);
        expect(acknowledgements, appendFirst ? 1 : 0);
        if (appendFirst) {
          expect(results.first, isA<Note>());
        } else {
          expect(results.last, ShortcutAppendFailure.unavailable);
        }
        final saved = notes.saved['note'];
        if (mutation == _LibraryMutation.permanentDelete) {
          expect(saved, isNull);
        } else {
          expect(saved, isNotNull);
          expect(saved!.isDeleted, mutation == _LibraryMutation.trash);
          expect(saved.isArchived, mutation == _LibraryMutation.archive);
          expect(saved.description,
              appendFirst ? 'Original body\n\nSiri capture' : 'Original body');
        }
        expect(store.drafts, isEmpty);
      });
    }
  }

  test('library mutations can nest in Home mutation transactions', () async {
    for (final mutation in _LibraryMutation.values) {
      await NoteMutations.run(() => _mutate(mutation, _Notes()));
    }
  });
}
