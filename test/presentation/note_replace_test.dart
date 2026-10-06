import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/Tools/app_typography_settings.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/presentation/components/note_find_bar.dart';
import 'package:onlynote/presentation/components/note_find_preview.dart';
import 'package:onlynote/presentation/components/note_search_text.dart';
import 'package:onlynote/services/note_find.dart';

Widget _bar(NoteSearchController controller,
        {FutureOr<void> Function(NoteSearchMatch)? edit,
        FutureOr<void> Function(NoteSearchMatch, String)? replace,
        FutureOr<void> Function(String)? replaceAll,
        bool actionsEnabled = true,
        bool expanded = false,
        ValueChanged<bool>? composingChanged,
        double scale = 1}) =>
    MaterialApp(
      builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: child!),
      home: Scaffold(
        body: SingleChildScrollView(
          child: NoteFindBar(
            controller: controller,
            hintText: 'Find in note',
            noMatchesText: 'No matches',
            previousTooltip: 'Previous match',
            nextTooltip: 'Next match',
            closeTooltip: 'Close find',
            onClose: () {},
            onEditMatch: edit,
            onReplace: replace,
            onReplaceAll: replaceAll,
            actionsEnabled: actionsEnabled,
            initialReplaceVisible: expanded,
            onComposingChanged: composingChanged,
          ),
        ),
      ),
    );

Finder _key(String name) => find.byKey(ValueKey(name));

