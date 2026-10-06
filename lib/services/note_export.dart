import 'package:characters/characters.dart';
import 'dart:typed_data';

import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/domain/model/note_text_style.dart';
import 'package:onlynote/services/note_text_format.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

enum NoteShareFormat { image, plainText, markdown, pdf, audio }

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
        ...note.voiceMemos
            .map((memo) => memo.transcript ?? '')
            .where((text) => text.isNotEmpty),
        if (note.todo.isNotEmpty)
          note.todo
              .map((todo) =>
                  '${todo.completed ? '[x]' : '[ ]'} ${todo.title ?? ''}')
              .join('\n'),
        if (reminder != null) reminder,
      ].join('\n\n');

  static String _escape(String text) => text.replaceAllMapped(
      RegExp(r'[\\`*_{}\[\]<>()#+\-.!|~&]'), (m) => '\\${m[0]}');

  static String markdown(Note note,
          {String? reminder,
          List<String> photos = const [],
          List<String> recordings = const [],
          String recordingLabel = 'Recording'}) =>
      [
        if (note.title?.isNotEmpty == true)
          '# ${_escape(note.title!).replaceAll('\n', ' ')}',
        if (note.description?.isNotEmpty == true)
          noteTextToMarkdown(note.description!, note.textStyles),
        ...note.voiceMemos
            .map((memo) => memo.transcript ?? '')
            .where((text) => text.isNotEmpty)
            .map(_escape),
        if (note.todo.isNotEmpty)
          note.todo
              .map((todo) =>
                  '- [${todo.completed ? 'x' : ' '}] ${_escape(todo.title ?? '').replaceAll('\n', '\n  ')}')
              .join('\n'),
        if (reminder != null) _escape(reminder),
        for (var i = 0; i < photos.length; i++)
          '![${i + 1}](${Uri.encodeComponent(photos[i])})',
        for (var i = 0; i < recordings.length; i++)
          '[${_escape(recordingLabel)} ${i + 1}](${Uri.encodeComponent(recordings[i])})',
      ].join('\n\n');
}

/// Pure PDF generation runs in an isolate; the UI loads fonts and photos first.
Future<Uint8List> buildNotePdf(NotePdfData data) async {
  final regular = pw.Font.ttf(ByteData.sublistView(data.regular));
  final bold = pw.Font.ttf(ByteData.sublistView(data.bold));
  final fallback = pw.Font.ttf(ByteData.sublistView(data.fallback));
  final boldGlyphs =
      TtfParser(ByteData.sublistView(data.bold)).charToGlyphIndexMap;
  final document = pw.Document(title: data.title, creator: 'Onlynote');
  final baseStyle = pw.TextStyle(
      fontNormal: regular,
      fontBold: bold,
      fontFallback: [fallback],
      fontSize: 12,
      lineSpacing: 4);
  pw.Widget text(String value,
      {bool heading = false, List<NoteTextStyleRange> textStyles = const []}) {
    final ranges = normalizeNoteTextStyles(textStyles, value).toList()
      ..sort((a, b) => a.start.compareTo(b.start));
    final style = heading
        ? baseStyle.copyWith(fontWeight: pw.FontWeight.bold, fontSize: 22)
        : baseStyle;
    final spans = <pw.InlineSpan>[];
    final buffer = StringBuffer();
    pw.TextStyle? bufferedStyle;
    bool? bufferedBold, bufferedHeading, bufferedSynthetic;
    void flush() {
      if (buffer.isEmpty) return;
      // pdf's fill text mode omits a reset operator, so explicitly reset it
      // between runs. This zero-size span leaves text metrics unchanged.
      spans.add(pw.WidgetSpan(child: _ResetPdfTextMode()));
      spans.add(pw.TextSpan(text: buffer.toString(), style: bufferedStyle));
      buffer.clear();
    }

    var offset = 0;
    var rangeIndex = 0;
    final active = <NoteTextStyleRange>[];
    for (final character in value.characters) {
      final characterEnd = offset + character.length;
      active.removeWhere((range) => range.end <= offset);
      while (rangeIndex < ranges.length &&
          ranges[rangeIndex].start < characterEnd) {
        active.add(ranges[rangeIndex++]);
      }
      final isHeading =
          active.any((range) => range.kind == NoteTextStyleKind.heading);
      final isBold = isHeading ||
          active.any((range) => range.kind == NoteTextStyleKind.bold);
      // The bundled CJK fallback has no bold face. A thin outline thickens
      // only fallback glyphs, retaining selectable text and identical metrics.
      final syntheticBold = (heading || isBold) &&
          character.runes.any((rune) => !boldGlyphs.containsKey(rune));
      if (bufferedBold != isBold ||
          bufferedHeading != isHeading ||
          bufferedSynthetic != syntheticBold) {
        flush();
        bufferedStyle = style.copyWith(
            fontWeight:
                heading || isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            renderingMode: syntheticBold
                ? PdfTextRenderingMode.fillAndStroke
                : PdfTextRenderingMode.fill,
            fontSize: isHeading ? 18 : style.fontSize);
        bufferedBold = isBold;
        bufferedHeading = isHeading;
        bufferedSynthetic = syntheticBold;
      }
      final glyph = data.glyphs[character];
      if (glyph == null) {
        buffer.write(character);
      } else {
        flush();
        final image = pw.MemoryImage(glyph);
        spans.add(pw.WidgetSpan(
            child: pw.Image(image,
                height: bufferedStyle!.fontSize!,
                width:
                    bufferedStyle.fontSize! * image.width! / image.height!)));
      }
      offset = characterEnd;
    }
    flush();
    return _NotePdfRichText(text: pw.TextSpan(children: spans, style: style));
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
        text(data.description, textStyles: data.textStyles),
        pw.SizedBox(height: 16)
      ],
      for (final transcript in data.transcripts) ...[
        text(transcript),
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

class _NotePdfRichText extends pw.RichText {
  _NotePdfRichText({required super.text})
      : super(overflow: pw.TextOverflow.span);

  @override
  void paint(pw.Context context) {
    context.canvas
      ..saveContext()
      ..setStrokeColor(PdfColors.black)
      ..setLineWidth(.36);
    super.paint(context);
    context.canvas.restoreContext();
  }
}

class _ResetPdfTextMode extends pw.Widget {
  @override
  void layout(pw.Context context, pw.BoxConstraints constraints,
      {bool parentUsesSize = false}) {
    box = const PdfRect(0, 0, 0, 0);
  }

  @override
  void paint(pw.Context context) {
    super.paint(context);
    context.canvas.reset();
  }
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
      this.textStyles = const [],
      this.transcripts = const [],
      this.glyphs = const {}});
  final String title, description, date;
  final List<(bool, String)> todos;
  final List<Uint8List> photos;
  final Uint8List regular, bold, fallback;
  final String? reminder;
  final List<NoteTextStyleRange> textStyles;
  final List<String> transcripts;
  final Map<String, Uint8List> glyphs;
}
