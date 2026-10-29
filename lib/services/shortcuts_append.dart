import 'dart:async';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:onlynote/data/dto/note_dto.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/domain/repository/note_repository.dart';
import 'package:onlynote/services/daily_note.dart';
import 'package:onlynote/services/note_autosave.dart';
import 'package:onlynote/services/note_creation_limit.dart';
import 'package:onlynote/services/note_mutations.dart';
import 'package:onlynote/services/note_selection.dart';
import 'package:onlynote/services/note_selection_transfer.dart';
import 'package:onlynote/services/premium_access.dart';
import 'package:onlynote/services/shortcuts_append_journal.dart';
import 'package:uuid/uuid.dart';

enum ShortcutAppendDestination { today, note, inbox }

class ShortcutAppendRequest {
  const ShortcutAppendRequest(
      {required this.id,
      required this.text,
      required this.destination,
      required this.createdAt,
      this.noteId});

  final String id;
  final String text;
  final ShortcutAppendDestination destination;
  final int createdAt;
  final String? noteId;

  Map<String, Object> toMap() => {
        'version': 1,
        'id': id,
        'text': text,
        'destination': destination.name,
        'createdAt': createdAt,
        if (noteId != null) 'noteId': noteId!,
      };

  static ShortcutAppendRequest? parse(Object? value) {
    if (value is! Map || value['version'] != 1) return null;
    final id = value['id'];
    final text = value['text'];
    final createdAt = value['createdAt'];
    final noteId = value['noteId'];
    final destination = ShortcutAppendDestination.values
        .where((item) => item.name == value['destination'])
        .firstOrNull;
    if (id is! String ||
        !RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$')
            .hasMatch(id) ||
        text is! String ||
        text.trim().isEmpty ||
        text.length > 100000 ||
        createdAt is! int ||
        createdAt < 0 ||
        createdAt > 8640000000000000 ||
        destination == null ||
        (destination == ShortcutAppendDestination.note &&
            (noteId is! String || noteId.isEmpty || noteId.length > 512)) ||
        (noteId != null && noteId is! String)) {
      return null;
    }
    return ShortcutAppendRequest(
        id: id,
        text: text,
        destination: destination,
        createdAt: createdAt,
        noteId: noteId as String?);
  }
}

enum ShortcutAppendFailure {
  saveBlocked,
  premiumRequired,
  unavailable,
  conflict,
  failed
}

class ShortcutAppendException implements Exception {
  const ShortcutAppendException(this.failure);
  final ShortcutAppendFailure failure;
}

abstract interface class ShortcutAppendJournal {
  Object? read(String key);
  Iterable<String> get keys;
  Future<void> write(String key, Object value);
  Future<void> remove(String key);
}

class HiveShortcutAppendJournal implements ShortcutAppendJournal {
  const HiveShortcutAppendJournal(this.box);
  final Box box;
  @override
  Object? read(String key) => box.get(key);
  @override
  Iterable<String> get keys => box.keys.whereType<String>();
  @override
  Future<void> write(String key, Object value) async {
    await box.put(key, value);
    await box.flush();
  }

  @override
  Future<void> remove(String key) async {
    await box.delete(key);
    await box.flush();
  }
}

/// Appending runs through the destination's active editor or normal autosave
/// queue. A durable before/after receipt prevents a retry from appending twice.
/// If an interrupted request and later text edits cannot be distinguished, its
/// original text remains pending for explicit review instead of guessing.
class ShortcutsAppendService {
  ShortcutsAppendService(
      {required this.repository,
      required this.journal,
      required this.store,
      required this.readDraft,
      this.premiumAccess,
      NoteSelectionTransfer? transfer,
      DateTime Function()? now,
      String Function()? createId})
      : _transfer = transfer ??
            NoteSelectionTransfer(
                repository: repository, store: store, readDraft: readDraft),
        _now = now ?? DateTime.now,
        _createId = createId ?? const Uuid().v4;

  static const journalPrefix = shortcutAppendJournalPrefix;
  static const receiptPrefix = '_shortcuts_append_done_v1.';
  static const inboxKey = '_shortcuts_inbox_note_v1';
  final NoteRepository repository;
  final ShortcutAppendJournal journal;
  final NoteAutosaveStore store;
  final Note? Function(String id) readDraft;
  final PremiumAccess? premiumAccess;
  final NoteSelectionTransfer _transfer;
  final DateTime Function() _now;
  final String Function() _createId;
  Future<void>? _tail;

