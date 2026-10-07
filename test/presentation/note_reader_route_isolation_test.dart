import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:onlynote/Tools/app_typography_settings.dart';
import 'package:onlynote/Tools/locator.dart';
import 'package:onlynote/data/dto/note_dto.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/domain/repository/note_repository.dart';
import 'package:onlynote/domain/usecase/get_note_usecase.dart';
import 'package:onlynote/domain/usecase/update_note_usecase.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/note_info_sheet.dart';
import 'package:onlynote/presentation/routes/routes.dart';
import 'package:onlynote/presentation/screens/note_detail/bloc/detail/note_detail_bloc.dart';
import 'package:onlynote/presentation/screens/note_detail/note_detail_screen.dart';
import 'package:onlynote/presentation/theme/theme.dart';
import 'package:onlynote/services/note_position_store.dart';
import 'package:onlynote/services/note_statistics.dart';

class _Notes implements NoteRepository {
  _Notes(Iterable<Note> initial)
      : values = {for (final note in initial) note.id!: NoteDto.fromNote(note)};
  final Map<String, NoteDto> values;
  final writes = <String>[];
  Future<NoteDto> Function(String)? readOverride;
  @override
  Future<NoteDto> getNote(String id) async =>
      readOverride == null ? values[id]! : await readOverride!(id);
  @override
  List<NoteDto> getAllNotes() => values.values.toList();
  @override
  Future<void> addUpdateNote(NoteDto note) async {
    writes.add(note.id!);
    values[note.id!] = note;
  }

  @override
  Future<void> deleteNote(String id) async => values.remove(id);
  @override
  Future<void> deleteMultiNotes(List<String> ids) async {
    for (final id in ids) {
      values.remove(id);
    }
  }
}

class _Router extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
        AutoRoute(
            initial: true,
            page: PageInfo(HomeRoute.name,
                builder: (_) => const Scaffold(body: Text('Library')))),
        AutoRoute(path: '/notes/:noteId', page: NoteDetailRoute.page),
        AutoRoute(
            page: PageInfo(AddUpdateNoteRoute.name,
                builder: (data) => Scaffold(
                    body: Text(
                        'Editing ${data.argsAs<AddUpdateNoteRouteArgs>().note!.id}')))),
      ];
}

Future<_Router> _mount(WidgetTester tester, _Notes notes,
    {double width = 390}) async {
  tester.view.physicalSize = Size(width, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final root = NoteDetailBloc(GetNoteUsecase(notes), UpdateNoteUsecase(notes));
  final router = _Router();
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    router.dispose();
    await root.close();
  });
  await tester.pumpWidget(BlocProvider.value(
    value: root,
    child: MaterialApp.router(
      routerConfig: router.config(),
      theme: AppTheme.light,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: true),
        child: child!,
      ),
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: S.delegate.supportedLocales,
    ),
  ));
  await tester.pumpAndSettle();
  return router;
}

LoadedView _loaded(WidgetTester tester) =>
    tester.widget<LoadedView>(find.byType(LoadedView));

NoteDetailBloc _bloc(WidgetTester tester) =>
    tester.element(find.byType(LoadedView)).read<NoteDetailBloc>();

Future<void> _push(WidgetTester tester, _Router router, String id,
    NotePositionStore positions) async {
  unawaited(
      router.push<void>(NoteDetailRoute(noteId: id, positionStore: positions)));
  await tester.pumpAndSettle();
}

