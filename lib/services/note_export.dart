import 'package:characters/characters.dart';
import 'dart:typed_data';

import 'package:onlynote/domain/model/note.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

enum NoteShareFormat { image, plainText, markdown, pdf }

class NoteExport {
  static String fileStem(Note note) {
    final title = (note.title ?? '')
        .trim()
        .replaceAll(RegExp(r'[\\/:*?"<>|\x00-\x1f]'), '_');
    final safe = title.replaceAll(RegExp(r'^\.+|\.+$'), '').trim();
    return safe.isEmpty ? 'note' : String.fromCharCodes(safe.runes.take(50));
  }

  static String plainText(Note note, {String? reminder}) => [
        if (note.title?.isNotEmpty == true) note.title!,
        if (note.description?.isNotEmpty == true) note.description!,
        if (note.todo.isNotEmpty)
          note.todo
              .map((todo) =>
                  '${todo.completed ? '[x]' : '[ ]'} ${todo.title ?? ''}')
              .join('\n'),
        if (reminder != null) reminder,
      ].join('\n\n');

  static String _escape(String text) => text.replaceAllMapped(
      RegExp(r'[\\`*_{}\[\]<>()#+\-.!|~]'), (m) => '\\${m[0]}');

  static String markdown(Note note,
          {String? reminder, List<String> photos = const []}) =>
      [
        if (note.title?.isNotEmpty == true)
          '# ${_escape(note.title!).replaceAll('\n', ' ')}',
        if (note.description?.isNotEmpty == true) _escape(note.description!),
        if (note.todo.isNotEmpty)
          note.todo
              .map((todo) =>
                  '- [${todo.completed ? 'x' : ' '}] ${_escape(todo.title ?? '').replaceAll('\n', '\n  ')}')
              .join('\n'),
        if (reminder != null) _escape(reminder),
        for (var i = 0; i < photos.length; i++)
          '![${i + 1}](${Uri.encodeComponent(photos[i])})',
      ].join('\n\n');
}

/// Pure PDF generation runs in an isolate; the UI loads fonts and photos first.
Future<Uint8List> buildNotePdf(NotePdfData data) async {
  final regular = pw.Font.ttf(ByteData.sublistView(data.regular));
  final bold = pw.Font.ttf(ByteData.sublistView(data.bold));
  final fallback = pw.Font.ttf(ByteData.sublistView(data.fallback));
  final document = pw.Document(title: data.title, creator: 'Onlynote');
  final baseStyle = pw.TextStyle(
      font: regular, fontFallback: [fallback], fontSize: 12, lineSpacing: 4);
  pw.Widget text(String value, {bool heading = false}) {
    final style =
        heading ? baseStyle.copyWith(font: bold, fontSize: 22) : baseStyle;
    final spans = <pw.InlineSpan>[];
    final buffer = StringBuffer();
    for (final character in value.characters) {
      final glyph = data.glyphs[character];
      if (glyph == null) {
        buffer.write(character);
      } else {
        if (buffer.isNotEmpty) {
          spans.add(pw.TextSpan(text: buffer.toString()));
          buffer.clear();
        }
        final image = pw.MemoryImage(glyph);
        spans.add(pw.WidgetSpan(
            child: pw.Image(image,
                height: style.fontSize!,
                width: style.fontSize! * image.width! / image.height!)));
      }
    }
    if (buffer.isNotEmpty) spans.add(pw.TextSpan(text: buffer.toString()));
    return pw.RichText(
        text: pw.TextSpan(children: spans, style: style),
        overflow: pw.TextOverflow.span);
  }

  document.addPage(pw.MultiPage(
    pageFormat: PdfPageFormat.a4,
    margin: const pw.EdgeInsets.all(40),
    // Bound pathological input but allow ordinary long notes to span pages.
    maxPages: 1000,
    theme: pw.ThemeData.withFont(
        base: regular, bold: bold, fontFallback: [fallback]),
    footer: (context) => pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Text('${context.pageNumber} / ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600))),
    build: (_) => [
      if (data.title.isNotEmpty) ...[
        text(data.title, heading: true),
        pw.SizedBox(height: 12)
      ],
      if (data.date.isNotEmpty) ...[text(data.date), pw.SizedBox(height: 16)],
      if (data.description.isNotEmpty) ...[
        text(data.description),
        pw.SizedBox(height: 16)
      ],
      for (final todo in data.todos) ...[
        text('${todo.$1 ? '[x]' : '[ ]'} ${todo.$2}'),
        pw.SizedBox(height: 6)
      ],
      if (data.reminder != null) ...[
        pw.SizedBox(height: 12),
        text(data.reminder!)
      ],
      for (final photo in data.photos) ...[
        pw.SizedBox(height: 16),
        pw.Image(pw.MemoryImage(photo),
            width: 515, height: 500, fit: pw.BoxFit.contain),
      ],
    ],
  ));
  return document.save();
}

class NotePdfData {
  const NotePdfData(
      {required this.title,
      required this.description,
      required this.date,
      required this.todos,
      required this.photos,
      required this.regular,
      required this.bold,
      required this.fallback,
      this.reminder,
      this.glyphs = const {}});
  final String title, description, date;
  final List<(bool, String)> todos;
  final List<Uint8List> photos;
  final Uint8List regular, bold, fallback;
  final String? reminder;
  final Map<String, Uint8List> glyphs;
}
