import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/domain/model/note_image_layout.dart';
import 'package:onlynote/domain/model/note_text_style.dart';
import 'package:onlynote/domain/model/voice_memo.dart';
import 'package:onlynote/services/note_edit_history.dart';
import 'package:onlynote/services/note_section_link_capture.dart';
import 'package:onlynote/services/note_section_links.dart';
import 'package:onlynote/services/note_outline.dart';

void main() {
  late DateTime now;
  final histories = <NoteEditHistory>[];

  NoteEditHistory history(Note note,
      {int maxSteps = 100, int maxTextBytes = 4 * 1024 * 1024}) {
    final value = NoteEditHistory(
        initial: NoteEditSnapshot(note: note),
        maxSteps: maxSteps,
        maxTextBytes: maxTextBytes,
        now: () => now);
    histories.add(value);
    return value;
  }

  NoteEditSnapshot snapshot(Note note, {int? titleCursor, int? bodyCursor}) =>
      NoteEditSnapshot(
        note: note,
        titleSelection: titleCursor == null
            ? null
            : TextSelection.collapsed(offset: titleCursor),
        bodySelection: bodyCursor == null
            ? null
            : TextSelection.collapsed(offset: bodyCursor),
      );

  setUp(() => now = DateTime.utc(2026, 10, 7));
  tearDown(() {
    for (final value in histories) {
      value.dispose();
    }
    histories.clear();
  });

  test('continuous title input coalesces and restores text and selection', () {
    final original = Note(id: 'note', title: '');
    final value = history(original);
    value.record(snapshot(original.copyWith(title: 'H'), titleCursor: 1),
        kind: NoteEditKind.titleTyping);
    now = now.add(const Duration(milliseconds: 100));
    value.record(snapshot(original.copyWith(title: 'He'), titleCursor: 2),
        kind: NoteEditKind.titleTyping);
    now = now.add(const Duration(milliseconds: 100));
    value.record(snapshot(original.copyWith(title: 'Hello'), titleCursor: 5),
        kind: NoteEditKind.titleTyping);

    expect(value.undoCount, 1);
    expect(value.undo()!.note.title, '');
    expect(value.canUndo, isFalse);
    expect(value.canRedo, isTrue);
    final restored = value.redo()!;
    expect(restored.note.title, 'Hello');
    expect(restored.titleSelection, const TextSelection.collapsed(offset: 5));
  });

  test('typing pause, field change and cursor movement split runs', () {
    final original = Note(id: 'note', title: '', description: '');
    final value = history(original);
    value.record(snapshot(original.copyWith(title: 'A'), titleCursor: 1),
        kind: NoteEditKind.titleTyping);
    now = now.add(const Duration(seconds: 1));
    value.record(snapshot(original.copyWith(title: 'AB'), titleCursor: 2),
        kind: NoteEditKind.titleTyping);
    final body = value.current.note.copyWith(description: 'One');
    value.record(snapshot(body, titleCursor: 2, bodyCursor: 3),
        kind: NoteEditKind.bodyTyping);
    value.record(snapshot(body, titleCursor: 2, bodyCursor: 0));
    value.record(
        snapshot(body.copyWith(description: 'New One'),
            titleCursor: 2, bodyCursor: 4),
        kind: NoteEditKind.bodyTyping);

    expect(value.undoCount, 4);
    expect(value.undo()!.note.description, 'One');
    expect(value.undo()!.note.description, '');
    expect(value.undo()!.note.title, 'A');
    expect(value.undo()!.note.title, '');
  });

  test('nonadjacent changes do not coalesce even without selection updates',
      () {
    final original = Note(id: 'note', description: 'AB');
    final value = history(original);
    value.record(snapshot(original.copyWith(description: 'ABC')),
        kind: NoteEditKind.bodyTyping);
    value.record(snapshot(original.copyWith(description: 'ZABC')),
        kind: NoteEditKind.bodyTyping);
    expect(value.undoCount, 2);
    expect(value.undo()!.note.description, 'ABC');
  });

  test('natural cursor update after input preserves its typing run', () {
    final original = Note(id: 'note', description: '');
    final value = history(original);
    final first = original.copyWith(description: 'A');
    value.record(snapshot(first), kind: NoteEditKind.bodyTyping);
    value.record(snapshot(first, bodyCursor: 1));
    value.record(snapshot(first.copyWith(description: 'AB'), bodyCursor: 2),
        kind: NoteEditKind.bodyTyping);
    expect(value.undoCount, 1);
    value.record(snapshot(value.current.note, bodyCursor: 0));
    value.record(
        snapshot(value.current.note.copyWith(description: 'ZAB'),
            bodyCursor: 1),
        kind: NoteEditKind.bodyTyping);
    expect(value.undoCount, 2);
  });

  test('backspace and forward delete group continuous deletions', () {
    final original = Note(id: 'note', description: 'ABCD');
    final value = history(original);
    value.record(snapshot(original.copyWith(description: 'ABC')),
        kind: NoteEditKind.bodyTyping);
    value.record(snapshot(original.copyWith(description: 'AB')),
        kind: NoteEditKind.bodyTyping);
    expect(value.undoCount, 1);
    expect(value.undo()!.note.description, 'ABCD');
    value.breakCoalescing();
    value.record(snapshot(original.copyWith(description: 'BCD')),
        kind: NoteEditKind.bodyTyping);
    value.record(snapshot(original.copyWith(description: 'CD')),
        kind: NoteEditKind.bodyTyping);
    expect(value.undoCount, 1);
    expect(value.undo()!.note.description, 'ABCD');
  });

  test('checklist input groups by item and structure always has its own step',
      () {
    final original = Note(id: 'note', todo: [
      Todo(id: 'first', title: ''),
      Todo(id: 'second', title: ''),
    ]);
    final value = history(original);
    value.record(
        snapshot(original.copyWith(todo: [
          original.todo[0].copyWith(title: 'A'),
          original.todo[1],
        ])),
        kind: NoteEditKind.todoTyping,
        fieldId: 'first');
    value.record(
        snapshot(original.copyWith(todo: [
          original.todo[0].copyWith(title: 'AB'),
          original.todo[1],
        ])),
        kind: NoteEditKind.todoTyping,
        fieldId: 'first');
    value.record(
        snapshot(value.current.note.copyWith(todo: [
          value.current.note.todo[0],
          original.todo[1].copyWith(title: 'Second'),
        ])),
        kind: NoteEditKind.todoTyping,
        fieldId: 'second');
    value.record(
        snapshot(value.current.note.copyWith(todo: [
          value.current.note.todo[0].copyWith(completed: true),
          value.current.note.todo[1],
        ])),
        kind: NoteEditKind.todoTyping,
        fieldId: 'first');
    expect(value.undoCount, 3);
    expect(value.undo()!.note.todo[0].completed, isFalse);
    expect(value.undo()!.note.todo[1].title, '');
    expect(value.undo()!.note.todo[0].title, '');
  });

  test('formatting, photo layout and removal are distinct reversible edits',
      () {
    const path = 'note_images/photo.jpg';
    const layout = NoteImageLayout(path: path, textOffset: 0);
    final original = Note(
        id: 'note',
        description: 'Read this',
        imagePaths: [path],
        imageLayouts: [layout]);
    final value = history(original);
    final formatted = original.copyWith(textStyles: [
      const NoteTextStyleRange(start: 0, end: 4, kind: NoteTextStyleKind.bold),
    ]);
    value.record(snapshot(formatted));
    value.record(snapshot(formatted.copyWith(
        imageLayouts: [layout.copyWith(widthFactor: 0.5, xFactor: 0.25)])));
    value
        .record(snapshot(formatted.copyWith(imagePaths: [], imageLayouts: [])));
    expect(value.undoCount, 3);
    expect(value.undo()!.note.imageLayouts.single.widthFactor, 0.5);
    expect(value.undo()!.note.imageLayouts.single, layout);
    expect(value.undo()!.note.textStyles, isEmpty);
    expect(value.redo()!.note.textStyles, formatted.textStyles);
  });

  test('body typing groups offset shifts with the text they accompany', () {
    const path = 'note_images/page.jpg';
    final original = Note(
      id: 'note',
      description: 'Text',
      imagePaths: [path],
      imageLayouts: [const NoteImageLayout(path: path, textOffset: 4)],
      textStyles: [
        const NoteTextStyleRange(
            start: 0, end: 4, kind: NoteTextStyleKind.bold),
      ],
    );
    final value = history(original);
    value.record(
        snapshot(original.copyWith(description: 'Text!', imageLayouts: [
          original.imageLayouts.single.copyWith(textOffset: 5)
        ], textStyles: [
          const NoteTextStyleRange(
              start: 0, end: 5, kind: NoteTextStyleKind.bold),
        ])),
        kind: NoteEditKind.bodyTyping);
    value.record(
        snapshot(original.copyWith(description: 'Text!!', imageLayouts: [
          original.imageLayouts.single.copyWith(textOffset: 6)
        ], textStyles: [
          const NoteTextStyleRange(
              start: 0, end: 6, kind: NoteTextStyleKind.bold),
        ])),
        kind: NoteEditKind.bodyTyping);
    expect(value.undoCount, 1);
    expect(value.undo()!.note.imageLayouts.single.textOffset, 4);
    expect(value.current.note.textStyles.single.end, 4);
  });

  test('library changes never become edits or revert during undo and redo', () {
    final original = Note(id: 'note', title: 'Before', folderId: 'old');
    final value = history(original);
    value.record(snapshot(original.copyWith(title: 'After')));
    final externallyUpdated = value.current.note.copyWith(
        folderId: 'new',
        isArchived: true,
        isPinned: true,
        sortOrder: 42,
        dailyNoteDateKey: '2026-10-07',
        tags: ['Work'],
        linkedNoteIds: ['other'],
        dateTime: now.add(const Duration(days: 1)));
    expect(value.record(snapshot(externallyUpdated)), isFalse);
    final undone = value.undo()!.note;
    expect(undone.title, 'Before');
    expect(undone.folderId, 'new');
    expect(undone.tags, ['Work']);
    expect(undone.linkedNoteIds, ['other']);
    expect(undone.isArchived, isTrue);
    expect(undone.isPinned, isTrue);
    expect(undone.sortOrder, 42);
    expect(undone.dailyNoteDateKey, '2026-10-07');
    expect(undone.dateTime, externallyUpdated.dateTime);
    expect(value.redo()!.note.folderId, 'new');
    expect(value.current.note.title, 'After');
    final latest = externallyUpdated.copyWith(folderId: 'latest');
    expect(value.current.applyTo(latest).folderId, 'latest');
  });

  test('self links survive undo and redo of text written before linking', () {
    final original = Note(id: 'note', description: 'Plan\nBody');
    final value = history(original);
    final formatted = original.copyWith(textStyles: const [
      NoteTextStyleRange(start: 0, end: 4, kind: NoteTextStyleKind.heading)
    ]);
    value.record(snapshot(formatted));
    final written = formatted.copyWith(description: 'Plan\nBody revised');
    value.record(snapshot(written), kind: NoteEditKind.bodyTyping);
    final capture = captureNoteSectionLink(written,
        buildNoteOutline(written.description!, written.textStyles).single)!;
    final linked = capture.target.copyWith(sectionLinks: [capture.link]);
    expect(value.record(snapshot(linked)), isFalse);
    expect(value.undoCount, 2);
    final undoneText = value.undo()!.note;
    expect(undoneText.description, 'Plan\nBody');
    expect(undoneText.sectionLinks, [capture.link]);
    expect(resolveNoteSectionLink(capture.link, [undoneText])?.heading.text,
        'Plan');
    final undoneStyle = value.undo()!.note;
    expect(undoneStyle.textStyles, isEmpty);
    expect(undoneStyle.sectionLinks, [capture.link]);
    expect(resolveNoteSectionLink(capture.link, [undoneStyle]), isNull);
    final redoneStyle = value.redo()!.note;
    expect(resolveNoteSectionLink(capture.link, [redoneStyle])?.heading.text,
        'Plan');
    final redoneText = value.redo()!.note;
    expect(redoneText.description, 'Plan\nBody revised');
    expect(resolveNoteSectionLink(capture.link, [redoneText])?.heading.anchorId,
        capture.link.headingId);
  });

  test('linking after a rename retains heading identity across undo and redo',
      () {
    final original = Note(
        id: 'note',
        description: 'Plan\nBody',
        textStyles: const [
          NoteTextStyleRange(start: 0, end: 4, kind: NoteTextStyleKind.heading)
        ]);
    final value = history(original);
    final renamed = original.copyWith(
        description: 'Launch plan\nBody',
        textStyles: const [
          NoteTextStyleRange(start: 0, end: 11, kind: NoteTextStyleKind.heading)
        ]);
    value.record(snapshot(renamed), kind: NoteEditKind.bodyTyping);
    final capture = captureNoteSectionLink(renamed,
        buildNoteOutline(renamed.description!, renamed.textStyles).single)!;
    expect(
        value.record(
            snapshot(capture.target.copyWith(sectionLinks: [capture.link]))),
        isFalse);
    final undone = value.undo()!.note;
    expect(
        resolveNoteSectionLink(capture.link, [undone])?.heading.text, 'Plan');
    final redone = value.redo()!.note;
    expect(resolveNoteSectionLink(capture.link, [redone])?.heading.text,
        'Launch plan');
  });

  test('link metadata preserves an existing redo stack and its destination',
      () {
    final original = Note(id: 'note', description: 'Plan', textStyles: const [
      NoteTextStyleRange(start: 0, end: 4, kind: NoteTextStyleKind.heading)
    ]);
    final value = history(original);
    value.record(
        snapshot(original
            .copyWith(description: 'Plan revised', textStyles: const [
          NoteTextStyleRange(start: 0, end: 12, kind: NoteTextStyleKind.heading)
        ])),
        kind: NoteEditKind.bodyTyping);
    final restored = value.undo()!.note;
    final capture = captureNoteSectionLink(restored,
        buildNoteOutline(restored.description!, restored.textStyles).single)!;
    expect(
        value.record(
            snapshot(capture.target.copyWith(sectionLinks: [capture.link]))),
        isFalse);
    expect(value.redoCount, 1);
    final redone = value.redo()!.note;
    expect(resolveNoteSectionLink(capture.link, [redone])?.heading.text,
        'Plan revised');
    expect(redone.sectionLinks, [capture.link]);
  });

  test('restoring heading metadata preserves explicit historical identities',
      () {
    final historical = Note(id: 'note', description: 'Plan', textStyles: const [
      NoteTextStyleRange(
          start: 0,
          end: 4,
          kind: NoteTextStyleKind.heading,
          anchorId: 'historical')
    ]);
    final latest = historical.copyWith(textStyles: const [
      NoteTextStyleRange(
          start: 0, end: 4, kind: NoteTextStyleKind.heading, anchorId: 'latest')
    ]);
    final restored = snapshot(historical).applyTo(latest);
    expect(restored.textStyles.single.anchorId, 'historical');
  });

  test('photo geometry change cannot join a body typing run', () {
    const path = 'note_images/photo.jpg';
    const layout = NoteImageLayout(path: path, textOffset: 0);
    final original = Note(
        id: 'note',
        description: '',
        imagePaths: [path],
        imageLayouts: [layout]);
    final value = history(original);
    value.record(snapshot(original.copyWith(description: 'A')),
        kind: NoteEditKind.bodyTyping);
    value.record(
        snapshot(original.copyWith(
            description: 'AB',
            imageLayouts: [layout.copyWith(widthFactor: 0.5)])),
        kind: NoteEditKind.bodyTyping);
    expect(value.undoCount, 2);
    expect(value.undo()!.note.description, 'A');
    expect(
        value.current.note.imageLayouts.single.widthFactor, layout.widthFactor);
  });

  test('new edits discard redo and release its attachment references', () {
    final original = Note(id: 'note');
    final value = history(original);
    value.record(
        snapshot(original.copyWith(imagePaths: ['note_images/old.jpg'])));
    value.undo();
    expect(value.referencedImages, {'note_images/old.jpg'});
    value.record(snapshot(original.copyWith(description: 'A different edit')));
    expect(value.canRedo, isFalse);
    expect(value.referencedImages, isEmpty);
  });

  test('bounded history releases evicted media and retains the earliest undo',
      () {
    final original = Note(id: 'note', imagePaths: ['note_images/old.jpg']);
    final value = history(original, maxSteps: 2);
    value.record(snapshot(original.copyWith(imagePaths: [])));
    value.record(snapshot(value.current.note.copyWith(title: 'One')));
    expect(value.referencedImages, {'note_images/old.jpg'});
    value.record(snapshot(value.current.note.copyWith(title: 'Two')));
    expect(value.undoCount, 2);
    expect(value.referencedImages, isEmpty);
    expect(value.undo()!.note.title, 'One');
    expect(value.undo()!.note.title, isNull);
    expect(value.undo(), isNull);
  });

  test('reset, note identity changes and dispose release session ownership',
      () {
    final first =
        history(Note(id: 'first', imagePaths: ['note_images/first.jpg']));
    final second =
        history(Note(id: 'second', imagePaths: ['note_images/second.jpg']));
    expect(NoteEditHistory.heldImages,
        containsAll(['note_images/first.jpg', 'note_images/second.jpg']));
    first.record(snapshot(Note(id: 'first', imagePaths: [])));
    first.reset(snapshot(Note(id: 'first')));
    expect(NoteEditHistory.heldImages, {'note_images/second.jpg'});
    second.record(snapshot(Note(id: 'another')));
    expect(second.canUndo, isFalse);
    expect(NoteEditHistory.heldImages, isEmpty);
    first.record(
        snapshot(Note(id: 'first', imagePaths: ['note_images/new.jpg'])));
    first.dispose();
    expect(NoteEditHistory.heldImages, isEmpty);
    expect(first.undo(), isNull);
  });

  test('voice attachments and transcript edits retain ownership through undo',
      () {
    final memo = VoiceMemo(
        id: 'voice',
        path: 'note_audio/voice.m4a',
        durationMs: 1000,
        createdAt: now);
    final original = Note(id: 'note', voiceMemos: [memo]);
    final value = history(original);
    value.record(snapshot(original
        .copyWith(voiceMemos: [memo.copyWith(transcript: 'Transcript')])));
    value.record(snapshot(original.copyWith(voiceMemos: [])));
    expect(NoteEditHistory.heldAudio, {'note_audio/voice.m4a'});
    expect(value.undo()!.note.voiceMemos.single.transcript, 'Transcript');
    expect(value.undo()!.note.voiceMemos.single.transcript, isNull);
  });

  test('large text snapshots obey their byte budget and retain nearest undo',
      () {
    final body = List.filled(1500, 'A').join();
    final original = Note(id: 'note', description: body);
    final value = history(original, maxTextBytes: 3100);
    value.record(snapshot(original.copyWith(description: '${body}B')));
    value.record(snapshot(original.copyWith(description: '${body}BC')));
    expect(value.undoCount, 1);
    expect(value.retainedTextBytes, lessThanOrEqualTo(value.maxTextBytes));
    expect(value.undo()!.note.description, '${body}B');
    expect(value.retainedTextBytes, lessThanOrEqualTo(value.maxTextBytes));
    expect(value.redo()!.note.description, '${body}BC');
  });

  test('unchanged large text is shared across structural snapshots', () {
    final body = List.filled(10000, 'A').join();
    final original = Note(id: 'note', description: body);
    final value = history(original, maxTextBytes: 10);
    for (var index = 0; index < 10; index++) {
      value.record(
          snapshot(original.copyWith(imagePaths: ['photo-$index.jpg'])));
    }
    expect(value.undoCount, 10);
    expect(value.retainedTextBytes, 0);
  });

  test('reversing a failed replay preserves both stacks and media ownership',
      () {
    final original = Note(id: 'note', imagePaths: ['original.jpg']);
    final value = history(original);
    value.record(snapshot(original.copyWith(imagePaths: ['crop.jpg'])));
    value.record(snapshot(value.current.note.copyWith(description: 'Caption')));
    value.undo();
    final savedUndoCount = value.undoCount;
    final savedRedoCount = value.redoCount;
    final beforeReplay = value.current;
    value.undo();
    value.redo(); // Journal failure reverses the proposed undo.
    expect(value.current.sameContent(beforeReplay), isTrue);
    expect(value.undoCount, savedUndoCount);
    expect(value.redoCount, savedRedoCount);
    value.redo();
    value.undo(); // Journal failure reverses the proposed redo.
    expect(value.current.sameContent(beforeReplay), isTrue);
    expect(value.undoCount, savedUndoCount);
    expect(value.redoCount, savedRedoCount);
    expect(value.referencedImages, {'original.jpg', 'crop.jpg'});
  });

  test('snapshots own immutable list and checklist cursor copies', () {
    final paths = ['note_images/photo.jpg'];
    final selections = {'task': const TextSelection.collapsed(offset: 2)};
    final captured = NoteEditSnapshot(
        note: Note(id: 'note', imagePaths: paths), todoSelections: selections);
    paths.clear();
    selections.clear();
    expect(captured.note.imagePaths, ['note_images/photo.jpg']);
    expect(captured.todoSelections['task'],
        const TextSelection.collapsed(offset: 2));
    expect(() => captured.todoSelections.clear(), throwsUnsupportedError);
  });
}
