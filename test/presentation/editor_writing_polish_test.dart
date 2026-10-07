import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/Tools/app_typography_settings.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/domain/model/note_text_style.dart';
import 'package:onlynote/domain/repository/note_repository.dart';
import 'package:onlynote/domain/usecase/add_note_usecase.dart';
import 'package:onlynote/domain/usecase/update_note_usecase.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/note_formatting_toolbar.dart';
import 'package:onlynote/presentation/components/note_insert_sheet.dart';
import 'package:onlynote/presentation/screens/add_update_note/add_update_note_screen.dart';
import 'package:onlynote/presentation/screens/add_update_note/bloc/add_update_bloc.dart';
import 'package:onlynote/presentation/theme/theme.dart';
import 'package:onlynote/services/note_autosave.dart';

class _UnusedRepository implements NoteRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw StateError('Unused');
}

class _Store implements NoteAutosaveStore {
  final notes = <Note>[];
  @override
  Future<void> writeDraft(Note note) async {}
  @override
  Future<void> removeDraft(String id) async {}
  @override
  Future<void> saveNote(Note note) async => notes.add(note);
}

Finder _body() => find.byWidgetPredicate(
    (widget) => widget is TextField && widget.maxLines == 100);

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

  Future<_Store> open(WidgetTester tester,
      {Note? note,
      Size size = const Size(390, 844),
      double textScale = 1,
      bool chinese = false,
      bool dark = false}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final repository = _UnusedRepository();
    final bloc = AddUpdateBloc(
        AddNoteUsecase(repository), UpdateNoteUsecase(repository));
    final store = _Store();
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      await bloc.close();
    });
    await tester.pumpWidget(MaterialApp(
      theme: dark ? AppTheme.dark : AppTheme.light,
      locale: chinese ? const Locale('zh', 'HK') : const Locale('en'),
      supportedLocales: S.delegate.supportedLocales,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
        ),
        child: child!,
      ),
      home: BlocProvider.value(
        value: bloc,
        child: AddUpdateNoteScreen(note: note, autosaveStore: store),
      ),
    ));
    await tester.pumpAndSettle();
    return store;
  }

  for (final dark in [false, true]) {
    testWidgets('empty note cursor has no inherited text frame, dark=$dark',
        (tester) async {
      await open(tester, dark: dark, textScale: 2);
      for (final target in [
        find.byKey(const ValueKey('note-title-input')),
        _body(),
      ]) {
        final field = tester.widget<TextField>(target);
        field.controller!.selection = const TextSelection.collapsed(offset: 0);
        field.focusNode!.requestFocus();
        await tester.pumpAndSettle();
        final decorator = tester.widget<InputDecorator>(
            find.descendant(of: target, matching: find.byType(InputDecorator)));
        expect(decorator.isFocused, isTrue);
        // Inspect the effective decoration after the app's theme defaults
        // have been applied, including the border used while focused.
        for (final border in [
          decorator.decoration.border,
          decorator.decoration.enabledBorder,
          decorator.decoration.focusedBorder,
          decorator.decoration.disabledBorder,
          decorator.decoration.errorBorder,
          decorator.decoration.focusedErrorBorder,
        ]) {
          expect(border, InputBorder.none);
        }
        expect(field.controller!.selection,
            const TextSelection.collapsed(offset: 0));
        expect(tester.testTextInput.isVisible, isTrue);
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
      'plain note starts with title and body, Insert adds a focused item',
      (tester) async {
    final store = await open(tester);
    expect(find.byKey(const ValueKey('editor-insert')), findsOneWidget);
    expect(find.text(S.current.Add_todo), findsNothing);
    expect(find.byKey(const ValueKey('editor-add-photo')), findsNothing);
    expect(find.byKey(const ValueKey('editor-record-voice')), findsNothing);
    expect(find.byType(NoteFormattingToolbar), findsNothing);
    final title = find.byKey(const ValueKey('note-title-input'));
    expect(tester.getRect(_body()).top - tester.getRect(title).bottom,
        lessThanOrEqualTo(32));
    await tester.tap(find.byKey(const ValueKey('editor-insert')));
    await tester.pumpAndSettle();
    expect(find.byType(NoteInsertSheet), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('editor-add-checklist')));
    await tester.pumpAndSettle();
    final item = find.byWidgetPredicate((widget) =>
        widget is TextField &&
        (widget.key?.toString().contains('todo-field-') ?? false));
    final field = tester.widget<TextField>(item);
    expect(field.focusNode!.hasFocus, isTrue);
    expect(find.byType(NoteInsertSheet), findsNothing);
    await tester.enterText(item, 'Pack a notebook');
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(store.notes.last.todo.single.title, 'Pack a notebook');
    expect(tester.takeException(), isNull);
  });

  testWidgets('formatting stays above keyboard while a long note scrolls',
      (tester) async {
    final text =
        List.generate(60, (index) => 'Line $index of my note').join('\n');
    final store = await open(tester,
        note: Note(id: 'long', title: 'Long note', description: text));
    final field = tester.widget<TextField>(_body());
    field.focusNode!.requestFocus();
    tester.view.viewInsets = const FakeViewPadding(bottom: 280);
    await tester.pumpAndSettle();
    field.controller!.selection =
        const TextSelection(baseOffset: 0, extentOffset: 4);
    await tester.pump();
    final scroll = Scrollable.of(tester.element(_body())).position;
    scroll.jumpTo(scroll.maxScrollExtent);
    await tester.pump();
    final button = find.byKey(const ValueKey('format-bold'));
    expect(tester.getRect(button).bottom, lessThanOrEqualTo(844 - 280));
    await tester.tap(button);
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(field.focusNode!.hasFocus, isTrue);
    expect(field.controller!.selection,
        const TextSelection(baseOffset: 0, extentOffset: 4));
    expect(store.notes.last.description, text);
    expect(
        store.notes.last.textStyles,
        contains(const NoteTextStyleRange(
            start: 0, end: 4, kind: NoteTextStyleKind.bold)));
    expect(tester.testTextInput.isVisible, isTrue);
    expect(tester.takeException(), isNull);
  });

  for (final size in [
    const Size(180, 640),
    const Size(320, 640),
    const Size(640, 320)
  ]) {
    testWidgets('keyboard and Insert fit at $size with large Chinese text',
        (tester) async {
      await open(tester, size: size, textScale: 2, chinese: true);
      await tester.tap(find.byKey(const ValueKey('editor-insert')));
      await tester.pumpAndSettle();
      expect(
          find.byKey(const ValueKey('editor-add-checklist')), findsOneWidget);
      await tester.tap(find.byTooltip('關閉'));
      await tester.pumpAndSettle();
      final field = tester.widget<TextField>(_body());
      field.focusNode!.requestFocus();
      tester.view.viewInsets =
          FakeViewPadding(bottom: size.height > 400 ? 260 : 130);
      await tester.pumpAndSettle();
      expect(find.byType(NoteFormattingToolbar), findsOneWidget);
      final last =
          tester.getRect(find.byKey(const ValueKey('format-highlight')));
      expect(last.right, lessThanOrEqualTo(size.width));
      expect(last.bottom,
          lessThanOrEqualTo(size.height - tester.view.viewInsets.bottom));
      expect(tester.takeException(), isNull);
    });
  }
}
