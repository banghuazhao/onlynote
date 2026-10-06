import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/data/dto/note_dto.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/domain/model/note_image_layout.dart';
import 'package:onlynote/services/note_document.dart';
import 'package:onlynote/services/scanned_note.dart';

void main() {
  test('scan pages retain review order, paragraph anchor and existing photos',
      () {
    final note = Note(
        id: 'note',
        description: 'First\nLast',
        imagePaths: const ['note_images/photo.jpg'],
        imageLayouts: const [
          NoteImageLayout(
              path: 'note_images/photo.jpg', textOffset: 0, widthFactor: .6)
        ],
        tags: const ['Work'],
        dailyNoteDateKey: '2026-10-07');
    final scanned = appendScannedPages(
        note,
        const [
          'note_images/page2.jpg',
          'note_images/page1.jpg',
          'note_images/page2.jpg'
        ],
        textOffset: 3);
    expect(scanned.imagePaths, [
      'note_images/photo.jpg',
      'note_images/page2.jpg',
      'note_images/page1.jpg'
    ]);
    expect(scanned.imageLayouts.first, note.imageLayouts.first);
    expect(scanned.imageLayouts.skip(1).map((page) => page.textOffset), [6, 6]);
    expect(
        scanned.imageLayouts
            .skip(1)
            .every((page) => page.isDocumentPage && page.widthFactor == 1),
        isTrue);
    expect(scanned.tags, note.tags);
    expect(scanned.dailyNoteDateKey, note.dailyNoteDateKey);
  });

  test(
      'optional scan metadata is backward compatible and survives storage and remapping',
      () {
    const page = NoteImageLayout(
        path: 'note_images/page.jpg', textOffset: 0, isDocumentPage: true);
    final note = appendScannedPages(Note(id: 'scan'), ['note_images/page.jpg']);
    final stored = NoteDto.fromNote(note).toDomain();
    expect(stored.imageLayouts.single.isDocumentPage, isTrue);
    expect(NoteImageLayout.tryFromMap(page.toMap()), page);
    expect(page.copyWith(path: 'note_images/copy.jpg').isDocumentPage, isTrue);
    expect(
        remapNoteImageLayouts(
                [page], {'note_images/page.jpg': 'note_images/copy.jpg'})
            .single
            .isDocumentPage,
        isTrue);
    final legacy = Map<String, dynamic>.from(page.toMap())
      ..remove('isDocumentPage');
    expect(NoteImageLayout.tryFromMap(legacy)!.isDocumentPage, isFalse);
    expect(NoteImageLayout.tryFromMap({...legacy, 'isDocumentPage': 'true'}),
        isNull);
    expect(page, isNot(page.copyWith(isDocumentPage: false)));
  });
}
