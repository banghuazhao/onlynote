import 'dart:async';
import 'dart:convert';

import 'package:characters/characters.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/Tools/widget_sync.dart';
import 'package:onlynote/data/dto/note_dto.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('onlynote.test/mac-widget-snapshot');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  testWidgets('Mac snapshots use the native bridge and coalesce library writes',
      (tester) async {
    final calls = <MethodCall>[];
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return null;
    });
    final notes = [NoteDto(id: 'one', title: 'Before')];
    final changes = StreamController<Object?>.broadcast(sync: true);
    addTearDown(changes.close);
    final sync = WidgetSync(
      platform: const MacWidgetSnapshotPlatform(channel: channel),
      readNotes: () => notes,
      watchNotes: () => changes.stream,
    );
    addTearDown(sync.dispose);

    await sync.init();
    expect(calls.map((call) => call.method), ['saveSnapshot', 'refresh']);
    final snapshot = jsonDecode(
        (calls.first.arguments as Map)['payload'] as String) as Map;
    expect((snapshot['allNotes'] as List).single['title'], 'Before');
    expect(calls.any((call) => call.method == 'initialize'), isFalse);

    notes[0] = NoteDto(id: 'one', title: 'Latest');
    changes.add(null);
    changes.add(null);
    changes.add(null);
    await tester.pump(const Duration(milliseconds: 299));
    expect(calls, hasLength(2));
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump();

    expect(calls.map((call) => call.method),
        ['saveSnapshot', 'refresh', 'saveSnapshot', 'refresh']);
    final updated = jsonDecode(
        (calls[2].arguments as Map)['payload'] as String) as Map;
    expect((updated['allNotes'] as List).single['title'], 'Latest');
  });

  testWidgets('Mac group-access failures leave library watching available',
      (tester) async {
    var writes = 0;
    var refreshes = 0;
    var available = false;
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'saveSnapshot') {
        writes++;
        if (!available) throw PlatformException(code: 'app_group_unavailable');
      } else if (call.method == 'refresh') {
        refreshes++;
      }
      return null;
    });
    final changes = StreamController<Object?>.broadcast(sync: true);
    addTearDown(changes.close);
    final sync = WidgetSync(
      platform: const MacWidgetSnapshotPlatform(channel: channel),
      readNotes: () => [NoteDto(id: 'one', title: 'Kept')],
      watchNotes: () => changes.stream,
    );
    addTearDown(sync.dispose);

    await sync.init();
    expect(writes, 1);
    expect(refreshes, 0);

    available = true;
    changes.add(null);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
    expect(writes, 2);
    expect(refreshes, 1);
  });

  test('configuration includes every active note beyond the overview rows', () {
    final notes = List.generate(
        12,
        (index) =>
            NoteDto(id: 'note-$index', title: 'Note $index', sortOrder: index));
    notes.add(NoteDto(id: 'trash', deletedAt: '2026-10-06'));
    final payload = WidgetSync.buildPayload(notes);
    expect(payload['total'], 12);
    expect(payload['notes'], hasLength(8));
    final all = payload['allNotes'] as List<Map<String, dynamic>>;
    expect(all, hasLength(12));
    expect(all.last['id'], 'note-11');
    expect(all.any((note) => note['id'] == 'trash'), false);
    expect(notes, hasLength(13));
  });

  test('snapshot carries stable item IDs and leaves legacy items read only',
      () {
    final payload = WidgetSync.buildPayload([
      NoteDto(id: 'one', title: 'Packing\n list', todoList: [
        TodoDto(id: 'passport', title: 'Passport', completed: true),
        TodoDto(title: 'Old item'),
      ]),
    ]);
    final note = (payload['allNotes'] as List<Map<String, dynamic>>).single;
    final todos = note['todos'] as List<Map<String, dynamic>>;
    expect(note['title'], 'Packing list');
    expect(note['todoTotal'], 2);
    expect(note['todoDone'], 1);
    expect(todos.first, {'id': 'passport', 't': 'Passport', 'c': true});
    expect(todos.last.containsKey('id'), false);
    expect(todos.last['c'], false);
  });
  test('archived notes are absent from overview and widget selection', () {
    final payload = WidgetSync.buildPayload([
      NoteDto(id: 'active', title: 'Visible'),
      NoteDto(id: 'archive', title: 'Archived', isArchived: true),
    ]);
    expect(payload['total'], 1);
    for (final key in ['notes', 'allNotes']) {
      expect((payload[key] as List).map((note) => note['id']), ['active']);
    }
  });

  test('Mac paper previews retain paragraphs and complete emoji clusters', () {
    const emoji = '👩🏽‍💻';
    final description =
        'First paragraph\n\nSecond line  with spaces\n${List.filled(900, emoji).join()}';
    final note = NoteDto(id: 'paper', description: description);
    final mobile = WidgetSync.buildPayload([note]);
    final desktop = WidgetSync.buildPayload([note], desktop: true);

    for (final key in ['notes', 'allNotes']) {
      final mobileBody = (mobile[key] as List).single['body'] as String;
      final desktopBody = (desktop[key] as List).single['body'] as String;
      expect(mobileBody, isNot(contains('\n')));
      expect(mobileBody, isNot(contains('  ')));
      expect(mobileBody.length, lessThanOrEqualTo(121));
      expect(desktopBody,
          startsWith('First paragraph\n\nSecond line  with spaces\n'));
      expect(desktopBody.length, greaterThan(120));
      expect(desktopBody.characters.length, 801);
      expect(desktopBody, endsWith('$emoji…'));
      // A Unicode roundtrip detects unpaired UTF-16 surrogate fragments.
      expect(utf8.decode(utf8.encode(desktopBody)), desktopBody);
    }

    const shortBody = '  Heading\n\nIndented:  keep this\n';
    final short = WidgetSync.buildPayload(
        [NoteDto(id: 'short', description: shortBody)],
        desktop: true);
    expect((short['allNotes'] as List).single['body'], shortBody);
  });

  test('Mac title and checklist summaries remain valid Unicode in native JSON',
      () {
    final prefix = List.filled(59, 'A').join();
    const titleEmoji = '😀';
    const todoEmoji = '👩🏽‍💻';
    final payload = WidgetSync.buildPayload([
      NoteDto(
        id: 'emoji-note',
        title: '  $prefix${titleEmoji}Tail\n',
        todoList: [
          TodoDto(id: 'emoji-todo', title: '$prefix${todoEmoji}Tail'),
          TodoDto(id: 'short', title: '  Pack\n\n passport  '),
        ],
      ),
    ], desktop: true);

    final nativeJSON =
        jsonDecode(utf8.decode(utf8.encode(jsonEncode(payload)))) as Map;
    for (final key in ['notes', 'allNotes']) {
      final note = (nativeJSON[key] as List).single as Map;
      expect(note['title'], '$prefix$titleEmoji…');
      final todos = note['todos'] as List;
      expect(todos.first['t'], '$prefix$todoEmoji…');
      expect(todos.last['t'], 'Pack passport');
    }
  });
}
