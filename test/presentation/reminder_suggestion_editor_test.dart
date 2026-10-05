import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/Tools/app_typography_settings.dart';
import 'package:onlynote/Tools/reminder.dart';
import 'package:onlynote/Tools/widget_commands.dart';
import 'package:onlynote/data/dto/note_dto.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/domain/repository/note_repository.dart';
import 'package:onlynote/domain/usecase/add_note_usecase.dart';
import 'package:onlynote/domain/usecase/update_note_usecase.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/reminder_suggestion_chip.dart';
import 'package:onlynote/presentation/screens/add_update_note/add_update_note_screen.dart';
import 'package:onlynote/presentation/screens/add_update_note/bloc/add_update_bloc.dart';
import 'package:onlynote/presentation/theme/theme.dart';
import 'package:onlynote/services/note_autosave.dart';
import 'package:onlynote/services/note_reminder_scheduler.dart';

class _Repository implements NoteRepository {
  final notes = <String, NoteDto>{};
  @override
  Future<void> addUpdateNote(NoteDto note) async => notes[note.id!] = note;
  @override
  Future<void> deleteNote(String id) async => notes.remove(id);
  @override
  Future<void> deleteMultiNotes(List<String> ids) async =>
      ids.forEach(notes.remove);
  @override
  List<NoteDto> getAllNotes() => notes.values.toList();
  @override
  Future<NoteDto> getNote(String id) async => notes[id]!;
}

class _Store implements NoteAutosaveStore {
  _Store(this.repository);
  final _Repository repository;
  bool fail = false;
  @override
  Future<void> writeDraft(Note note) async {}
  @override
  Future<void> removeDraft(String id) async {}
  @override
  Future<void> saveNote(Note note) async {
    if (fail) throw StateError('Disk full');
    await repository.addUpdateNote(NoteDto.fromNote(note));
  }
}

class _Scheduler extends NoteReminderScheduler {
  _Scheduler(this.repository);
  final _Repository repository;
  Reminder? existing;
  int calls = 0;
  Note? scheduledNote;
  DateTime? scheduledDate;
  @override
  Reminder? current(Note note) => existing;
  @override
  Future<NoteReminderSaveResult> save(BuildContext context, Note note,
      DateTime date, ReminderRepeat repeat) async {
    calls++;
    // The callback must see an already durable note, including its last edit.
    expect(repository.notes[note.id]!.description, note.description);
    expect(repository.notes[note.id]!.title, note.title);
    scheduledNote = note;
    scheduledDate = date;
    existing = Reminder(
        noteId: note.id!, reminderId: 1, reminderDate: date, repeat: repeat);
    return NoteReminderSaveResult.saved;
  }
}

Finder _bodyField() => find.byWidgetPredicate(
    (widget) => widget is TextField && widget.maxLines == 100);

