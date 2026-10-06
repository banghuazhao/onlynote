import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/domain/model/note_text_style.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/formatted_note_text.dart';
import 'package:onlynote/presentation/components/note_document_view.dart';
import 'package:onlynote/presentation/components/note_search_text.dart';
import 'package:onlynote/services/note_find.dart';
import 'package:onlynote/services/note_text_format.dart';

const _style = TextStyle(fontSize: 17, height: 1.5);

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  bool dark = false,
  double textScale = 1,
  Locale locale = const Locale('en'),
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(320, 640);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(MaterialApp(
    theme: ThemeData(
      brightness: dark ? Brightness.dark : Brightness.light,
      platform: TargetPlatform.android,
    ),
    locale: locale,
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
    home: Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: child,
      ),
    ),
  ));
  await tester.pumpAndSettle();
}

List<TextSpan> _leaves(InlineSpan span) {
  if (span is! TextSpan) return [];
  if (span.children?.isNotEmpty == true) {
    return span.children!.expand(_leaves).toList();
  }
  return [span];
}

Offset _selectableOffset(WidgetTester tester, int start, int end) {
  final editable =
      tester.state<EditableTextState>(find.byType(EditableText)).renderEditable;
  final box = editable
      .getBoxesForSelection(TextSelection(baseOffset: start, extentOffset: end))
      .first;
  return editable.localToGlobal(box.toRect().center);
}

