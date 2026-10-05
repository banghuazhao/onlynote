import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/Tools/app_typography_settings.dart';
import 'package:onlynote/Tools/onboarding_settings.dart';
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
import 'package:shared_preferences/shared_preferences.dart';

class _MemoryNotes implements NoteRepository {
  final notes = <String, NoteDto>{};

  @override
  Future<void> addUpdateNote(NoteDto note) async {
    notes[note.id!] = note;
  }

  @override
  Future<void> deleteNote(String id) async {
    notes.remove(id);
  }

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

class _MemoryAutosaveStore implements NoteAutosaveStore {
  final saved = <Note>[];

  @override
  Future<void> writeDraft(Note note) async {}

  @override
  Future<void> removeDraft(String id) async {}

  @override
  Future<void> saveNote(Note note) async => saved.add(note);
}

/// Uses real first-run and editor pages, with a simple library destination so
/// unrelated HomeScreen services and ads do not affect these routing tests.
class _FirstRunRouter extends RootStackRouter {
  _FirstRunRouter(this.store);

  final _MemoryAutosaveStore store;

  @override
  List<AutoRoute> get routes => [
        AutoRoute(page: OnboardingRoute.page, initial: true),
        AutoRoute(
          page: PageInfo(
            HomeRoute.name,
            builder: (_) => const Scaffold(body: Text('Library')),
          ),
        ),
        AutoRoute(
          page: PageInfo(
            AddUpdateNoteRoute.name,
            builder: (data) {
              final args = data.argsAs<AddUpdateNoteRouteArgs>();
              return AddUpdateNoteScreen(
                  start: args.start, autosaveStore: store);
            },
          ),
        ),
      ];
}

Widget _app(_FirstRunRouter router, AddUpdateBloc bloc) => BlocProvider.value(
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
    );

Finder _descriptionField() => find.byWidgetPredicate(
      (widget) => widget is TextField && widget.maxLines == 100,
    );

Finder _checklistField() => find.byWidgetPredicate(
      (widget) => widget is TextField && widget.maxLines == 4,
    );

bool _fieldHasFocus(WidgetTester tester, Finder field) {
  final editable = tester.widget<EditableText>(
    find.descendant(of: field, matching: find.byType(EditableText)),
  );
  return editable.focusNode.hasFocus;
}

void main() {
  final originalFonts = Map<String, GoogleFontBuilder>.of(kAppFontFamilies);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await OnboardingSettings.instance.load();
    for (final family in originalFonts.keys) {
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

  tearDown(() {
    kAppFontFamilies.addAll(originalFonts);
    OnboardingSettings.instance.completed = false;
  });

  testWidgets(
    'Write a note opens the focused editor and saves the first note',
    (tester) async {
      final store = _MemoryAutosaveStore();
      final repository = _MemoryNotes();
      final bloc = AddUpdateBloc(
        AddNoteUsecase(repository),
        UpdateNoteUsecase(repository),
      );
      final router = _FirstRunRouter(store);
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        router.dispose();
        await bloc.close();
      });

      await tester.pumpWidget(_app(router, bloc));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Write a note'));
      await tester.pumpAndSettle();

      expect(router.stackData.map((route) => route.name), [
        HomeRoute.name,
        AddUpdateNoteRoute.name,
      ]);
      expect(find.byType(AddUpdateNoteScreen), findsOneWidget);
      expect(_fieldHasFocus(tester, _descriptionField()), isTrue);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('onboarding_completed'), isTrue);

      await tester.enterText(_descriptionField(), 'My first note');
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(store.saved.single.description, 'My first note');

      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(router.stackData.map((route) => route.name), [HomeRoute.name]);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Make a checklist focuses its first item without saving a blank note',
    (tester) async {
      final store = _MemoryAutosaveStore();
      final repository = _MemoryNotes();
      final bloc = AddUpdateBloc(
        AddNoteUsecase(repository),
        UpdateNoteUsecase(repository),
      );
      final router = _FirstRunRouter(store);
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        router.dispose();
        await bloc.close();
      });

      await tester.pumpWidget(_app(router, bloc));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Make a checklist'));
      await tester.pumpAndSettle();

      expect(router.stackData.map((route) => route.name), [
        HomeRoute.name,
        AddUpdateNoteRoute.name,
      ]);
      expect(_checklistField(), findsOneWidget);
      expect(_fieldHasFocus(tester, _checklistField()), isTrue);

      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(router.stackData.map((route) => route.name), [HomeRoute.name]);
      expect(store.saved, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );
}
