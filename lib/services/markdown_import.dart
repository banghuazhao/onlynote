import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:onlynote/common/constants.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/domain/model/note_image_layout.dart';
import 'package:onlynote/domain/model/note_text_style.dart';
import 'package:onlynote/services/note_text_format.dart';

enum MarkdownImportWarning { plainTextFormatting, missingImages, emptyFiles }

class MarkdownImportImage {
  const MarkdownImportImage(
      {required this.path, required this.bytes, required this.extension});
  final String path;
  final Uint8List bytes;
  final String extension;
}

class MarkdownImportDocument {
  const MarkdownImportDocument(
      {required this.sourceName,
      required this.note,
      this.images = const [],
      this.warnings = const {}});
  final String sourceName;
  final Note note;
  final List<MarkdownImportImage> images;
  final Set<MarkdownImportWarning> warnings;
  bool get hasContent =>
      (note.title?.trim().isNotEmpty ?? false) ||
      (note.description?.trim().isNotEmpty ?? false) ||
      note.todo.isNotEmpty ||
      images.isNotEmpty;
}

class MarkdownImportBatch {
  const MarkdownImportBatch({required this.documents, this.skippedEmpty = 0});
  final List<MarkdownImportDocument> documents;
  final int skippedEmpty;
}

/// A deliberately bounded Markdown subset matching Onlynote's saved editor.
/// Unsupported syntax remains readable text, including its original URL.
class MarkdownImportParser {
  static MarkdownImportDocument parse(String markdown,
      {required String sourceName,
      Map<String, Uint8List> attachments = const {}}) {
    final text = markdown
        .replaceFirst('\uFEFF', '')
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n');
    final lines = text.split('\n');
    final body = StringBuffer();
    final styles = <NoteTextStyleRange>[];
    final todos = <Todo>[];
    final images = <MarkdownImportImage>[];
    final layouts = <NoteImageLayout>[];
    final warnings = <MarkdownImportWarning>{};
    String? title;
    String? fence;
    var seenContent = false;

    _InlineMarkdown parseInline(String value) {
      final literal = _hasLiteralInlineSyntax(value);
      if (literal || value.contains('://') || value.contains('mailto:')) {
        // These constructs have no equivalent in the saved editor. Parsing
        // emphasis inside them could change code, HTML attributes or a URL.
        warnings.add(MarkdownImportWarning.plainTextFormatting);
        return _InlineMarkdown(
            literal ? value : _unescapeMarkdown(value), const []);
      }
      return _parseInline(value);
    }

    void writeLine(String line, {bool heading = false, bool literal = false}) {
      if (body.isNotEmpty) body.write('\n');
      final start = body.length;
      final inline =
          literal ? _InlineMarkdown(line, const []) : parseInline(line);
      body.write(inline.text);
      for (final range in inline.styles) {
        styles.add(NoteTextStyleRange(
            start: start + range.start,
            end: start + range.end,
            kind: range.kind));
      }
      if (heading && inline.text.trim().isNotEmpty) {
        styles.add(NoteTextStyleRange(
            start: start, end: body.length, kind: NoteTextStyleKind.heading));
      }
    }

    for (var index = 0; index < lines.length; index++) {
      final line = lines[index];
      final trimmed = line.trim();
      final fenceMatch = RegExp(r'^(`{3,}|~{3,})').firstMatch(trimmed);
      if (fence != null) {
        writeLine(line, literal: true);
        if (trimmed.length >= fence.length &&
            ((fence.startsWith('`') && RegExp(r'^`+$').hasMatch(trimmed)) ||
                (fence.startsWith('~') && RegExp(r'^~+$').hasMatch(trimmed)))) {
          fence = null;
        }
        continue;
      }
      if (fenceMatch != null) {
        fence = fenceMatch.group(1)!;
        warnings.add(MarkdownImportWarning.plainTextFormatting);
        writeLine(line, literal: true);
        seenContent = true;
        continue;
      }
      if (line.startsWith('    ') || line.startsWith('\t')) {
        warnings.add(MarkdownImportWarning.plainTextFormatting);
        writeLine(line, literal: true);
        if (trimmed.isNotEmpty) seenContent = true;
        continue;
      }
      final heading = RegExp(r'^ {0,3}(#{1,6})[ \t]+(.*)$').firstMatch(line);
      final setext = index + 1 < lines.length && trimmed.isNotEmpty
          ? RegExp(r'^ {0,3}(=+|-+)[ \t]*$').firstMatch(lines[index + 1])
          : null;
      if (heading != null || setext != null) {
        final isTitleLevel = heading != null
            ? heading.group(1)!.length == 1
            : setext!.group(1)!.startsWith('=');
        final content = heading == null
            ? line
            : heading
                .group(2)!
                .replaceFirst(RegExp(r'[ \t]+#+[ \t]*$'), '')
                .trimRight();
        if (!seenContent && isTitleLevel) {
          final fullTitle = parseInline(content).text;
          title = _truncate(fullTitle, maxTitleCharCount);
          if (title != fullTitle) {
            writeLine(content, heading: true);
            warnings.add(MarkdownImportWarning.plainTextFormatting);
          }
        } else {
          writeLine(content, heading: true);
        }
        if (setext != null && heading == null) index++;
        seenContent = true;
        continue;
      }
      final task = RegExp(r'^\s*[-+*]\s+\[([ xX])\]\s+(.*)$').firstMatch(line);
      if (task != null) {
        var content = task.group(2)!;
        while (index + 1 < lines.length &&
            lines[index + 1].startsWith('  ') &&
            lines[index + 1].trim().isNotEmpty) {
          content += '\n${lines[++index].substring(2)}';
        }
        final value = parseInline(content).text;
        if (value.length > todoMaxCharCount) {
          writeLine('[${task.group(1)}] $value', literal: true);
          warnings.add(MarkdownImportWarning.plainTextFormatting);
        } else if (value.trim().isNotEmpty) {
          todos.add(Todo(
              title: value, completed: task.group(1)!.toLowerCase() == 'x'));
        }
        seenContent = true;
        continue;
      }
      final image = _imageReference(trimmed);
      if (image != null) {
        final resolved = resolveMarkdownImagePath(sourceName, image.source);
        final bytes = resolved == null ? null : attachments[resolved];
        final extension = bytes == null ? null : markdownImageExtension(bytes);
        if (bytes != null && extension != null && images.length < 100) {
          if (body.isNotEmpty && !body.toString().endsWith('\n')) {
            body.write('\n');
          }
          final path = 'markdown-image-${images.length}';
          images.add(MarkdownImportImage(
              path: path, bytes: bytes, extension: extension));
          layouts.add(NoteImageLayout(
              path: path,
              textOffset: body.length,
              widthFactor: image.width,
              xFactor: image.x));
        } else {
          warnings.add(MarkdownImportWarning.missingImages);
          writeLine(line, literal: true);
        }
        seenContent = true;
        continue;
      }
      if (RegExp(r'^ {0,3}(?:(?:\*\s*){3,}|(?:-\s*){3,}|(?:_\s*){3,})$')
          .hasMatch(line)) {
        if (body.isNotEmpty) body.write('\n');
        final start = body.length;
        body.write(noteDividerText);
        styles.add(NoteTextStyleRange(
            start: start, end: body.length, kind: NoteTextStyleKind.divider));
        seenContent = true;
        continue;
      }
      if (RegExp(r'!\[|^\s*>|\|.*\||~~|(?:^|\s)[*_][^*_]+[*_](?:\s|$)')
          .hasMatch(line)) {
        warnings.add(MarkdownImportWarning.plainTextFormatting);
      }
      writeLine(line);
      if (trimmed.isNotEmpty) seenContent = true;
    }
    var description = body.toString();
    // Blank padding after a title is layout rather than note content. Offset
    // translation keeps imported heading/photo anchors tied to the same text.
    final leading = RegExp(r'^(?:[ \t]*\n)+').firstMatch(description)?.end ?? 0;
    description = description
        .substring(leading)
        .replaceFirst(RegExp(r'(?:\n[ \t]*)+$'), '');
    if (description.trim().isEmpty) description = '';
    final cleanStyles = normalizeNoteTextStyles([
      for (final range in styles)
        NoteTextStyleRange(
            start: range.start - leading,
            end: range.end - leading,
            kind: range.kind),
    ], description);
    final cleanLayouts = [
      for (final layout in layouts)
        layout.copyWith(
            textOffset:
                (layout.textOffset - leading).clamp(0, description.length))
    ];
    final fallback = sourceName
        .split('/')
        .last
        .replaceFirst(RegExp(r'\.(md|markdown)$', caseSensitive: false), '');
    return MarkdownImportDocument(
        sourceName: sourceName,
        note: Note(
            title: title ??
                (description.isEmpty && todos.isEmpty && images.isEmpty
                    ? null
                    : _truncate(fallback, maxTitleCharCount)),
            description: description,
            textStyles: cleanStyles,
            todo: todos,
            imagePaths: images.map((image) => image.path).toList(),
            imageLayouts: cleanLayouts),
        images: List.unmodifiable(images),
        warnings: Set.unmodifiable(warnings));
  }
}

