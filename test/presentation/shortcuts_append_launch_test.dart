import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/Tools/onboarding_settings.dart';
import 'package:onlynote/Tools/shortcuts_append_launch.dart';
import 'package:onlynote/data/dto/note_dto.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/presentation/routes/routes.dart';
import 'package:onlynote/services/shortcuts_append.dart';
import '../services/shortcuts_append_test.dart'
    show AppendTestNotes, AppendTestJournal, AppendTestStore, appendRequest;

class _Router extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
        AutoRoute(
            initial: true,
            page: PageInfo('ShortcutTestRoute',
                builder: (_) => const Scaffold(body: Text('Library'))))
      ];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('test.shortcuts_append');
  late AppendTestNotes notes;
  late AppendTestStore store;
  late AppendTestJournal journal;
  late ShortcutsAppendService service;
  late List<ShortcutAppendRequest> native;
  late List<ShortcutAppendFailure> failures;
  late List<List<Object?>> catalogs;
  late bool onboarding;
  setUp(() {
    onboarding = OnboardingSettings.instance.completed;
    OnboardingSettings.instance.completed = true;
    notes = AppendTestNotes();
    store = AppendTestStore(notes);
    journal = AppendTestJournal();
    notes.values['target'] = NoteDto.fromNote(
        Note(id: 'target', title: 'Shopping', description: 'Before'));
    service = ShortcutsAppendService(
        repository: notes,
        journal: journal,
        store: store,
        readDraft: (id) => store.drafts[id]);
    native = [];
    failures = [];
    catalogs = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      switch (call.method) {
        case 'pending':
          return native.map((request) => request.toMap()).toList();
        case 'acknowledge':
          native.removeWhere(
              (request) => request.id == (call.arguments as Map)['id']);
          return null;
        case 'saveCatalog':
          catalogs.add((call.arguments as List).cast<Object?>());
          return null;
        default:
          throw MissingPluginException();
      }
    });
  });
  tearDown(() {
    OnboardingSettings.instance.completed = onboarding;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  Future<(_Router, ShortcutsAppendLaunch)> mount(WidgetTester tester,
      {Future<bool> Function()? prepareEditors,
      VoidCallback? onApplied}) async {
    final router = _Router();
    final launch = ShortcutsAppendLaunch(
        channel: channel,
        enabled: true,
        service: service,
        readNotes: () => notes.values.values.map((dto) => dto.toDomain()),
        prepareEditors: prepareEditors ?? () async => true);
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await launch.dispose();
      router.dispose();
    });
    await tester.pumpWidget(MaterialApp.router(routerConfig: router.config()));
    await tester.pumpAndSettle();
    launch.attach(router,
        onApplied: onApplied,
        onFailure: failures.add,
        titleForDay: (day) => 'Today',
        inboxTitle: () => 'Inbox');
    await launch.init();
    await tester.pumpAndSettle();
    return (router, launch);
  }

  testWidgets(
      'native requests drain once, update catalog, and keep current route',
      (tester) async {
    native = [appendRequest()];
    var applied = 0;
    final (router, launch) = await mount(tester, onApplied: () => applied++);
    expect(notes.values['target']!.description, 'Before\n\nAdded');
    expect(native, isEmpty);
    expect(launch.pendingRequests, isEmpty);
    expect(applied, 1);
    expect(router.current.name, 'ShortcutTestRoute');
    expect(catalogs.last.single,
        isA<Map>().having((row) => row['id'], 'stable ID', 'target'));
    native = [appendRequest()];
    launch.refresh();
    await tester.pumpAndSettle();
    expect(notes.values['target']!.description, 'Before\n\nAdded');
    expect(notes.writes, 1);
    expect(failures, isEmpty);
  });

  testWidgets('failed editor flush retains request for review and retry',
      (tester) async {
    native = [appendRequest()];
    var ready = false;
    final (_, launch) = await mount(tester, prepareEditors: () async => ready);
    expect(notes.writes, 0);
    expect(launch.pendingRequests.single.text, 'Added');
    expect(failures, [ShortcutAppendFailure.saveBlocked]);
    ready = true;
    launch.retry();
    await tester.pumpAndSettle();
    expect(notes.values['target']!.description, 'Before\n\nAdded');
    expect(launch.pendingRequests, isEmpty);
  });

  testWidgets(
      'discard retains text until native acknowledgement then suppresses replay',
      (tester) async {
    native = [appendRequest(noteId: 'missing')];
    final (_, launch) = await mount(tester);
    expect(failures, [ShortcutAppendFailure.unavailable]);
    final request = launch.pendingRequests.single;
    expect(request.text, 'Added');
    await launch.discard(request.id);
    expect(native, isEmpty);
    expect(launch.pendingRequests, isEmpty);
    native = [request];
    launch.refresh();
    await tester.pumpAndSettle();
    expect(native, isEmpty);
    expect(notes.writes, 0);
  });

  testWidgets(
      'covered app lifetime cannot finish a pending flush after disposal',
      (tester) async {
    final gate = Completer<bool>();
    native = [appendRequest()];
    final (_, launch) = await mount(tester, prepareEditors: () => gate.future);
    expect(notes.writes, 0);
    await launch.dispose();
    gate.complete(true);
    await tester.pumpAndSettle();
    expect(notes.writes, 0);
    expect(native, hasLength(1));
    expect(failures, isEmpty);
  });

  testWidgets('reattaching during a flush resumes the new app lifetime',
      (tester) async {
    final gate = Completer<bool>();
    native = [appendRequest()];
    final (router, launch) =
        await mount(tester, prepareEditors: () => gate.future);
    expect(notes.writes, 0);
    launch.detach();
    launch.attach(router,
        onFailure: failures.add,
        titleForDay: (day) => 'Today',
        inboxTitle: () => 'Inbox');
    gate.complete(true);
    await tester.pumpAndSettle();
    expect(notes.values['target']!.description, 'Before\n\nAdded');
    expect(native, isEmpty);
    expect(launch.pendingRequests, isEmpty);
    expect(failures, isEmpty);
  });

  testWidgets('one failed destination preserves order while other notes finish',
      (tester) async {
    native = [
      appendRequest(sequence: 1, noteId: 'missing'),
      appendRequest(sequence: 2, noteId: 'missing', text: 'Second'),
      appendRequest(sequence: 3, text: 'Other note')
    ];
    final (_, launch) = await mount(tester);
    expect(notes.values['target']!.description, 'Before\n\nOther note');
    expect(launch.pendingRequests.map((request) => request.text),
        ['Added', 'Second']);
    expect(failures, [ShortcutAppendFailure.unavailable]);
    notes.values['missing'] =
        NoteDto.fromNote(Note(id: 'missing', title: 'Restored'));
    launch.retry();
    await tester.pumpAndSettle();
    expect(notes.values['missing']!.description, 'Added\n\nSecond');
    expect(launch.pendingRequests, isEmpty);
  });
}
