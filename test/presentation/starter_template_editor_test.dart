import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/Tools/app_typography_settings.dart';
import 'package:onlynote/data/dto/note_dto.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/domain/repository/note_repository.dart';
import 'package:onlynote/domain/usecase/add_note_usecase.dart';
import 'package:onlynote/domain/usecase/update_note_usecase.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/routes/routes.dart';
import 'package:onlynote/presentation/screens/add_update_note/add_update_note_screen.dart';
import 'package:onlynote/presentation/screens/add_update_note/bloc/add_update_bloc.dart';
import 'package:onlynote/presentation/theme/theme.dart';
import 'package:onlynote/services/note_autosave.dart';
import 'package:onlynote/services/note_templates.dart';

class _MemoryNotes implements NoteRepository {
  @override
  Future<void> addUpdateNote(NoteDto note) async {}
  @override
  Future<void> deleteNote(String id) async {}
  @override
  Future<void> deleteMultiNotes(List<String> ids) async {}
  @override
  List<NoteDto> getAllNotes() => [];
  @override
  Future<NoteDto> getNote(String id) async => throw StateError('No notes');
}

class _MemoryStore implements NoteAutosaveStore {
  final saved = <String, Note>{};
  final drafts = <String, Note>{};
  @override
  Future<void> writeDraft(Note note) async => drafts[note.id!] = note;
  @override
  Future<void> removeDraft(String id) async => drafts.remove(id);
  @override
  Future<void> saveNote(Note note) async => saved[note.id!] = note;
}

class _TemplateRouter extends RootStackRouter {
  _TemplateRouter(this.store, {this.customNote});
  final _MemoryStore store;
  final Note? customNote;

  @override
  List<AutoRoute> get routes => [
        AutoRoute(
          initial: true,
          page: PageInfo(
            HomeRoute.name,
            builder: (_) => Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () => context.router.push(AddUpdateNoteRoute(
                    template: customNote == null ? NoteTemplate.packing : null,
                    customTemplateNote: customNote,
                    folderId: 'travel',
                  )),
                  child: const Text('Open packing template'),
                ),
              ),
            ),
          ),
        ),
        AutoRoute(
          page: PageInfo(
            AddUpdateNoteRoute.name,
            builder: (data) {
              final args = data.argsAs<AddUpdateNoteRouteArgs>();
              return AddUpdateNoteScreen(
                template: args.template,
                customTemplateNote: args.customTemplateNote,
                folderId: args.folderId,
                autosaveStore: store,
              );
            },
          ),
        ),
      ];
}

void main() {
  final fonts = Map<String, GoogleFontBuilder>.of(kAppFontFamilies);
  setUp(() {
    for (final family in fonts.keys) {
      kAppFontFamilies[family] = (
              {textStyle, color, fontSize, fontWeight, fontStyle}) =>
          (textStyle ?? const TextStyle()).copyWith(
            color: color,
            fontSize: fontSize,
            fontWeight: fontWeight,
            fontStyle: fontStyle,
          );
    }
  });
  tearDown(() => kAppFontFamilies.addAll(fonts));

  for (final useDone in [true, false]) {
    testWidgets(
      'selected template saves without edits when leaving with ${useDone ? 'Done' : 'Back'}',
      (tester) async {
        final store = _MemoryStore();
        final repository = _MemoryNotes();
        final bloc = AddUpdateBloc(
          AddNoteUsecase(repository),
          UpdateNoteUsecase(repository),
        );
        final router = _TemplateRouter(store);
        addTearDown(() async {
          await tester.pumpWidget(const SizedBox.shrink());
          router.dispose();
          await bloc.close();
        });
        await tester.pumpWidget(BlocProvider.value(
          value: bloc,
          child: MaterialApp.router(
            routerConfig: router.config(),
            theme: AppTheme.light,
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
        await tester.tap(find.text('Open packing template'));
        await tester.pumpAndSettle();
        expect(find.text('Packing list'), findsOneWidget);
        expect(find.text('Travel documents'), findsOneWidget);

        if (useDone) {
          await tester.tap(find.text('Done'));
        } else {
          await router.maybePop();
        }
        await tester.pumpAndSettle();

        expect(router.stackData.map((route) => route.name), [HomeRoute.name]);
        expect(store.saved, hasLength(1));
        final note = store.saved.values.single;
        expect(note.folderId, 'travel');
        expect(note.title, 'Packing list');
        expect(note.todo, hasLength(5));
        expect(note.todo.every((item) => !item.completed), isTrue);
        expect(note.todo.map((item) => item.id).toSet(), hasLength(5));
        expect(store.drafts, isEmpty);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
      'custom template seed is saved as a new independent note without edits',
      (tester) async {
    final store = _MemoryStore();
    final repository = _MemoryNotes();
    final bloc = AddUpdateBloc(
        AddNoteUsecase(repository), UpdateNoteUsecase(repository));
    final initial = Note(
        id: 'custom-new-note',
        title: 'Trip',
        description: 'Travel notes',
        folderId: 'travel',
        color: const Color(0xffd3ede4),
        todo: [Todo(id: 'new-passport', title: 'Passport')]);
    final router = _TemplateRouter(store, customNote: initial);
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      router.dispose();
      await bloc.close();
    });
    await tester.pumpWidget(BlocProvider.value(
        value: bloc,
        child: MaterialApp.router(
          routerConfig: router.config(),
          theme: AppTheme.light,
          localizationsDelegates: const [
            S.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate
          ],
        )));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open packing template'));
    await tester.pumpAndSettle();
    expect(find.text('Trip'), findsOneWidget);
    expect(find.text('Passport'), findsOneWidget);
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(store.saved.values.single, initial);
    expect(store.drafts, isEmpty);
    expect(router.stackData.map((route) => route.name), [HomeRoute.name]);
    expect(tester.takeException(), isNull);
  });
}