class _InlineMarkdown {
  const _InlineMarkdown(this.text, this.styles);
  final String text;
  final List<NoteTextStyleRange> styles;
}

String _unescapeMarkdown(String text) => text.replaceAllMapped(
    RegExp(r'\\([\\`*_{}\[\]<>()#+\-.!|~&])'), (match) => match.group(1)!);

bool _hasLiteralInlineSyntax(String text) {
  var bracket = false;
  var angle = false;
  for (var index = 0; index < text.length; index++) {
    final character = text[index];
    if (character == r'\') {
      index++;
    } else if (character == '`') {
      return true;
    } else if (character == '[') {
      bracket = true;
    } else if (character == ']' &&
        bracket &&
        index + 1 < text.length &&
        text[index + 1] == '(') {
      return true;
    } else if (character == '<') {
      angle = true;
    } else if (character == '>' && angle) {
      return true;
    }
  }
  return false;
}

_InlineMarkdown _parseInline(String text) {
  final out = StringBuffer();
  final styles = <NoteTextStyleRange>[];
  var cursor = 0;
  final strong = RegExp(r'(?<!\\)(\*\*|__)(.+?)(?<!\\)\1');
  for (final match in strong.allMatches(text)) {
    if (match.group(1) == '__' &&
        ((match.start > 0 && RegExp(r'\w').hasMatch(text[match.start - 1])) ||
            (match.end < text.length &&
                RegExp(r'\w').hasMatch(text[match.end])))) {
      continue;
    }
    out.write(_unescapeMarkdown(text.substring(cursor, match.start)));
    final start = out.length;
    out.write(_unescapeMarkdown(match.group(2)!));
    if (out.length > start) {
      styles.add(NoteTextStyleRange(
          start: start, end: out.length, kind: NoteTextStyleKind.bold));
    }
    cursor = match.end;
  }
  out.write(_unescapeMarkdown(text.substring(cursor)));
  return _InlineMarkdown(out.toString(), styles);
}

