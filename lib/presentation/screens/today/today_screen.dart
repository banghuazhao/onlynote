import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:onlynote/domain/repository/note_repository.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/paper_note.dart';
import 'package:onlynote/presentation/components/premium_feature_gate.dart';
import 'package:onlynote/presentation/components/toast.dart';
import 'package:onlynote/services/daily_note.dart';
import 'package:onlynote/services/note_creation_limit.dart';
import 'package:onlynote/services/premium_access.dart';
import 'package:onlynote/services/today_agenda.dart';

import 'today_agenda_content.dart';
import 'today_agenda_live.dart';

@RoutePage(name: 'TodayRoute')
class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key, this.controller});

  final TodayAgendaController? controller;

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> with WidgetsBindingObserver {
  late final TodayAgendaController _controller =
      widget.controller ?? createLiveTodayAgendaController();
  Timer? _clockRefresh;
  bool _navigating = false;
  TodayTaskCompletionUndo? _undoReceipt;
  Timer? _undoExpiry;
  int _feedbackGeneration = 0;
  ScaffoldFeatureController<SnackBar, SnackBarClosedReason>? _undoFeedback;
  ScaffoldMessengerState? _undoMessenger;

  void _clearUndoFeedback({bool dismiss = true}) {
    _undoReceipt = null;
    _undoExpiry?.cancel();
    _feedbackGeneration++;
    final feedback = _undoFeedback;
    final messenger = _undoMessenger;
    _undoFeedback = null;
    _undoMessenger = null;
    if (dismiss && messenger?.mounted == true) feedback?.close();
  }

  void _showUndoFeedback(TodayTaskCompletionUndo receipt, String message,
      {bool retry = false}) {
    _clearUndoFeedback();
    _undoReceipt = receipt;
    final generation = _feedbackGeneration;
    const duration = Duration(seconds: 6);
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    final feedback = messenger.showSnackBar(SnackBar(
      // A failed Undo becomes a new Retry action, with fresh native button
      // state even though both messages belong to the same completion.
      key: ValueKey('today-task-undo-feedback-$generation'),
      content: Text(message),
      duration: duration,
      action: SnackBarAction(
        key: const ValueKey('today-task-undo-action'),
        label: retry ? S.of(context).Retry : S.of(context).Undo,
        onPressed: () => _undoTask(receipt),
      ),
    ));
    _undoFeedback = feedback;
    _undoMessenger = messenger;
    // Action feedback remains available to accessibility users until they
    // dismiss or use it. Ordinary feedback also has a route-owned timeout,
    // canceled on replacement or disposal so it cannot close a later bar.
    if (!MediaQuery.accessibleNavigationOf(context)) {
      _undoExpiry = Timer(duration, () {
        if (!mounted || generation != _feedbackGeneration) return;
        _clearUndoFeedback();
      });
    }
    unawaited(feedback.closed.then((_) {
      if (mounted && generation == _feedbackGeneration) {
        _clearUndoFeedback(dismiss: false);
      }
    }));
  }

  bool get _canAct => mounted && ModalRoute.of(context)?.isCurrent != false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_controller.refresh());
    _clockRefresh = Timer.periodic(const Duration(minutes: 1), (_) {
      if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
        unawaited(_controller.refresh());
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_controller.refresh());
  }

  Future<void> _openDailyNote() async {
    if (!_canAct || _navigating || _controller.busyTaskKey != null) return;
    _clearUndoFeedback();
    setState(() => _navigating = true);
    final strings = S.of(context);
    try {
      final repository = getIt<NoteRepository>();
      final access = PremiumAccess.instance;
      final service = DailyNoteService(repository, premiumAccess: access);
      final locale = Localizations.localeOf(context).toString();
      final title = DateFormat.yMMMMd(locale).format;
      Note note;
      try {
        note = await service.openToday(titleForDay: title);
      } on PremiumRequired {
        if (!mounted || !_canAct) return;
        final allowed = await ensurePremiumAccess(
          context,
          PremiumFeature.notes,
          currentCount: NoteCreationLimit.count(repository),
          access: access,
        );
        if (!mounted || !_canAct || !allowed) return;
        note = await service.openToday(titleForDay: title);
      }
      if (!mounted || !_canAct) return;
      await context.router
          .push(AddUpdateNoteRoute(note: note, premiumAccess: access));
      if (mounted) await _controller.refresh();
    } catch (_) {
      if (mounted && _canAct) {
        context.showToast(strings.Today_Note_Open_Failed, isError: true);
      }
    } finally {
      if (mounted) setState(() => _navigating = false);
    }
  }

  Future<void> _openNote(String id) async {
    if (!_canAct || _navigating || _controller.busyTaskKey != null) return;
    _clearUndoFeedback();
    setState(() => _navigating = true);
    final strings = S.of(context);
    try {
      final note = await _controller.resolveNote(id);
      if (!mounted || !_canAct) return;
      if (note == null) {
        context.showToast(strings.Reminders_Note_Unavailable, isError: true);
        await _controller.refresh();
        return;
      }
      await context.router.push(NoteDetailRoute(noteId: note.id!));
      if (mounted) await _controller.refresh();
    } catch (_) {
      if (mounted && _canAct) {
        context.showToast(strings.Today_Load_Failed, isError: true);
      }
    } finally {
      if (mounted) setState(() => _navigating = false);
    }
  }

  Future<void> _openReminders() async {
    if (!_canAct || _navigating || _controller.busyTaskKey != null) return;
    _clearUndoFeedback();
    setState(() => _navigating = true);
    try {
      await context.router.push(RemindersRoute());
      if (mounted) await _controller.refresh();
    } finally {
      if (mounted) setState(() => _navigating = false);
    }
  }

  Future<void> _completeTask(TodayTaskEntry entry) async {
    if (!_canAct || _navigating || _controller.busyTaskKey != null) return;
    if (!_controller.agenda.tasks.any((value) =>
        value.key == entry.key && value.todo.title == entry.todo.title)) {
      return;
    }
    _clearUndoFeedback();
    final strings = S.of(context);
    final result = await _controller.completeTask(entry);
    if (!mounted || !_canAct) return;
    switch (result) {
      case TodayTaskActionResult.saved:
        final receipt = _controller.lastCompletionUndo;
        if (receipt != null) {
          _showUndoFeedback(receipt, strings.Checklist_Item_Completed);
        }
      case TodayTaskActionResult.unavailable:
        context.showToast(strings.Checklist_Item_Unavailable, isError: true);
      case TodayTaskActionResult.changed:
        context.showToast(strings.Today_Task_Changed, isError: true);
      case TodayTaskActionResult.failed:
        context.showToast(strings.Today_Task_Save_Failed, isError: true);
      case TodayTaskActionResult.busy:
        break;
    }
  }

  Future<void> _undoTask(TodayTaskCompletionUndo receipt) async {
    if (!_canAct || _navigating || !identical(_undoReceipt, receipt)) return;
    _clearUndoFeedback();
    final strings = S.of(context);
    final result = await _controller.undoTaskCompletion(receipt);
    if (!mounted || !_canAct) return;
    switch (result) {
      case TodayTaskActionResult.saved:
        context.showToast(strings.Today_Task_Undone);
      case TodayTaskActionResult.failed:
        _showUndoFeedback(receipt, strings.Today_Task_Undo_Failed, retry: true);
      case TodayTaskActionResult.changed:
      case TodayTaskActionResult.unavailable:
        context.showToast(strings.Today_Task_Undo_Unavailable, isError: true);
      case TodayTaskActionResult.busy:
        break;
    }
  }

  @override
  void dispose() {
    _clockRefresh?.cancel();
    _clearUndoFeedback();
    WidgetsBinding.instance.removeObserver(this);
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = S.of(context);
    return Scaffold(
      backgroundColor: DeskSurface.colorOf(context),
      appBar: AppBar(title: Text(strings.Today_Title)),
      body: DeskSurface(
        child: SafeArea(
          top: false,
          child: ListenableBuilder(
            listenable: _controller,
            builder: (context, _) => TodayAgendaContent(
              agenda: _controller.agenda,
              now: _controller.referenceTime,
              loading: _controller.loading,
              loadFailed: _controller.loadFailed,
              busyTaskKey: _controller.busyTaskKey,
              navigating: _navigating,
              onRefresh: _controller.refresh,
              onOpenDailyNote: _openDailyNote,
              onOpenNote: _openNote,
              onOpenReminders: _openReminders,
              onCompleteTask: _completeTask,
            ),
          ),
        ),
      ),
    );
  }
}
