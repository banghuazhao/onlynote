import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/domain/model/note_image_layout.dart';
import 'package:onlynote/domain/model/note_text_style.dart';
import 'package:onlynote/domain/model/voice_memo.dart';
import 'package:onlynote/services/note_export.dart';

Map<int, String> _pdfObjects(Uint8List bytes) => {
      for (final match in RegExp(r'(\d+) 0 obj\s*(.*?)\s*endobj', dotAll: true)
          .allMatches(latin1.decode(bytes)))
        int.parse(match[1]!): match[2]!,
    };

List<String> _pdfPages(Map<int, String> objects) => objects.values
    .where((value) => RegExp(r'/Type\s*/Page(?!s)').hasMatch(value))
    .toList();

String _pdfStream(String object) {
  final start = object.indexOf('stream\n') + 'stream\n'.length;
  final end = object.lastIndexOf('\nendstream');
  final bytes = latin1.encode(object.substring(start, end));
  return latin1
      .decode(object.contains('/FlateDecode') ? zlib.decode(bytes) : bytes);
}

List<int> _pdfImageWidths(String page, Map<int, String> objects) {
  final resources = RegExp(r'/XObject<<(.*?)>>', dotAll: true).firstMatch(page);
  return [
    for (final reference
        in RegExp(r'/I\d+\s+(\d+) 0 R').allMatches(resources?[1] ?? ''))
      int.parse(RegExp(r'/Width\s*(\d+)')
          .firstMatch(objects[int.parse(reference[1]!)]!)![1]!),
  ];
}

/// Read this producer's ToUnicode mappings so assertions check actual exported
/// content, including text that lies after a dedicated scanned document page.
String _pdfPageText(String page, Map<int, String> objects) {
  final fonts = <String, Map<String, String>>{};
  final resources = RegExp(r'/Font<<(.*?)>>', dotAll: true).firstMatch(page);
  for (final reference
      in RegExp(r'/(F\d+)\s+(\d+) 0 R').allMatches(resources?[1] ?? '')) {
    final font = objects[int.parse(reference[2]!)]!;
    final unicode = RegExp(r'/ToUnicode\s*(\d+) 0 R').firstMatch(font);
    if (unicode == null) continue;
    final mapping = _pdfStream(objects[int.parse(unicode[1]!)]!);
    fonts[reference[1]!] = {
      for (final pair
          in RegExp(r'<([0-9A-F]{4})>\s*<([0-9A-F]+)>').allMatches(mapping))
        pair[1]!: String.fromCharCodes([
          for (var offset = 0; offset < pair[2]!.length; offset += 4)
            int.parse(pair[2]!.substring(offset, offset + 4), radix: 16),
        ]),
    };
  }
  final contentReference = RegExp(r'/Contents\s*(\d+) 0 R').firstMatch(page)!;
  final content = _pdfStream(objects[int.parse(contentReference[1]!)]!);
  final words = <String>[];
  String? font;
  for (final token in RegExp(r'/(F\d+)\s+[\d.]+\s+Tf|<([0-9a-fA-F]+)>')
      .allMatches(content)) {
    if (token[1] != null) {
      font = token[1];
      continue;
    }
    final value = token[2]!;
    words.add([
      for (var offset = 0; offset + 4 <= value.length; offset += 4)
        fonts[font]?[value.substring(offset, offset + 4).toUpperCase()] ?? '',
    ].join());
  }
  return words.join(' ').replaceAll(RegExp(r'\s+'), ' ');
}

Future<Uint8List> _documentImage(int width, int height, int markerColor) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.drawRect(ui.Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
      ui.Paint()..color = const ui.Color(0xffffffff));
  canvas.drawRect(ui.Rect.fromLTWH(0, 0, width.toDouble(), 4),
      ui.Paint()..color = ui.Color(markerColor));
  canvas.drawRect(
      ui.Rect.fromLTWH(0, (height - 4).toDouble(), width.toDouble(), 4),
      ui.Paint()..color = ui.Color(markerColor));
  for (var y = 12.0; y < height - 8; y += 9) {
    canvas.drawRect(ui.Rect.fromLTWH(8, y, (width - 16).toDouble(), 2),
        ui.Paint()..color = const ui.Color(0xff333333));
  }
  final picture = recorder.endRecording();
  final image = await picture.toImage(width, height);
  try {
    return (await image.toByteData(format: ui.ImageByteFormat.png))!
        .buffer
        .asUint8List();
  } finally {
    image.dispose();
    picture.dispose();
  }
}

