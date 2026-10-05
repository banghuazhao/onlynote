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
import 'package:onlynote/presentation/routes/routes.dart';
import 'package:onlynote/presentation/screens/note_detail/bloc/detail/note_detail_bloc.dart';
import 'package:onlynote/presentation/screens/note_detail/note_detail_screen.dart';
import 'package:onlynote/presentation/theme/theme.dart';
import 'package:onlynote/services/custom_note_template_store.dart';

import '../support/memory_preferences.dart';
import '../support/template_images.dart';

class _Notes implements NoteRepository {
  _Notes(this.note);
  final NoteDto note;
  @override
  Future<NoteDto> getNote(String id) async => note;
  @override
  List<NoteDto> getAllNotes() => [note];
  @override
  Future<void> addUpdateNote(NoteDto note) async =>
      throw StateError('Saving a template must not edit the source note');
  @override
  Future<void> deleteNote(String id) async {}
  @override
  Future<void> deleteMultiNotes(List<String> ids) async {}
}

class _Preferences extends MemoryPreferences {
  _Preferences({this.failWrites = false});
  final bool failWrites;
  @override
  Future<void> setString(String key, String value) async {
    if (failWrites) throw StateError('Storage unavailable');
    await super.setString(key, value);
  }
}

class _DetailRouter extends RootStackRouter {
  _DetailRouter(this.store);
  final CustomNoteTemplateStore store;

  @override
  List<AutoRoute> get routes => [
        AutoRoute(
          initial: true,
          page: PageInfo(
            'TemplateDetailTestRoute',
            builder: (_) =>
                NoteDetailScreen(noteId: 'source', templateStore: store),
          ),
        ),
      ];
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
            fontStyle: fontStyle,
          );
    }
  });
  tearDown(() => kAppFontFamilies.addAll(fonts));

  for (final fail in [false, true]) {
    testWidgets(
        'note menu saves a named template and ${fail ? 'surfaces failed persistence' : 'keeps source content independent'}',
        (tester) async {
      final source = Note(
        id: 'source',
        title: 'Weekend trip',
        description: 'Travel notes',
        color: const Color(0xffd3ede4),
        dateTime: DateTime(2026, 10, 1),
        todo: [Todo(id: 'passport', title: 'Passport', completed: true)],
      );
      final repository = _Notes(NoteDto.fromNote(source));
      final preferences = _Preferences(failWrites: fail);
      final templates = CustomNoteTemplateStore(
          preferences: preferences, images: MemoryTemplateImages());
      final detail = NoteDetailBloc(
          GetNoteUsecase(repository), UpdateNoteUsecase(repository));
      final router = _DetailRouter(templates);
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        router.dispose();
        await detail.close();
        templates.dispose();
      });

      await tester.pumpWidget(BlocProvider.value(
        value: detail,
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
      expect(find.text('Weekend trip'), findsOneWidget);
      await tester.tap(find.byTooltip('More options'));
      await tester.pumpAndSettle();
      expect(find.text('Delete'), findsOneWidget);
      await tester.tap(find.text('Save as template'));
      await tester.pumpAndSettle();
      final name = find.byKey(const ValueKey('template-name'));
      expect(tester.widget<TextField>(name).controller!.text, 'Weekend trip');
      await tester.enterText(name, '   ');
      await tester.pump();
      expect(
          tester
              .widget<FilledButton>(find.widgetWithText(FilledButton, 'OK'))
              .onPressed,
          isNull);
      await tester.enterText(name, 'Packing routine');
      await tester.pump();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      if (fail) {
        expect(templates.templates, isEmpty);
        expect(preferences.values, isEmpty);
        expect(find.text(S.current.Template_Save_Failed), findsOneWidget);
      } else {
        expect(templates.templates, hasLength(1));
        expect(templates.templates.single.name, 'Packing routine');
        expect(templates.templates.single.title, 'Weekend trip');
        expect(templates.templates.single.body, 'Travel notes');
        expect(templates.templates.single.color, source.color!.toARGB32());
        final reused =
            await templates.createNote(templates.templates.single.id);
        expect(reused.todo.single.completed, isFalse);
        expect(reused.id, isNot(source.id));
        expect(reused.todo.single.id, isNot('passport'));
        expect(find.text(S.current.Template_Saved), findsOneWidget);
      }
      expect(repository.note.toDomain().title, 'Weekend trip');
      expect(repository.note.toDomain().todo.single.completed, isTrue);
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
