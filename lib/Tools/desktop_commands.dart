import 'dart:async';
import 'dart:ui' show AppExitResponse;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:onlynote/generated/l10n.dart';

enum DesktopCommand { newNote, settings, searchNotes, findInNote, undo, redo }

/// Connects the native menu to the current route and waits for all editor
/// writes before macOS is allowed to terminate the Flutter engine.
class DesktopCommands extends ChangeNotifier {
  DesktopCommands({Duration? saveBudget})
      : saveBudget = saveBudget ?? const Duration(seconds: 5);
  static final instance = DesktopCommands();

  /// How long a quit waits for editor saves before it stops waiting.
  ///
  /// Saving a note is a local write of milliseconds, so reaching this means a
  /// save is stuck rather than slow. macOS gives an app no way to say "still
  /// working": until this answers, the app sits in NSTerminateLater with no
  /// window and looks frozen, which is what App Review rejects. So the wait is
  /// bounded and a stuck save answers exit — the app quits and that one write
  /// is lost, rather than hanging with everything else already saved.
  final Duration saveBudget;

  final _commands = <_CommandRegistration>[];
  final _editors = <Future<bool> Function()>[];
  final _editorRefreshes = <Future<void> Function()>[];
  final _pendingSaves = <Future<bool>>{};
  Future<AppExitResponse>? _exitRequest;
  bool _refreshQueued = false;

  VoidCallback registerCommand(
    DesktopCommand command, {
    required VoidCallback invoke,
    required bool Function() isActive,
    bool Function()? isEnabled,
  }) {
    final registration = _CommandRegistration(
        command, invoke, isActive, isEnabled ?? () => true);
    _commands.add(registration);
    refresh();
    return () {
      _commands.remove(registration);
      refresh();
    };
  }

  _CommandRegistration? _active(DesktopCommand command) => _commands.reversed
      .where((entry) => entry.command == command && entry.isActive())
      .firstOrNull;

  bool hasActive(DesktopCommand command) => _active(command) != null;

  bool isEnabled(DesktopCommand command) =>
      _active(command)?.isEnabled() ?? false;

  bool invoke(DesktopCommand command) {
    final registration = _active(command);
    if (registration == null) return false;
    // An unavailable editor command must not fall through to text-field undo.
    if (registration.isEnabled()) registration.invoke();
    return true;
  }

  VoidCallback registerEditor(Future<bool> Function() flush) {
    _editors.add(flush);
    return () => _editors.remove(flush);
  }

  VoidCallback registerEditorRefresh(Future<void> Function() refresh) {
    _editorRefreshes.add(refresh);
    return () => _editorRefreshes.remove(refresh);
  }

  Future<void> refreshEditors() async {
    for (final refresh in List.of(_editorRefreshes)) {
      await refresh();
    }
  }

  /// A removed route may still be saving. Retain that future after its editor
  /// has unregistered so Quit cannot race its final write.
  void trackSave(Future<bool> save) {
    late final Future<bool> tracked;
    tracked = save.catchError((Object _) => false).whenComplete(() {
      _pendingSaves.remove(tracked);
    });
    _pendingSaves.add(tracked);
  }

  Future<AppExitResponse> prepareToExit() => _exitRequest ??= _flushEditors()
      // The budget covers the whole flush, not each save: only a bound on the
      // total can promise macOS an answer. Saves that are still running keep
      // running; they are simply no longer waited on.
      .timeout(saveBudget, onTimeout: () => AppExitResponse.exit)
      .whenComplete(() => _exitRequest = null);

  Future<AppExitResponse> _flushEditors() async {
    var saved = true;
    // Older, covered editors flush before the current editor. This preserves
    // the current route's final snapshot if the same note has been reopened.
    for (final flush in List.of(_editors)) {
      try {
        if (!await flush()) saved = false;
      } catch (error) {
        debugPrint('Editor save prevented application exit: $error');
        saved = false;
      }
    }
    while (_pendingSaves.isNotEmpty) {
      final results = await Future.wait(List.of(_pendingSaves));
      if (results.any((result) => !result)) saved = false;
    }
    return saved ? AppExitResponse.exit : AppExitResponse.cancel;
  }

