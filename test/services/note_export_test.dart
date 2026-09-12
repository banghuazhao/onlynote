import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/domain/model/note.dart';
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
  test('export filenames are safe, bounded and retain Unicode', () {
    expect(NoteExport.fileStem(Note(title: '../../茶/notes:')), '_.._茶_notes_');
    expect(NoteExport.fileStem(Note(title: '...')), 'note');
    expect(NoteExport.fileStem(Note(title: 'A' * 200)).length, 50);
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
}