class _ImageReference {
  const _ImageReference(this.source, {this.width = .85, this.x = .5});
  final String source;
  final double width;
  final double x;
}

_ImageReference? _imageReference(String line) {
  final markdown =
      RegExp(r'^!\[[^\]]*\]\((?:<([^>]+)>|([^\s)]+))(?:\s+"[^"]*")?\)$')
          .firstMatch(line);
  if (markdown != null) {
    return _ImageReference(markdown.group(1) ?? markdown.group(2)!);
  }
  final html = RegExp(r'''^<img\s+[^>]*src\s*=\s*["']([^"']+)["'][^>]*>\s*$''',
          caseSensitive: false)
      .firstMatch(line);
  if (html == null) return null;
  final width = double.tryParse(
          RegExp(r'width:\s*([\d.]+)%').firstMatch(line)?.group(1) ?? '') ??
      85;
  final left = double.tryParse(
          RegExp(r'margin-left:\s*([\d.]+)%').firstMatch(line)?.group(1) ??
              '') ??
      ((100 - width) / 2);
  return _ImageReference(html.group(1)!,
      width: (width / 100).clamp(.25, 1),
      x: width >= 100 ? .5 : (left / (100 - width)).clamp(0, 1));
}

/// Archive-relative references can walk up within the archive, never above it.
String? resolveMarkdownImagePath(String sourceName, String reference) {
  try {
    final uri = Uri.parse(reference);
    if (uri.hasScheme ||
        uri.hasAuthority ||
        reference.startsWith('/') ||
        reference.contains('\\')) {
      return null;
    }
    final decoded = Uri.decodeComponent(uri.path);
    if (decoded.startsWith('/') ||
        decoded.contains('\\') ||
        decoded.contains('\u0000')) {
      return null;
    }
    final parts = sourceName.split('/')..removeLast();
    for (final part in decoded.split('/')) {
      if (part.isEmpty || part == '.') continue;
      if (part == '..') {
        if (parts.isEmpty) return null;
        parts.removeLast();
      } else {
        parts.add(part);
      }
    }
    return parts.join('/');
  } catch (_) {
    return null;
  }
}