  void refresh() {
    if (kIsWeb ||
        defaultTargetPlatform != TargetPlatform.macOS ||
        _refreshQueued) {
      return;
    }
    // Editor registrations and save-state changes can occur during build.
    _refreshQueued = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _refreshQueued = false;
      notifyListeners();
    });
    SchedulerBinding.instance.scheduleFrame();
  }
}

class _CommandRegistration {
  const _CommandRegistration(
      this.command, this.invoke, this.isActive, this.isEnabled);
  final DesktopCommand command;
  final VoidCallback invoke;
  final bool Function() isActive;
  final bool Function() isEnabled;
}

/// Native macOS menus use the focused text field's own actions for clipboard
/// operations, preserving selection handling and IME behavior.
class DesktopAppMenu extends StatelessWidget {
  const DesktopAppMenu({
    super.key,
    required this.child,
    required this.onNewNote,
    required this.onSettings,
    required this.onQuit,
    this.commands,
  });

  final Widget child;
  final VoidCallback onNewNote;
  final VoidCallback onSettings;
  final VoidCallback onQuit;
  final DesktopCommands? commands;

  DesktopCommands get _commands => commands ?? DesktopCommands.instance;

  static void _invokeTextAction(Intent intent) {
    final context = FocusManager.instance.primaryFocus?.context;
    if (context != null) Actions.maybeInvoke<Intent>(context, intent);
  }

  void _find() {
    if (!_commands.invoke(DesktopCommand.findInNote)) {
      _commands.invoke(DesktopCommand.searchNotes);
    }
  }

  PlatformMenuItem _historyItem(
      String label, DesktopCommand command, Intent intent,
      {bool shift = false}) {
    final enabled =
        !_commands.hasActive(command) || _commands.isEnabled(command);
    return PlatformMenuItem(
      label: label,
      shortcut: SingleActivator(LogicalKeyboardKey.keyZ,
          meta: true, shift: shift, includeRepeats: false),
      onSelected: enabled
          ? () {
              if (!_commands.invoke(command)) _invokeTextAction(intent);
            }
          : null,
    );
  }

  PlatformMenuItem _textItem(
          String label, LogicalKeyboardKey key, Intent intent) =>
      PlatformMenuItem(
        label: label,
        shortcut: SingleActivator(key, meta: true, includeRepeats: false),
        // Recheck at invocation time: selection can change without focus.
        onSelected: () => _invokeTextAction(intent),
      );

