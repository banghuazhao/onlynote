import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/domain/model/note_image_layout.dart';
import 'package:onlynote/services/note_document.dart';

NoteImageLayout photo(String path, int offset) =>
    NoteImageLayout(path: path, textOffset: offset);

void main() {
  test('image layout map round trip and path remapping preserve geometry', () {
    const layout = NoteImageLayout(
      path: 'photo.jpg',
      textOffset: 12,
      widthFactor: .4,
      xFactor: 1,
      aspectRatio: 2,
    );
    expect(NoteImageLayout.tryFromMap(layout.toMap()), layout);
    expect(layout.copyWith(path: 'restored.jpg').toMap(), {
      'path': 'restored.jpg',
      'textOffset': 12,
      'widthFactor': .4,
      'xFactor': 1.0,
      'aspectRatio': 2.0,
    });
    expect(NoteImageLayout.tryFromMap({'path': 'a', 'textOffset': 0}),
        photo('a', 0));
    for (final invalid in <Object?>[
      null,
      [],
      {'path': '', 'textOffset': 0},
      {'path': 'a', 'textOffset': -1},
      {'path': 'a', 'textOffset': 0.0},
      {'path': 'a', 'textOffset': 0, 'widthFactor': 'wide'},
      {'path': 'a', 'textOffset': 0, 'xFactor': double.nan},
      {'path': 'a', 'textOffset': 0, 'aspectRatio': double.infinity},
    ]) {
      expect(NoteImageLayout.tryFromMap(invalid), isNull,
          reason: '$invalid must not enter an imported document');
    }
  });

  test('legacy photos receive safe end anchors in original order', () {
    final layouts = normalizeNoteImageLayouts([], ['b', 'a', 'b'], 'body');
    expect(layouts, [photo('b', 4), photo('a', 4)]);
    expect(() => layouts.add(photo('c', 4)), throwsUnsupportedError);
    expect(normalizeNoteImageLayouts([], ['a'], ''), [photo('a', 0)]);
  });

  test('copy remapping preserves placement and drops failed photo copies', () {
    final left = photo('left', 2)
        .copyWith(widthFactor: .4, xFactor: 0, aspectRatio: 1.5);
    final right = photo('right', 2)
        .copyWith(widthFactor: .6, xFactor: 1, aspectRatio: .5);
    final layouts = remapNoteImageLayouts([
      right,
      photo('missing', 0),
      left,
      photo('invalid', 8)
    ], {
      'left': 'copied-left',
      'right': 'copied-right',
      'invalid': '',
    });
    expect(layouts, [
      right.copyWith(path: 'copied-right'),
      left.copyWith(path: 'copied-left'),
    ]);
    expect(() => layouts.clear(), throwsUnsupportedError);
    expect(
        remapNoteImageLayouts([left, right], {'left': 'same', 'right': 'same'}),
        [left.copyWith(path: 'same')]);
  });

  test('normalization repairs geometry without changing supplied photo order',
      () {
    final layouts = normalizeNoteImageLayouts([
      const NoteImageLayout(
          path: 'b',
          textOffset: 2,
          widthFactor: 4,
          xFactor: -2,
          aspectRatio: double.nan),
      photo('b', 0),
      photo('unknown', 0),
      const NoteImageLayout(
          path: 'a',
          textOffset: -20,
          widthFactor: double.infinity,
          xFactor: double.nan,
          aspectRatio: 40),
    ], [
      'a',
      'b',
      'c'
    ], 'one\ntwo');
    expect(layouts, [
      photo('b', 4).copyWith(widthFactor: 1, xFactor: 0),
      photo('a', 0).copyWith(aspectRatio: 10),
      photo('c', 7),
    ]);
    expect(normalizeNoteImageLayouts(layouts, ['c', 'a', 'b'], 'one\ntwo'),
        layouts);
  });

  test('anchors snap after complete paragraphs and never cut Unicode text', () {
    const body = '👩‍💻é\n中\nend';
    expect(noteImageInsertionOffsets(body), [0, 8, 10, 13]);
    expect(snapNoteImageOffset(1, body), 8);
    expect(snapNoteImageOffset(6, body), 8);
    expect(snapNoteImageOffset(8, body), 8);
    expect(snapNoteImageOffset(9, body), 10);
    expect(snapNoteImageOffset(200, body), 13);
    expect(snapNoteImageOffset(-1, body), 0);
    expect(noteImageInsertionOffsets('a\r\nb\n'), [0, 3, 5]);
    expect(noteImageInsertionOffsets(''), [0]);
  });

  test('strict import validation rejects corrupt layouts and unknown photos',
      () {
    expect(areValidNoteImageLayouts([], ['a'], 'a\nb'), isTrue);
    expect(areValidNoteImageLayouts([photo('a', 2)], ['a'], 'a\nb'), isTrue);
    final invalid = <List<NoteImageLayout>>[
      [photo('unknown', 0)],
      [photo('a', 0), photo('a', 2)],
      [photo('a', -1)],
      [photo('a', 1)],
      [photo('a', 4)],
      [photo('a', 0).copyWith(widthFactor: .24)],
      [photo('a', 0).copyWith(widthFactor: 1.01)],
      [photo('a', 0).copyWith(xFactor: double.nan)],
      [photo('a', 0).copyWith(xFactor: -1)],
      [photo('a', 0).copyWith(aspectRatio: double.infinity)],
      [photo('a', 0).copyWith(aspectRatio: .09)],
    ];
    for (final layouts in invalid) {
      expect(areValidNoteImageLayouts(layouts, ['a'], 'a\nb'), isFalse,
          reason: '$layouts must fail strict import validation');
    }
    expect(areValidNoteImageLayouts([photo('a', 1)], ['a'], '😀\nb'), isFalse);
  });

  test('inserting and deleting earlier text moves photos with their paragraph',
      () {
    final layouts = [photo('a', 2), photo('b', 5)];
    expect(
        rebaseNoteImageLayouts(
            'a\nb\nc', 'first\na\nb\nc', layouts, ['a', 'b']),
        [photo('a', 8), photo('b', 11)]);
    expect(rebaseNoteImageLayouts('a\nb\nc', 'b\nc', layouts, ['a', 'b']),
        [photo('a', 0), photo('b', 3)]);
    expect(rebaseNoteImageLayouts('a\nb\nc', 'c', layouts, ['a', 'b']),
        [photo('a', 0), photo('b', 1)]);
    expect(rebaseNoteImageLayouts('😀\n中', '😃\n中', [photo('a', 3)], ['a']),
        [photo('a', 3)]);
  });

  test('boundary insertion affinity distinguishes text before and after photo',
      () {
    final layouts = [photo('a', 2)];
    expect(rebaseNoteImageLayouts('a\nb', 'a\nnew\nb', layouts, ['a']),
        [photo('a', 6)]);
    expect(
        rebaseNoteImageLayouts('a\nb', 'a\nnew\nb', layouts, ['a'],
            editedPartStart: 2, editedPartEnd: 3),
        [photo('a', 2)]);
    expect(
        rebaseNoteImageLayouts('a\nb', 'a\nnew\nb', layouts, ['a'],
            editedPartStart: 0, editedPartEnd: 2),
        [photo('a', 6)]);
    expect(
        rebaseNoteImageLayouts('body', 'body\nafter', [photo('a', 4)], ['a'],
            editedPartStart: 4, editedPartEnd: 4),
        [photo('a', 5)]);
    expect(
        rebaseNoteImageLayouts('', 'after', [photo('a', 0)], ['a'],
            editedPartStart: 0, editedPartEnd: 0),
        [photo('a', 0)]);
  });

  test('segment context resolves identical repeated paragraph edits', () {
    final layouts = [photo('a', 2), photo('b', 2)];
    final rebased = rebaseNoteImageLayouts(
        'A\nA\n', 'A\nA\nA\n', layouts, ['a', 'b'],
        editedPartStart: 0, editedPartEnd: 2);
    expect(rebased, [photo('a', 4), photo('b', 4)]);
    // Invalid context falls back to the complete-document diff safely.
    expect(
        rebaseNoteImageLayouts('A\nA\n', 'A\nA\nA\n', layouts, ['a', 'b'],
            editedPartStart: 100, editedPartEnd: 101),
        [photo('a', 2), photo('b', 2)]);
  });

  test('typing before, between and after photos sharing one anchor', () {
    final layouts = [photo('a', 0), photo('b', 0)];
    List<NoteImageLayout> insert(Set<String> preceding) =>
        rebaseNoteImageLayouts('', 'new\n', layouts, ['a', 'b'],
            editedPartStart: 0,
            editedPartEnd: 0,
            precedingImagePaths: preceding);
    expect(insert({}), [photo('a', 4), photo('b', 4)]);
    expect(insert({'a'}), [photo('a', 0), photo('b', 4)]);
    expect(insert({'a', 'b'}), [photo('a', 0), photo('b', 0)]);
    // The same affinity works at the end of an existing text paragraph. The
    // added newline is the boundary between that paragraph and new text.
    expect(
        rebaseNoteImageLayouts(
            'old', 'old\nnew\n', [photo('a', 3), photo('b', 3)], ['a', 'b'],
            editedPartStart: 3, editedPartEnd: 3, precedingImagePaths: {'a'}),
        [photo('a', 4), photo('b', 8)]);
  });

  test('deleting a separator puts the image after the merged paragraph', () {
    expect(rebaseNoteImageLayouts('a\nb', 'ab', [photo('a', 2)], ['a']),
        [photo('a', 2)]);
    expect(rebaseNoteImageLayouts('a\nb\nc', 'ab\nc', [photo('a', 2)], ['a']),
        [photo('a', 3)]);
  });

  test('document parts preserve all text and stable equal-anchor photo order',
      () {
    const body = 'a\nb\nc';
    final parts = noteDocumentParts(body, [
      photo('end', 5),
      photo('middle-b', 2),
      photo('start', 0),
      photo('middle-a', 2),
    ]);
    expect(parts, [
      const NoteTextPart(start: 0, end: 0),
      NoteImagePart(layout: photo('start', 0)),
      const NoteTextPart(start: 0, end: 2),
      NoteImagePart(layout: photo('middle-b', 2)),
      const NoteTextPart(start: 2, end: 2),
      NoteImagePart(layout: photo('middle-a', 2)),
      const NoteTextPart(start: 2, end: 5),
      NoteImagePart(layout: photo('end', 5)),
      const NoteTextPart(start: 5, end: 5),
    ]);
    expect(
        parts
            .whereType<NoteTextPart>()
            .map((part) => body.substring(part.start, part.end))
            .join(),
        body);
    expect(() => parts.clear(), throwsUnsupportedError);
    expect(noteDocumentParts('', []), [const NoteTextPart(start: 0, end: 0)]);
  });
}
