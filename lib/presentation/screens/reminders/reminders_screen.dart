import 'dart:async';

import 'package:flutter/material.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/app_sheet.dart';
import 'package:onlynote/presentation/components/paper_note.dart';
import 'package:onlynote/presentation/components/reminder_picker_sheet.dart';
import 'package:onlynote/presentation/components/toast.dart' show ContextEx;
import 'package:onlynote/presentation/routes/routes.dart';
import 'package:onlynote/services/reminder_agenda.dart';
import 'package:onlynote/services/reminder_agenda_controller.dart';

import 'reminder_agenda_live.dart';
import 'reminders_agenda_search.dart';

@RoutePage(name: 'RemindersRoute')
class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key, this.controller});
  final ReminderAgendaController? controller;

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen>
    with WidgetsBindingObserver {
  ReminderAgendaController? _controller;
  Timer? _clockRefresh;
  bool _openingNote = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller != null) return;
    final l10n = S.of(context);
    _controller = widget.controller ??
        createLiveReminderAgendaController(
          title: l10n.Onlynote,
          body: (note) => '${l10n.Reminder}: ${note.title ?? ''}',
          requestPermission: (notifications) async {
            if (!mounted) return false;
            final allowed =
                await notifications.checkAndAskForPermission(context);
            return mounted && allowed == true;
          },
        );
    unawaited(_controller!.refresh());
    _clockRefresh = Timer.periodic(const Duration(minutes: 1), (_) {
      if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
        unawaited(_controller!.refresh());
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _controller != null) {
      unawaited(_controller!.refresh());
    }
  }

  Future<void> _openNote(ReminderAgendaEntry entry) async {
    if (_openingNote ||
        _controller!.busyReminderId != null ||
        ModalRoute.of(context)?.isCurrent != true) {
      return;
    }
    _openingNote = true;
    final l10n = S.of(context);
    try {
      final note = await _controller!.resolveNote(entry);
      if (!mounted || ModalRoute.of(context)?.isCurrent != true) return;
      if (note == null) {
        context.showToast(l10n.Reminders_Note_Unavailable, isError: true);
        await _controller!.refresh();
        return;
      }
      await context.router.push(NoteDetailRoute(noteId: note.id!));
      if (mounted) await _controller!.refresh();
    } catch (_) {
      if (mounted && ModalRoute.of(context)?.isCurrent == true) {
        context.showToast(l10n.Reminders_Load_Failed, isError: true);
      }
    } finally {
      _openingNote = false;
    }
  }

  Future<void> _snooze(ReminderAgendaEntry entry) async {
    if (!mounted ||
        _controller!.busyReminderId != null ||
        ModalRoute.of(context)?.isCurrent != true) {
      return;
    }
    final l10n = S.of(context);
    bool chosen = false;
    void choose(BuildContext sheetContext, Duration delay) {
      if (chosen ||
          !sheetContext.mounted ||
          ModalRoute.of(sheetContext)?.isCurrent != true) {
        return;
      }
      chosen = true;
      Navigator.pop(sheetContext, delay);
    }

    final delay = await showAppSheet<Duration>(
      context: context,
      builder: (context) => AppSheet(
        title: l10n.Reminders_Snooze,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            minVerticalPadding: 14,
            leading: const Icon(Icons.snooze_rounded),
            title: Text(l10n.Reminder_Snooze_10_Minutes),
            onTap: () => choose(context, const Duration(minutes: 10)),
          ),
          ListTile(
            minVerticalPadding: 14,
            leading: const Icon(Icons.schedule_outlined),
            title: Text(l10n.Reminder_Snooze_1_Hour),
            onTap: () => choose(context, const Duration(hours: 1)),
          ),
        ]),
      ),
    );
    if (delay == null ||
        !mounted ||
        ModalRoute.of(context)?.isCurrent != true) {
      return;
    }
    final result = await _controller!.snooze(entry, delay);
    if (mounted) _showResult(result, snooze: true);
  }

  Future<void> _reschedule(ReminderAgendaEntry entry) async {
    if (!mounted ||
        _controller!.busyReminderId != null ||
        ModalRoute.of(context)?.isCurrent != true) {
      return;
    }
    final selection = await showAppSheet<ReminderPickerResult>(
      context: context,
      builder: (_) =>
          ReminderPickerSheet(current: entry.reminder, allowDelete: false),
    );
    if (selection == null ||
        selection.delete ||
        !mounted ||
        ModalRoute.of(context)?.isCurrent != true) {
      return;
    }
    final result =
        await _controller!.reschedule(entry, selection.date!, selection.repeat);
    if (mounted) _showResult(result);
  }

  void _showResult(ReminderAgendaActionResult result, {bool snooze = false}) {
    if (!mounted || ModalRoute.of(context)?.isCurrent != true) return;
    final l10n = S.of(context);
    switch (result) {
      case ReminderAgendaActionResult.saved:
        context
            .showToast(snooze ? l10n.Reminders_Snoozed : l10n.Reminder_Saved);
      case ReminderAgendaActionResult.failed:
        context.showToast(
          snooze ? l10n.Reminders_Snooze_Failed : l10n.Reminder_Save_Failed,
          isError: true,
        );
      case ReminderAgendaActionResult.unavailable:
        context.showToast(l10n.Reminders_Note_Unavailable, isError: true);
      case ReminderAgendaActionResult.changed:
        context.showToast(l10n.Reminders_Changed, isError: true);
      case ReminderAgendaActionResult.busy:
        break;
    }
  }

  @override
  void dispose() {
    _clockRefresh?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    if (widget.controller == null) _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller!;
    final l10n = S.of(context);
    return Scaffold(
      backgroundColor: DeskSurface.colorOf(context),
      appBar: AppBar(title: Text(l10n.Reminders_Title)),
      body: DeskSurface(
        child: SafeArea(
          top: false,
          child: ListenableBuilder(
            listenable: controller,
            builder: (context, _) => Column(children: [
              if (controller.loadFailed)
                MaterialBanner(
                  content: Text(l10n.Reminders_Load_Failed),
                  leading: const Icon(Icons.info_outline_rounded),
                  actions: [
                    TextButton(
                        onPressed:
                            controller.loading ? null : controller.refresh,
                        child: Text(l10n.Retry)),
                  ],
                ),
              Expanded(
                child: SearchableRemindersAgenda(
                  entries: controller.entries,
                  now: controller.referenceTime,
                  loading: controller.loading,
                  busyReminderId: controller.busyReminderId,
                  onRefresh: controller.refresh,
                  onOpen: _openNote,
                  onSnooze: _snooze,
                  onReschedule: _reschedule,
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