  @override
  Widget build(BuildContext context) {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.macOS) return child;
    return ListenableBuilder(
      listenable: Listenable.merge([_commands, FocusManager.instance]),
      builder: (context, _) {
        final strings = S.of(context);
        final material = MaterialLocalizations.of(context);
        return PlatformMenuBar(
          menus: [
            PlatformMenu(label: 'Onlynote', menus: [
              const PlatformProvidedMenuItem(
                  type: PlatformProvidedMenuItemType.about),
              PlatformMenuItemGroup(members: [
                PlatformMenuItem(
                  label: '${strings.Settings}…',
                  shortcut: const SingleActivator(LogicalKeyboardKey.comma,
                      meta: true, includeRepeats: false),
                  onSelected: onSettings,
                ),
              ]),
              const PlatformProvidedMenuItem(
                  type: PlatformProvidedMenuItemType.servicesSubmenu),
              const PlatformMenuItemGroup(members: [
                PlatformProvidedMenuItem(
                    type: PlatformProvidedMenuItemType.hide),
                PlatformProvidedMenuItem(
                    type: PlatformProvidedMenuItemType.hideOtherApplications),
                PlatformProvidedMenuItem(
                    type: PlatformProvidedMenuItemType.showAllApplications),
              ]),
              PlatformMenuItemGroup(members: [
                PlatformMenuItem(
                  label: strings.Desktop_Menu_Quit,
                  shortcut: const SingleActivator(LogicalKeyboardKey.keyQ,
                      meta: true, includeRepeats: false),
                  onSelected: onQuit,
                ),
              ]),
            ]),
            PlatformMenu(label: strings.Desktop_Menu_File, menus: [
              PlatformMenuItem(
                label: strings.Desktop_Menu_New_Note,
                shortcut: const SingleActivator(LogicalKeyboardKey.keyN,
                    meta: true, includeRepeats: false),
                onSelected: onNewNote,
              ),
              PlatformMenuItemGroup(members: [
                PlatformMenuItem(
                  label: strings.Desktop_Menu_Close_Window,
                  shortcut: const SingleActivator(LogicalKeyboardKey.keyW,
                      meta: true, includeRepeats: false),
                  onSelected: onQuit,
                ),
              ]),
            ]),
            PlatformMenu(label: strings.Edit, menus: [
              PlatformMenuItemGroup(members: [
                _historyItem(strings.Note_Undo, DesktopCommand.undo,
                    const UndoTextIntent(SelectionChangedCause.keyboard)),
                _historyItem(strings.Note_Redo, DesktopCommand.redo,
                    const RedoTextIntent(SelectionChangedCause.keyboard),
                    shift: true),
              ]),
              PlatformMenuItemGroup(members: [
                _textItem(
                    material.cutButtonLabel,
                    LogicalKeyboardKey.keyX,
                    const CopySelectionTextIntent.cut(
                        SelectionChangedCause.keyboard)),
                _textItem(material.copyButtonLabel, LogicalKeyboardKey.keyC,
                    CopySelectionTextIntent.copy),
                _textItem(material.pasteButtonLabel, LogicalKeyboardKey.keyV,
                    const PasteTextIntent(SelectionChangedCause.keyboard)),
                _textItem(
                    material.selectAllButtonLabel,
                    LogicalKeyboardKey.keyA,
                    const SelectAllTextIntent(SelectionChangedCause.keyboard)),
              ]),
              PlatformMenuItemGroup(members: [
                PlatformMenuItem(
                  label: _commands.hasActive(DesktopCommand.findInNote)
                      ? strings.Find_In_Note
                      : strings.Search_Notes,
                  shortcut: const SingleActivator(LogicalKeyboardKey.keyF,
                      meta: true, includeRepeats: false),
                  onSelected: _find,
                ),
              ]),
            ]),
            PlatformMenu(label: strings.Desktop_Menu_Window, menus: const [
              PlatformProvidedMenuItem(
                  type: PlatformProvidedMenuItemType.minimizeWindow),
              PlatformProvidedMenuItem(
                  type: PlatformProvidedMenuItemType.zoomWindow),
              PlatformProvidedMenuItem(
                  type: PlatformProvidedMenuItemType.toggleFullScreen),
              PlatformProvidedMenuItem(
                  type: PlatformProvidedMenuItemType.arrangeWindowsInFront),
            ]),
          ],
          child: CallbackShortcuts(
            bindings: {
              const SingleActivator(LogicalKeyboardKey.keyN,
                  meta: true, includeRepeats: false): onNewNote,
              const SingleActivator(LogicalKeyboardKey.comma,
                  meta: true, includeRepeats: false): onSettings,
              const SingleActivator(LogicalKeyboardKey.keyF,
                  meta: true, includeRepeats: false): _find,
              const SingleActivator(LogicalKeyboardKey.keyQ,
                  meta: true, includeRepeats: false): onQuit,
              const SingleActivator(LogicalKeyboardKey.keyW,
                  meta: true, includeRepeats: false): onQuit,
            },
            child: Focus(autofocus: true, skipTraversal: true, child: child),
          ),
        );
      },
    );
  }
}
