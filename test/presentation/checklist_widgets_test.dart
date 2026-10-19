import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/Tools/app_checklist_settings.dart';
import 'package:onlynote/Tools/app_typography_settings.dart';
import 'package:onlynote/data/dto/note_dto.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/domain/repository/note_repository.dart';
import 'package:onlynote/domain/usecase/add_note_usecase.dart';
import 'package:onlynote/domain/usecase/update_note_usecase.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/note_checklist.dart';
import 'package:onlynote/presentation/screens/add_update_note/add_update_note_screen.dart';
import 'package:onlynote/presentation/screens/add_update_note/bloc/add_update_bloc.dart';
import 'package:onlynote/presentation/theme/theme.dart';
import 'package:onlynote/services/note_autosave.dart';

class _Notes implements NoteRepository {
  final notes = <String, NoteDto>{};
  @override
  Future<void> addUpdateNote(NoteDto note) async => notes[note.id!] = note;
  @override
  Future<void> deleteNote(String id) async => notes.remove(id);
  @override
  Future<void> deleteMultiNotes(List<String> ids) async {
    for (final id in ids) {
      notes.remove(id);
    }
  }

  @override
  List<NoteDto> getAllNotes() => notes.values.toList();
  @override
  Future<NoteDto> getNote(String id) async => notes[id]!;
}

class _Store implements NoteAutosaveStore {
  Note? saved;
  @override
  Future<void> writeDraft(Note note) async {}
  @override
  Future<void> removeDraft(String id) async {}
  @override
  Future<void> saveNote(Note note) async => saved = note;
}

Widget _app(Widget home) => MaterialApp(
      theme: AppTheme.light,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate
      ],
      home: home,
    );

Finder _todoFields() => find.byWidgetPredicate((widget) =>
    widget is TextField &&
    widget.key is ValueKey<String> &&
    (widget.key as ValueKey<String>).value.startsWith('todo-field-'));