String? markdownImageExtension(Uint8List bytes) {
  if (bytes.length >= 24 &&
      bytes[0] == 137 &&
      bytes[1] == 80 &&
      bytes[2] == 78 &&
      bytes[3] == 71) {
    final data = ByteData.sublistView(bytes);
    final width = data.getUint32(16), height = data.getUint32(20);
    return _safeImageSize(width, height) ? 'png' : null;
  }
  if (bytes.length > 4 && bytes[0] == 255 && bytes[1] == 216) {
    var cursor = 2;
    while (cursor + 8 < bytes.length) {
      if (bytes[cursor] != 255) {
        cursor++;
        continue;
      }
      final marker = bytes[cursor + 1];
      if (marker == 216 || marker == 217) {
        cursor += 2;
        continue;
      }
      final length = (bytes[cursor + 2] << 8) | bytes[cursor + 3];
      if (length < 2 || cursor + length + 2 > bytes.length) return null;
      if ({192, 193, 194, 195, 197, 198, 199, 201, 202, 203, 205, 206, 207}
          .contains(marker)) {
        final height = (bytes[cursor + 5] << 8) | bytes[cursor + 6];
        final width = (bytes[cursor + 7] << 8) | bytes[cursor + 8];
        return _safeImageSize(width, height) ? 'jpg' : null;
      }
      cursor += length + 2;
    }
  }
  return null;
}

bool _safeImageSize(int width, int height) =>
    width > 0 &&
    height > 0 &&
    width <= 20000 &&
    height <= 20000 &&
    width * height <= 64000000;

/// ZIPs are never extracted to disk. Header checks happen before decompression,
/// then a bounded output stream also rejects a forged uncompressed-size field.
class MarkdownImportReader {
  static const maxInputBytes = 32 * 1024 * 1024;
  static const maxExpandedBytes = 64 * 1024 * 1024;
  static const maxMarkdownBytes = 2 * 1024 * 1024;
  static const maxImageBytes = 12 * 1024 * 1024;
  static const maxDocuments = 100;

