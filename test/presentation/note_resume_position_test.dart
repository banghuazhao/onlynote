import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/domain/model/note_image_layout.dart';
import 'package:onlynote/domain/model/note_text_style.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/formatted_note_text.dart';
import 'package:onlynote/presentation/components/note_document_view.dart';
import 'package:onlynote/presentation/components/note_outline_navigation_controller.dart';
import 'package:onlynote/presentation/components/note_reader_position_controller.dart';
import 'package:onlynote/presentation/components/note_resume_previews.dart';
import 'package:onlynote/services/note_position_store.dart';

Future<void> _pump(WidgetTester tester, Widget child,
    {Size size = const Size(320, 600), double scale = 1}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(MaterialApp(
    localizationsDelegates: const [
      S.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: S.delegate.supportedLocales,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(scale),
        disableAnimations: true,
      ),
      child: child!,
    ),
    home: Scaffold(body: child),
  ));
  await tester.pumpAndSettle();
}

Widget _photo(BuildContext context, String path) =>
    ColoredBox(key: ValueKey('fixture-$path'), color: Colors.blueGrey);

Future<bool> _restore(WidgetTester tester, NoteReaderPositionController reader,
    NoteReadingPosition position) async {
  final pending = reader.restore(position);
  await tester.pumpAndSettle();
  return pending;
}

NoteReaderGlyph _glyph(WidgetTester tester, String containing) {
  final text = find.byWidgetPredicate((widget) =>
      widget is FormattedNoteText && widget.text.contains(containing));
  return NoteReaderGlyph.fromContext(tester.element(text))!;
}

