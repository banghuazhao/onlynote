import 'package:onlynote/data/dto/note_dto.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/domain/repository/note_repository.dart';
import 'package:onlynote/services/markdown_import.dart';
import 'package:onlynote/services/note_creation_limit.dart';
import 'package:onlynote/services/premium_access.dart';
import 'package:uuid/uuid.dart';

abstract class MarkdownImportImageStore {
  Future<String> write(MarkdownImportImage image);
  Future<void> delete(List<String> paths);
}

enum MarkdownImportFailure { save, premium, busy }

class MarkdownImportResult {
  const MarkdownImportResult(
      {this.importedIds = const [], this.remaining = const [], this.failure});
  final List<String> importedIds;
  final List<MarkdownImportDocument> remaining;
  final MarkdownImportFailure? failure;
}

class _ImportAttempt {
  _ImportAttempt() : id = const Uuid().v4();
  final String id;
  final List<String> owned = [];
  Note? note;
  bool writeStarted = false;
}

/// Each note is committed only after its attachments have durable owned paths.
/// Ambiguous write failures retain their ID and files until retry can verify
/// ownership; a retry never makes another copy of the same pending note.
class MarkdownImportService {
  MarkdownImportService(
      {required this.repository,
      required this.imageStore,
      this.premiumAccess,
      DateTime Function()? now})
      : now = now ?? DateTime.now;
  final NoteRepository repository;
  final MarkdownImportImageStore imageStore;
  final PremiumAccess? premiumAccess;
  final DateTime Function() now;
  final Map<MarkdownImportDocument, _ImportAttempt> _attempts = {};
  bool _busy = false;

  /// Retrying an ambiguously saved note verifies the existing ID rather than
  /// creating another note, so it must not consume another free-plan slot.
  int requiredNewNotes(List<MarkdownImportDocument> documents) {
    final existing = repository.getAllNotes().map((note) => note.id).toSet();
    return documents
        .where((document) =>
            document.hasContent && !existing.contains(_attempts[document]?.id))
        .length;
  }

  Future<MarkdownImportResult> importDocuments(
      List<MarkdownImportDocument> documents) async {
    if (_busy) {
      return MarkdownImportResult(
          remaining: documents, failure: MarkdownImportFailure.busy);
    }
    final pending = documents.where((document) => document.hasContent).toList();
    if (pending.isEmpty) return const MarkdownImportResult();
    _busy = true;
    final imported = <String>[];
    final queue = <MarkdownImportDocument>[];
    try {
      final current = repository.getAllNotes();
      final ids = current.map((note) => note.id).toSet();
      for (final document in pending) {
        final attempt = _attempts[document];
        if (attempt != null && ids.contains(attempt.id)) {
          imported.add(attempt.id);
          _attempts.remove(document);
        } else {
          queue.add(document);
        }
      }
      if (queue.isEmpty) {
        return MarkdownImportResult(importedIds: List.unmodifiable(imported));
      }
      final access = premiumAccess ?? PremiumAccess.instance;
      if (!access.allows(PremiumFeature.notes,
          currentCount: current.where((note) => !note.isDeleted).length +
              queue.length -
              1)) {
        return MarkdownImportResult(
            importedIds: List.unmodifiable(imported),
            remaining: List.unmodifiable(queue),
            failure: MarkdownImportFailure.premium);
      }
      for (var index = 0; index < queue.length; index++) {
        final document = queue[index];
        final attempt = _attempts.putIfAbsent(document, _ImportAttempt.new);
        try {
          if (attempt.note == null) {
            final paths = <String, String>{};
            for (final image in document.images) {
              final path = await imageStore.write(image);
              attempt.owned.add(path);
              paths[image.path] = path;
            }
            final moment = now();
            attempt.note = document.note.copyWith(
                id: attempt.id,
                dateTime: moment,
                sortOrder: -moment.millisecondsSinceEpoch,
                todo: [
                  for (final todo in document.note.todo)
                    todo.copyWith(id: const Uuid().v4())
                ],
                imagePaths: [
                  for (final image in document.images) paths[image.path]!
                ],
                imageLayouts: [
                  for (final layout in document.note.imageLayouts)
                    if (paths.containsKey(layout.path))
                      layout.copyWith(path: paths[layout.path])
                ]);
          }
          attempt.writeStarted = true;
          await NoteCreationLimit.save(
              repository, NoteDto.fromNote(attempt.note!),
              access: access);
          imported.add(attempt.id);
          _attempts.remove(document);
        } catch (error) {
          bool? persisted = false;
          if (attempt.writeStarted) {
            try {
              persisted =
                  repository.getAllNotes().any((note) => note.id == attempt.id);
            } catch (_) {
              persisted = null;
            }
          }
          if (persisted == true) {
            imported.add(attempt.id);
            _attempts.remove(document);
          } else if (persisted == false) {
            // Cleanup is best effort. A locked orphan must not hide earlier
            // successful notes or cause a whole batch to be imported again.
            try {
              await imageStore.delete(attempt.owned);
            } catch (_) {}
            _attempts.remove(document);
          }
          return MarkdownImportResult(
              importedIds: List.unmodifiable(imported),
              remaining: List.unmodifiable(
                  queue.sublist(index + (persisted == true ? 1 : 0))),
              failure: error is PremiumRequired
                  ? MarkdownImportFailure.premium
                  : MarkdownImportFailure.save);
        }
      }
      return MarkdownImportResult(importedIds: List.unmodifiable(imported));
    } catch (_) {
      // A failed preflight read has not consumed any pending document.
      return MarkdownImportResult(
          importedIds: List.unmodifiable(imported),
          remaining: List.unmodifiable(queue.isEmpty ? pending : queue),
          failure: MarkdownImportFailure.save);
    } finally {
      _busy = false;
    }
  }
}
