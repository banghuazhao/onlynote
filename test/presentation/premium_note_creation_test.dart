import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/Tools/app_typography_settings.dart';
import 'package:onlynote/data/dto/note_dto.dart';
import 'package:onlynote/di/di.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/domain/repository/note_repository.dart';
import 'package:onlynote/domain/usecase/add_note_usecase.dart';
import 'package:onlynote/domain/usecase/update_note_usecase.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/screens/add_update_note/add_update_note_screen.dart';
import 'package:onlynote/presentation/screens/add_update_note/bloc/add_update_bloc.dart';
import 'package:onlynote/presentation/screens/settings/premium_screen.dart';
import 'package:onlynote/presentation/theme/theme.dart';
import 'package:onlynote/services/note_autosave.dart';
import 'package:onlynote/services/note_templates.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/premium_test_fakes.dart';

class _Notes extends Fake implements NoteRepository {
  final values = <String, NoteDto>{};
  @override
  List<NoteDto> getAllNotes() => values.values.toList();
  @override
  Future<void> addUpdateNote(NoteDto note) async => values[note.id!] = note;
}

class _Store implements NoteAutosaveStore {
  _Store(this.notes);
  final _Notes notes;
  int writes = 0;
  @override
  Future<void> writeDraft(Note note) async => writes++;
  @override
  Future<void> removeDraft(String id) async {}
  @override
  Future<void> saveNote(Note note) async =>
      notes.addUpdateNote(NoteDto.fromNote(note));
}

void main() {
  late PremiumTestFixture fixture;
  late _Notes notes;
  late _Store store;
  late AddUpdateBloc bloc;
  late Map<String, GoogleFontBuilder> fonts;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await getIt.reset();
    getIt.registerSingleton<S>(S());
    fixture = PremiumTestFixture();
    await fixture.init();
    notes = _Notes();
    for (var i = 0; i < 10; i++) {
      notes.values['$i'] = NoteDto(id: '$i', title: 'Existing $i');
    }
    getIt.registerSingleton<NoteRepository>(notes);
    store = _Store(notes);
    bloc = AddUpdateBloc(AddNoteUsecase(notes), UpdateNoteUsecase(notes));
    fonts = Map.of(kAppFontFamilies);
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

  tearDown(() async {
    kAppFontFamilies.addAll(fonts);
    await bloc.close();
    await fixture.dispose();
    await getIt.reset();
  });

  Widget host(
          {Note? note,
          NoteTemplate? template,
          NoteEditorStart start = NoteEditorStart.standard}) =>
      MaterialApp(
        theme: AppTheme.light,
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: BlocProvider.value(
          value: bloc,
          child: AddUpdateNoteScreen(
            note: note,
            template: template,
            start: start,
            premiumAccess: fixture.access,
            autosaveStore: store,
          ),
        ),
      );

  testWidgets('new editors and native capture starts respect the free limit',
      (tester) async {
    await tester.pumpWidget(host(start: NoteEditorStart.photo));
    await tester.pumpAndSettle();
    expect(find.byType(PremiumScreen), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    expect(store.writes, 0);
    expect(notes.values.length, 10);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  testWidgets('existing notes stay editable even when above the free limit',
      (tester) async {
    notes.values['old-extra'] = NoteDto(id: 'old-extra', title: 'Over limit');
    await tester.pumpWidget(host(note: notes.values['0']!.toDomain()));
    await tester.pumpAndSettle();
    expect(find.byType(PremiumScreen), findsNothing);
    await tester.enterText(find.byType(TextField).first, 'Still editable');
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(notes.values['0']!.title, 'Still editable');
    expect(notes.values.length, 11);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('upgrade resumes a seeded template without creating it early',
      (tester) async {
    await tester.pumpWidget(host(template: NoteTemplate.values.first));
    await tester.pumpAndSettle();
    expect(find.byType(PremiumScreen), findsOneWidget);
    expect(store.writes, 0);
    await tester.runAsync(() async {
      fixture.store.grant();
      await pumpEventQueue();
    });
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.byType(PremiumScreen), findsNothing);
    expect(find.byType(TextField), findsWidgets);
    expect(notes.values.length, 11);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
