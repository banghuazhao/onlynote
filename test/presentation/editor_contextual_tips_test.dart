import 'dart:async';
import 'dart:convert';
import 'dart:io';

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
import 'package:onlynote/presentation/components/note_editor_tip.dart';
import 'package:onlynote/presentation/screens/add_update_note/add_update_note_screen.dart';
import 'package:onlynote/presentation/screens/add_update_note/bloc/add_update_bloc.dart';
import 'package:onlynote/presentation/screens/add_update_note/bloc/add_update_form/add_update_form_bloc.dart';
import 'package:onlynote/presentation/theme/theme.dart';
import 'package:onlynote/services/note_autosave.dart';
import 'package:onlynote/services/note_editor_tips.dart';
import 'package:onlynote/services/note_position_store.dart';

import '../support/memory_preferences.dart';

class _Preferences extends MemoryPreferences {
  @override
  Future<bool?> getBool(String key) async => values[key] as bool?;

  @override
  Future<void> setBool(String key, bool value) async => values[key] = value;
}

class _PendingTips extends NoteEditorTips {
  final formatting = Completer<bool>();
  final imageLayout = Completer<bool>();
  final dismissed = <NoteEditorTipKind>[];

  @override
  Future<bool> shouldShow(NoteEditorTipKind kind) =>
      kind == NoteEditorTipKind.formatting
          ? formatting.future
          : imageLayout.future;

  @override
  Future<void> dismiss(NoteEditorTipKind kind) async => dismissed.add(kind);
}

class _Repository implements NoteRepository {
  final notes = <String, NoteDto>{};

  @override
  List<NoteDto> getAllNotes() => notes.values.toList();

  @override
  Future<NoteDto> getNote(String id) async => notes[id]!;

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
}

class _Store implements NoteAutosaveStore {
  @override
  Future<void> writeDraft(Note note) async {}

  @override
  Future<void> removeDraft(String id) async {}

  @override
  Future<void> saveNote(Note note) async {}
}

Finder _body() => find.byWidgetPredicate(
    (widget) => widget is TextField && widget.maxLines == 100);

Future<void> _open(
  WidgetTester tester, {
  required NoteEditorTips tips,
  Note? note,
}) async {
  final repository = _Repository();
  if (note != null) repository.notes[note.id!] = NoteDto.fromNote(note);
  final bloc =
      AddUpdateBloc(AddNoteUsecase(repository), UpdateNoteUsecase(repository));
  addTearDown(bloc.close);
  await tester.pumpWidget(MaterialApp(
    theme: AppTheme.light,
    supportedLocales: S.delegate.supportedLocales,
    localizationsDelegates: const [
      S.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: true),
      child: child!,
    ),
    home: BlocProvider.value(
      value: bloc,
      child: AddUpdateNoteScreen(
        key: UniqueKey(),
        note: note,
        autosaveStore: _Store(),
        editorTips: tips,
        positionStore: NotePositionStore.memory(),
      ),
    ),
  ));
  await tester.pumpAndSettle();
}

Future<void> _close(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
}