  List<ShortcutAppendRequest> get retainedRequests => [
        for (final key in journal.keys)
          if (key.startsWith(journalPrefix))
            if (journal.read(key) case final Map record)
              if (ShortcutAppendRequest.parse(record['request'])
                  case final request?)
                request,
      ];

  Future<T> _serial<T>(Future<T> Function() action) async {
    final previous = _tail;
    final finished = Completer<void>();
    _tail = finished.future;
    try {
      if (previous != null) await previous;
      return await NoteMutations.run(action);
    } finally {
      if (identical(_tail, finished.future)) _tail = null;
      finished.complete();
    }
  }

  Future<Note?> apply(
    ShortcutAppendRequest request, {
    required Future<void> Function(String) acknowledge,
    required String Function(DateTime) titleForDay,
    required String inboxTitle,
  }) =>
      _serial(() async {
        if (ShortcutAppendRequest.parse(request.toMap()) == null) {
          throw const FormatException('Invalid append request');
        }
        final key = '$journalPrefix${request.id}';
        final raw = journal.read(key);
        var record =
            raw is Map ? Map<String, Object?>.from(raw) : <String, Object?>{};
        if (record['discarded'] == true) {
          await _finishDiscard(request.id, record, acknowledge);
          return null;
        }
        final completed = journal.read('$receiptPrefix${request.id}');
        if (completed is Map) {
          await acknowledge(request.id);
          await journal.remove(key);
          return _savedNote(completed['noteId'] as String?);
        }
        if (record.isNotEmpty &&
            ShortcutAppendRequest.parse(record['request'])
                    ?.toMap()
                    .toString() !=
                request.toMap().toString()) {
          throw const ShortcutAppendException(ShortcutAppendFailure.conflict);
        }
        if (record['committed'] == true) {
          final note = _savedNote(record['noteId'] as String?);
          await _retainReceipt(request.id, record['noteId'] as String?);
          await acknowledge(request.id);
          await journal.remove(key);
          return note;
        }
        Note target;
        if (record['target'] case final NoteDto dto) {
          final noteId = dto.id;
          final saved = _savedNote(noteId);
          final draft = noteId == null ? null : readDraft(noteId);
          final before = record['before'];
          final after = record['after'];
          if (saved?.isDeleted == true ||
              saved?.isArchived == true ||
              (saved == null && record['new'] != true)) {
            throw const ShortcutAppendException(
                ShortcutAppendFailure.unavailable);
          }
          final savedBody = saved?.description ?? '';
          final savedHasAppend = saved != null &&
              after is String &&
              (savedBody == after ||
                  (after.isNotEmpty && savedBody.contains(after)));
          if (draft != null && saved != null && !savedHasAppend) {
            final baseline = record['savedBefore'];
            if (baseline is! NoteDto ||
                !_sameContent(saved, baseline.toDomain())) {
              throw const ShortcutAppendException(
                  ShortcutAppendFailure.conflict);
            }
          }
          if (savedHasAppend) {
            // The note save already committed. Never replay an older recovery
            // snapshot over later saved edits, even if acknowledgement failed.
            if (draft != null && !_sameContent(draft, dto.toDomain())) {
              throw const ShortcutAppendException(
                  ShortcutAppendFailure.conflict);
            }
            target = saved;
            if (draft != null) await store.removeDraft(noteId!);
            record = {...record, 'committed': true};
          } else if (draft != null &&
              after is String &&
              (draft.description == after ||
                  (draft.description ?? '').contains(after))) {
            if (saved == null) {
              target = draft;
              await _saveNew(target);
            } else {
              final baseline = record['savedBefore'];
              if (baseline is! NoteDto ||
                  !_sameContent(saved, baseline.toDomain())) {
                // A newer checklist/title/photo/transcript edit is independent
                // of this append. Keep both snapshots for explicit review.
                throw const ShortcutAppendException(
                    ShortcutAppendFailure.conflict);
              }
              target = _withLibraryMetadata(draft, saved);
              await store.writeDraft(target);
              await store.saveNote(target);
              await store.removeDraft(noteId!);
            }
            record = {...record, 'committed': true};
          } else if (saved == null && before == null && record['new'] == true) {
            target = dto.toDomain();
            if (request.destination == ShortcutAppendDestination.inbox) {
              await journal.write(inboxKey, target.id!);
            }
            await _saveNew(target);
            record = {...record, 'committed': true};
          } else if (saved == null || (draft ?? saved).description != before) {
            throw const ShortcutAppendException(ShortcutAppendFailure.conflict);
          } else {
            target = await _append(
                _withLibraryMetadata(draft ?? saved, saved), request.text);
            record = {...record, 'committed': true};
          }
        } else {
          final resolved = await _resolve(request, titleForDay, inboxTitle);
          final existing = _savedNote(resolved.id);
          final draft = readDraft(resolved.id!);
          final current = existing == null
              ? (draft ?? resolved)
              : _withLibraryMetadata(draft ?? existing, existing);
          if (current.isDeleted || current.isArchived) {
            throw const ShortcutAppendException(
                ShortcutAppendFailure.unavailable);
          }
          final after = appendSelectionToNote(
                  current, NoteTextSelection(text: request.text))
              .copyWith(dateTime: _now());
          record = {
            'request': request.toMap(),
            'noteId': current.id,
            'target': NoteDto.fromNote(after),
            if (existing != null) 'savedBefore': NoteDto.fromNote(existing),
            'new': existing == null,
            'before': existing == null ? null : current.description ?? '',
            'after': after.description ?? '',
            'committed': false,
          };
          await journal.write(key, record);
          if (existing == null) {
            if (request.destination == ShortcutAppendDestination.inbox) {
              await journal.write(inboxKey, current.id!);
            }
            target = after;
            await _saveNew(target);
          } else {
            target = await _append(current, request.text);
          }
          record = {...record, 'committed': true};
        }
        await journal.write(key, record);
        await _retainReceipt(request.id, target.id);
        await acknowledge(request.id);
        await journal.remove(key);
        return target;
      });