Future<NotePdfData> _documentPdfData({
  required List<Uint8List> photos,
  required List<String> paths,
  required List<NoteImageLayout> layouts,
  String title = 'Scanned contract',
  String description = '',
  String date = 'October 7, 2026',
  List<(bool, String)> todos = const [],
  List<String> transcripts = const [],
  String? reminder,
}) async =>
    NotePdfData(
      title: title,
      description: description,
      date: date,
      todos: todos,
      transcripts: transcripts,
      reminder: reminder,
      photos: photos,
      imagePaths: paths,
      imageLayouts: layouts,
      regular: await File('assets/fonts/Roboto-Regular.ttf').readAsBytes(),
      bold: await File('assets/fonts/Roboto-Bold.ttf').readAsBytes(),
      fallback: await File('assets/fonts/DroidSansFallback.ttf').readAsBytes(),
    );

void main() {
  test(
      'plain text exports full content and checklist states without local paths',
      () {
    final note = Note(
        title: 'Trip',
        description: '正文\nSecond line',
        imagePaths: ['/private/photo.jpg'],
        todo: [Todo(title: 'Book', completed: true), Todo(title: 'Pack')]);
    expect(NoteExport.plainText(note, reminder: 'Reminder: tomorrow'),
        'Trip\n\n正文\nSecond line\n\n[x] Book\n[ ] Pack\n\nReminder: tomorrow');
  });
  test('Markdown escapes note text and uses portable photo attachments', () {
    final result = NoteExport.markdown(
        Note(
            title: '[Trip]',
            description: '<script> *not bold*',
            todo: [Todo(title: 'one\ntwo', completed: true)]),
        photos: ['photo-1.png']);
    expect(result, contains(r'# \[Trip\]'));
    expect(result, contains(r'\<script\> \*not bold\*'));
    expect(result, contains('- [x] one\n  two'));
    expect(result, contains('![1](photo-1.png)'));
  });
  test('Markdown places sized photos among styled paragraphs with safe links',
      () {
    const body = 'First\nSecond\nThird';
    const paths = ['note_images/one.jpg', 'note_images/two.jpg'];
    final note =
        Note(description: body, imagePaths: paths, imageLayouts: const [
      NoteImageLayout(
          path: 'note_images/one.jpg',
          textOffset: 6,
          widthFactor: .5,
          xFactor: 1,
          aspectRatio: 2),
      NoteImageLayout(
          path: 'note_images/two.jpg',
          textOffset: 13,
          widthFactor: .25,
          xFactor: 0,
          aspectRatio: 1),
    ], textStyles: const [
      NoteTextStyleRange(start: 6, end: 12, kind: NoteTextStyleKind.bold),
    ]);
    final markdown =
        NoteExport.markdown(note, photos: ['Photo 茶 1.png', 'two.png']);
    expect(markdown.indexOf('First'), lessThan(markdown.indexOf('<img')));
    expect(
        markdown.indexOf('**Second**'), greaterThan(markdown.indexOf('<img')));
    expect(markdown.indexOf('two.png'),
        greaterThan(markdown.indexOf('**Second**')));
    expect(markdown.indexOf('Third'), greaterThan(markdown.indexOf('two.png')));
    expect(markdown, contains('src="Photo%20%E8%8C%B6%201.png"'));
    expect(markdown, contains('width:50%;margin-left:50%;'));
    expect(markdown, contains('width:25%;margin-left:0%;'));
    expect('<img'.allMatches(markdown).length, 2);
    expect(markdown, isNot(contains('note_images/')));
    expect(NoteExport.plainText(note), body);
  });

  test('export filenames are safe, bounded and retain Unicode', () {
    expect(NoteExport.fileStem(Note(title: '../../茶/notes:')), '_.._茶_notes_');
    expect(NoteExport.fileStem(Note(title: '...')), 'note');
    expect(NoteExport.fileStem(Note(title: 'A' * 200)).length, 50);
  });
  test('Markdown uses only stored styles and keeps plain text easy to read',
      () {
    final note = Note(
        description: 'Summary\n• Bring tea\nImportant\n**literal**',
        textStyles: const [
          NoteTextStyleRange(start: 0, end: 7, kind: NoteTextStyleKind.heading),
          NoteTextStyleRange(start: 20, end: 29, kind: NoteTextStyleKind.bold),
        ]);
    final markdown = NoteExport.markdown(note);
    expect(markdown, contains('## Summary'));
    expect(markdown, contains('- Bring tea'));
    expect(markdown, contains('**Important**'));
    expect(markdown, contains(r'\*\*literal\*\*'));
    expect(NoteExport.plainText(note), note.description);
  });
  test('highlight exports mark tags while plain sharing retains original body',
      () {
    final note = Note(description: 'Remember 茶\nBody', textStyles: const [
      NoteTextStyleRange(start: 0, end: 10, kind: NoteTextStyleKind.bold),
      NoteTextStyleRange(start: 0, end: 10, kind: NoteTextStyleKind.highlight),
    ]);
    expect(NoteExport.markdown(note), '<mark>**Remember 茶**</mark>\nBody');
    expect(NoteExport.plainText(note), 'Remember 茶\nBody');
  });
  test(
      'Markdown recordings use relative encoded links and preserve transcripts',
      () {
    final note = Note(description: 'Before the recording', voiceMemos: [
      VoiceMemo(
          id: 'memo',
          path: 'note_audio/memo.m4a',
          durationMs: 2500,
          createdAt: DateTime.utc(2026, 10, 6),
          transcript: '[Reviewed] transcript'),
    ]);
    final markdown = NoteExport.markdown(note,
        recordings: ['Recording 茶 1.m4a'], recordingLabel: '語音備忘');
    expect(markdown, contains('[語音備忘 1](Recording%20%E8%8C%B6%201.m4a)'));
    expect(markdown, contains(r'\[Reviewed\] transcript'));
    expect(markdown, isNot(contains('note_audio/')));
    expect(NoteExport.plainText(note),
        'Before the recording\n\n[Reviewed] transcript');
  });
  test('PDF paginates full long text, checklist, Chinese, and a photo',
      () async {
    final bytes = await buildNotePdf(NotePdfData(
      title: 'Travel notes · 旅行筆記',
      description:
          '${'A walk through the city. 香港的早晨，买茶和麵包。\n' * 180}\nEND OF FULL NOTE',
      date: 'September 13, 2026',
      todos: [(true, 'Booked the train'), (false, '收拾行李')],
      reminder: 'Reminder: Tomorrow at 9am',
      photos: [await File('assets/app_icon.png').readAsBytes()],
      regular: await File('assets/fonts/Roboto-Regular.ttf').readAsBytes(),
      bold: await File('assets/fonts/Roboto-Bold.ttf').readAsBytes(),
      fallback: await File('assets/fonts/DroidSansFallback.ttf').readAsBytes(),
    ));
    expect(ascii.decode(bytes.take(5).toList()), '%PDF-');
    expect(bytes.length, greaterThan(10000));
    await File('/tmp/onlynote-export-preview.pdf').writeAsBytes(bytes);
  });

  test('PDF places photos between paragraphs and bounds a tall photo',
      () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    canvas.drawRect(const ui.Rect.fromLTWH(0, 0, 100, 1000),
        ui.Paint()..color = const ui.Color(0xff69a989));
    canvas.drawRect(const ui.Rect.fromLTWH(0, 0, 100, 25),
        ui.Paint()..color = const ui.Color(0xff333366));
    canvas.drawRect(const ui.Rect.fromLTWH(0, 975, 100, 25),
        ui.Paint()..color = const ui.Color(0xffcc6633));
    final picture = recorder.endRecording();
    final image = await picture.toImage(100, 1000);
    final tall = (await image.toByteData(format: ui.ImageByteFormat.png))!
        .buffer
        .asUint8List();
    image.dispose();
    picture.dispose();
    final square = await File('assets/app_icon.png').readAsBytes();
    const body = 'Before the photo\nStyled middle paragraph\nAfter the photo';
    final bytes = await buildNotePdf(NotePdfData(
      title: 'Photo layout',
      description: body,
      date: '',
      todos: const [],
      photos: [square, square, tall],
      imagePaths: const ['top', 'middle', 'tall'],
      imageLayouts: const [
        NoteImageLayout(
            path: 'top',
            textOffset: 0,
            widthFactor: .25,
            xFactor: 0,
            aspectRatio: 1),
        NoteImageLayout(
            path: 'middle',
            textOffset: 17,
            widthFactor: .5,
            xFactor: 1,
            aspectRatio: 1),
        NoteImageLayout(
            path: 'tall',
            textOffset: 41,
            widthFactor: 1,
            xFactor: .5,
            aspectRatio: .1),
      ],
      textStyles: const [
        NoteTextStyleRange(start: 17, end: 40, kind: NoteTextStyleKind.bold)
      ],
      transcripts: const ['Separate plain transcript'],
      regular: await File('assets/fonts/Roboto-Regular.ttf').readAsBytes(),
      bold: await File('assets/fonts/Roboto-Bold.ttf').readAsBytes(),
      fallback: await File('assets/fonts/DroidSansFallback.ttf').readAsBytes(),
    ));
    expect(ascii.decode(bytes.take(5).toList()), '%PDF-');
    expect(bytes.length, greaterThan(10000));
    await File('/tmp/onlynote-inline-photos-preview.pdf').writeAsBytes(bytes);
  });

  test(
      'PDF preserves styled body, Unicode glyphs, and separate plain transcripts',
      () async {
    const body = '旅行摘要\n• 香港的早晨 😊\nRemember 买茶\n';
    final bytes = await buildNotePdf(NotePdfData(
      title: '',
      description: body * 100,
      textStyles: [
        for (var offset = 0; offset < body.length * 100; offset += body.length)
          NoteTextStyleRange(
              start: offset, end: offset + 4, kind: NoteTextStyleKind.heading),
        for (var offset = 0; offset < body.length * 100; offset += body.length)
          NoteTextStyleRange(
              start: offset + body.indexOf('Remember'),
              end: offset + body.indexOf('Remember') + 'Remember 买茶'.length,
              kind: NoteTextStyleKind.bold),
      ],
      transcripts: const ['Reviewed transcript **literal markers**'],
      date: '',
      todos: const [],
      photos: const [],
      glyphs: {
        '😊': await File('assets/app_icon.png').readAsBytes(),
      },
      regular: await File('assets/fonts/Roboto-Regular.ttf').readAsBytes(),
      bold: await File('assets/fonts/Roboto-Bold.ttf').readAsBytes(),
      fallback: await File('assets/fonts/DroidSansFallback.ttf').readAsBytes(),
    ));
    expect(ascii.decode(bytes.take(5).toList()), '%PDF-');
    expect(bytes.length, greaterThan(10000));
    expect(latin1.decode(bytes), contains('Roboto-Bold'));
    await File('/tmp/onlynote-formatted-export-preview.pdf')
        .writeAsBytes(bytes);
  });

  test('PDF fills only marked ranges and preserves selectable long note text',
      () async {
    const opening = 'Highlighted title\nRemember 茶 😊\n';
    final body = '$opening${'Plain text after the marker.\n' * 120}LAST LINE';
    final bytes = await buildNotePdf(NotePdfData(
      title: '',
      description: body,
      date: '',
      todos: const [],
      photos: const [],
      textStyles: const [
        NoteTextStyleRange(start: 0, end: 17, kind: NoteTextStyleKind.heading),
        NoteTextStyleRange(
            start: 0, end: 17, kind: NoteTextStyleKind.highlight),
        NoteTextStyleRange(start: 18, end: 31, kind: NoteTextStyleKind.bold),
        NoteTextStyleRange(
            start: 18, end: 31, kind: NoteTextStyleKind.highlight),
      ],
      glyphs: {'😊': await File('assets/app_icon.png').readAsBytes()},
      regular: await File('assets/fonts/Roboto-Regular.ttf').readAsBytes(),
      bold: await File('assets/fonts/Roboto-Bold.ttf').readAsBytes(),
      fallback: await File('assets/fonts/DroidSansFallback.ttf').readAsBytes(),
    ));
    final objects = _pdfObjects(bytes);
    final pages = _pdfPages(objects);
    expect(pages.length, greaterThan(1));
    final streams = [
      for (final page in pages)
        _pdfStream(objects[int.parse(
            RegExp(r'/Contents\s*(\d+) 0 R').firstMatch(page)![1]!)]!),
    ];
    bool hasMarker(String stream) =>
        RegExp(r'([\d.]+)\s+([\d.]+)\s+([\d.]+)\s+rg').allMatches(stream).any(
            (match) =>
                (double.parse(match[1]!) - 1).abs() < .001 &&
                (double.parse(match[2]!) - 231 / 255).abs() < .001 &&
                (double.parse(match[3]!) - 160 / 255).abs() < .001);
    expect(hasMarker(streams.first), isTrue);
    expect(hasMarker(streams.last), isFalse);
    final exportedText =
        pages.map((page) => _pdfPageText(page, objects)).join(' ');
    expect(exportedText, contains('Highlighted title'));
    expect(exportedText, contains('Remember 茶'));
    expect(exportedText, contains('LAST LINE'));
    expect(exportedText, isNot(contains('<mark>')));
    await File('/tmp/onlynote-highlight-export-preview.pdf')
        .writeAsBytes(bytes);
  });

  test('document-only PDF has one complete page per scan in reviewed order',
      () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final bytes = await buildNotePdf(await _documentPdfData(
      photos: [
        await _documentImage(90, 140, 0xff336699),
        await _documentImage(160, 80, 0xffaa5533),
      ],
      paths: const ['portrait', 'landscape'],
      // The user's reviewed order is independent of attachment file order.
      layouts: const [
        NoteImageLayout(path: 'landscape', textOffset: 0, isDocumentPage: true),
        NoteImageLayout(path: 'portrait', textOffset: 0, isDocumentPage: true),
      ],
    ));
    final objects = _pdfObjects(bytes);
    final pages = _pdfPages(objects);
    expect(pages, hasLength(2));
    expect(_pdfImageWidths(pages[0], objects), [160]);
    expect(_pdfImageWidths(pages[1], objects), [90]);
    expect(pages[0], contains('/MediaBox[0 0 841.88976 595.27559]'));
    expect(pages[1], contains('/MediaBox[0 0 595.27559 841.88976]'));
    expect(pages.every((page) => !page.contains('/Font')), isTrue);
    expect(latin1.decode(bytes), contains('Scanned contract'));
    await File('/tmp/onlynote-scan-pages-preview.pdf').writeAsBytes(bytes);
  });

  test(
      'mixed PDF keeps ordinary photos and text before between and after scans',
      () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    const body =
        'Before the first scan\nBetween the scans\nAfter the second scan';
    final bytes = await buildNotePdf(await _documentPdfData(
      title: 'Mixed document note',
      description: body,
      photos: [
        await _documentImage(64, 64, 0xff448866),
        await _documentImage(90, 140, 0xff336699),
        await _documentImage(160, 80, 0xffaa5533),
      ],
      paths: const ['photo', 'first-scan', 'second-scan'],
      layouts: [
        const NoteImageLayout(path: 'photo', textOffset: 0, widthFactor: .25),
        NoteImageLayout(
            path: 'first-scan',
            textOffset: body.indexOf('Between'),
            isDocumentPage: true),
        NoteImageLayout(
            path: 'second-scan',
            textOffset: body.indexOf('After'),
            isDocumentPage: true),
      ],
      todos: const [(false, 'File the original')],
      transcripts: const ['Reviewed voice transcript'],
      reminder: 'Reminder: Friday morning',
    ));
    final objects = _pdfObjects(bytes);
    final pages = _pdfPages(objects);
    expect(pages, hasLength(5));
    expect(pages.map((page) => _pdfImageWidths(page, objects)), [
      [64],
      [90],
      [],
      [160],
      []
    ]);
    final firstText = _pdfPageText(pages[0], objects);
    expect(firstText, contains('Mixed document note'));
    expect(firstText, contains('October 7, 2026'));
    expect(firstText, contains('Before the first scan'));
    expect(_pdfPageText(pages[2], objects), contains('Between the scans'));
    final lastText = _pdfPageText(pages[4], objects);
    expect(lastText, contains('After the second scan'));
    expect(lastText, contains('Reviewed voice transcript'));
    expect(lastText, contains('File the original'));
    expect(lastText, contains('Reminder: Friday morning'));
    expect(pages[1].contains('/Font'), isFalse);
    expect(pages[3].contains('/Font'), isFalse);
    await File('/tmp/onlynote-scan-mixed-preview.pdf').writeAsBytes(bytes);
  });

  test('unmarked landscape photos retain normal portrait note PDF export',
      () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final bytes = await buildNotePdf(await _documentPdfData(
      title: 'Ordinary photo',
      photos: [await _documentImage(160, 80, 0xffaa5533)],
      paths: const ['photo'],
      layouts: const [NoteImageLayout(path: 'photo', textOffset: 0)],
    ));
    final objects = _pdfObjects(bytes);
    final page = _pdfPages(objects).single;
    expect(page, contains('/MediaBox[0 0 595.27559 841.88976]'));
    expect(_pdfImageWidths(page, objects), [160]);
    expect(_pdfPageText(page, objects), contains('Ordinary photo'));
    expect(_pdfPageText(page, objects), contains('October 7, 2026'));
  });
}
