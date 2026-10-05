import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:onlynote/Tools/notification_service.dart';
import 'package:onlynote/Tools/reminder_data.dart';
import 'package:onlynote/Tools/share_helper.dart';
import 'package:onlynote/common/constants.dart';
import 'package:onlynote/data/dto/note_dto.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/components.dart';
import 'package:onlynote/services/backup/backup_contents.dart';
import 'package:onlynote/services/backup/backup_service.dart';
import 'package:onlynote/services/note_autosave.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});
  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  final _exportKey = GlobalKey();
  bool _busy = false;
  String? _progress;

  Future<BackupService> _service() async => BackupService(
        notes: Hive.box(databaseBox),
        drafts: Hive.box(draftDatabaseBox),
        folders: Hive.box(folderDatabaseBox),
        journal: Hive.box(backupRecoveryBox),
        documents: await getApplicationDocumentsDirectory(),
        readReminders: () => ReminderData.shared.reminders,
        writeReminders: ReminderData.shared.replaceAll,
      );

  Future<void> _export() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _progress = S.of(context).Backup_Preparing;
    });
    final origin = ShareHelper.shareOriginFromKey(_exportKey);
    try {
      final bytes = await (await _service()).export();
      if (!mounted) return;
      final stamp = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '-')
          .split('.')
          .first;
      final name = 'Onlynote-$stamp.onlynote';
      await SharePlus.instance.share(ShareParams(
        files: [
          XFile.fromData(bytes,
              mimeType: 'application/octet-stream', name: name)
        ],
        fileNameOverrides: [name],
        sharePositionOrigin: origin,
      ));
    } catch (_) {
      if (mounted) _message(S.of(context).Backup_Export_Failed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
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
                        Text(S.of(context).Backup_Contents(
                            contents.notes.length,
                            contents.folders.length,
                            contents.photos.length)),
                        const SizedBox(height: 16),
                        Text(S.of(context).Backup_Restore_Description),
                        if (contents.reminders
                            .any((r) => r.date.isAfter(DateTime.now()))) ...[
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
      final future = reminders
          .where((r) =>
              r.reminderDate.isAfter(DateTime.now()) &&
              !(Hive.box(databaseBox).get(r.noteId) as NoteDto).isDeleted)
          .toList();
      var remindersEnabled = true;
      if (schedule && future.isNotEmpty) {
        try {
          final service = NotificationService();
          remindersEnabled =
              await service.checkAndAskForPermission(context) == true;
          if (!mounted) return;
          if (remindersEnabled) {
            for (final reminder in future) {
              final note =
                  Hive.box(databaseBox).get(reminder.noteId) as NoteDto;
              final scheduled = await service.scheduleNotifications(
                id: reminder.reminderId,
                title: S.of(context).Onlynote,
                body: '${S.of(context).Reminder}: ${note.title ?? ''}',
                time: reminder.reminderDate,
                noteId: reminder.noteId,
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
                              SectionCard(
                                title: S.of(context).Backup_Export,
                                subtitle:
                                    S.of(context).Backup_Export_Description,
                                icon: Icons.inventory_2_outlined,
                                children: [
                                  SizedBox(
                                      width: double.infinity,
                                      child: FilledButton.icon(
                                        key: _exportKey,
                                        onPressed: _busy ? null : _export,
                                        icon:
                                            const Icon(Icons.ios_share_rounded),
                                        label:
                                            Text(S.of(context).Backup_Export),
                                      ))
                                ],
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
