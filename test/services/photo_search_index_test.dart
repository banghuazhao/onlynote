import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:onlynote/data/dto/note_dto.dart';
import 'package:onlynote/services/photo_search_index.dart';
import 'package:onlynote/services/photo_text_extraction.dart';

const _a = 'note_images/a.jpg';
const _b = 'note_images/b.png';

Future<void> _waitUntil(bool Function() ready) async {
  final elapsed = Stopwatch()..start();
  while (elapsed.elapsed < const Duration(seconds: 5)) {
    await Future<void>.delayed(const Duration(milliseconds: 2));
    if (ready()) return;
  }
  fail('Photo search operation did not settle');
}

Map<String, Object> _cached(String text) => {
      'version': 1,
      'status': text.isEmpty ? 'no_text' : 'text',
      'text': text,
    };

class _DelayedCache extends Fake implements Box {
  _DelayedCache(this.delegate);
  final Box delegate;
  final putEntered = Completer<void>();
  final releasePut = Completer<void>();
  @override
  Iterable<dynamic> get keys => delegate.keys;
  @override
  dynamic get(dynamic key, {dynamic defaultValue}) =>
      delegate.get(key, defaultValue: defaultValue);
  @override
  Future<void> deleteAll(Iterable<dynamic> keys) => delegate.deleteAll(keys);
  @override
  Future<void> delete(dynamic key) => delegate.delete(key);
  @override
  Future<void> put(dynamic key, dynamic value) async {
    if (!putEntered.isCompleted) putEntered.complete();
    await releasePut.future;
    await delegate.put(key, value);
  }
}