void main() {
  late AppChecklistSettings checklistSettings;
  setUp(() {
    checklistSettings = AppChecklistSettings.memory();
    addTearDown(checklistSettings.dispose);
    final fonts = Map<String, GoogleFontBuilder>.of(kAppFontFamilies);
    for (final family in fonts.keys) {
      kAppFontFamilies[family] = (
              {textStyle, color, fontSize, fontWeight, fontStyle}) =>
          (textStyle ?? const TextStyle()).copyWith(
              color: color,
              fontSize: fontSize,
              fontWeight: fontWeight,
              fontStyle: fontStyle);
    }
    addTearDown(() => kAppFontFamilies.addAll(fonts));
  });

  Future<_Store> editor(WidgetTester tester, List<Todo> todos) async {
    final repository = _Notes();
    final store = _Store();
    final bloc = AddUpdateBloc(
        AddNoteUsecase(repository), UpdateNoteUsecase(repository));
    addTearDown(bloc.close);
    await tester.pumpWidget(_app(BlocProvider.value(
        value: bloc,
        child: AddUpdateNoteScreen(
            note: Note(id: 'note', title: 'Shopping', todo: todos),
            autosaveStore: store))));
    await tester.pumpAndSettle();
    return store;
  }

  Future<void> openMoveActions(WidgetTester tester, String id) async {
    final handle = find.byKey(ValueKey('todo-reorder-$id'));
    await tester.ensureVisible(handle);
    await tester.pumpAndSettle();
    await tester.tap(handle);
    await tester.pumpAndSettle();
  }

  testWidgets('tapping a checklist handle moves its row up or down and saves',
      (tester) async {
    final store = await editor(tester, [
      Todo(id: 'a', title: 'Milk'),
      Todo(id: 'b', title: 'Eggs', completed: true),
      Todo(id: 'c', title: 'Bread'),
    ]);
    await openMoveActions(tester, 'b');
    expect(find.text(S.current.Move_Up), findsOneWidget);
    expect(find.text(S.current.Move_Down), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('todo-move-up')));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(store.saved!.todo.map((todo) => todo.id), ['b', 'a', 'c']);
    expect(store.saved!.todo.first.completed, isTrue);
    expect(
        tester
            .widgetList<TextField>(_todoFields())
            .map((field) => field.controller!.text),
        ['Eggs', 'Milk', 'Bread']);

    await openMoveActions(tester, 'b');
    await tester.tap(find.byKey(const ValueKey('todo-move-down')));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(store.saved!.todo.map((todo) => todo.id), ['a', 'b', 'c']);
    expect(store.saved!.todo[1].completed, isTrue);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });

  testWidgets('checklist move actions disable the first and last boundaries',
      (tester) async {
    await editor(tester, [
      Todo(id: 'a', title: 'Milk'),
      Todo(id: 'b', title: 'Eggs'),
    ]);
    await openMoveActions(tester, 'a');
    expect(
        tester
            .widget<ListTile>(find.byKey(const ValueKey('todo-move-up')))
            .enabled,
        isFalse);
    expect(
        tester
            .widget<ListTile>(find.byKey(const ValueKey('todo-move-down')))
            .enabled,
        isTrue);
    await tester.tap(find.byKey(const ValueKey('todo-move-up')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('todo-move-up')), findsOneWidget);
    await tester.tap(find.text(S.current.Cancel));
    await tester.pumpAndSettle();
    await openMoveActions(tester, 'b');
    expect(
        tester
            .widget<ListTile>(find.byKey(const ValueKey('todo-move-up')))
            .enabled,
        isTrue);
    expect(
        tester
            .widget<ListTile>(find.byKey(const ValueKey('todo-move-down')))
            .enabled,
        isFalse);
    await tester.tap(find.text(S.current.Cancel));
    await tester.pumpAndSettle();
    expect(
        tester
            .widgetList<TextField>(_todoFields())
            .map((field) => field.controller!.text),
        ['Milk', 'Eggs']);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });

  testWidgets('holding and dragging a checklist handle still reorders rows',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 1000);
    addTearDown(tester.view.reset);
    final store = await editor(tester, [
      Todo(id: 'a', title: 'Milk'),
      Todo(id: 'b', title: 'Eggs'),
      Todo(id: 'c', title: 'Bread'),
    ]);
    final firstHandle = find.byKey(const ValueKey('todo-reorder-a'));
    final lastHandle = find.byKey(const ValueKey('todo-reorder-c'));
    await tester.ensureVisible(lastHandle);
    await tester.pumpAndSettle();
    await tester.ensureVisible(firstHandle);
    await tester.pumpAndSettle();
    final start = tester.getCenter(firstHandle);
    final lastRow = tester.getRect(lastHandle);
    final drag = await tester.startGesture(start);
    await tester.pump(const Duration(milliseconds: 600));
    await drag.moveBy(const Offset(0, 20));
    await tester.pump(const Duration(milliseconds: 300));
    // Start recognition consumes the first movement. Move the whole row past
    // the last row, rather than stopping the pointer near its handle center.
    await drag.moveTo(Offset(start.dx, lastRow.bottom + lastRow.height));
    await tester.pump(const Duration(milliseconds: 500));
    await drag.up();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('todo-move-up')), findsNothing);
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(store.saved!.todo.map((todo) => todo.id), ['b', 'c', 'a']);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });

  testWidgets('moving a newly added row preserves its text selection and focus',
      (tester) async {
    final store = await editor(tester, [
      Todo(id: 'a', title: 'Milk'),
      Todo(id: 'b', title: 'Eggs'),
    ]);
    await tester.tap(find.byKey(const ValueKey('todo-field-b')));
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pumpAndSettle();
    final newField = tester.widget<TextField>(_todoFields().last);
    final newId = (newField.key as ValueKey<String>)
        .value
        .substring('todo-field-'.length);
    expect(newField.focusNode!.hasFocus, isTrue);
    await tester.enterText(_todoFields().last, 'Bread');
    newField.controller!.selection = const TextSelection.collapsed(offset: 2);
    await openMoveActions(tester, newId);
    await tester.tap(find.byKey(const ValueKey('todo-move-up')));
    await tester.pumpAndSettle();
    final moved =
        tester.widget<TextField>(find.byKey(ValueKey('todo-field-$newId')));
    expect(moved.controller!.text, 'Bread');
    expect(
        moved.controller!.selection, const TextSelection.collapsed(offset: 2));
    expect(moved.focusNode!.hasFocus, isTrue);
    expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('todo-field-a')))
            .focusNode!
            .hasFocus,
        isFalse);
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(
        store.saved!.todo.map((todo) => todo.title), ['Milk', 'Bread', 'Eggs']);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });

  testWidgets(
      'editor checkboxes save completion and Return inserts and focuses the next row',
      (tester) async {
    final store = await editor(
        tester, [Todo(id: 'a', title: 'Milk'), Todo(id: 'b', title: 'Eggs')]);
    await tester.tap(find.byKey(const ValueKey('todo-check-a')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(store.saved!.todo.first.completed, isTrue);
    expect(store.saved!.todo.map((todo) => todo.id), ['a', 'b']);

    await tester.tap(_todoFields().first);
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pumpAndSettle();
    final fields = tester.widgetList<TextField>(_todoFields()).toList();
    expect(fields.map((field) => field.controller!.text), ['Milk', '', 'Eggs']);
    expect(fields[1].focusNode!.hasFocus, isTrue);
    await tester.enterText(_todoFields().at(1), 'Bread');
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(
        store.saved!.todo.map((todo) => todo.title), ['Milk', 'Bread', 'Eggs']);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });

  testWidgets('Return reuses a blank next row and stops on an empty row',
      (tester) async {
    await editor(
        tester, [Todo(id: 'a', title: 'Milk'), Todo(id: 'b', title: '')]);
    await tester.tap(_todoFields().first);
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pumpAndSettle();
    expect(_todoFields(), findsNWidgets(2));
    expect(tester.widget<TextField>(_todoFields().last).focusNode!.hasFocus,
        isTrue);
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pumpAndSettle();
    expect(_todoFields(), findsNWidgets(2));
    expect(tester.widget<TextField>(_todoFields().last).focusNode!.hasFocus,
        isFalse);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });

  testWidgets(
      'a hardware-style newline creates the next row after entering a fresh item',
      (tester) async {
    final store = await editor(tester, [Todo(id: 'a', title: '')]);
    await tester.enterText(_todoFields().first, 'Milk\n');
    await tester.pumpAndSettle();
    final fields = tester.widgetList<TextField>(_todoFields()).toList();
    expect(fields.map((field) => field.controller!.text), ['Milk', '']);
    expect(fields.last.focusNode!.hasFocus, isTrue);
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(store.saved!.todo.first.title, 'Milk');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });

  testWidgets(
      'multiline paste makes separate items without cutting the entire clipboard to 100 characters',
      (tester) async {
    final store = await editor(
        tester, [Todo(id: 'a', title: ''), Todo(id: 'b', title: 'Last')]);
    final longItem = List.filled(90, 'a').join();
    await tester.enterText(_todoFields().first, '$longItem\nEggs\n\nBread');
    await tester.pumpAndSettle();
    final fields = tester.widgetList<TextField>(_todoFields()).toList();
    expect(fields.map((field) => field.controller!.text),
        [longItem, 'Eggs', 'Bread', 'Last']);
    expect(fields[2].focusNode!.hasFocus, isTrue);
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(store.saved!.todo.map((todo) => todo.title),
        [longItem, 'Eggs', 'Bread', 'Last']);
    expect(store.saved!.todo.map((todo) => todo.id).toSet().length, 4);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });

  testWidgets(
      'reader reports progress, collapses completed items and keeps reset available',
      (tester) async {
    var todos = [
      Todo(id: 'a', title: 'Milk'),
      Todo(id: 'b', title: 'Eggs', completed: true)
    ];
    var resets = 0;
    await tester.pumpWidget(_app(Scaffold(
        body: StatefulBuilder(
            builder: (context, setState) => Padding(
                padding: const EdgeInsets.all(16),
                child: NoteChecklist(
                    settings: checklistSettings,
                    todos: todos,
                    onToggle: (id) => setState(() => todos = [
                          for (final todo in todos)
                            todo.id == id
                                ? todo.copyWith(completed: !todo.completed)
                                : todo
                        ]),
                    onReset: () => resets++))))));
    await tester.pumpAndSettle();
    expect(find.text('1 of 2 complete'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('checklist-completed-toggle')));
    await tester.pumpAndSettle();
    expect(find.text('Eggs'), findsNothing);
    expect(find.text('Milk'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('checklist-item-a')));
    await tester.pumpAndSettle();
    expect(find.text('2 of 2 complete'), findsOneWidget);
    expect(find.text('All done'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('checklist-reset')));
    expect(resets, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'image export expands hidden items and removes interactive controls',
      (tester) async {
    var exportMode = false;
    await tester.pumpWidget(_app(Scaffold(
        body: StatefulBuilder(
            builder: (context, setState) => Column(children: [
                  TextButton(
                      onPressed: () => setState(() => exportMode = true),
                      child: const Text('Export')),
                  NoteChecklist(
                      settings: checklistSettings,
                      todos: [
                        Todo(id: 'a', title: 'Milk'),
                        Todo(id: 'b', title: 'Eggs', completed: true)
                      ],
                      exportMode: exportMode,
                      onToggle: (_) {},
                      onReset: () {}),
                ])))));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('checklist-completed-toggle')));
    await tester.pumpAndSettle();
    expect(find.text('Eggs'), findsNothing);
    await tester.tap(find.text('Export'));
    await tester.pump();
    expect(find.text('Eggs'), findsOneWidget);
    expect(find.text('Milk'), findsOneWidget);
    expect(find.byKey(const ValueKey('checklist-reset')), findsNothing);
    expect(
        find.byKey(const ValueKey('checklist-completed-toggle')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'read-only reader fits large text, exposes full titles and honors reduced motion',
      (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    var toggles = 0;
    var resets = 0;
    const title = 'Buy bread, milk and fresh vegetables for dinner';
    await tester.pumpWidget(_app(Scaffold(
        body: MediaQuery(
            data: const MediaQueryData(
                textScaler: TextScaler.linear(2), disableAnimations: true),
            child: SingleChildScrollView(
                child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: NoteChecklist(
                        settings: checklistSettings,
                        todos: [Todo(id: 'a', title: title, completed: true)],
                        readOnly: true,
                        onToggle: (_) => toggles++,
                        onReset: () => resets++)))))));
    await tester.pumpAndSettle();
    expect(find.text(title), findsOneWidget);
    expect(find.byKey(const ValueKey('checklist-reset')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('checklist-item-a')));
    await tester.pump();
    expect(toggles, 0);
    expect(resets, 0);
    expect(find.byType(AnimatedSize), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