  static bool _sameContent(Note a, Note b) =>
      a.title == b.title &&
      a.description == b.description &&
      listEquals(a.todo, b.todo) &&
      listEquals(a.imagePaths, b.imagePaths) &&
      listEquals(a.imageLayouts, b.imageLayouts) &&
      listEquals(a.voiceMemos, b.voiceMemos) &&
      listEquals(a.textStyles, b.textStyles);

  static Note _withLibraryMetadata(Note content, Note saved) =>
      content.copyWith(
          isArchived: saved.isArchived,
          isPinned: saved.isPinned,
          deletedAt: saved.deletedAt,
          folderId: saved.folderId,
          dailyNoteDateKey: saved.dailyNoteDateKey,
          sortOrder: saved.sortOrder,
          cardStyle: saved.cardStyle,
          color: saved.color,
          tags: saved.tags,
          linkedNoteIds: saved.linkedNoteIds,
          sectionLinks: saved.sectionLinks);

  Future<void> _retainReceipt(String id, String? noteId) async {
    await journal.write('$receiptPrefix$id', {
      if (noteId != null) 'noteId': noteId,
      'processedAt': _now().millisecondsSinceEpoch,
    });
    // Acknowledgement deletes the native source file; a bounded receipt window
    // also protects against duplicate delivery already queued in this process.
    final receipts =
        journal.keys.where((key) => key.startsWith(receiptPrefix)).toList();
    if (receipts.length > 1000) {
      int time(String key) => switch (journal.read(key)) {
            {'processedAt': final int value} => value,
            _ => 0,
          };
      receipts.sort((a, b) => time(a).compareTo(time(b)));
      for (final key in receipts.take(receipts.length - 1000)) {
        await journal.remove(key);
      }
    }
  }

  Note? _savedNote(String? id) {
    if (id == null) return null;
    return repository
        .getAllNotes()
        .where((note) => note.id == id)
        .firstOrNull
        ?.toDomain();
  }

  /// Requests for one destination keep their order when an older save fails.
  /// Other notes can still finish while that destination waits for review.
  String destinationKey(ShortcutAppendRequest request,
      {required String inboxTitle}) {
    final raw = journal.read('$journalPrefix${request.id}');
    if (raw is Map && raw['noteId'] is String) return 'note:${raw['noteId']}';
    if (request.destination == ShortcutAppendDestination.note) {
      return 'note:${request.noteId}';
    }
    if (request.destination == ShortcutAppendDestination.inbox) {
      final stored = journal.read(inboxKey);
      if (stored is String) return 'note:$stored';
      final matches = repository
          .getAllNotes()
          .where((note) =>
              !note.isDeleted &&
              !note.isArchived &&
              note.title?.trim() == inboxTitle)
          .toList();
      return matches.length == 1 ? 'note:${matches.single.id}' : 'inbox';
    }
    final day =
        DateTime.fromMillisecondsSinceEpoch(request.createdAt).toLocal();
    final existing = DailyNoteService(repository).existingForDay(day);
    return existing?.id != null
        ? 'note:${existing!.id}'
        : 'today:${day.year}-${day.month}-${day.day}';
  }