void main() {
  late Directory directory;
  late Box notes;
  late Box cache;
  late PhotoSearchIndex index;
  late DateTime now;
  late List<String> recognized;

  PhotoSearchIndex makeIndex({
    Future<PhotoTextResult> Function(String)? recognize,
    Future<bool> Function(String)? exists,
    Box? cacheOverride,
  }) =>
      PhotoSearchIndex(
        notes: notes,
        cache: cacheOverride ?? cache,
        exists: exists ?? (_) async => true,
        recognize: recognize ??
            (path) async {
              recognized.add(path);
              return PhotoTextResult(PhotoTextStatus.text, text: 'Text $path');
            },
        now: () => now,
      );

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('onlynote-photo-search-');
    Hive.init(directory.path);
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(TodoDtoAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(NoteDtoAdapter());
    notes = await Hive.openBox('notes');
    cache = await Hive.openBox(PhotoSearchIndex.boxName);
    now = DateTime.utc(2026, 10, 6);
    recognized = [];
    index = makeIndex();
  });

  tearDown(() async {
    index.dispose();
    await notes.close();
    await cache.close();
    await directory.delete(recursive: true);
  });

  test('start returns before OCR and never changes note content or edit dates',
      () async {
    final original = NoteDto(
        id: 'receipt',
        title: 'Receipt',
        description: 'Keep this',
        dateTime: '2026-09-01T10:30:00.000',
        imagePaths: [_a]);
    await notes.put('receipt', original);
    final result = Completer<PhotoTextResult>();
    index.dispose();
    index = makeIndex(recognize: (path) => result.future);
    final changes = <bool>[];
    index.addListener(() => changes.add(index.isIndexing));
    await index.start();
    expect(result.isCompleted, isFalse);
    expect(index.isIndexing, isTrue);
    expect(index.textsForNote(original.toDomain()), isEmpty);
    result.complete(const PhotoTextResult(PhotoTextStatus.text,
        text: '  Grocery\r\nTotal: 42.00  '));
    await _waitUntil(() => !index.isIndexing);
    expect(index.matchingText(original.toDomain(), 'total: 42'),
        'Grocery\nTotal: 42.00');
    expect(notes.get('receipt'), same(original));
    expect(original.dateTime, '2026-09-01T10:30:00.000');
    expect(changes.first, isTrue);
    expect(changes.last, isFalse);
  });

  test('results and no-text photos persist across actual cache reopen',
      () async {
    final note = NoteDto(id: 'one', imagePaths: [_a, _b]);
    await notes.put('one', note);
    index.dispose();
    index = makeIndex(recognize: (path) async {
      recognized.add(path);
      return path == _a
          ? const PhotoTextResult(PhotoTextStatus.text, text: 'Milk 3.50')
          : const PhotoTextResult(PhotoTextStatus.noText);
    });
    await index.start();
    await _waitUntil(() => !index.isIndexing);
    expect(recognized, [_a, _b]);
    index.dispose();
    await cache.close();
    cache = await Hive.openBox(PhotoSearchIndex.boxName);
    index = makeIndex();
    await index.start();
    await _waitUntil(() => !index.isIndexing);
    expect(index.textsForNote(note.toDomain()), ['Milk 3.50']);
    expect(recognized, [_a, _b]);
    expect(cache.get(_b), _cached(''));
  });

  test('shared and legacy paths dedupe; matches choose the correct attachment',
      () async {
    const absolute = '/old/container/Documents/note_images/b.png';
    final one = NoteDto(id: 'one', imagePaths: [_a, absolute, _b]);
    await notes.putAll({
      'one': one,
      'two': NoteDto(id: 'two', imagePaths: [_a, _b]),
    });
    index.dispose();
    index = makeIndex(recognize: (path) async {
      recognized.add(path);
      return PhotoTextResult(PhotoTextStatus.text,
          text: path == _a ? 'School schedule' : '咖啡 Receipt [3.50]');
    });
    await index.start();
    await _waitUntil(() => !index.isIndexing);
    expect(recognized, [_a, _b]);
    expect(index.textsForNote(one.toDomain()),
        ['School schedule', '咖啡 Receipt [3.50]']);
    expect(
        index.matchingText(one.toDomain(), ' REceipt '), '咖啡 Receipt [3.50]');
    expect(index.matchingText(one.toDomain(), '[3.50]'), isNotNull);
    expect(index.matchingText(one.toDomain(), '咖啡'), isNotNull);
    expect(index.matchingText(one.toDomain(), '   '), isNull);
    expect(index.matchingPhotoPath(one.toDomain(), 'receipt'), absolute);
  });

  test('note saves index new photos and only current attachments match',
      () async {
    final one = NoteDto(id: 'one', imagePaths: [_a]);
    await notes.putAll({
      'one': one,
      'other': NoteDto(id: 'other', imagePaths: [_a]),
    });
    await index.start();
    await _waitUntil(() => !index.isIndexing);
    final replaced = one.copyWith(imagePaths: [_b]);
    await notes.put('one', replaced);
    await _waitUntil(() => index.matchingText(replaced.toDomain(), _b) != null);
    await _waitUntil(() => !index.isIndexing);
    expect(index.matchingText(replaced.toDomain(), _a), isNull);
    expect(index.matchingText(one.toDomain(), _a), isNotNull);
    expect(recognized, [_a, _b]);
  });

  test('Trash photos remain indexed until the final reference is deleted',
      () async {
    final deleted = NoteDto(
        id: 'trash', imagePaths: [_a], deletedAt: '2026-10-01T00:00:00.000');
    await notes.put('trash', deleted);
    await index.start();
    await _waitUntil(() => !index.isIndexing);
    expect(index.matchingText(deleted.toDomain(), _a), isNotNull);
    await notes.delete('trash');
    await _waitUntil(() => !cache.containsKey(_a));
    expect(index.textsForNote(deleted.toDomain()), isEmpty);
  });

  test('a removed in-flight photo cannot publish or persist its result',
      () async {
    final result = Completer<PhotoTextResult>();
    final one = NoteDto(id: 'one', imagePaths: [_a]);
    await notes.put('one', one);
    index.dispose();
    index = makeIndex(recognize: (path) {
      recognized.add(path);
      return path == _a
          ? result.future
          : Future.value(
              const PhotoTextResult(PhotoTextStatus.text, text: 'Replacement'));
    });
    await index.start();
    await _waitUntil(() => recognized.isNotEmpty);
    final replacement = one.copyWith(imagePaths: [_b]);
    await notes.put('one', replacement);
    result.complete(
        const PhotoTextResult(PhotoTextStatus.text, text: 'Discard this'));
    await _waitUntil(() => !index.isIndexing);
    expect(index.textsForNote(one.toDomain()), isEmpty);
    expect(index.textsForNote(replacement.toDomain()), ['Replacement']);
    expect(cache.containsKey(_a), isFalse);
    expect(recognized, [_a, _b]);
  });

  test('remove and reattach while OCR runs drops the previous generation',
      () async {
    final first = Completer<PhotoTextResult>();
    final one = NoteDto(id: 'one', imagePaths: [_a]);
    await notes.put('one', one);
    index.dispose();
    index = makeIndex(recognize: (path) {
      recognized.add(path);
      return recognized.length == 1
          ? first.future
          : Future.value(
              const PhotoTextResult(PhotoTextStatus.text, text: 'Fresh'));
    });
    await index.start();
    await _waitUntil(() => recognized.isNotEmpty);
    await notes.put('one', one.copyWith(imagePaths: []));
    await Future<void>.delayed(const Duration(milliseconds: 4));
    await notes.put('one', one);
    first.complete(
        const PhotoTextResult(PhotoTextStatus.text, text: 'Old request'));
    await _waitUntil(() => !index.isIndexing);
    expect(index.textsForNote(one.toDomain()), ['Fresh']);
    expect(recognized, [_a, _a]);
  });

  test('pruning waits for a cache write then removes a deleted photo',
      () async {
    final delayed = _DelayedCache(cache);
    final one = NoteDto(id: 'one', imagePaths: [_a]);
    await notes.put('one', one);
    index.dispose();
    index = makeIndex(cacheOverride: delayed);
    await index.start();
    await delayed.putEntered.future;
    await notes.delete('one');
    await Future<void>.delayed(const Duration(milliseconds: 4));
    expect(index.textsForNote(one.toDomain()), isEmpty);
    delayed.releasePut.complete();
    await _waitUntil(() => !index.isIndexing && !cache.containsKey(_a));
  });

  test('background pause keeps native work serial and resumes pending photos',
      () async {
    final first = Completer<PhotoTextResult>();
    final one = NoteDto(id: 'one', imagePaths: [_a, _b]);
    await notes.put('one', one);
    index.dispose();
    index = makeIndex(recognize: (path) {
      recognized.add(path);
      return path == _a
          ? first.future
          : Future.value(
              const PhotoTextResult(PhotoTextStatus.text, text: 'Second'));
    });
    await index.start();
    await _waitUntil(() => recognized.isNotEmpty);
    index.setActive(false);
    expect(index.isIndexing, isFalse);
    first.complete(const PhotoTextResult(PhotoTextStatus.text, text: 'First'));
    await _waitUntil(() => cache.containsKey(_a));
    expect(recognized, [_a]);
    index.setActive(true);
    await _waitUntil(() => !index.isIndexing);
    expect(recognized, [_a, _b]);
    expect(index.textsForNote(one.toDomain()), ['First', 'Second']);
  });

  test('failed recognition retries only on a cooled-down sync or resume',
      () async {
    final one = NoteDto(id: 'one', imagePaths: [_a]);
    await notes.put('one', one);
    index.dispose();
    index = makeIndex(recognize: (path) async {
      recognized.add(path);
      if (recognized.length == 1) throw StateError('Native unavailable');
      return const PhotoTextResult(PhotoTextStatus.text, text: 'Recovered');
    });
    await index.start();
    await _waitUntil(() => !index.isIndexing);
    expect(recognized, [_a]);
    expect(cache.containsKey(_a), isFalse);
    final editObserved = notes.watch(key: 'one').first;
    await notes.put('one', one.copyWith(title: 'Unrelated edit'));
    await editObserved;
    index.setActive(false);
    index.setActive(true);
    await _waitUntil(() => !index.isIndexing);
    expect(recognized, [_a]);
    now = now.add(const Duration(minutes: 6));
    await Future<void>.delayed(const Duration(milliseconds: 8));
    expect(recognized, [_a]);
    index.setActive(false);
    index.setActive(true);
    await _waitUntil(() => !index.isIndexing);
    expect(recognized, [_a, _a]);
    expect(index.textsForNote(one.toDomain()), ['Recovered']);
  });

  test('unsupported recognition stops this session and retains valid cache',
      () async {
    final one = NoteDto(id: 'one', imagePaths: [_a, _b]);
    await notes.put('one', one);
    await cache.put(_a, _cached('Existing'));
    final files = {_a, _b};
    final probes = <String, int>{};
    index.dispose();
    index = makeIndex(exists: (path) async {
      probes[path] = (probes[path] ?? 0) + 1;
      return files.contains(path);
    }, recognize: (path) async {
      recognized.add(path);
      return const PhotoTextResult(PhotoTextStatus.unsupported);
    });
    await index.start();
    await _waitUntil(() => !index.isIndexing);
    expect(recognized, [_b]);
    now = now.add(const Duration(days: 1));
    final initialProbes = probes[_a]!;
    index.setActive(false);
    index.setActive(true);
    final editObserved = notes.watch(key: 'one').first;
    await notes.put('one', one.copyWith(title: 'Update'));
    await editObserved;
    await _waitUntil(() => probes[_a]! > initialProbes && !index.isIndexing);
    expect(recognized, [_b]);
    expect(index.textsForNote(one.toDomain()), ['Existing']);
    expect(index.isIndexing, isFalse);
    files.remove(_a);
    final previousProbes = probes[_a]!;
    index.setActive(false);
    index.setActive(true);
    await _waitUntil(() => probes[_a]! > previousProbes && !index.isIndexing);
    expect(index.textsForNote(one.toDomain()), isEmpty);
    expect(cache.containsKey(_a), isFalse);
    expect(recognized, [_b]);
  });

  test('invalid managed paths and malformed or orphaned cache entries vanish',
      () async {
    final invalid = [
      'file:///tmp/a.jpg',
      '/tmp/a.jpg',
      'note_images/',
      'note_images/..',
      'note_images/../secret.jpg',
      'note_images/nested/a.jpg',
      'note_images/a\\b.jpg',
      'note_images/a\u0000.jpg',
    ];
    final photos = [
      _a,
      _b,
      'note_images/c.jpg',
      'note_images/d.jpg',
      ...invalid,
    ];
    await notes.put('one', NoteDto(id: 'one', imagePaths: photos));
    await cache.putAll({
      _a: {'version': 2, 'status': 'text', 'text': 'Wrong version'},
      _b: {'version': 1, 'status': 'failed', 'text': 'Wrong status'},
      'note_images/c.jpg': {
        'version': 1,
        'status': 'text',
        'text': List.filled(maxPhotoTextLength + 1, 'a').join(),
      },
      'note_images/d.jpg': {'version': 1, 'status': 'text', 'text': 23},
      'note_images/orphan.jpg': _cached('Orphan'),
      'note_images/../bad.jpg': _cached('Unsafe'),
      7: _cached('Wrong key type'),
    });
    await index.start();
    await _waitUntil(() => !index.isIndexing);
    expect(recognized, photos.take(4));
    expect(cache.keys.toSet(), photos.take(4).toSet());
  });

  test('missing files are removed from cached search on startup and resume',
      () async {
    final one = NoteDto(id: 'one', imagePaths: [_a, _b]);
    await notes.put('one', one);
    await cache.putAll({_a: _cached('Missing'), _b: _cached('Available')});
    final files = {_b};
    index.dispose();
    index = makeIndex(exists: (path) async => files.contains(path));
    await index.start();
    await _waitUntil(() => !index.isIndexing);
    expect(index.textsForNote(one.toDomain()), ['Available']);
    expect(cache.containsKey(_a), isFalse);
    expect(recognized, isEmpty);
    files.clear();
    index.setActive(false);
    index.setActive(true);
    await _waitUntil(() => !index.isIndexing);
    expect(index.textsForNote(one.toDomain()), isEmpty);
    expect(cache.keys, isEmpty);
    expect(recognized, isEmpty);
  });

  test('dispose drops in-flight text and clears the configured instance',
      () async {
    final result = Completer<PhotoTextResult>();
    final one = NoteDto(id: 'one', imagePaths: [_a]);
    await notes.put('one', one);
    index.dispose();
    index = makeIndex(recognize: (path) {
      recognized.add(path);
      return result.future;
    });
    PhotoSearchIndex.configure(index);
    var notifications = 0;
    index.addListener(() => notifications++);
    await index.start();
    await _waitUntil(() => recognized.isNotEmpty);
    expect(PhotoSearchIndex.initializedInstance, same(index));
    index.dispose();
    final before = notifications;
    result.complete(
        const PhotoTextResult(PhotoTextStatus.text, text: 'Too late'));
    await Future<void>.delayed(const Duration(milliseconds: 8));
    expect(PhotoSearchIndex.initializedInstance, isNull);
    expect(notifications, before);
    expect(index.textsForNote(one.toDomain()), isEmpty);
    expect(cache.keys, isEmpty);
  });
}
