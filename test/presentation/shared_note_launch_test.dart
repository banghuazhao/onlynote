import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:onlynote/Tools/onboarding_settings.dart';
import 'package:onlynote/Tools/shared_note_launch.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/presentation/routes/routes.dart';
import 'package:onlynote/services/shared_note_import.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/shared_note_import_test.dart'
    show SharedTestNotes, sharedId;

class _MemoryJournal extends Fake implements Box {
  final entries = <Object, Object?>{};
  @override
  Iterable<dynamic> get keys => entries.keys;
  @override
  dynamic get(dynamic key, {dynamic defaultValue}) =>
      entries[key] ?? defaultValue;
  @override
  Future<void> put(dynamic key, dynamic value) async => entries[key] = value;
  @override
  Future<void> delete(dynamic key) async => entries.remove(key);
  @override
  Future<void> flush() async {}
}

class _ShareRouter extends RootStackRouter {
  _ShareRouter({this.onboarding = false});
  final bool onboarding;
  @override
  List<AutoRoute> get routes => [
        AutoRoute(
          initial: onboarding,
          page: PageInfo(OnboardingRoute.name,
              builder: (_) => const Scaffold(body: Text('Welcome'))),
        ),
        AutoRoute(
          initial: !onboarding,
          page: PageInfo(HomeRoute.name,
              builder: (_) => const Scaffold(body: Text('Library'))),
        ),
        AutoRoute(
          page: PageInfo(AddUpdateNoteRoute.name, builder: (data) {
            final args = data.argsAs<AddUpdateNoteRouteArgs>();
            return Scaffold(
              key: args.key,
              body: TextField(
                key: ValueKey('editor-${args.note?.id}'),
                decoration: InputDecoration(labelText: args.note?.title),
              ),
            );
          }),
        ),
      ];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('onlynote.share.launch.test');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late List<Object> pending;
  late SharedTestNotes notes;
  late _MemoryJournal journal;
  late SharedNoteLaunch launch;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await OnboardingSettings.instance.load();
    pending = [];
    notes = SharedTestNotes();
    journal = _MemoryJournal();
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'pending') return pending.toList();
      if (call.method == 'acknowledge') {
        final id = (call.arguments as Map)['id'];
        pending.removeWhere((value) => (value as Map)['id'] == id);
      }
      return null;
    });
    launch = SharedNoteLaunch(channel: channel, enabled: true);
  });
  tearDown(() {
    launch.dispose();
    messenger.setMockMethodCallHandler(channel, null);
    OnboardingSettings.instance.completed = false;
  });

  testWidgets('cold share is retained before routing and opens after startup',
      (tester) async {
    pending.add(const SharedNotePayload(
            id: sharedId, title: 'Recipe', text: 'https://example.com')
        .toMap());
    // Construct the serial import queue in the same real async zone that runs
    // startup. Queues created in setUp can retain unpumped real microtasks.
    await tester.runAsync(() async {
      launch.configure(SharedNoteImport(journal: journal, notes: notes));
      await launch.recoverInbox();
    });
    expect(notes.saved.length, 1);
    expect(pending, isEmpty);
    final router = _ShareRouter(onboarding: true);
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      router.dispose();
    });
    await tester.pumpWidget(MaterialApp.router(routerConfig: router.config()));
    await tester.pumpAndSettle();
    launch.attach(router);
    await launch.init();
    await tester.pumpAndSettle();
    expect(router.stackData.map((route) => route.name),
        [HomeRoute.name, AddUpdateNoteRoute.name]);
    expect(
        find.byKey(const ValueKey('editor-share-$sharedId')), findsOneWidget);
    expect(OnboardingSettings.instance.completed, isTrue);
  });

  testWidgets('warm share refreshes library and preserves the active draft',
      (tester) async {
    // Foreground imports are driven by pumped frames, so their serial queue
    // must be constructed inside this widget test's FakeAsync zone.
    launch.configure(SharedNoteImport(journal: journal, notes: notes));
    OnboardingSettings.instance.completed = true;
    final router = _ShareRouter();
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      router.dispose();
    });
    await tester.pumpWidget(MaterialApp.router(routerConfig: router.config()));
    await tester.pumpAndSettle();
    router.push(AddUpdateNoteRoute(note: Note(id: 'active-draft')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Keep my unfinished text');
    final original = tester.element(find.byType(TextField));
    var refreshed = 0;
    launch.attach(router, onImported: () => refreshed++);
    await launch.init();
    await tester.pumpAndSettle();
    pending.add(const SharedNotePayload(id: sharedId, title: 'Shared').toMap());
    await messenger.handlePlatformMessage(
      channel.name,
      const StandardMethodCodec()
          .encodeMethodCall(const MethodCall('inboxChanged')),
      (_) {},
    );
    await tester.pumpAndSettle();
    expect(router.stackData.length, 3);
    expect(refreshed, 1);
    expect(
        find.byKey(const ValueKey('editor-share-$sharedId')), findsOneWidget);
    // A duplicate native delivery acknowledges the same note without opening
    // another editor or reverting the original import.
    pending.add(const SharedNotePayload(id: sharedId, title: 'Shared').toMap());
    launch.refresh();
    await tester.pumpAndSettle();
    expect(router.stackData.length, 3);
    expect(notes.writes, 1);
    await router.maybePop();
    await tester.pumpAndSettle();
    expect(find.text('Keep my unfinished text'), findsOneWidget);
    expect(tester.element(find.byType(TextField)), same(original));
  });

  testWidgets('failed import reports retry and native ownership is retained',
      (tester) async {
    launch.configure(SharedNoteImport(journal: journal, notes: notes));
    OnboardingSettings.instance.completed = true;
    final router = _ShareRouter();
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      router.dispose();
    });
    await tester.pumpWidget(MaterialApp.router(routerConfig: router.config()));
    await tester.pumpAndSettle();
    var failures = 0;
    notes.failSave = true;
    pending
        .add(const SharedNotePayload(id: sharedId, text: 'Important').toMap());
    launch.attach(router, onFailure: () => failures++);
    await launch.init();
    await tester.pumpAndSettle();
    expect(failures, greaterThanOrEqualTo(1));
    expect(pending.length, 1);
    expect(journal.keys, isNotEmpty);
    expect(router.stackData.length, 1);
    notes.failSave = false;
    launch.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(notes.saved.length, 1);
    expect(pending, isEmpty);
    expect(router.current.name, AddUpdateNoteRoute.name);
  });
}