  Future<Note> _append(Note target, String text) async {
    if (!await _transfer.copyToExisting(
        target.id!, NoteTextSelection(text: text))) {
      throw const ShortcutAppendException(ShortcutAppendFailure.failed);
    }
    final saved = _savedNote(target.id!);
    if (saved == null || saved.isDeleted) {
      throw const ShortcutAppendException(ShortcutAppendFailure.unavailable);
    }
    return saved;
  }

  Future<void> _saveNew(Note note) async {
    if (!NoteCreationLimit.canSave(repository, note.id,
        access: premiumAccess)) {
      throw const PremiumRequired(PremiumFeature.notes);
    }
    await store.writeDraft(note);
    await store.saveNote(note);
    await store.removeDraft(note.id!);
  }

  Future<Note> _resolve(ShortcutAppendRequest request,
      String Function(DateTime) titleForDay, String inboxTitle) async {
    if (request.destination == ShortcutAppendDestination.note) {
      final note = _savedNote(request.noteId);
      if (note == null || note.isDeleted || note.isArchived) {
        throw const ShortcutAppendException(ShortcutAppendFailure.unavailable);
      }
      return note;
    }
    if (request.destination == ShortcutAppendDestination.today) {
      return DailyNoteService(repository,
              premiumAccess: premiumAccess,
              now: () => DateTime.fromMillisecondsSinceEpoch(request.createdAt))
          .openToday(titleForDay: titleForDay);
    }
    final stored = journal.read(inboxKey);
    if (stored is String) {
      final note = _savedNote(stored);
      if (note == null || note.isDeleted || note.isArchived) {
        throw const ShortcutAppendException(ShortcutAppendFailure.unavailable);
      }
      return note;
    }
    final matching = repository
        .getAllNotes()
        .where((note) =>
            !note.isDeleted &&
            !note.isArchived &&
            note.title?.trim() == inboxTitle)
        .toList();
    if (matching.length > 1) {
      throw const ShortcutAppendException(ShortcutAppendFailure.conflict);
    }
    if (matching.isNotEmpty) {
      await journal.write(inboxKey, matching.single.id!);
      return matching.single.toDomain();
    }
    final now = _now();
    final id = _createId();
    if (_savedNote(id) != null) {
      throw const ShortcutAppendException(ShortcutAppendFailure.conflict);
    }
    return Note(
        id: id,
        title: inboxTitle,
        dateTime: now,
        sortOrder: -now.millisecondsSinceEpoch);
  }

  Future<void> discard(String id,
          {required Future<void> Function(String) acknowledge}) =>
      _serial(() async {
        if (!RegExp(r'^[a-f0-9-]{36}$').hasMatch(id)) {
          throw const FormatException('Invalid request ID');
        }
        final raw = journal.read('$journalPrefix$id');
        final record = <String, Object?>{
          if (raw is Map) ...Map<String, Object?>.from(raw),
          'discarded': true,
        };
        // This unbounded-in-time tombstone is retained until acknowledgement and
        // recovery cleanup both succeed; bounded receipts alone are insufficient.
        await journal.write('$journalPrefix$id', record);
        await _finishDiscard(id, record, acknowledge);
      });

  Future<void> _finishDiscard(
      String id, Map record, Future<void> Function(String) acknowledge) async {
    await _retainReceipt(id, null);
    await acknowledge(id);
    final noteId = record['noteId'];
    if (noteId is String) {
      if (record['new'] == true &&
          record['committed'] != true &&
          _savedNote(noteId) == null &&
          journal.read(inboxKey) == noteId) {
        await journal.remove(inboxKey);
      }
      final draft = readDraft(noteId);
      final target = record['target'];
      // The append journal owns this exact snapshot even for existing notes.
      // Leave newer independent edits intact, but never leave discarded text
      // available for generic startup recovery after removing its tombstone.
      if (draft != null &&
          target is NoteDto &&
          draft.copyWith(dateTime: null) ==
              target.toDomain().copyWith(dateTime: null)) {
        await store.removeDraft(noteId);
      }
    }
    await journal.remove('$journalPrefix$id');
  }
}
