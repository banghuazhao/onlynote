import 'dart:async';
import 'dart:ui' show AppExitResponse;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/Tools/app_typography_settings.dart';
import 'package:onlynote/Tools/desktop_commands.dart';
import 'package:onlynote/data/dto/note_dto.dart';
import 'package:onlynote/domain/repository/note_repository.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/domain/usecase/add_note_usecase.dart';
import 'package:onlynote/domain/usecase/update_note_usecase.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/screens/add_update_note/add_update_note_screen.dart';
import 'package:onlynote/presentation/screens/add_update_note/bloc/add_update_bloc.dart';
import 'package:onlynote/presentation/screens/settings/backup_screen.dart';
import 'package:onlynote/presentation/theme/theme.dart';
import 'package:onlynote/services/note_autosave.dart';

class EditorRepository implements NoteRepository {
  final notes = <String, NoteDto>{};
  @override
  Future addUpdateNote(NoteDto note) async {
    notes[note.id!] = note;
  }

  @override
  Future deleteNote(String id) async {
    notes.remove(id);
  }

  @override
  Future deleteMultiNotes(List<String> ids) async {
    ids.forEach(notes.remove);
  }

  @override
  List<NoteDto> getAllNotes() => notes.values.toList();
  @override
  Future<NoteDto> getNote(String id) async => notes[id]!;
}

class EditorAutosaveStore implements NoteAutosaveStore {
  EditorAutosaveStore(this.repository);
  final EditorRepository repository;
  @override
  Future<void> writeDraft(Note note) async {}
  @override
  Future<void> removeDraft(String id) async {}
  @override
  Future<void> saveNote(Note note) async {
    await repository.addUpdateNote(NoteDto.fromNote(note));
  }
}

class RetryEditorAutosaveStore extends EditorAutosaveStore {
  RetryEditorAutosaveStore(super.repository);

  bool failSaves = true;
  int saveAttempts = 0;
  Completer<void>? nextSave;

  @override
  Future<void> saveNote(Note note) async {
    saveAttempts++;
    if (failSaves) throw StateError('Save temporarily unavailable');
    await nextSave?.future;
    await super.saveNote(note);
  }
}

Widget app(Widget home) => MaterialApp(
      theme: AppTheme.light,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate
      ],
      home: home,
    );

