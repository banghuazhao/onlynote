import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
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
import 'package:onlynote/presentation/components/note_history_sheet.dart';
import 'package:onlynote/presentation/routes/routes.dart';
import 'package:onlynote/presentation/screens/note_detail/bloc/detail/note_detail_bloc.dart';
import 'package:onlynote/presentation/screens/note_detail/note_detail_screen.dart';
import 'package:onlynote/presentation/theme/theme.dart';
import 'package:onlynote/services/note_position_store.dart';
import 'package:onlynote/services/note_dates.dart';
import 'package:onlynote/services/note_statistics.dart';
import 'package:onlynote/services/note_history.dart';

class _Notes implements NoteRepository {
  _Notes(Iterable<Note> initial)
      : values = {for (final note in initial) note.id!: NoteDto.fromNote(note)};
  final Map<String, NoteDto> values;
  final writes = <String>[];
  final reads = <String, int>{};
  Future<NoteDto> Function(String)? readOverride;
  Future<void> Function(NoteDto)? beforeSave;
  @override
  Future<NoteDto> getNote(String id) async {
    reads.update(id, (count) => count + 1, ifAbsent: () => 1);
    return readOverride == null ? values[id]! : await readOverride!(id);
  }

  @override
  List<NoteDto> getAllNotes() => values.values.toList();
  @override
  Future<void> addUpdateNote(NoteDto note) async {
    await beforeSave?.call(note);
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

class _WaitingPositionStorage extends MemoryNotePositionStorage {
  Completer<void>? waiting;
  int writes = 0;

  @override
  Future<void> write(String key, String value) async {
    writes++;
    await waiting?.future;
    await super.write(key, value);
  }
}

class _HistoryBox extends Fake implements Box {
  final _values = <dynamic, dynamic>{};

  @override
  dynamic get(dynamic key, {dynamic defaultValue}) =>
      _values[key] ?? defaultValue;
  @override
  Future<void> put(dynamic key, dynamic value) async => _values[key] = value;
  @override
  Future<void> flush() async {}
}

Future<_Router> _mount(WidgetTester tester, _Notes notes,
    {double width = 390,
    double textScale = 1,
    Locale locale = const Locale('en')}) async {
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
      locale: locale,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
            disableAnimations: true, textScaler: TextScaler.linear(textScale)),
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

  for (final completion in ['open', 'dismissed', 'reader closed']) {
    testWidgets(
        'successful history restore refreshes once with $completion reader',
        (tester) async {
      final original =
          Note(id: 'a', title: 'Original title', description: 'Original body');
      final current = original.copyWith(
          title: 'Current title', description: 'Current body');
      final notes = _Notes([current]);
      final history = NoteHistory(box: _HistoryBox(), repository: notes);
      final previousHistory = NoteHistory.initializedInstance;
      NoteHistory.configure(history);
      addTearDown(() {
        NoteHistory.initializedInstance = previousHistory;
        history.dispose();
      });
      await history.recordBeforeSave(
          NoteDto.fromNote(original), NoteDto.fromNote(current));
      final version = history.versionsFor('a').single;
      final permitWrite = Completer<void>();
      final started = Completer<void>();
      notes.beforeSave = (_) async {
        started.complete();
        await permitWrite.future;
      };
      final router = await _mount(tester, notes);
      addTearDown(() {
        if (!permitWrite.isCompleted) permitWrite.complete();
      });
      await _push(tester, router, 'a', NotePositionStore.memory());
      await tester.tap(find.byTooltip(S.current.More_Options));
      await tester.pumpAndSettle();
      final historyAction = find.text(S.current.History_Title);
      await tester.ensureVisible(historyAction);
      await tester.tap(historyAction);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ValueKey('history-version-${version.id}')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('history-restore-action')));
      await tester.pump();
      expect(started.isCompleted, isTrue);
      if (completion != 'open') {
        await tester.tap(find.byTooltip('Close'));
        await tester.pumpAndSettle();
        expect(find.byType(NoteHistorySheet), findsNothing);
        expect(_loaded(tester).note.title, 'Current title');
      }
      if (completion == 'reader closed') {
        await router.maybePop();
        await tester.pumpAndSettle();
        expect(find.text('Library'), findsOneWidget);
      }
      final readsBeforeCompletion = notes.reads['a']!;
      permitWrite.complete();
      await tester.pumpAndSettle();
      expect(notes.values['a']!.title, 'Original title');
      expect(notes.writes, ['a']);
      expect(find.byType(NoteHistorySheet), findsNothing);
      if (completion == 'reader closed') {
        expect(notes.reads['a'], readsBeforeCompletion);
        expect(find.text('Library'), findsOneWidget);
        expect(find.byType(LoadedView), findsNothing);
      } else {
        expect(notes.reads['a'], readsBeforeCompletion + 1);
        expect(_loaded(tester).note.title, 'Original title');
        expect(_loaded(tester).note.description, 'Original body');
        expect(router.stack, hasLength(2));
      }
      expect(tester.takeException(), isNull);
      if (completion == 'open') {
        await tester.pump(const Duration(seconds: 5));
        await tester.pumpAndSettle();
      }
    });
  }

  for (final linked in [false, true]) {
    for (final covered in [false, true]) {
      testWidgets(
          '${linked ? 'linked reader' : 'Edit'} waits for one position save${covered ? ' and respects a covering sheet' : ' despite repeated taps'}',
          (tester) async {
        final a = Note(
            id: 'a',
            title: 'Reading project',
            description:
                'Project paragraph to remember while navigating.\n' * 70,
            linkedNoteIds: ['b']);
        final b =
            Note(id: 'b', title: 'Linked project', description: 'Other text');
        final notes = _Notes([a, b]);
        locator.registerSingleton<NoteRepository>(notes);
        addTearDown(() => locator.unregister<NoteRepository>());
        final storage = _WaitingPositionStorage();
        final positions = NotePositionStore(storage: storage);
        final router = await _mount(tester, notes);
        await _push(tester, router, 'a', positions);
        final view = _loaded(tester);
        view.scrollController!.jumpTo(300);
        await tester.pump();
        final beforeWrites = storage.writes;
        storage.waiting = Completer<void>();
        final VoidCallback action;
        if (linked) {
          action = () => view.onOpenLinkedNote!(b);
        } else {
          action = tester
              .widget<TextButton>(find.descendant(
                  of: find.byTooltip(S.current.Edit),
                  matching: find.byType(TextButton)))
              .onPressed!;
        }
        action();
        action();
        await tester.pump();
        expect(storage.writes, beforeWrites + 1);
        if (covered) {
          unawaited(showDialog<void>(
              context: tester.element(find.byType(LoadedView)),
              builder: (_) =>
                  const AlertDialog(title: Text('Another action'))));
          await tester.pumpAndSettle();
        }
        storage.waiting!.complete();
        storage.waiting = null;
        await tester.pumpAndSettle();
        if (covered) {
          expect(find.text('Another action'), findsOneWidget);
          expect(router.stack, hasLength(2));
          expect(find.text('Editing a'), findsNothing);
          Navigator.of(tester.element(find.byType(AlertDialog))).pop();
          await tester.pumpAndSettle();
          action();
          await tester.pumpAndSettle();
        }
        if (linked) {
          expect(_loaded(tester).note.id, 'b');
          expect(
              router.stack.where((route) => route.name == NoteDetailRoute.name),
              hasLength(2));
        } else {
          expect(find.text('Editing a'), findsOneWidget);
          expect(
              router.stack
                  .where((route) => route.name == AddUpdateNoteRoute.name),
              hasLength(1));
        }
        expect(notes.writes, isEmpty);
        expect(tester.takeException(), isNull);
      });
    }
  }

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
    expect(find.text(S.current.Note_Info), findsOneWidget);
    expect(find.text(S.current.Edit), findsOneWidget);
    for (final label in [
      S.current.Note_Menu_Editing,
      S.current.Note_Menu_Organization,
      S.current.Note_Menu_Sharing,
      S.current.Note_Menu_Details,
    ]) {
      expect(find.text(label), findsOneWidget);
    }
    expect(tester.getTopLeft(find.text(S.current.Edit)).dy,
        lessThan(tester.getTopLeft(find.text(S.current.Reminder)).dy));
    expect(tester.getTopLeft(find.text(S.current.Share)).dy,
        lessThan(tester.getTopLeft(find.text(S.current.Note_Info)).dy));
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

  for (final (width, textScale, locale) in [
    (180.0, 1.0, const Locale('en')),
    (240.0, 2.0, const Locale('zh', 'HK')),
    (280.0, 2.0, const Locale('zh')),
    (390.0, 1.0, const Locale('en')),
  ]) {
    testWidgets('Trash Note info is reachable at $width px in $locale',
        (tester) async {
      final deletedAt = DateTime.utc(2026, 10, 7, 14, 30);
      final note = Note(
        id: 'trash-info',
        title: 'Archived research 茶',
        description: 'Keep this saved text.',
        dateTime: DateTime(2020, 1, 2),
        deletedAt: deletedAt,
        isArchived: true,
        todo: [Todo(id: 'unfinished', title: 'Preserve the task')],
      );
      final notes = _Notes([note]);
      final before = Map<String, NoteDto>.of(notes.values);
      final router = await _mount(tester, notes,
          width: width, textScale: textScale, locale: locale);
      await _push(tester, router, note.id!, NotePositionStore.memory());
      if (width < 280) {
        await tester.tap(find.byTooltip(S.current.More_Options));
        await tester.pumpAndSettle();
        expect(find.text(S.current.Share), findsOneWidget);
        expect(find.text(S.current.Restore), findsOneWidget);
        expect(find.text(S.current.Delete_Forever), findsOneWidget);
        final action = find.text(S.current.Note_Info);
        await tester.ensureVisible(action);
        await tester.tap(action);
      } else {
        expect(find.byTooltip(S.current.Share), findsOneWidget);
        expect(find.byTooltip(S.current.Restore), findsOneWidget);
        expect(find.byTooltip(S.current.Delete_Forever), findsOneWidget);
        await tester.tap(find.byTooltip(S.current.Note_Info));
      }
      await tester.pumpAndSettle();
      final sheet = tester.widget<NoteInfoSheet>(find.byType(NoteInfoSheet));
      expect(sheet.deletedAt, deletedAt);
      expect(
          sheet.statistics.wordCount, NoteStatistics.fromNote(note).wordCount);
      expect(find.text(S.current.Note_Info_Moved_To_Trash), findsOneWidget);
      expect(
          tester
              .widget<Text>(
                  find.byKey(const ValueKey('note-info-moved-to-trash-value')))
              .data,
          noteTrashDateTimeLabel(deletedAt, locale.toString()));
      expect(tester.takeException(), isNull);
      await tester.tap(find.byTooltip(
          MaterialLocalizations.of(tester.element(find.byType(NoteInfoSheet)))
              .closeButtonTooltip));
      await tester.pumpAndSettle();
      expect(find.byType(NoteInfoSheet), findsNothing);
      expect(_loaded(tester).note, note);
      expect(notes.values, before);
      expect(notes.writes, isEmpty);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('repeated Trash info callbacks leave one sheet over the reader',
      (tester) async {
    final note = Note(
        id: 'trash-repeat',
        title: 'Keep the note',
        description: 'Saved body',
        deletedAt: DateTime(2026, 10, 7));
    final notes = _Notes([note]);
    final router = await _mount(tester, notes, width: 180);
    await _push(tester, router, note.id!, NotePositionStore.memory());
    await tester.tap(find.byTooltip(S.current.More_Options));
    await tester.pumpAndSettle();
    final tile = tester.widget<ListTile>(find.ancestor(
        of: find.text(S.current.Note_Info), matching: find.byType(ListTile)));
    tile.onTap!();
    tile.onTap!();
    await tester.pumpAndSettle();
    expect(find.byType(NoteInfoSheet), findsOneWidget);
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    tile.onTap!();
    await tester.pumpAndSettle();
    expect(find.byType(NoteInfoSheet), findsNothing);
    expect(_loaded(tester).note, note);
    expect(notes.writes, isEmpty);
    expect(tester.takeException(), isNull);
  });
}