void main() {
  final fonts = Map<String, GoogleFontBuilder>.of(kAppFontFamilies);
  setUpAll(() async {
    await initializeDateFormatting();
    if (!locator.isRegistered<S>()) locator.registerSingleton(S());
  });
  setUp(() {
    for (final family in fonts.keys) {
      kAppFontFamilies[family] = (
              {textStyle, color, fontSize, fontWeight, fontStyle}) =>
          (textStyle ?? const TextStyle()).copyWith(
              color: color,
              fontSize: fontSize,
              fontWeight: fontWeight,
              fontStyle: fontStyle);
    }
  });
  tearDown(() => kAppFontFamilies.addAll(fonts));

  testWidgets('stacked readers retain their own content, info and position',
      (tester) async {
    final a = Note(
        id: 'a',
        title: 'Original reading project',
        description: 'A recognizable paragraph with project details.\n' * 70,
        dateTime: DateTime(2026, 10, 7));
    final b = Note(
        id: 'b',
        title: 'Other note',
        description: 'This is separate saved content.',
        dateTime: DateTime(2026, 10, 7));
    final notes = _Notes([a, b]);
    final positions = NotePositionStore.memory();
    final router = await _mount(tester, notes);
    await _push(tester, router, 'a', positions);
    final aBloc = _bloc(tester);
    final aView = _loaded(tester);
    final reminderAnimation = tester.widget<AnimatedSwitcher>(find.descendant(
        of: find.byTooltip(S.current.Reminder),
        matching: find.byType(AnimatedSwitcher)));
    expect(reminderAnimation.duration, Duration.zero);
    aView.scrollController!.jumpTo(1400);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    final aPosition = (await positions.read('a')).reading!;
    final aPixels = aView.scrollController!.offset;
    expect(aPosition.resolve(a.description!), greaterThan(0));

    await _push(tester, router, 'b', positions);
    expect(_loaded(tester).note.id, 'b');
    expect(identical(aBloc, _bloc(tester)), isFalse);
    expect(aBloc.state.whenOrNull(success: (note) => note.id), 'a');
    expect(aBloc.state.whenOrNull(success: (note) => note.description),
        a.description);
    expect((await positions.read('a')).reading!.resolve(a.description!),
        aPosition.resolve(a.description!));
    await tester.tap(find.byTooltip(S.current.More_Options));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text(S.current.Note_Info));
    await tester.tap(find.text(S.current.Note_Info));
    await tester.pumpAndSettle();
    final info = tester.widget<NoteInfoSheet>(find.byType(NoteInfoSheet));
    expect(info.statistics.wordCount, NoteStatistics.fromNote(b).wordCount);
    Navigator.of(tester.element(find.byType(NoteInfoSheet))).pop();
    await tester.pumpAndSettle();
    await router.maybePop();
    await tester.pumpAndSettle();

    expect(_loaded(tester).note.id, 'a');
    expect(_loaded(tester).note.description, a.description);
    expect(_bloc(tester), same(aBloc));
    expect(_loaded(tester).scrollController!.offset, closeTo(aPixels, 1));
    expect((await positions.read('b')).reading!.resolve(b.description!), 0);
    expect(notes.writes, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('checkbox changes in reader B never update hidden reader A',
      (tester) async {
    final a = Note(
        id: 'a',
        title: 'Note A',
        description: 'Original body A',
        todo: [Todo(id: 'same-row-id', title: 'A task')]);
    final b = Note(
        id: 'b',
        title: 'Note B',
        description: 'Original body B',
        todo: [Todo(id: 'same-row-id', title: 'B task')]);
    final notes = _Notes([a, b]);
    final positions = NotePositionStore.memory();
    final router = await _mount(tester, notes);
    await _push(tester, router, 'a', positions);
    final aBloc = _bloc(tester);
    await _push(tester, router, 'b', positions);
    _bloc(tester).add(const NoteDetailEvent.toggleTodoCheckbox('same-row-id'));
    await tester.pumpAndSettle();
    expect(_loaded(tester).note.id, 'b');
    expect(_loaded(tester).note.todo.single.completed, isTrue);
    expect(notes.values['b']!.toDomain().todo.single.completed, isTrue);
    expect(notes.values['a']!.toDomain().todo.single.completed, isFalse);
    expect(
        aBloc.state.whenOrNull(success: (note) => note.todo.single.completed),
        isFalse);
    await router.maybePop();
    await tester.pumpAndSettle();
    expect(_loaded(tester).note.id, 'a');
    expect(_loaded(tester).note.description, 'Original body A');
    expect(_loaded(tester).note.todo.single.completed, isFalse);
    expect(notes.writes, ['b']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a delayed hidden reader load cannot replace the visible note',
      (tester) async {
    final a = Note(id: 'a', title: 'Delayed note', description: 'Body A');
    final b = Note(id: 'b', title: 'Visible note', description: 'Body B');
    final loadA = Completer<NoteDto>();
    final notes = _Notes([a, b]);
    notes.readOverride =
        (id) async => id == 'a' ? await loadA.future : notes.values[id]!;
    final positions = NotePositionStore.memory();
    final router = await _mount(tester, notes);
    await _push(tester, router, 'a', positions);
    final aBloc =
        tester.element(find.byType(NoteDetailScreen)).read<NoteDetailBloc>();
    expect(find.byType(LoadedView), findsNothing);
    await _push(tester, router, 'b', positions);
    expect(_loaded(tester).note.id, 'b');

    loadA.complete(notes.values['a']);
    await tester.pumpAndSettle();
    expect(_loaded(tester).note.description, 'Body B');
    expect(
        aBloc.state.whenOrNull(success: (note) => note.description), 'Body A');
    await router.maybePop();
    await tester.pumpAndSettle();
    expect(_loaded(tester).note.id, 'a');
    expect(_loaded(tester).note.description, 'Body A');
    expect(notes.writes, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('narrow reader keeps primary actions reachable through More',
      (tester) async {
    final note = Note(id: 'narrow', title: 'Tea', description: 'Remember milk');
    final notes = _Notes([note]);
    final positions = NotePositionStore.memory();
    final router = await _mount(tester, notes, width: 180);
    await _push(tester, router, 'narrow', positions);
    expect(find.byTooltip(S.current.More_Options), findsOneWidget);
    expect(find.byTooltip(S.current.Edit), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byTooltip(S.current.More_Options));
    await tester.pumpAndSettle();
    expect(find.text(S.current.Reminder), findsOneWidget);
    expect(find.text(S.current.Share), findsOneWidget);
    expect(find.text(S.current.Edit), findsOneWidget);
    await tester.ensureVisible(find.text(S.current.Edit));
    await tester.tap(find.text(S.current.Edit));
    await tester.pumpAndSettle();
    expect(find.text('Editing narrow'), findsOneWidget);
    await router.maybePop();
    await tester.pumpAndSettle();
    expect(_loaded(tester).note.description, 'Remember milk');
    expect(notes.writes, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('narrow trash reader keeps share and deletion actions accessible',
      (tester) async {
    final note = Note(
        id: 'trash',
        title: 'Old note',
        description: 'Body',
        deletedAt: DateTime(2026, 10, 7));
    final notes = _Notes([note]);
    final router = await _mount(tester, notes, width: 180);
    await _push(tester, router, 'trash', NotePositionStore.memory());
    expect(find.byTooltip(S.current.More_Options), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byTooltip(S.current.More_Options));
    await tester.pumpAndSettle();
    expect(find.text(S.current.Share), findsOneWidget);
    expect(find.text(S.current.Restore), findsOneWidget);
    expect(find.text(S.current.Delete_Forever), findsOneWidget);
    expect(find.text(S.current.Edit), findsNothing);
    await tester.ensureVisible(find.text(S.current.Cancel));
    await tester.tap(find.text(S.current.Cancel));
    await tester.pumpAndSettle();
    expect(_loaded(tester).note.isDeleted, isTrue);
    expect(notes.writes, isEmpty);
    expect(tester.takeException(), isNull);
  });
}