void main() {
  for (final selectable in [true, false]) {
    testWidgets(
        'capture restores the same glyph after reflow and photo resizing (selectable $selectable)',
        (tester) async {
      final body = '${'A long introductory paragraph with many words.\n' * 35}'
          'Resume 👩🏽‍💻 at this recognizable paragraph.\n'
          '${'A following paragraph with enough content.\n' * 30}';
      final target = body.indexOf('Resume');
      final reader = NoteReaderPositionController();
      final scroll = ScrollController();
      addTearDown(reader.dispose);
      addTearDown(scroll.dispose);
      var text = body;
      var photoRatio = 1.3;
      Widget page() => SingleChildScrollView(
            controller: scroll,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: NoteDocumentView(
                key: const ValueKey('document'),
                text: text,
                style: const TextStyle(fontSize: 17, height: 1.5),
                selectable: selectable,
                readerPositionController: reader,
                imagePaths: const ['photo'],
                imageLayouts: [
                  NoteImageLayout(
                      path: 'photo', textOffset: 0, aspectRatio: photoRatio),
                ],
                imageBuilder: _photo,
              ),
            ),
          );
      await _pump(tester, page());
      expect(
          await _restore(
              tester,
              reader,
              NoteReadingPosition.capture(
                  text: body, offset: target, leadingDisplacement: 9)),
          isTrue);
      final captured = reader.capture()!;
      expect(captured.imagePath, isNull);
      expect(captured.resolve(body), target);
      expect(captured.leadingDisplacement, closeTo(9, 1));
      final oldPixels = scroll.offset;
      scroll.jumpTo(0);
      text = 'An inserted opening paragraph.\n$body';
      photoRatio = .45;
      await _pump(tester, page(), scale: 1.8, size: const Size(260, 600));
      expect(await _restore(tester, reader, captured), isTrue);
      final rect =
          _glyph(tester, 'Resume').globalRectForOffset(captured.resolve(text))!;
      expect(rect.top, closeTo(captured.leadingDisplacement, 1));
      expect(scroll.offset, greaterThan(oldPixels));
      for (final editable
          in tester.stateList<EditableTextState>(find.byType(EditableText))) {
        expect(editable.widget.focusNode.hasFocus, isFalse);
      }
      expect(tester.testTextInput.isVisible, isFalse);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('restore expands a folded section and does not focus text',
      (tester) async {
    const heading = 'First heading';
    const prefix = '$heading\n';
    final body = '$prefix${'Paragraph with wrapped body text.\n' * 35}'
        'Resume body paragraph\n${'More text after the target.\n' * 20}';
    final reader = NoteReaderPositionController();
    final scroll = ScrollController();
    addTearDown(reader.dispose);
    addTearDown(scroll.dispose);
    await _pump(
      tester,
      SingleChildScrollView(
        controller: scroll,
        child: NoteDocumentView(
          text: body,
          styles: const [
            NoteTextStyleRange(
                start: 0, end: heading.length, kind: NoteTextStyleKind.heading),
          ],
          readerPositionController: reader,
          collapsibleSections: true,
          style: const TextStyle(fontSize: 17, height: 1.5),
        ),
      ),
      scale: 1.5,
    );
    await tester.tap(find.byKey(const ValueKey('note-section-toggle-0')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Resume body'), findsNothing);
    final position = NoteReadingPosition.capture(
        text: body,
        offset: body.indexOf('Resume body'),
        leadingDisplacement: 5);
    expect(await _restore(tester, reader, position), isTrue);
    expect(find.textContaining('Resume body'), findsOneWidget);
    final rect = _glyph(tester, 'Resume body')
        .globalRectForOffset(position.resolve(body) - prefix.length)!;
    expect(rect.top, closeTo(5, 1));
    expect(tester.testTextInput.isVisible, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('explicit outline navigation cancels pending resume restoration',
      (tester) async {
    final body = '${'Opening text paragraph.\n' * 30}Resume here\n'
        '${'Middle text paragraph.\n' * 30}Outline destination\n'
        '${'Following text paragraph.\n' * 30}';
    final reader = NoteReaderPositionController();
    final outline = NoteOutlineNavigationController();
    final scroll = ScrollController();
    addTearDown(reader.dispose);
    addTearDown(outline.dispose);
    addTearDown(scroll.dispose);
    await _pump(
        tester,
        SingleChildScrollView(
          controller: scroll,
          child: NoteDocumentView(
            text: body,
            style: const TextStyle(fontSize: 17, height: 1.5),
            readerPositionController: reader,
            outlineController: outline,
          ),
        ));
    final resume = reader.restore(NoteReadingPosition.capture(
        text: body, offset: body.indexOf('Resume here')));
    final jump = outline.jumpTo(body.indexOf('Outline destination'));
    await tester.pumpAndSettle();
    expect(await resume, isFalse);
    expect(await jump, isTrue);
    final rect = _glyph(tester, 'Outline destination')
        .globalRectForOffset(body.indexOf('Outline destination'))!;
    expect(rect.top, greaterThanOrEqualTo(0));
    expect(rect.bottom, lessThanOrEqualTo(600));
    expect(tester.takeException(), isNull);
  });

  testWidgets('photo at the next heading expands its owning previous section',
      (tester) async {
    final body = 'First\n${'Body before the photo.\n' * 20}'
        'Second\n${'Body after the photo.\n' * 40}';
    final photoOffset = body.indexOf('Second');
    final reader = NoteReaderPositionController();
    addTearDown(reader.dispose);
    await _pump(
      tester,
      SingleChildScrollView(
        child: NoteDocumentView(
          text: body,
          styles: [
            const NoteTextStyleRange(
                start: 0, end: 5, kind: NoteTextStyleKind.heading),
            NoteTextStyleRange(
                start: photoOffset,
                end: photoOffset + 6,
                kind: NoteTextStyleKind.heading),
          ],
          readerPositionController: reader,
          collapsibleSections: true,
          imagePaths: const ['boundary-photo'],
          imageLayouts: [
            NoteImageLayout(path: 'boundary-photo', textOffset: photoOffset),
          ],
          imageBuilder: _photo,
          style: const TextStyle(fontSize: 17),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('note-section-toggle-0')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('fixture-boundary-photo')), findsNothing);
    expect(
        await _restore(
            tester,
            reader,
            NoteReadingPosition.capture(
                text: body, offset: photoOffset, imagePath: 'boundary-photo')),
        isTrue);
    expect(
        find.byKey(const ValueKey('fixture-boundary-photo')), findsOneWidget);
    expect(
        tester
            .getTopLeft(
                find.byKey(const ValueKey('document-image-boundary-photo')))
            .dy,
        closeTo(0, 1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('user interaction and owner guards reject a delayed restore',
      (tester) async {
    final text = 'Scrollable text.\n' * 150;
    final reader = NoteReaderPositionController();
    final scroll = ScrollController();
    addTearDown(reader.dispose);
    addTearDown(scroll.dispose);
    await _pump(
        tester,
        SingleChildScrollView(
          controller: scroll,
          child: NoteDocumentView(
            text: text,
            readerPositionController: reader,
            style: const TextStyle(fontSize: 17),
          ),
        ));
    final position = NoteReadingPosition.capture(text: text, offset: 1200);
    final canceled = reader.restore(position);
    reader.cancelPendingRestore();
    await tester.pumpAndSettle();
    expect(await canceled, isFalse);
    expect(scroll.offset, 0);
    var allowed = true;
    final guarded = reader.restore(position, canRestore: () => allowed);
    allowed = false;
    await tester.pumpAndSettle();
    expect(await guarded, isFalse);
    expect(scroll.offset, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('top title position replaces a stale deep body position',
      (tester) async {
    final body = 'Body text paragraph.\n' * 100;
    final reader = NoteReaderPositionController();
    final scroll = ScrollController();
    addTearDown(reader.dispose);
    addTearDown(scroll.dispose);
    await _pump(
      tester,
      SingleChildScrollView(
        controller: scroll,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 190, child: Text('Note title and metadata')),
            NoteDocumentView(
              text: body,
              readerPositionController: reader,
              style: const TextStyle(fontSize: 17),
            ),
          ],
        ),
      ),
    );
    final beginning = reader.capture()!;
    expect(beginning.resolve(body), 0);
    expect(beginning.leadingDisplacement, closeTo(190, 1));
    scroll.jumpTo(1500);
    expect(await _restore(tester, reader, beginning), isTrue);
    expect(scroll.offset, closeTo(0, 1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('media-only photo anchors restore after the photo is resized',
      (tester) async {
    final reader = NoteReaderPositionController();
    final scroll = ScrollController();
    addTearDown(reader.dispose);
    addTearDown(scroll.dispose);
    var ratio = .25;
    Widget page() => SingleChildScrollView(
          controller: scroll,
          child: NoteDocumentView(
            text: '',
            readerPositionController: reader,
            imagePaths: const ['first', 'second'],
            imageLayouts: [
              const NoteImageLayout(path: 'first', textOffset: 0),
              NoteImageLayout(
                  path: 'second', textOffset: 0, aspectRatio: ratio),
            ],
            imageBuilder: _photo,
          ),
        );
    await _pump(tester, page());
    scroll.jumpTo(350);
    await tester.pump();
    final saved = reader.capture()!;
    expect(saved.imagePath, 'second');
    expect(saved.imageFraction, greaterThan(0));
    scroll.jumpTo(0);
    ratio = .18;
    await _pump(tester, page());
    expect(await _restore(tester, reader, saved), isTrue);
    final recaptured = reader.capture()!;
    expect(recaptured.imagePath, 'second');
    expect(recaptured.imageFraction, closeTo(saved.imageFraction, .002));
    expect(tester.takeException(), isNull);
  });

  testWidgets('a removed photo falls back to its anchored text position',
      (tester) async {
    final body = '${'A paragraph before the photo.\n' * 30}'
        'The photo was here.\n${'A paragraph after the photo.\n' * 30}';
    final target = body.indexOf('The photo');
    final position = NoteReadingPosition.capture(
      text: body,
      offset: target,
      imagePath: 'removed-photo',
      imageFraction: .5,
    );
    final reader = NoteReaderPositionController();
    addTearDown(reader.dispose);
    await _pump(
        tester,
        SingleChildScrollView(
          child: NoteDocumentView(
            text: body,
            readerPositionController: reader,
            style: const TextStyle(fontSize: 17, height: 1.5),
          ),
        ));
    expect(await _restore(tester, reader, position), isTrue);
    expect(_glyph(tester, 'The photo').globalRectForOffset(target)!.top,
        closeTo(0, 1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('preview supports capture, edited content and scaled restore',
      (tester) async {
    await tester.pumpWidget(noteResumePreview(fontFamily: 'Roboto'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('resume-preview-deep')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('resume-preview-save')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('resume-preview-reflow')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('resume-preview-restore')));
    await tester.pumpAndSettle();
    expect(find.text('Restored reading position'), findsOneWidget);
    expect(tester.testTextInput.isVisible, isFalse);
    expect(tester.takeException(), isNull);
  });
}