void main() {
  final originalFonts = Map<String, GoogleFontBuilder>.of(kAppFontFamilies);
  setUp(() {
    for (final family in originalFonts.keys) {
      kAppFontFamilies[family] = (
              {textStyle, color, fontSize, fontWeight, fontStyle}) =>
          (textStyle ?? const TextStyle()).copyWith(
              color: color,
              fontSize: fontSize,
              fontWeight: fontWeight,
              fontStyle: fontStyle);
    }
  });
  tearDown(() => kAppFontFamilies.addAll(originalFonts));

  Future<void> mount(WidgetTester tester, _Store store, _Scheduler scheduler,
      {Note? note, WidgetCommands? commands}) async {
    final repository = store.repository;
    final bloc = AddUpdateBloc(
        AddNoteUsecase(repository), UpdateNoteUsecase(repository));
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      await bloc.close();
    });
    await tester.pumpWidget(BlocProvider.value(
      value: bloc,
      child: MaterialApp(
        theme: AppTheme.light,
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate
        ],
        home: AddUpdateNoteScreen(
            note: note,
            autosaveStore: store,
            reminderScheduler: scheduler,
            widgetCommands: commands),
      ),
    ));
    await tester.pumpAndSettle();
  }

  Future<void> revealHint(WidgetTester tester) async {
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byType(ReminderSuggestionChip));
    await tester.pumpAndSettle();
  }

  testWidgets('typed hint confirms in picker after flushing unchanged text',
      (tester) async {
    final repository = _Repository();
    final store = _Store(repository);
    final scheduler = _Scheduler(repository);
    await mount(tester, store, scheduler);
    await tester.enterText(
        find.byType(TextField).first, 'Call tomorrow at 9am');
    await tester.enterText(_bodyField(), 'Discuss the trip.');
    await revealHint(tester);
    expect(scheduler.calls, 0);
    await tester.tap(find.textContaining('Remind me:'));
    await tester.pumpAndSettle();
    expect(scheduler.calls, 0);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    await tester.tap(find.text('Use suggested time'));
    await tester.pumpAndSettle();
    expect(scheduler.calls, 1);
    expect(scheduler.scheduledNote!.title, 'Call tomorrow at 9am');
    expect(scheduler.scheduledNote!.description, 'Discuss the trip.');
    expect(scheduler.scheduledDate!.hour, 9);
    expect(find.byType(ReminderSuggestionChip), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('dismissed phrase stays hidden through further typing',
      (tester) async {
    final repository = _Repository();
    await mount(tester, _Store(repository), _Scheduler(repository));
    await tester.enterText(
        find.byType(TextField).first, 'Call tomorrow at 9am');
    await revealHint(tester);
    await tester.tap(find.byTooltip('Dismiss suggestion'));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byType(TextField).first, 'Call tomorrow at 9am about travel');
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.byType(ReminderSuggestionChip), findsNothing);
    await tester.enterText(
        find.byType(TextField).first, 'Call tomorrow at 10am');
    await revealHint(tester);
    expect(find.byType(ReminderSuggestionChip), findsOneWidget);
  });

  testWidgets('current matching reminder is not suggested again',
      (tester) async {
    final repository = _Repository();
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1, 9);
    final note = Note(id: 'existing', title: 'Call tomorrow at 9am');
    repository.notes[note.id!] = NoteDto.fromNote(note);
    final scheduler = _Scheduler(repository)
      ..existing =
          Reminder(noteId: note.id!, reminderId: 7, reminderDate: tomorrow);
    await mount(tester, _Store(repository), scheduler, note: note);
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.byType(ReminderSuggestionChip), findsNothing);
  });

  testWidgets('failed draft save prevents notification scheduling',
      (tester) async {
    final repository = _Repository();
    final store = _Store(repository)..fail = true;
    final scheduler = _Scheduler(repository);
    await mount(tester, store, scheduler);
    await tester.enterText(
        find.byType(TextField).first, 'Call tomorrow at 9am');
    await revealHint(tester);
    await tester.tap(find.textContaining('Remind me:'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Use suggested time'));
    await tester.pumpAndSettle();
    expect(scheduler.calls, 0);
    expect(repository.notes, isEmpty);
    expect(find.byType(ReminderSuggestionChip), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('cancelling suggestion picker leaves reminders unchanged',
      (tester) async {
    final repository = _Repository();
    final scheduler = _Scheduler(repository);
    await mount(tester, _Store(repository), scheduler);
    await tester.enterText(
        find.byType(TextField).first, 'Call tomorrow at 9am');
    await revealHint(tester);
    await tester.tap(find.textContaining('Remind me:'));
    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
    await tester.ensureVisible(find.text('Cancel'));
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(scheduler.calls, 0);
    expect(find.byType(ReminderSuggestionChip), findsOneWidget);
  });

  testWidgets(
      'widget completion merges with active unsaved title and task text',
      (tester) async {
    final repository = _Repository();
    final note = Note(
        id: 'list',
        title: 'Groceries',
        description: 'Keep cold',
        todo: [
          Todo(id: 'milk', title: 'Milk'),
          Todo(id: 'bread', title: 'Bread')
        ]);
    repository.notes[note.id!] = NoteDto.fromNote(note);
    final acknowledged = <String>[];
    final commands = WidgetCommands(
      repository: repository,
      readPending: () async => [
        <String, Object>{
          'id': 'widget-change',
          'noteId': 'list',
          'todoId': 'milk',
          'completed': true,
          'createdAt': 1,
        }
      ],
      acknowledge: (ids) async => acknowledged.addAll(ids),
      readDraft: (_) => null,
      writeDraft: (_) async {},
      removeDraft: (_) async {},
      syncWidgets: () async {},
    );
    await mount(tester, _Store(repository), _Scheduler(repository),
        note: note, commands: commands);
    await tester.enterText(find.byType(TextField).first, 'Weekend groceries');
    await tester.enterText(
        find.byKey(const ValueKey('todo-field-milk')), 'Oat milk');
    final importing = commands.importPending();
    await tester.pumpAndSettle();
    await importing;
    final saved = repository.notes['list']!.toDomain();
    expect(saved.title, 'Weekend groceries');
    expect(saved.description, 'Keep cold');
    expect(saved.todo.map((todo) => todo.id), ['milk', 'bread']);
    expect(saved.todo.first.title, 'Oat milk');
    expect(saved.todo.first.completed, isTrue);
    expect(acknowledged, ['widget-change']);
    expect(find.text('Weekend groceries'), findsOneWidget);
    expect(find.text('Oat milk'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
