import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/services/note_bulk_export.dart';
import 'package:onlynote/services/note_export_format_store.dart';

import '../support/memory_preferences.dart';

class _PendingReadPreferences extends MemoryPreferences {
  final pending = Completer<String?>();

  @override
  Future<String?> getString(String key) => pending.future;
}

class _FailingPreferences extends MemoryPreferences {
  @override
  Future<String?> getString(String key) async => throw StateError('No store');

  @override
  Future<void> setString(String key, String value) async =>
      throw StateError('No storage space');
}

class _PendingWritePreferences extends MemoryPreferences {
  _PendingWritePreferences({this.failFirst = false});

  final firstWrite = Completer<void>();
  final firstStarted = Completer<void>();
  final writes = <String>[];
  final bool failFirst;

  @override
  Future<void> setString(String key, String value) async {
    writes.add(value);
    if (writes.length == 1) {
      firstStarted.complete();
      await firstWrite.future;
      if (failFirst) throw StateError('First write failed');
    }
    await super.setString(key, value);
  }
}

void main() {
  for (final format in NoteBulkExportFormat.values) {
    test('$format persists by enum name and survives reopening', () async {
      final preferences = MemoryPreferences();
      final store = NoteExportFormatStore(preferences: preferences);
      expect(await store.read(), NoteBulkExportFormat.markdown);
      await store.write(format);
      expect(
          preferences.values, {NoteExportFormatStore.storageKey: format.name});
      expect(
          await NoteExportFormatStore(preferences: preferences).read(), format);
    });
  }

  test('missing, malformed and unsupported preferences use Markdown', () async {
    for (final raw in <Object?>[null, '', 'PDF', 'text', 'unknown', '1', 123]) {
      final preferences = MemoryPreferences();
      if (raw != null) {
        preferences.values[NoteExportFormatStore.storageKey] = raw;
      }
      expect(await NoteExportFormatStore(preferences: preferences).read(),
          NoteBulkExportFormat.markdown,
          reason: '$raw');
    }
  });

  test('preference failures preserve the session choice without throwing',
      () async {
    final store = NoteExportFormatStore(preferences: _FailingPreferences());
    expect(await store.read(), NoteBulkExportFormat.markdown);
    await expectLater(store.write(NoteBulkExportFormat.pdf), completes);
    expect(await store.read(), NoteBulkExportFormat.pdf);

    final unavailablePlugin = NoteExportFormatStore();
    expect(await unavailablePlugin.read(), NoteBulkExportFormat.markdown);
    await expectLater(
        unavailablePlugin.write(NoteBulkExportFormat.plainText), completes);
    expect(await unavailablePlugin.read(), NoteBulkExportFormat.plainText);
  });

  test('a delayed read cannot replace a newly selected format', () async {
    final preferences = _PendingReadPreferences();
    final store = NoteExportFormatStore(preferences: preferences);
    final initialRead = store.read();
    await store.write(NoteBulkExportFormat.plainText);
    preferences.pending.complete(NoteBulkExportFormat.pdf.name);
    expect(await initialRead, NoteBulkExportFormat.plainText);
    expect(await store.read(), NoteBulkExportFormat.plainText);
  });

  for (final failFirst in [false, true]) {
    test('rapid choices remain ordered when first write fails: $failFirst',
        () async {
      final preferences = _PendingWritePreferences(failFirst: failFirst);
      final store = NoteExportFormatStore(preferences: preferences);
      final first = store.write(NoteBulkExportFormat.pdf);
      final second = store.write(NoteBulkExportFormat.plainText);
      final third = store.write(NoteBulkExportFormat.markdown);
      await preferences.firstStarted.future;
      expect(preferences.writes, ['pdf']);
      expect(await store.read(), NoteBulkExportFormat.markdown);
      preferences.firstWrite.complete();
      await Future.wait([first, second, third]);
      expect(preferences.writes, ['pdf', 'plainText', 'markdown']);
      expect(await NoteExportFormatStore(preferences: preferences).read(),
          NoteBulkExportFormat.markdown);
    });
  }
}