void main() {
  testWidgets('desktop exit saves the last keystroke before allowing Quit',
      (tester) async {
    final repository = EditorRepository();
    final gate = Completer<void>();
    final store = RetryEditorAutosaveStore(repository)
      ..failSaves = false
      ..nextSave = gate;
    final bloc = AddUpdateBloc(
        AddNoteUsecase(repository), UpdateNoteUsecase(repository));
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
    addTearDown(() async {
      kAppFontFamilies.addAll(fonts);
      await bloc.close();
    });
    await tester.pumpWidget(app(BlocProvider.value(
        value: bloc, child: AddUpdateNoteScreen(autosaveStore: store))));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Last keystroke');
    var finished = false;
    final exit = DesktopCommands.instance.prepareToExit().then((response) {
      finished = true;
      return response;
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump();
    expect(finished, isFalse);
    expect(store.saveAttempts, 1);
    expect(repository.notes, isEmpty);
    gate.complete();
    await tester.pumpAndSettle();
    expect(await exit, AppExitResponse.exit);
    expect(repository.notes.values.single.title, 'Last keystroke');
    expect(find.byType(AddUpdateNoteScreen), findsOneWidget);
    store.failSaves = true;
    store.nextSave = null;
    await tester.enterText(
        find.byType(TextField).first, 'Keep the failed draft');
    final rejectedExit = DesktopCommands.instance.prepareToExit();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump();
    expect(await rejectedExit, AppExitResponse.cancel);
    expect(repository.notes.values.single.title, 'Last keystroke');
    expect(find.byType(AddUpdateNoteScreen), findsOneWidget);
    store.failSaves = false;
    final retriedExit = DesktopCommands.instance.prepareToExit();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump();
    expect(await retriedExit, AppExitResponse.exit);
    expect(repository.notes.values.single.title, 'Keep the failed draft');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });

  testWidgets('retry saves the latest text and stays in the focused editor',
      (tester) async {
    final repository = EditorRepository();
    final store = RetryEditorAutosaveStore(repository);
    final bloc = AddUpdateBloc(
        AddNoteUsecase(repository), UpdateNoteUsecase(repository));
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
    addTearDown(() async {
      kAppFontFamilies.addAll(fonts);
      await bloc.close();
    });
    await tester.pumpWidget(app(BlocProvider.value(
        value: bloc, child: AddUpdateNoteScreen(autosaveStore: store))));
    await tester.pumpAndSettle();
    final title = find.byType(TextField).first;
    await tester.enterText(title, 'Earlier text');
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.text('Not saved'), findsOneWidget);
    expect(repository.notes, isEmpty);
    expect(store.saveAttempts, 1);

    await tester.enterText(title, 'Latest text');
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(store.saveAttempts, 2);
    final field = tester.widget<TextField>(title);
    final selection = field.controller!.selection;
    expect(field.focusNode!.hasFocus, isTrue);
    store.failSaves = false;
    final inFlight = Completer<void>();
    store.nextSave = inFlight;
    final retry = find.byKey(const ValueKey('editor-retry-save'));
    await tester.tap(retry);
    await tester.pump();
    // Retry waits for queued form and recording writes through a zero-delay
    // timer. Advance fake time to run it while the save stays gated below.
    await tester.pump(const Duration(milliseconds: 1));
    expect(find.text('Saving…'), findsOneWidget);
    expect(store.saveAttempts, 3);
    await tester.tap(retry);
    await tester.pump();
    expect(store.saveAttempts, 3);

    inFlight.complete();
    await tester.pumpAndSettle();
    expect(find.text('Saved'), findsOneWidget);
    expect(repository.notes.values.single.title, 'Latest text');
    expect(find.byType(AddUpdateNoteScreen), findsOneWidget);
    expect(field.focusNode!.hasFocus, isTrue);
    expect(field.controller!.selection, selection);
    expect(tester.testTextInput.isVisible, isTrue);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });

  testWidgets(
      'typing saves without leaving the editor, then updates the same note',
      (tester) async {
    final repository = EditorRepository();
    final bloc = AddUpdateBloc(
        AddNoteUsecase(repository), UpdateNoteUsecase(repository));
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
    addTearDown(() async {
      kAppFontFamilies.addAll(fonts);
      await bloc.close();
    });
    await tester.pumpWidget(app(BlocProvider.value(
        value: bloc,
        child: AddUpdateNoteScreen(
            folderId: 'ideas',
            autosaveStore: EditorAutosaveStore(repository)))));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'First idea');
    await tester.pump();
    expect(find.text('Saving…'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    await tester.pump();
    expect(repository.notes.length, 1);
    expect(repository.notes.values.single.title, 'First idea');
    expect(repository.notes.values.single.folderId, 'ideas');
    expect(find.text('Saved'), findsOneWidget);
    expect(find.byType(AddUpdateNoteScreen), findsOneWidget);
    final id = repository.notes.keys.single;
    await tester.enterText(find.byType(TextField).first, 'Updated idea');
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    await tester.pump();
    expect(repository.notes.keys, [id]);
    expect(repository.notes[id]!.title, 'Updated idea');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });

  testWidgets('backup entry screen fits a small phone with large text',
      (tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app(MediaQuery(
      data: const MediaQueryData(textScaler: TextScaler.linear(2)),
      child: const BackupScreen(),
    )));
    await tester.pumpAndSettle();
    expect(find.text('Backup & Restore'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Choose backup file'), 200);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
