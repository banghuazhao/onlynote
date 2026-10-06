import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/domain/model/note_image_layout.dart';
import 'package:onlynote/domain/model/note_text_style.dart';
import 'package:onlynote/domain/model/voice_memo.dart';
import 'package:onlynote/services/note_export.dart';

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
}
