import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/services/note_position_store.dart';
// The preference plugin exposes its test platform in a separate package.
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  group('content anchors', () {
    test('relocates a caret after inserted and removed preceding text', () {
      const body =
          'Opening paragraph.\nKeep this caret here.\nClosing paragraph.';
      final offset = body.indexOf('caret');
      final anchor = NoteTextAnchor.capture(body, offset);
      final inserted = '${'New introductory paragraph.\n' * 20}$body';
      expect(anchor.resolve(inserted), inserted.indexOf('caret'));
      final removed = body.substring(body.indexOf('Keep'));
      expect(anchor.resolve(removed), removed.indexOf('caret'));
    });

    test('preserves the occurrence among repeated paragraphs', () {
      const paragraph = 'A repeated paragraph with a reading position.\n';
      final body = 'Intro\n${paragraph * 12}Ending';
      final offset = 'Intro\n'.length + paragraph.length * 7 + 14;
      final anchor = NoteTextAnchor.capture(body, offset);
      final prefix = 'A new introduction that is different.\n' * 8;
      expect(anchor.resolve('$prefix$body'), prefix.length + offset);
    });

    test('edited immediate text retains the surviving context boundary', () {
      final before = 'Distinct preceding paragraph before this caret.\n' * 4;
      const after = 'The following paragraph keeps its own recognizable text.';
      final anchor = NoteTextAnchor.capture('$before$after', before.length);
      final changed = '${'New text above.\n' * 30}${before}Edited: $after';
      expect(anchor.resolve(changed), changed.indexOf('Edited:'));
    });

    test('repeated following text stays beside its surviving preceding context',
        () {
      const before =
          'A unique preceding paragraph with enough recognizable content.\n';
      const paragraph = 'A repeated paragraph with a reading position.\n';
      final anchor =
          NoteTextAnchor.capture('$before${paragraph * 4}', before.length);
      final changed = '${paragraph * 8}${before}Edited: ${paragraph * 4}';
      expect(anchor.resolve(changed), changed.indexOf('Edited:') + 8);
    });

    test('deleted anchor text clamps safely when no context remains', () {
      final anchor = NoteTextAnchor.capture('A complete old paragraph', 15);
      expect(anchor.resolve(''), 0);
      expect(anchor.resolve('👩🏽‍💻'), '👩🏽‍💻'.length);
    });

    test('UTF-16 offsets never split emoji or combining characters', () {
      const text = 'A👩🏽‍💻e\u0301Z';
      final emojiEnd = 1 + '👩🏽‍💻'.length;
      for (var offset = 2; offset < emojiEnd; offset++) {
        expect(clampNotePositionOffset(text, offset), 1);
        expect(clampNotePositionOffset(text, offset, roundUp: true), emojiEnd);
        expect(NoteTextAnchor.capture(text, offset).resolve(text), 1);
      }
      expect(clampNotePositionOffset(text, emojiEnd + 1), emojiEnd);
      expect(clampNotePositionOffset(text, emojiEnd + 1, roundUp: true),
          emojiEnd + 2);
    });
  });

  group('writing snapshots', () {
    test('relocates a reverse selection and retains direction and affinity',
        () {
      const text = 'Before selected phrase after';
      final position = NoteWritingPosition.capture(
        field: NoteWritingField.body,
        text: text,
        selection: const TextSelection(
          baseOffset: 22,
          extentOffset: 7,
          affinity: TextAffinity.upstream,
          isDirectional: true,
        ),
      );
      final resolved = position.resolve(title: '', body: 'New\n$text');
      expect(resolved.field, NoteWritingField.body);
      expect(resolved.selection.baseOffset, 26);
      expect(resolved.selection.extentOffset, 11);
      expect(resolved.selection.affinity, TextAffinity.upstream);
      expect(resolved.selection.isDirectional, isTrue);
    });

    test('selection snaps both sides outwards around complete graphemes', () {
      const body = 'A👩🏽‍💻e\u0301Z';
      final position = NoteWritingPosition.capture(
        field: NoteWritingField.body,
        text: body,
        selection: const TextSelection(baseOffset: 2, extentOffset: 5),
      );
      final selection = position.resolve(title: '', body: body).selection;
      expect(selection.start, 1);
      expect(selection.end, 1 + '👩🏽‍💻'.length);
    });

    test(
        'todo identity survives reordering and a removed todo falls back to body',
        () {
      const body = 'A body caret remains here.';
      final position = NoteWritingPosition.capture(
        field: NoteWritingField.todo,
        todoId: 'saved-item',
        text: 'Buy groceries',
        selection: const TextSelection.collapsed(offset: 4),
        bodyText: body,
        bodySelection: const TextSelection.collapsed(offset: 7),
      );
      final reordered = position.resolve(
        title: 'Title',
        body: body,
        todos: {'other': 'Another', 'saved-item': 'Remember: Buy groceries'},
      );
      expect(reordered.field, NoteWritingField.todo);
      expect(reordered.todoId, 'saved-item');
      expect(reordered.selection.extentOffset, 14);
      final removed = position.resolve(title: 'Title', body: 'New\n$body');
      expect(removed.field, NoteWritingField.body);
      expect(removed.todoId, isNull);
      expect(removed.selection.extentOffset, 11);
    });

    test('invalid native selection gives a safe inactive caret', () {
      final position = NoteWritingPosition.capture(
        field: NoteWritingField.title,
        text: 'Title',
        selection: const TextSelection.collapsed(offset: -1),
      );
      expect(
          position.resolve(title: 'Title', body: '').selection.extentOffset, 0);
    });
  });

  group('local position storage', () {
    final writing = NoteWritingPosition.capture(
      field: NoteWritingField.body,
      text: 'Body text',
      selection: const TextSelection.collapsed(offset: 5),
    );
    final reading = NoteReadingPosition.capture(
      text: 'Body text',
      offset: 3,
      leadingDisplacement: -4.5,
      imagePath: 'photo',
      imageFraction: .25,
    );

    test('persists independent writer and reader state per note', () async {
      final storage = MemoryNotePositionStorage();
      final store = NotePositionStore(storage: storage);
      await Future.wait([
        store.saveWriting('first', writing),
        store.saveReading('first', reading),
        store.saveReading(
            'second', NoteReadingPosition.capture(text: 'Other', offset: 4)),
      ]);
      final reopened = NotePositionStore(storage: storage);
      final first = await reopened.read('first');
      expect(
          first.writing!
              .resolve(title: '', body: 'Body text')
              .selection
              .extentOffset,
          5);
      expect(first.reading!.resolve('Body text'), 3);
      expect(first.reading!.leadingDisplacement, -4.5);
      expect(first.reading!.imagePath, 'photo');
      expect(first.reading!.imageFraction, .25);
      expect((await reopened.read('second')).writing, isNull);
      expect((await reopened.read('missing')).reading, isNull);
      expect(
          storage.values.keys,
          containsAll([
            NotePositionStore.storageKey('first'),
            NotePositionStore.storageKey('second'),
          ]));
      expect(
          jsonDecode(storage.values[NotePositionStore.storageKey('first')]!)
              .keys,
          unorderedEquals(['version', 'writing', 'reading']));
    });

    test('corrupted records are ignored and replaced by a later capture',
        () async {
      final storage = MemoryNotePositionStorage({
        NotePositionStore.storageKey('note'): '{not json',
      });
      final store = NotePositionStore(storage: storage);
      expect((await store.read('note')).writing, isNull);
      await store.saveWriting('note', writing);
      final fresh = await NotePositionStore(storage: storage).read('note');
      expect(fresh.writing, isNotNull);
    });

    test('a malformed field does not discard the other valid position',
        () async {
      final storage = MemoryNotePositionStorage({
        NotePositionStore.storageKey('note'): jsonEncode({
          'version': 1,
          'writing': {'field': 'removed-field'},
          'reading': reading.toJson(),
        }),
        NotePositionStore.storageKey('future'): jsonEncode({'version': 99}),
      });
      final store = NotePositionStore(storage: storage);
      final positions = await store.read('note');
      expect(positions.writing, isNull);
      expect(positions.reading!.resolve('Body text'), 3);
      expect((await store.read('future')).reading, isNull);
      expect(
          NoteReadingPosition.tryFromJson({
            'anchor': reading.anchor.toJson(),
            'leadingDisplacement': double.nan,
          }),
          isNull);
    });

    test('removal clears the record and session cache', () async {
      final storage = MemoryNotePositionStorage();
      final store = NotePositionStore(storage: storage);
      await store.saveWriting('note', writing);
      await store.remove('note');
      expect((await store.read('note')).writing, isNull);
      expect(storage.values, isEmpty);
    });

    test('an unavailable preference backend retains navigation in memory',
        () async {
      final store = NotePositionStore(storage: _UnavailableStorage());
      expect((await store.read('note')).writing, isNull);
      await store.saveWriting('note', writing);
      expect((await store.read('note')).writing, same(writing));
      await store.remove('note');
    });

    test('an absent preference platform keeps snapshots and permits removal',
        () async {
      final previous = SharedPreferencesAsyncPlatform.instance;
      try {
        SharedPreferencesAsyncPlatform.instance = null;
        final store = NotePositionStore();
        expect((await store.read('note')).writing, isNull);
        await store.saveWriting('note', writing);
        await store.saveReading('note', reading);
        final cached = await store.read('note');
        expect(cached.writing, same(writing));
        expect(cached.reading, same(reading));
        await store.remove('note');
        final removed = await store.read('note');
        expect(removed.writing, isNull);
        expect(removed.reading, isNull);
      } finally {
        SharedPreferencesAsyncPlatform.instance = previous;
      }
    });
  });
}

class _UnavailableStorage implements NotePositionStorage {
  @override
  Future<String?> read(String key) async => throw StateError('No preferences');
  @override
  Future<void> write(String key, String value) async =>
      throw StateError('No preferences');
  @override
  Future<void> remove(String key) async => throw StateError('No preferences');
}
