import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/Tools/app_typography_settings.dart';
import 'package:onlynote/data/dto/note_dto.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/domain/model/note_text_style.dart';
import 'package:onlynote/domain/repository/note_repository.dart';
import 'package:onlynote/domain/usecase/add_note_usecase.dart';
import 'package:onlynote/domain/usecase/update_note_usecase.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/note_divider_block.dart';
import 'package:onlynote/presentation/screens/add_update_note/add_update_note_screen.dart';
import 'package:onlynote/presentation/screens/add_update_note/bloc/add_update_bloc.dart';
import 'package:onlynote/presentation/theme/theme.dart';
import 'package:onlynote/services/note_autosave.dart';

class _UnusedRepository implements NoteRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw StateError('Unused');
}

class _Store implements NoteAutosaveStore {
  NoteDto? saved;
  @override
  Future<void> writeDraft(Note note) async {}
  @override
  Future<void> removeDraft(String id) async {}
  @override
  Future<void> saveNote(Note note) async => saved = NoteDto.fromNote(note);
}

Finder _body() => find.byWidgetPredicate(
    (widget) => widget is TextField && widget.maxLines == 100);

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
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

  testWidgets('Insert divider saves, supports editing undo/redo, and reopens',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    final repository = _UnusedRepository();
    final bloc = AddUpdateBloc(
        AddNoteUsecase(repository), UpdateNoteUsecase(repository));
    final store = _Store();
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await bloc.close();
    });
    Future<void> open(Note note) async {
      await tester.pumpWidget(MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: const [
            S.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate
          ],
          home: BlocProvider.value(
              value: bloc,
              child: AddUpdateNoteScreen(
                  key: ValueKey(note.description),
                  note: note,
                  autosaveStore: store))));
      await tester.pumpAndSettle();
    }

    await open(Note(
        id: 'divider-release',
        title: 'Release plan',
        description: 'Before\nAfter'));
    final field = tester.widget<TextField>(_body());
    field.controller!.selection = const TextSelection.collapsed(offset: 7);
    field.focusNode!.requestFocus();
    await tester.pumpAndSettle();
    await _tap(tester, find.byKey(const ValueKey('editor-insert')));
    await _tap(tester, find.byKey(const ValueKey('editor-add-divider')));
    expect(find.byType(NoteDividerBlock), findsOneWidget);
    final after = find.byKey(const ValueKey('note-body-end'));
    expect(tester.widget<TextField>(after).focusNode!.hasFocus, isTrue);
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(store.saved!.description, 'Before\n─\nAfter');
    expect(store.saved!.toDomain().textStyles.single.kind,
        NoteTextStyleKind.divider);
    await tester.enterText(after, 'After writing');
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(store.saved!.description, 'Before\n─\nAfter writing');
    await _tap(tester, find.byKey(const ValueKey('note-undo')));
    expect(store.saved!.description, 'Before\n─\nAfter');
    await _tap(tester, find.byKey(const ValueKey('note-undo')));
    expect(find.byType(NoteDividerBlock), findsNothing);
    expect(store.saved!.description, 'Before\nAfter');
    await _tap(tester, find.byKey(const ValueKey('note-redo')));
    expect(find.byType(NoteDividerBlock), findsOneWidget);
    expect(store.saved!.description, 'Before\n─\nAfter');
    await _tap(tester, find.byKey(const ValueKey('note-redo')));
    expect(store.saved!.description, 'Before\n─\nAfter writing');
    final saved = store.saved!.toDomain();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await open(saved);
    expect(find.byType(NoteDividerBlock), findsOneWidget);
    expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('note-body-end')))
            .controller!
            .text,
        'After writing');
    expect(tester.takeException(), isNull);
  },
      variant: const TargetPlatformVariant(
          {TargetPlatform.iOS, TargetPlatform.android}));
}
