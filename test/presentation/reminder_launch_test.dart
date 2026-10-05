import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/Tools/onboarding_settings.dart';
import 'package:onlynote/Tools/reminder.dart';
import 'package:onlynote/Tools/reminder_launch.dart';
import 'package:onlynote/data/dto/note_dto.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/domain/repository/note_repository.dart';
import 'package:onlynote/presentation/routes/routes.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MemoryNotes implements NoteRepository {
  _MemoryNotes(Iterable<NoteDto> notes)
      : _notes = {for (final note in notes) note.id!: note};

  final Map<String, NoteDto> _notes;

  @override
  Future<NoteDto> getNote(String id) async => _notes[id]!;

  @override
  List<NoteDto> getAllNotes() => _notes.values.toList();

  @override
  Future<void> addUpdateNote(NoteDto note) async {
    _notes[note.id!] = note;
  }

  @override
  Future<void> deleteNote(String id) async {
    _notes.remove(id);
  }

  @override
  Future<void> deleteMultiNotes(List<String> ids) async {
    for (final id in ids) {
      _notes.remove(id);
    }
  }
}

class _ReminderRouter extends RootStackRouter {
  _ReminderRouter({this.startWithOnboarding = false});

  final bool startWithOnboarding;

  @override
  List<AutoRoute> get routes => [
        AutoRoute(
          initial: startWithOnboarding,
          page: PageInfo(
            OnboardingRoute.name,
            builder: (_) => const Scaffold(body: Text('Welcome')),
          ),
        ),
        AutoRoute(
          initial: !startWithOnboarding,
          page: PageInfo(
            HomeRoute.name,
            builder: (_) => const Scaffold(body: Text('Library')),
          ),
        ),
        AutoRoute(
          path: '/notes/:noteId',
          page: PageInfo(
            NoteDetailRoute.name,
            builder: (data) {
              final args = data.argsAs<NoteDetailRouteArgs>();
              return Scaffold(
                key: args.key,
                body: Text('Detail ${args.noteId}'),
              );
            },
          ),
        ),
        AutoRoute(
          path: '/add-update-note',
          page: PageInfo(
            AddUpdateNoteRoute.name,
            builder: (data) {
              final args = data.argsAs<AddUpdateNoteRouteArgs>();
              return Scaffold(body: Text('Editing ${args.note?.id}'));
            },
          ),
        ),
      ];
}

NotificationResponse _tap({String? payload, int? id}) => NotificationResponse(
      notificationResponseType: NotificationResponseType.selectedNotification,
      payload: payload,
      id: id,
    );

List<String> _stack(_ReminderRouter router) =>
    router.stackData.map((route) => route.name).toList();