NoteSearchController _controller() => NoteSearchController()
  ..setFields([const NoteSearchField('body', 'tea tea')])
  ..setQuery('tea');

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
              fontStyle: fontStyle);
    }
  });
  tearDown(() => kAppFontFamilies.addAll(fonts));

  testWidgets('reader Find has no editing controls', (tester) async {
    final controller = _controller();
    addTearDown(controller.dispose);
    await tester.pumpWidget(_bar(controller));
    await tester.pumpAndSettle();
    expect(_key('note-find-edit-match'), findsNothing);
    expect(_key('note-find-replace-toggle'), findsNothing);
    expect(_key('note-find-replacement'), findsNothing);
    expect(find.text('1 / 2'), findsOneWidget);
  });

  testWidgets('editor controls select the current match and allow deletion',
      (tester) async {
    final controller = _controller();
    addTearDown(controller.dispose);
    final edits = <NoteSearchMatch>[];
    final replacements = <(NoteSearchMatch, String)>[];
    final replaceAll = <String>[];
    await tester.pumpWidget(_bar(controller,
        edit: edits.add,
        replace: (match, text) => replacements.add((match, text)),
        replaceAll: replaceAll.add));
    await tester.pumpAndSettle();
    expect(_key('note-find-replacement'), findsNothing);
    await tester.tap(_key('note-find-next'));
    await tester.tap(_key('note-find-edit-match'));
    await tester.pumpAndSettle();
    expect(edits, [const NoteSearchMatch('body', 4, 7)]);
    await tester.tap(_key('note-find-replace-toggle'));
    await tester.pumpAndSettle();
    await tester.tap(_key('note-find-replace'));
    await tester.pumpAndSettle();
    expect(replacements, [(const NoteSearchMatch('body', 4, 7), '')]);
    await tester.enterText(_key('note-find-replacement'), 'coffee');
    await tester.tap(_key('note-find-replace-all'));
    await tester.pumpAndSettle();
    expect(replaceAll, ['coffee']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('an in-flight replacement disables duplicate actions and inputs',
      (tester) async {
    final controller = _controller();
    addTearDown(controller.dispose);
    final operation = Completer<void>();
    var calls = 0;
    await tester.pumpWidget(
        _bar(controller, expanded: true, replace: (_, __) {}, replaceAll: (_) {
      calls++;
      return operation.future;
    }));
    await tester.pumpAndSettle();
    await tester.tap(_key('note-find-replace-all'));
    await tester.pump();
    await tester.tap(_key('note-find-replace-all'));
    expect(calls, 1);
    expect(tester.widget<FilledButton>(_key('note-find-replace-all')).onPressed,
        isNull);
    expect(
        tester.widget<TextButton>(_key('note-find-replace')).onPressed, isNull);
    expect(tester.widget<TextField>(_key('note-find-query')).readOnly, isTrue);
    expect(tester.widget<TextField>(_key('note-find-replacement')).readOnly,
        isTrue);
    operation.complete();
    await tester.pumpAndSettle();
    expect(tester.widget<FilledButton>(_key('note-find-replace-all')).onPressed,
        isNotNull);
  });

  testWidgets('IME composition and draft guard disable mutations',
      (tester) async {
    final controller = _controller();
    addTearDown(controller.dispose);
    var calls = 0;
    await tester.pumpWidget(_bar(controller,
        expanded: true,
        edit: (_) => calls++,
        replace: (_, __) => calls++,
        replaceAll: (_) => calls++));
    await tester.pumpAndSettle();
    tester.testTextInput.updateEditingValue(const TextEditingValue(
        text: 'tea',
        selection: TextSelection.collapsed(offset: 3),
        composing: TextRange(start: 0, end: 3)));
    await tester.pump();
    expect(tester.widget<TextButton>(_key('note-find-edit-match')).onPressed,
        isNull);
    expect(tester.widget<FilledButton>(_key('note-find-replace-all')).onPressed,
        isNull);
    tester.testTextInput.updateEditingValue(const TextEditingValue(
        text: 'tea', selection: TextSelection.collapsed(offset: 3)));
    await tester.pump();
    await tester.tap(_key('note-find-replacement'));
    tester.testTextInput.updateEditingValue(const TextEditingValue(
        text: '咖',
        selection: TextSelection.collapsed(offset: 1),
        composing: TextRange(start: 0, end: 1)));
    await tester.pump();
    expect(
        tester.widget<TextButton>(_key('note-find-replace')).onPressed, isNull);
    await tester.pumpWidget(_bar(controller,
        expanded: true,
        actionsEnabled: false,
        edit: (_) => calls++,
        replace: (_, __) => calls++,
        replaceAll: (_) => calls++));
    await tester.pump();
    expect(tester.widget<TextButton>(_key('note-find-edit-match')).onPressed,
        isNull);
    expect(calls, 0);
  });

  testWidgets('composition callback synchronously reports combined transitions',
      (tester) async {
    final controller = _controller();
    addTearDown(controller.dispose);
    final composing = <bool>[];
    await tester.pumpWidget(_bar(controller,
        expanded: true, replaceAll: (_) {}, composingChanged: composing.add));
    await tester.pumpAndSettle();
    final query = tester.widget<TextField>(_key('note-find-query')).controller!;
    final replacement =
        tester.widget<TextField>(_key('note-find-replacement')).controller!;
    query.value = const TextEditingValue(
        text: 'tea',
        selection: TextSelection.collapsed(offset: 3),
        composing: TextRange(start: 0, end: 3));
    // Parent guards must update in the input event, before the next frame.
    expect(composing, [true]);
    query.selection = const TextSelection.collapsed(offset: 2);
    replacement.value = const TextEditingValue(
        text: '咖',
        selection: TextSelection.collapsed(offset: 1),
        composing: TextRange(start: 0, end: 1));
    expect(composing, [true]);
    query.clearComposing();
    expect(composing, [true],
        reason: 'The replacement field is still composing');
    replacement.clearComposing();
    expect(composing, [true, false]);
    replacement.value = const TextEditingValue(
        text: '咖啡',
        selection: TextSelection.collapsed(offset: 2),
        composing: TextRange(start: 0, end: 2));
    expect(composing, [true, false, true]);
    replacement.clearComposing();
    expect(composing, [true, false, true, false]);
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('expanded replacement controls fit narrow screens at large text',
      (tester) async {
    tester.view.physicalSize = const Size(320, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = _controller();
    addTearDown(controller.dispose);
    await tester.pumpWidget(_bar(controller,
        expanded: true,
        scale: 2,
        edit: (_) {},
        replace: (_, __) {},
        replaceAll: (_) {}));
    await tester.pumpAndSettle();
    expect(_key('note-find-replace-all'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tapping a highlighted draft occurrence selects and edits it',
      (tester) async {
    final note = Note(description: 'tea and tea');
    final controller = NoteSearchController()
      ..setFields(noteSearchFields(note))
      ..setQuery('tea');
    addTearDown(controller.dispose);
    final edits = <NoteSearchMatch>[];
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: NoteFindPreview(
              note: note, controller: controller, onEditMatch: edits.add),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    final text = find.byWidgetPredicate(
        (widget) => widget is NoteSearchText && widget.fieldId == 'body');
    final rich = find.descendant(of: text, matching: find.byType(RichText));
    final paragraph = tester.renderObject<RenderParagraph>(rich);
    final box = paragraph
        .getBoxesForSelection(
            const TextSelection(baseOffset: 8, extentOffset: 11))
        .first
        .toRect();
    await tester.tapAt(paragraph.localToGlobal(box.center));
    await tester.pump();
    expect(edits, [const NoteSearchMatch('body', 8, 11)]);
    expect(controller.currentIndex, 1);
    expect(note.description, 'tea and tea');
    expect(tester.widget<NoteSearchText>(text).enableWebLinks, isFalse);
  });
}