  static MarkdownImportBatch readBytes(String name, Uint8List bytes) {
    if (bytes.length > maxInputBytes) {
      throw const FormatException('Import too large');
    }
    final extension = name.toLowerCase();
    if (extension.endsWith('.md') || extension.endsWith('.markdown')) {
      if (bytes.length > maxMarkdownBytes) {
        throw const FormatException('Markdown too large');
      }
      final document = MarkdownImportParser.parse(utf8.decode(bytes),
          sourceName: name.split('/').last);
      return MarkdownImportBatch(
          documents: document.hasContent ? [document] : [],
          skippedEmpty: document.hasContent ? 0 : 1);
    }
    if (!extension.endsWith('.zip')) {
      throw const FormatException('Unsupported import');
    }
    final directory = ZipDirectory()..read(InputMemoryStream(bytes));
    if (directory.filePosition < 0 ||
        directory.fileHeaders.length > 1000 ||
        directory.fileHeaders.isEmpty) {
      throw const FormatException('Invalid ZIP');
    }
    final entries = <String, ZipFileHeader>{};
    var expanded = 0;
    for (final header in directory.fileHeaders) {
      final path = header.filename;
      final parts = path.split('/');
      if (path.startsWith('/') ||
          path.contains('\\') ||
          path.contains('\u0000') ||
          parts.contains('..') ||
          parts.contains('.') ||
          path.contains(':') ||
          (header.externalFileAttributes >> 16) & 0xf000 == 0xa000 ||
          (header.generalPurposeBitFlag & 1) != 0 ||
          !{0, 8}.contains(header.compressionMethod) ||
          header.uncompressedSize < 0) {
        throw const FormatException('Unsafe ZIP entry');
      }
      if (path.endsWith('/')) continue;
      if (entries.containsKey(path)) {
        throw const FormatException('Duplicate ZIP entry');
      }
      entries[path] = header;
      expanded += header.uncompressedSize;
      if (expanded > maxExpandedBytes ||
          header.uncompressedSize > maxImageBytes) {
        throw const FormatException('Expanded import too large');
      }
    }
    final markdown = entries.keys
        .where((path) =>
            path.toLowerCase().endsWith('.md') ||
            path.toLowerCase().endsWith('.markdown'))
        .toList()
      ..sort();
    if (markdown.isEmpty || markdown.length > maxDocuments) {
      throw const FormatException('No Markdown files');
    }
    Uint8List decode(ZipFileHeader header, int limit) {
      if (header.uncompressedSize > limit) {
        throw const FormatException('Entry too large');
      }
      final out = _BoundedOutput(math.min(limit, header.uncompressedSize));
      header.file!.decompress(out);
      final result = out.getBytes();
      if (result.length != header.uncompressedSize ||
          getCrc32(result) != header.crc32) {
        throw const FormatException('Invalid ZIP content');
      }
      return result;
    }

    final attachments = <String, Uint8List>{};
    for (final entry in entries.entries) {
      if (RegExp(r'\.(png|jpe?g)$', caseSensitive: false).hasMatch(entry.key)) {
        final image = decode(entry.value, maxImageBytes);
        if (markdownImageExtension(image) != null) {
          attachments[entry.key] = image;
        }
      }
    }
    final docs = <MarkdownImportDocument>[];
    var skipped = 0;
    for (final path in markdown) {
      final document = MarkdownImportParser.parse(
          utf8.decode(decode(entries[path]!, maxMarkdownBytes)),
          sourceName: path,
          attachments: attachments);
      if (document.hasContent) {
        docs.add(document);
      } else {
        skipped++;
      }
    }
    return MarkdownImportBatch(
        documents: List.unmodifiable(docs), skippedEmpty: skipped);
  }
}

class _BoundedOutput extends OutputMemoryStream {
  _BoundedOutput(this.limit) : super(size: math.min(limit, 32768));
  final int limit;
  void _check(int count) {
    if (length + count > limit) {
      throw const FormatException('Expanded entry too large');
    }
  }

  @override
  void writeByte(int value) {
    _check(1);
    super.writeByte(value);
  }

  @override
  void writeBytes(List<int> bytes, {int? length}) {
    _check(length ?? bytes.length);
    super.writeBytes(bytes, length: length);
  }

  @override
  void writeStream(InputStream stream) {
    _check(stream.length);
    super.writeStream(stream);
  }
}

String _truncate(String value, int limit) {
  if (value.length <= limit) return value;
  var end = limit;
  final last = value.codeUnitAt(end - 1);
  if (last >= 0xD800 && last <= 0xDBFF) end--;
  return value.substring(0, end);
}
