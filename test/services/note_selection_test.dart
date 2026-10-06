import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/domain/model/note_image_layout.dart';
import 'package:onlynote/domain/model/note_text_style.dart';
import 'package:onlynote/domain/model/voice_memo.dart';
import 'package:onlynote/services/note_document.dart';
import 'package:onlynote/services/note_selection.dart';
import 'package:onlynote/services/note_text_format.dart';

void main() {
  test('captures reversed selections and clips all formatting locally', () {
    final snapshot = captureNoteTextSelection(
      text: 'Before heading and after',
      selection: const TextSelection(baseOffset: 18, extentOffset: 7),
      styles: const [
        NoteTextStyleRange(start: 0, end: 14, kind: NoteTextStyleKind.bold),
        NoteTextStyleRange(start: 7, end: 18, kind: NoteTextStyleKind.heading),
        NoteTextStyleRange(
            start: 9, end: 23, kind: NoteTextStyleKind.highlight),
      ],
    )!;
    expect(snapshot.text, 'heading and');
    expect(snapshot.textStyles, const [
      NoteTextStyleRange(start: 0, end: 7, kind: NoteTextStyleKind.bold),
      NoteTextStyleRange(start: 0, end: 11, kind: NoteTextStyleKind.heading),
      NoteTextStyleRange(start: 2, end: 11, kind: NoteTextStyleKind.highlight),
    ]);
  });

  test('copies complete emoji and combining characters at partial offsets', () {
    const text = 'A👩🏽‍💻e\u0301Z';
    final snapshot = captureNoteTextSelection(
      text: text,
      selection: const TextSelection(baseOffset: 2, extentOffset: 9),
      styles: const [
        NoteTextStyleRange(start: 2, end: 9, kind: NoteTextStyleKind.bold),
      ],
    )!;
    expect(snapshot.text, '👩🏽‍💻e\u0301');
    expect(snapshot.textStyles, [
      NoteTextStyleRange(
          start: 0, end: snapshot.text.length, kind: NoteTextStyleKind.bold),
    ]);
    expect(areValidNoteTextStyles(snapshot.textStyles, snapshot.text), isTrue);
  });

  test('rejects empty selections and active input composition', () {
    for (final selection in const [
      TextSelection.collapsed(offset: 2),
      TextSelection(baseOffset: -1, extentOffset: 3),
      TextSelection(baseOffset: 8, extentOffset: 20),
    ]) {
      expect(
          captureNoteTextSelection(text: 'abc', selection: selection), isNull);
    }
    expect(
      captureNoteTextSelection(
        text: 'abc',
        selection: const TextSelection(baseOffset: 0, extentOffset: 3),
        composing: const TextRange(start: 0, end: 2),
      ),
      isNull,
    );
    expect(
      captureNoteTextSelection(
        text: '',
        selection: const TextSelection(baseOffset: 0, extentOffset: 3),
      ),
      isNull,
    );
  });

  test('snapshot stays independent of later source formatting changes', () {
    final styles = [
      const NoteTextStyleRange(
          start: 0, end: 4, kind: NoteTextStyleKind.highlight),
    ];
    final snapshot = captureNoteTextSelection(
      text: 'Keep me',
      selection: const TextSelection(baseOffset: 0, extentOffset: 4),
      styles: styles,
    )!;
    styles.clear();
    expect(snapshot.textStyles, hasLength(1));
    expect(() => snapshot.textStyles.clear(), throwsUnsupportedError);
  });

  test('append retains destination metadata and separate formatting', () {
    final memo = VoiceMemo(
      id: 'memo',
      path: 'note_audio/memo.m4a',
      durationMs: 100,
      createdAt: DateTime(2026, 10, 7),
    );
    final destination = Note(
      id: 'destination',
      title: 'Title',
      description: 'Existing',
      color: Colors.amber,
      dateTime: DateTime(2026, 10, 1),
      todo: [Todo(id: 'todo', title: 'A task', completed: true)],
      imagePaths: ['photo.jpg'],
      imageLayouts: const [
        NoteImageLayout(
            path: 'photo.jpg', textOffset: 0, widthFactor: .5, xFactor: .2),
      ],
      voiceMemos: [memo],
      sortOrder: 8,
      isPinned: true,
      folderId: 'folder',
      tags: ['tag'],
      linkedNoteIds: ['related'],
      dailyNoteDateKey: '2026-10-01',
      textStyles: const [
        NoteTextStyleRange(start: 0, end: 8, kind: NoteTextStyleKind.bold),
      ],
    );
    final copied = NoteTextSelection(text: 'Selected', textStyles: const [
      NoteTextStyleRange(start: 0, end: 8, kind: NoteTextStyleKind.heading),
      NoteTextStyleRange(start: 0, end: 8, kind: NoteTextStyleKind.highlight),
      NoteTextStyleRange(start: 0, end: 8, kind: NoteTextStyleKind.bold),
    ]);
    final result = appendSelectionToNote(destination, copied);
    expect(result.description, 'Existing\n\nSelected');
    expect(result.textStyles, const [
      NoteTextStyleRange(start: 0, end: 8, kind: NoteTextStyleKind.bold),
      NoteTextStyleRange(start: 10, end: 18, kind: NoteTextStyleKind.bold),
      NoteTextStyleRange(start: 10, end: 18, kind: NoteTextStyleKind.heading),
      NoteTextStyleRange(start: 10, end: 18, kind: NoteTextStyleKind.highlight),
    ]);
    expect(
      result.copyWith(
          description: destination.description,
          textStyles: destination.textStyles,
          imageLayouts: destination.imageLayouts),
      destination,
    );
    expect(destination.description, 'Existing');
  });

  test('append keeps final and legacy photos before copied text', () {
    final destination = Note(
      description: 'Existing',
      imagePaths: ['placed.jpg', 'legacy.jpg'],
      imageLayouts: const [
        NoteImageLayout(
          path: 'placed.jpg',
          textOffset: 8,
          widthFactor: .6,
          xFactor: .3,
          aspectRatio: 2,
        ),
      ],
    );
    final result =
        appendSelectionToNote(destination, NoteTextSelection(text: 'Copied'));
    expect(result.imageLayouts.map((layout) => layout.textOffset), [9, 9]);
    expect(result.imageLayouts.first.widthFactor, .6);
    expect(result.imageLayouts.first.xFactor, .3);
    expect(result.imageLayouts.first.aspectRatio, 2);
    final parts = noteDocumentParts(result.description!, result.imageLayouts);
    final last = parts.last as NoteTextPart;
    expect(result.description!.substring(last.start, last.end), '\nCopied');
  });

  test('photo-only destination appends text after its photos', () {
    final destination = Note(imagePaths: ['legacy.jpg']);
    final result =
        appendSelectionToNote(destination, NoteTextSelection(text: 'Copied'));
    expect(result.description, 'Copied');
    expect(result.imageLayouts.single.textOffset, 0);
    final parts = noteDocumentParts(result.description!, result.imageLayouts);
    expect(parts[1], isA<NoteImagePart>());
    expect(parts.last, const NoteTextPart(start: 0, end: 6));
  });

  test('append validates old styles before adding text and avoids extra gaps',
      () {
    for (final before in ['Existing\n', 'Existing\n\n']) {
      final destination = Note(description: before, textStyles: const [
        NoteTextStyleRange(start: 0, end: 100, kind: NoteTextStyleKind.bold),
      ]);
      final result =
          appendSelectionToNote(destination, NoteTextSelection(text: 'Copied'));
      expect(result.description, 'Existing\n\nCopied');
      expect(result.textStyles.single.end, before.length);
    }
  });

  test('empty snapshot does not change the destination', () {
    final destination = Note(description: 'Keep');
    expect(appendSelectionToNote(destination, NoteTextSelection(text: '')),
        same(destination));
  });
}