Future<String> _photo(WidgetTester tester) async {
  final directory = (await tester
      .runAsync(() => Directory.systemTemp.createTemp('onlynote-tip-test-')))!;
  final file = File('${directory.path}/photo.png');
  await tester.runAsync(() => file.writeAsBytes(base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/l9sAAAAASUVORK5CYII=')));
  addTearDown(() => directory.delete(recursive: true));
  return file.path;
}

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

  testWidgets('formatting hint needs both body focus and a text selection',
      (tester) async {
    final preferences = _Preferences();
    final tips = NoteEditorTips(preferences: preferences);
    await _open(tester, tips: tips);

    expect(find.byType(NoteEditorTip), findsNothing);
    final field = tester.widget<TextField>(_body());
    field.controller!.value = const TextEditingValue(
      text: 'A useful idea',
      selection: TextSelection(baseOffset: 2, extentOffset: 8),
    );
    await tester.pumpAndSettle();
    expect(find.byType(NoteEditorTip), findsNothing);
    expect(preferences.values, isEmpty);

    field.focusNode!.requestFocus();
    field.controller!.selection = const TextSelection.collapsed(offset: 8);
    await tester.pumpAndSettle();
    expect(field.focusNode!.hasFocus, isTrue);
    expect(find.byType(NoteEditorTip), findsNothing);
    expect(preferences.values, isEmpty);

    const selection = TextSelection(baseOffset: 2, extentOffset: 8);
    field.controller!.selection = selection;
    await tester.pumpAndSettle();
    expect(find.text(S.current.Editor_Tip_Formatting), findsOneWidget);
    expect(find.byType(NoteEditorTip), findsOneWidget);
    expect(preferences.values,
        {NoteEditorTips.storageKey(NoteEditorTipKind.formatting): true});

    await tester.tap(find.byKey(const ValueKey('note-editor-tip-dismiss')));
    await tester.pump();
    expect(find.byType(NoteEditorTip), findsNothing);
    expect(field.controller!.selection, selection);
    expect(field.focusNode!.hasFocus, isTrue);
    expect(tester.testTextInput.isVisible, isTrue);

    // Dismissal is persisted outside the screen/controller lifecycle.
    await _close(tester);
    await _open(tester, tips: NoteEditorTips(preferences: preferences));
    final reopened = tester.widget<TextField>(_body());
    reopened.focusNode!.requestFocus();
    reopened.controller!.value = const TextEditingValue(
      text: 'A useful idea',
      selection: selection,
    );
    await tester.pumpAndSettle();
    expect(find.byType(NoteEditorTip), findsNothing);
    expect(tester.takeException(), isNull);
    await _close(tester);
  });

  testWidgets('a displayed hint is offered once even when the editor is closed',
      (tester) async {
    final preferences = _Preferences();
    await _open(tester, tips: NoteEditorTips(preferences: preferences));
    final field = tester.widget<TextField>(_body());
    field.focusNode!.requestFocus();
    field.controller!.value = const TextEditingValue(
      text: 'Format this idea',
      selection: TextSelection(baseOffset: 0, extentOffset: 6),
    );
    await tester.pumpAndSettle();
    expect(find.text(S.current.Editor_Tip_Formatting), findsOneWidget);
    await _close(tester);

    await _open(tester, tips: NoteEditorTips(preferences: preferences));
    final reopened = tester.widget<TextField>(_body());
    reopened.focusNode!.requestFocus();
    reopened.controller!.value = const TextEditingValue(
      text: 'Format this idea',
      selection: TextSelection(baseOffset: 0, extentOffset: 6),
    );
    await tester.pumpAndSettle();
    expect(find.byType(NoteEditorTip), findsNothing);
    expect(tester.takeException(), isNull);
    await _close(tester);
  });

  testWidgets('existing photos do not consume the image-layout hint',
      (tester) async {
    final preferences = _Preferences();
    final path = await _photo(tester);
    await _open(
      tester,
      tips: NoteEditorTips(preferences: preferences),
      note: Note(id: 'existing-photo', imagePaths: [path]),
    );

    expect(find.text(S.current.Editor_Tip_Image_Layout), findsNothing);
    expect(preferences.values, isEmpty);
    expect(tester.takeException(), isNull);
    await _close(tester);
  });

  testWidgets('a newly inserted photo shows and persists its layout hint',
      (tester) async {
    final preferences = _Preferences();
    final path = await _photo(tester);
    await _open(tester, tips: NoteEditorTips(preferences: preferences));
    final form = tester.element(_body()).read<AddUpdateFormBloc>();

    form.add(AddUpdateFormEvent.addImage(path));
    await tester.pumpAndSettle();

    expect(find.text(S.current.Editor_Tip_Image_Layout), findsOneWidget);
    expect(find.byType(NoteEditorTip), findsOneWidget);
    expect(preferences.values,
        {NoteEditorTips.storageKey(NoteEditorTipKind.imageLayout): true});
    final close = find.byKey(const ValueKey('note-editor-tip-dismiss'));
    await tester.ensureVisible(close);
    await tester.tap(close);
    await tester.pump();
    expect(find.byType(NoteEditorTip), findsNothing);
    expect(form.state.imagePaths, [path]);
    expect(tester.takeException(), isNull);
    await _close(tester);
  });

  testWidgets('late hint loading cannot update a disposed editor',
      (tester) async {
    final tips = _PendingTips();
    await _open(tester, tips: tips);
    expect(find.byType(NoteEditorTip), findsNothing);
    await _close(tester);

    tips.formatting.complete(true);
    tips.imageLayout.complete(true);
    await tester.pump();

    expect(tips.dismissed, isEmpty);
    expect(tester.takeException(), isNull);
  });
}