Future<void> _pumpRouter(WidgetTester tester, _ReminderRouter router) async {
  await tester.pumpWidget(MaterialApp.router(routerConfig: router.config()));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await OnboardingSettings.instance.load();
  });

  tearDown(() => OnboardingSettings.instance.completed = false);

  testWidgets('cold reminder waits for router and completes onboarding',
      (tester) async {
    final launch = ReminderLaunch();
    final router = _ReminderRouter(startWithOnboarding: true);
    final notes = _MemoryNotes([NoteDto(id: 'first', title: 'First')]);
    addTearDown(() async {
      launch.detach();
      await tester.pumpWidget(const SizedBox.shrink());
      router.dispose();
    });

    launch.handleNotificationResponse(_tap(payload: 'first'));
    await _pumpRouter(tester, router);
    expect(_stack(router), [OnboardingRoute.name]);

    launch.attach(router: router, notes: notes, reminders: () => []);
    await tester.pump();
    await tester.pumpAndSettle();

    expect(_stack(router), [HomeRoute.name, NoteDetailRoute.name]);
    expect(find.text('Detail first'), findsOneWidget);
    expect(OnboardingSettings.instance.completed, isTrue);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('onboarding_completed'), isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('warm reminder switches details without stacking or reopening',
      (tester) async {
    final launch = ReminderLaunch();
    final router = _ReminderRouter();
    final notes = _MemoryNotes([
      NoteDto(id: 'first', title: 'First'),
      NoteDto(id: 'second', title: 'Second'),
    ]);
    addTearDown(() async {
      launch.detach();
      await tester.pumpWidget(const SizedBox.shrink());
      router.dispose();
    });

    OnboardingSettings.instance.completed = true;
    await _pumpRouter(tester, router);
    launch.attach(router: router, notes: notes, reminders: () => []);

    launch.handleNotificationResponse(_tap(payload: 'first'));
    await tester.pumpAndSettle();
    expect(_stack(router), [HomeRoute.name, NoteDetailRoute.name]);
    expect(find.text('Detail first'), findsOneWidget);

    launch.handleNotificationResponse(_tap(payload: 'second'));
    await tester.pumpAndSettle();
    expect(_stack(router), [HomeRoute.name, NoteDetailRoute.name]);
    expect(find.text('Detail second'), findsOneWidget);
    final activeDetail = tester.element(find.text('Detail second'));

    launch.handleNotificationResponse(_tap(payload: 'second'));
    await tester.pumpAndSettle();
    expect(_stack(router), [HomeRoute.name, NoteDetailRoute.name]);
    expect(tester.element(find.text('Detail second')), same(activeDetail));

    showDialog<void>(
      context: activeDetail,
      builder: (_) => const AlertDialog(content: Text('Open dialog')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Open dialog'), findsOneWidget);

    launch.handleNotificationResponse(_tap(payload: 'second'));
    await tester.pumpAndSettle();
    expect(find.text('Open dialog'), findsNothing);
    expect(_stack(router), [HomeRoute.name, NoteDetailRoute.name]);
    expect(tester.element(find.text('Detail second')), same(activeDetail));

    router.push(AddUpdateNoteRoute(note: Note(id: 'second')));
    await tester.pumpAndSettle();
    expect(_stack(router),
        [HomeRoute.name, NoteDetailRoute.name, AddUpdateNoteRoute.name]);
    final activeEditor = tester.element(find.text('Editing second'));

    launch.handleNotificationResponse(_tap(payload: 'second'));
    await tester.pumpAndSettle();
    expect(_stack(router),
        [HomeRoute.name, NoteDetailRoute.name, AddUpdateNoteRoute.name]);
    expect(tester.element(find.text('Editing second')), same(activeEditor));

    launch.handleNotificationResponse(_tap(payload: 'first'));
    await tester.pumpAndSettle();
    expect(_stack(router), [
      HomeRoute.name,
      NoteDetailRoute.name,
      AddUpdateNoteRoute.name,
      NoteDetailRoute.name,
    ]);
    expect(find.text('Detail first'), findsOneWidget);
    await router.maybePop();
    await tester.pumpAndSettle();
    expect(_stack(router),
        [HomeRoute.name, NoteDetailRoute.name, AddUpdateNoteRoute.name]);
    expect(tester.element(find.text('Editing second')), same(activeEditor));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'legacy ID resolves a note while missing and trashed targets are ignored',
      (tester) async {
    final launch = ReminderLaunch();
    final router = _ReminderRouter();
    final notes = _MemoryNotes([
      NoteDto(id: 'legacy', title: 'Legacy'),
      NoteDto(
        id: 'trashed',
        title: 'Trashed',
        deletedAt: DateTime(2026, 1, 1).toIso8601String(),
      ),
    ]);
    final reminders = [
      Reminder(
        reminderId: 42,
        noteId: 'legacy',
        reminderDate: DateTime(2026, 1, 2),
      ),
    ];
    addTearDown(() async {
      launch.detach();
      await tester.pumpWidget(const SizedBox.shrink());
      router.dispose();
    });

    OnboardingSettings.instance.completed = true;
    await _pumpRouter(tester, router);
    launch.attach(router: router, notes: notes, reminders: () => reminders);

    launch.handleNotificationResponse(_tap(id: 42));
    await tester.pumpAndSettle();
    expect(find.text('Detail legacy'), findsOneWidget);
    final activeDetail = tester.element(find.text('Detail legacy'));

    for (final response in [
      _tap(payload: '', id: 42),
      _tap(payload: 'missing'),
      _tap(payload: 'trashed'),
      _tap(id: 999),
    ]) {
      launch.handleNotificationResponse(response);
      await tester.pumpAndSettle();
      expect(_stack(router), [HomeRoute.name, NoteDetailRoute.name]);
      expect(tester.element(find.text('Detail legacy')), same(activeDetail));
    }
    expect(tester.takeException(), isNull);
  });
}