void main() {
  testWidgets('reader opens full URL across saved formatting boundaries',
      (tester) async {
    const text = '📝 Visit https://example.com/a(b).';
    final start = text.indexOf('https://');
    final end = text.length - 1;
    final opened = <Uri>[];
    await _pump(
      tester,
      FormattedNoteText(
        text: text,
        style: _style.copyWith(color: Colors.white),
        styles: [
          NoteTextStyleRange(
              start: start, end: end, kind: NoteTextStyleKind.highlight),
          NoteTextStyleRange(
              start: start + 8, end: start + 15, kind: NoteTextStyleKind.bold),
        ],
        onOpenUrl: (uri) async {
          opened.add(uri);
          return true;
        },
      ),
      dark: true,
      textScale: 2,
    );
    final span =
        tester.widget<SelectableText>(find.byType(SelectableText)).textSpan!;
    expect(span.toPlainText(), text);
    final links =
        _leaves(span).where((span) => span.recognizer != null).toList();
    expect(links, hasLength(3));
    expect(links.map((span) => span.text).join(), text.substring(start, end));
    expect(
        links
            .every((span) => span.style?.backgroundColor == noteHighlightColor),
        isTrue);
    expect(links.every((span) => span.style?.color == noteHighlightedTextColor),
        isTrue);
    expect(links[1].style?.fontWeight, FontWeight.w700);
    expect(
        links.every((span) =>
            span.style?.decoration?.contains(TextDecoration.underline) == true),
        isTrue);
    expect(_leaves(span).last.text, '.');
    expect(_leaves(span).last.recognizer, isNull);
    await tester.tapAt(_selectableOffset(tester, start + 8, start + 11));
    await tester.pumpAndSettle();
    expect(opened, [Uri.parse('https://example.com/a(b)')]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('long press selects and copies URL text without opening it',
      (tester) async {
    const text = 'Read https://example.com for details.';
    final opened = <Uri>[];
    String? copied;
    tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        copied = (call.arguments as Map)['text'] as String;
      }
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null));
    await _pump(
      tester,
      FormattedNoteText(
        text: text,
        style: _style,
        onOpenUrl: (uri) async {
          opened.add(uri);
          return true;
        },
      ),
    );
    await tester.longPressAt(_selectableOffset(tester, 13, 16));
    await tester.pumpAndSettle();
    final editing = tester.widget<EditableText>(find.byType(EditableText));
    final selection = editing.controller.selection;
    expect(selection.isCollapsed, isFalse);
    expect(opened, isEmpty);
    expect(find.text('Copy'), findsOneWidget);
    await tester.tap(find.text('Copy'));
    await tester.pumpAndSettle();
    expect(copied, text.substring(selection.start, selection.end));
    expect(opened, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('nonselectable editor and sharing text have no link recognizers',
      (tester) async {
    var opened = false;
    await _pump(
      tester,
      FormattedNoteText(
        text: 'https://example.com',
        style: _style,
        selectable: false,
        onOpenUrl: (_) async {
          opened = true;
          return true;
        },
      ),
    );
    final text = tester.widget<Text>(find.byType(Text));
    expect(text.semanticsLabel, 'https://example.com');
    expect(_leaves(text.textSpan!).every((span) => span.recognizer == null),
        isTrue);
    await tester.tap(find.byType(Text));
    expect(opened, isFalse);
  });

  testWidgets('failed launch shows localized transient feedback',
      (tester) async {
    await _pump(
      tester,
      FormattedNoteText(
        text: 'www.example.com',
        style: _style,
        onOpenUrl: (_) async => false,
      ),
      locale: const Locale('zh', 'HK'),
    );
    await tester.tapAt(_selectableOffset(tester, 0, 3));
    await tester.pumpAndSettle();
    expect(find.text(S.current.Web_Link_Open_Failed), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(find.byType(SnackBar), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('launch completion after reader disposal is ignored',
      (tester) async {
    final result = Completer<bool>();
    await _pump(
      tester,
      FormattedNoteText(
        text: 'https://example.com',
        style: _style,
        onOpenUrl: (_) => result.future,
      ),
    );
    await tester.tapAt(_selectableOffset(tester, 0, 3));
    await tester.pumpWidget(const SizedBox.shrink());
    result.complete(false);
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('document reader forwards opener and replaces links on rebuild',
      (tester) async {
    final opened = <Uri>[];
    Future<bool> open(Uri uri) async {
      opened.add(uri);
      return true;
    }

    await _pump(
      tester,
      NoteDocumentView(text: 'www.first.com', style: _style, onOpenUrl: open),
    );
    await tester.tapAt(_selectableOffset(tester, 0, 3));
    await tester.pumpAndSettle();
    await _pump(
      tester,
      NoteDocumentView(text: 'www.second.com', style: _style, onOpenUrl: open),
    );
    await tester.tapAt(_selectableOffset(tester, 0, 3));
    await tester.pumpAndSettle();
    expect(opened, [
      Uri.parse('https://www.first.com'),
      Uri.parse('https://www.second.com')
    ]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('find emphasis retains website taps and restores selection',
      (tester) async {
    const text = 'See https://example.com';
    final controller = NoteSearchController()
      ..setFields([const NoteSearchField('body', text)])
      ..setQuery('example');
    addTearDown(controller.dispose);
    final opened = <Uri>[];
    await _pump(
      tester,
      NoteSearchText(
        controller: controller,
        fieldId: 'body',
        text: text,
        style: _style,
        onOpenUrl: (uri) async {
          opened.add(uri);
          return true;
        },
      ),
    );
    final rich = tester.widget<Text>(find.byType(Text));
    expect(rich.semanticsLabel, isNull);
    final matched =
        _leaves(rich.textSpan!).singleWhere((span) => span.text == 'example');
    expect(matched.style?.backgroundColor, const Color(0xFFF2BD54));
    expect(matched.recognizer, isNotNull);
    await tester.tapAt(_paragraphOffset(tester, 12, 15));
    await tester.pumpAndSettle();
    expect(opened, [Uri.parse('https://example.com')]);
    controller.setQuery('');
    await tester.pumpAndSettle();
    expect(find.byType(SelectableText), findsOneWidget);
    expect(
        tester
            .widget<SelectableText>(find.byType(SelectableText))
            .textSpan!
            .toPlainText(),
        text);
    expect(tester.takeException(), isNull);
  });

  testWidgets('editor search taps a match while website links are disabled',
      (tester) async {
    const text = 'https://example.com';
    final controller = NoteSearchController()
      ..setFields([const NoteSearchField('body', text)])
      ..setQuery('example');
    addTearDown(controller.dispose);
    NoteSearchMatch? tapped;
    var opened = false;
    await _pump(
      tester,
      NoteSearchText(
        controller: controller,
        fieldId: 'body',
        text: text,
        style: _style,
        enableWebLinks: false,
        onMatchTap: (match) => tapped = match,
        onOpenUrl: (_) async {
          opened = true;
          return true;
        },
      ),
    );
    expect(tester.widget<Text>(find.byType(Text)).semanticsLabel, isNull);
    await tester.tapAt(_paragraphOffset(tester, 8, 11));
    await tester.pumpAndSettle();
    expect(tapped, const NoteSearchMatch('body', 8, 15));
    expect(opened, isFalse);
    expect(tester.takeException(), isNull);
  });
}

Offset _paragraphOffset(WidgetTester tester, int start, int end) {
  final text = tester.renderObject<RenderParagraph>(find.byType(RichText));
  final boxes = text.getBoxesForSelection(
      TextSelection(baseOffset: start, extentOffset: end));
  return text.localToGlobal(boxes.first.toRect().center);
}
