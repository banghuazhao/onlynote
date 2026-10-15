import 'dart:io';
import 'dart:ui' as ui;

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:onlynote/Tools/export_archive.dart';
import 'package:onlynote/Tools/image_storage.dart';
import 'package:onlynote/Tools/notification_service.dart';
import 'package:onlynote/Tools/desktop_commands.dart';
import 'package:onlynote/Tools/pdf_glyphs.dart';
import 'package:onlynote/Tools/reminder_data.dart';
import 'package:onlynote/Tools/share_helper.dart';
import 'package:onlynote/common/constants.dart';
import 'package:onlynote/data/dto/note_dto.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/domain/model/voice_memo.dart';
import 'package:onlynote/domain/repository/note_repository.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/backup_restore_preview.dart';
import 'package:onlynote/presentation/components/backup_export_section.dart';
import 'package:onlynote/presentation/components/components.dart';
import 'package:onlynote/presentation/components/note_export_section.dart';
import 'package:onlynote/services/audio_storage.dart';
import 'package:onlynote/services/backup/backup_contents.dart';
import 'package:onlynote/services/backup/backup_service.dart';
import 'package:onlynote/services/custom_note_template_store.dart';
import 'package:onlynote/services/note_autosave.dart';
import 'package:onlynote/services/note_bulk_export.dart';
import 'package:onlynote/services/note_export.dart';
import 'package:onlynote/services/note_history.dart';
import 'package:onlynote/services/saved_note_views.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({
    super.key,
    this.exportBackup,
    this.shareBackup,
    this.saveBackup,
    this.exportNotes,
    this.shareNotes,
    this.saveNotes,
  });

  final Future<Uint8List> Function()? exportBackup;
  final Future<ShareResult> Function(ShareParams)? shareBackup;

  /// Returns true once saved, false when the save dialog was cancelled.
  final Future<bool> Function(Uint8List bytes, String suggestedName)?
      saveBackup;

  /// Builds the readable export archive, reporting progress per note.
  final Future<NoteArchiveExport?> Function(
    NoteBulkExportFormat format,
    void Function(int done, int total) onProgress,
  )? exportNotes;
  final Future<ShareResult> Function(ShareParams)? shareNotes;

  /// Returns true once saved, false when the save dialog was cancelled.
  final Future<bool> Function(File file, String suggestedName)? saveNotes;
  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  final _exportKey = GlobalKey();
  final _exportNotesKey = GlobalKey();
  bool _busy = false;
  String? _progress;
  NoteBulkExportFormat _noteFormat = NoteBulkExportFormat.markdown;
  late final VoidCallback _unregisterExitGuard;

  @override
  void initState() {
    super.initState();
    _unregisterExitGuard =
        DesktopCommands.instance.registerEditor(() async => !_busy);
  }

  @override
  void dispose() {
    _unregisterExitGuard();
    super.dispose();
  }

  bool get _saveToFile =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.macOS;

  Future<bool> _saveBackup(Uint8List bytes, String name) async {
    final location = await getSaveLocation(
      suggestedName: name,
      acceptedTypeGroups: const [
        XTypeGroup(
          label: 'Onlynote backup',
          extensions: ['onlynote'],
          uniformTypeIdentifiers: ['public.data'],
        ),
      ],
    );
    if (location == null) return false;
    await XFile.fromData(bytes, mimeType: 'application/octet-stream')
        .saveTo(location.path);
    return true;
  }

  Future<BackupService> _service() async => BackupService(
        notes: Hive.box(databaseBox),
        drafts: Hive.box(draftDatabaseBox),
        folders: Hive.box(folderDatabaseBox),
        journal: Hive.box(backupRecoveryBox),
        documents: await getApplicationDocumentsDirectory(),
        readReminders: () => ReminderData.shared.reminders,
        writeReminders: ReminderData.shared.replaceAll,
        templateStore: CustomNoteTemplateStore.instance,
        history: NoteHistory.initializedInstance,
        savedViewStore: SavedNoteViewStore.instance,
      );

  Future<void> _export() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _progress = S.of(context).Backup_Preparing;
    });
    final origin = ShareHelper.shareOriginFromKey(_exportKey);
    var prepared = false;
    try {
      final bytes = widget.exportBackup != null
          ? await widget.exportBackup!()
          : await (await _service()).export();
      if (!mounted) return;
      prepared = true;
      final stamp = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '-')
          .split('.')
          .first;
      final name = 'Onlynote-$stamp.onlynote';
      if (_saveToFile) {
        final saved = await (widget.saveBackup ?? _saveBackup)(bytes, name);
        if (!mounted) return;
        _message(saved
            ? S.of(context).Backup_Export_Saved
            : S.of(context).Backup_Export_Save_Cancelled);
        return;
      }
      final params = ShareParams(
        files: [
          XFile.fromData(bytes,
              mimeType: 'application/octet-stream', name: name)
        ],
        fileNameOverrides: [name],
        sharePositionOrigin: origin,
      );
      final result = widget.shareBackup != null
          ? await widget.shareBackup!(params)
          : await SharePlus.instance.share(params);
      if (!mounted) return;
      final strings = S.of(context);
      _message(switch (result.status) {
        ShareResultStatus.success => strings.Backup_Export_Shared,
        ShareResultStatus.dismissed => strings.Backup_Export_Cancelled,
        ShareResultStatus.unavailable => strings.Backup_Export_Prepared,
      });
    } catch (_) {
      if (mounted) {
        _message(!prepared
            ? S.of(context).Backup_Export_Failed
            : _saveToFile
                ? S.of(context).Backup_Export_Save_Failed
                : S.of(context).Backup_Export_Share_Failed);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool> _saveNoteArchive(File file, String name) async {
    final location = await getSaveLocation(
      suggestedName: name,
      acceptedTypeGroups: const [
        XTypeGroup(
          label: 'Zip archive',
          extensions: ['zip'],
          uniformTypeIdentifiers: ['public.zip-archive'],
        ),
      ],
    );
    if (location == null) return false;
    await file.copy(location.path);
    return true;
  }

  /// Builds one note's PDF with the same fonts, glyph fallback and layout the
  /// share sheet uses. Photos are copied verbatim rather than re-encoded: a
  /// library archive should keep what the user actually took, and one note's
  /// photos are all that is ever in memory at once.
  Future<Uint8List> _notePdf(
      Note note, String? reminder, List<ByteData> fonts) async {
    final paths = <String>[];
    final photos = <Uint8List>[];
    for (final stored in note.imagePaths) {
      final file = File(ImageStorage.resolvePath(stored));
      if (!await file.exists()) continue;
      paths.add(stored);
      photos.add(await file.readAsBytes());
    }
    final glyphImages = await renderMissingPdfGlyphs(
        '${NoteExport.plainText(note, reminder: reminder)}\n${note.dateWithTime}',
        fonts);
    final glyphs = <String, Uint8List>{};
    try {
      for (final entry in glyphImages.entries) {
        final png =
            await entry.value.toByteData(format: ui.ImageByteFormat.png);
        if (png != null) glyphs[entry.key] = png.buffer.asUint8List();
      }
    } finally {
      for (final image in glyphImages.values) {
        image.dispose();
      }
    }
    return compute(
        buildNotePdf,
        NotePdfData(
          title: note.title ?? '',
          description: note.description ?? '',
          textStyles: note.textStyles,
          imagePaths: paths,
          imageLayouts: note.imageLayouts,
          transcripts: [
            ...note.voiceMemos
                .map((memo) => memo.transcript ?? '')
                .where((text) => text.isNotEmpty),
          ],
          date: note.dateWithTime,
          todos: note.todo.map((t) => (t.completed, t.title ?? '')).toList(),
          photos: photos,
          glyphs: glyphs,
          reminder: reminder,
          regular: fonts[0].buffer.asUint8List(),
          bold: fonts[1].buffer.asUint8List(),
          fallback: fonts[2].buffer.asUint8List(),
        ));
  }

  Future<NoteArchiveExport?> _buildNoteExport(
    NoteBulkExportFormat format,
    void Function(int done, int total) onProgress,
  ) async {
    final strings = S.of(context);
    final notes = <Note>[];
    for (final dto in getIt<NoteRepository>().getAllNotes()) {
      final note = dto.toDomain();
      // Trash is for notes on their way out; a readable archive is not where
      // the user expects to meet them again.
      if (!note.isDeleted) notes.add(note);
    }
    if (notes.isEmpty) return null;
    final fonts = format == NoteBulkExportFormat.pdf
        ? await Future.wait([
            'Roboto-Regular.ttf',
            'Roboto-Bold.ttf',
            'DroidSansFallback.ttf'
          ].map((name) => rootBundle.load('assets/fonts/$name')))
        : const <ByteData>[];
    final stamp =
        DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;
    final directory = await getTemporaryDirectory();
    final archive =
        ExportArchive.create('${directory.path}/Onlynote-notes-$stamp.zip');
    try {
      final export = NoteBulkExport(
        format: format,
        write: archive.add,
        onProgress: onProgress,
        recordingLabel: strings.Voice_Memo,
        reminderFor: (note) {
          final reminder = ReminderData.shared.getCurrentReminder(note);
          return reminder == null
              ? null
              : '${strings.Reminder}: ${reminder.timeString}';
        },
        resolvePhoto: (stored) {
          final path = ImageStorage.resolvePath(stored);
          return File(path).existsSync() ? path : null;
        },
        resolveRecording: (memo) async {
          if (!VoiceMemo.isManagedPath(memo.path)) return null;
          final path = await AudioStorage.instance.resolvePath(memo.path);
          return await File(path).exists() ? path : null;
        },
        buildPdf: format == NoteBulkExportFormat.pdf
            ? (note, reminder) => _notePdf(note, reminder, fonts)
            : null,
      );
      final result = await export.run(notes);
      await archive.close();
      return NoteArchiveExport(archive.file, result);
    } catch (_) {
      await archive.discard();
      rethrow;
    }
  }

  Future<void> _exportNotes() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _progress = S.of(context).Export_Notes_Preparing;
    });
    final origin = ShareHelper.shareOriginFromKey(_exportNotesKey);
    final format = _noteFormat;
    NoteArchiveExport? export;
    try {
      export = await (widget.exportNotes ?? _buildNoteExport)(
          format, _reportExportProgress);
      if (!mounted) return;
      if (export == null || export.result.exported == 0) {
        _message(export == null || export.result.total == 0
            ? S.of(context).Export_Notes_Empty
            : S.of(context).Export_Notes_Failed);
        return;
      }
      final incomplete = export.result.failed > 0
          ? ' ${S.of(context).Export_Notes_Incomplete(export.result.failed)}'
          : '';
      final name = export.file.uri.pathSegments.last;
      if (_saveToFile) {
        final saved =
            await (widget.saveNotes ?? _saveNoteArchive)(export.file, name);
        if (!mounted) return;
        _message(saved
            ? '${S.of(context).Export_Notes_Saved}$incomplete'
            : S.of(context).Export_Notes_Save_Cancelled);
        return;
      }
      final params = ShareParams(
        files: [
          XFile(export.file.path, mimeType: 'application/zip', name: name)
        ],
        fileNameOverrides: [name],
        sharePositionOrigin: origin,
      );
      final result = widget.shareNotes != null
          ? await widget.shareNotes!(params)
          : await SharePlus.instance.share(params);
      if (!mounted) return;
      final strings = S.of(context);
      _message(switch (result.status) {
            ShareResultStatus.success => strings.Export_Notes_Shared,
            ShareResultStatus.dismissed => strings.Export_Notes_Cancelled,
            ShareResultStatus.unavailable => strings.Export_Notes_Prepared,
          } +
          incomplete);
    } catch (_) {
      if (mounted) {
        _message(export == null
            ? S.of(context).Export_Notes_Failed
            : _saveToFile
                ? S.of(context).Export_Notes_Save_Failed
                : S.of(context).Export_Notes_Share_Failed);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _reportExportProgress(int done, int total) {
    if (!mounted) return;
    final counter = '$done / $total';
    if (_progress == counter) return;
    setState(() => _progress = counter);
  }

  Future<void> _restore() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _progress = S.of(context).Backup_Reading;
    });
    try {
      final file = await openFile(acceptedTypeGroups: const [
        XTypeGroup(
          label: 'Onlynote backup',
          extensions: ['onlynote'],
          mimeTypes: ['application/octet-stream', 'application/json'],
          uniformTypeIdentifiers: ['public.data'],
        )
      ]);
      if (file == null || !mounted) return;
      if (await file.length() > maxBackupBytes) throw const FormatException();
      final contents = await compute(decodeBackup, await file.readAsBytes());
      if (!mounted) return;
      var schedule = true;
      final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => StatefulBuilder(
                builder: (context, update) => AlertDialog(
                  scrollable: true,
                  icon: const Icon(Icons.restore_page_outlined),
                  title: Text(S.of(context).Backup_Restore),
                  content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        BackupRestorePreview(
                          metadata: backupRestoreMetadata(contents),
                        ),
                        const SizedBox(height: 16),
                        Text(S.of(context).Backup_Restore_Description),
                        if (contents.reminders
                            .any((r) => r.isSchedulable(DateTime.now()))) ...[
                          const SizedBox(height: 12),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title:
                                Text(S.of(context).Backup_Schedule_Reminders),
                            value: schedule,
                            onChanged: (value) =>
                                update(() => schedule = value),
                          ),
                        ],
                      ]),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text(S.of(context).Cancel)),
                    FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: Text(S.of(context).Restore)),
                  ],
                ),
              ));
      if (confirmed != true || !mounted) return;
      setState(() => _progress = S.of(context).Backup_Restoring);
      final reminders = await (await _service()).restore(contents);
      if (!mounted) return;
      final schedulable = reminders
          .where((r) =>
              r.isSchedulable(DateTime.now()) &&
              !(Hive.box(databaseBox).get(r.noteId) as NoteDto).isDeleted)
          .toList();
      var remindersEnabled = true;
      if (schedule && schedulable.isNotEmpty) {
        try {
          final service = NotificationService();
          remindersEnabled =
              await service.checkAndAskForPermission(context) == true;
          if (!mounted) return;
          if (remindersEnabled) {
            for (final reminder in schedulable) {
              final note =
                  Hive.box(databaseBox).get(reminder.noteId) as NoteDto;
              final scheduled = await service.scheduleNotifications(
                id: reminder.reminderId,
                title: S.of(context).Onlynote,
                body: '${S.of(context).Reminder}: ${note.title ?? ''}',
                time: reminder.reminderDate,
                noteId: reminder.noteId,
                repeat: reminder.repeat,
              );
              remindersEnabled = scheduled && remindersEnabled;
              if (!mounted) return;
            }
          }
        } catch (_) {
          remindersEnabled = false;
        }
      }
      if (!mounted) return;
      _message(remindersEnabled
          ? S.of(context).Backup_Restored
          : S.of(context).Backup_Restored_No_Notifications);
    } on FormatException {
      if (mounted) _message(S.of(context).Backup_Invalid);
    } catch (_) {
      if (mounted) _message(S.of(context).Backup_Restore_Failed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _message(String message) =>
      showTransientSnackBar(context, SnackBar(content: Text(message)));

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: !_busy,
        child: Scaffold(
          backgroundColor: DeskSurface.colorOf(context),
          appBar: AppBar(title: Text(S.of(context).Backup_Title)),
          body: DeskSurface(
              child: SafeArea(
                  top: false,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Center(
                          child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 640),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              BackupExportSection(
                                saveToFile: _saveToFile,
                                exportButtonKey: _exportKey,
                                onExport: _busy ? null : _export,
                              ),
                              const SizedBox(height: 16),
                              NoteExportSection(
                                saveToFile: _saveToFile,
                                format: _noteFormat,
                                exportButtonKey: _exportNotesKey,
                                onFormatChanged: (format) =>
                                    setState(() => _noteFormat = format),
                                onExport: _busy ? null : _exportNotes,
                              ),
                              const SizedBox(height: 16),
                              SectionCard(
                                title: S.of(context).Backup_Restore,
                                subtitle:
                                    S.of(context).Backup_Restore_Description,
                                icon: Icons.restore_page_outlined,
                                children: [
                                  SizedBox(
                                      width: double.infinity,
                                      child: OutlinedButton.icon(
                                        onPressed: _busy ? null : _restore,
                                        icon: const Icon(
                                            Icons.folder_open_outlined),
                                        label:
                                            Text(S.of(context).Backup_Choose),
                                      ))
                                ],
                              ),
                              if (_busy) ...[
                                const SizedBox(height: 24),
                                const LinearProgressIndicator(),
                                const SizedBox(height: 12),
                                Semantics(
                                    liveRegion: true,
                                    child: Text(_progress ?? '',
                                        textAlign: TextAlign.center)),
                              ],
                            ]),
                      ))
                    ],
                  ))),
        ),
      );
}

/// Counts validated backup records without reading or modifying their media.
BackupRestoreMetadata backupRestoreMetadata(BackupContents contents) =>
    BackupRestoreMetadata(
      createdAt: contents.createdAt,
      noteCount: contents.notes.length,
      folderCount: contents.folders.length,
      photoCount: contents.photos.length,
      templateCount: contents.templates.length,
      recordingFileCount: contents.audio.length,
      savedViewCount: contents.savedViews.length,
      historyVersionCount: contents.histories.values
          .fold(0, (total, versions) => total + versions.length),
    );
