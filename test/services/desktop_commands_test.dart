import 'dart:async';
import 'dart:ui' show AppExitResponse;

import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/Tools/desktop_commands.dart';

void main() {
  test('commands follow the active route and consume unavailable undo', () {
    final commands = DesktopCommands();
    var editorActive = false;
    var editorEnabled = false;
    final invoked = <String>[];
    commands.registerCommand(DesktopCommand.undo,
        invoke: () => invoked.add('library'), isActive: () => !editorActive);
    final unregister = commands.registerCommand(DesktopCommand.undo,
        invoke: () => invoked.add('editor'),
        isActive: () => editorActive,
        isEnabled: () => editorEnabled);

    expect(commands.invoke(DesktopCommand.undo), isTrue);
    expect(invoked, ['library']);
    editorActive = true;
    expect(commands.isEnabled(DesktopCommand.undo), isFalse);
    expect(commands.invoke(DesktopCommand.undo), isTrue);
    expect(invoked, ['library']);
    editorEnabled = true;
    commands.invoke(DesktopCommand.undo);
    expect(invoked, ['library', 'editor']);
    unregister();
    expect(commands.invoke(DesktopCommand.undo), isFalse);
    commands.dispose();
  });

  test('repeated exit requests await every editor once', () async {
    final commands = DesktopCommands();
    final save = Completer<bool>();
    final order = <String>[];
    commands.registerEditor(() async {
      order.add('covered draft');
      return save.future;
    });
    commands.registerEditor(() async {
      order.add('current draft');
      return true;
    });
    final first = commands.prepareToExit();
    final repeated = commands.prepareToExit();
    expect(identical(first, repeated), isTrue);
    expect(order, ['covered draft']);
    save.complete(true);
    expect(await first, AppExitResponse.exit);
    expect(order, ['covered draft', 'current draft']);
    commands.dispose();
  });

  test('failed editor cancels exit and a later request can retry', () async {
    final commands = DesktopCommands();
    var savesAvailable = false;
    var otherSaved = false;
    commands.registerEditor(() async => savesAvailable);
    commands.registerEditor(() async {
      otherSaved = true;
      return true;
    });
    expect(await commands.prepareToExit(), AppExitResponse.cancel);
    expect(otherSaved, isTrue);
    savesAvailable = true;
    expect(await commands.prepareToExit(), AppExitResponse.exit);
    commands.dispose();
  });

  test('exit waits for the final save of an editor removed from navigation',
      () async {
    final commands = DesktopCommands();
    final finalSave = Completer<bool>();
    final unregister = commands.registerEditor(() async => true);
    commands.trackSave(finalSave.future);
    unregister();
    var finished = false;
    final exit = commands.prepareToExit().then((response) {
      finished = true;
      return response;
    });
    await Future<void>.delayed(Duration.zero);
    expect(finished, isFalse);
    finalSave.complete(false);
    expect(await exit, AppExitResponse.cancel);
    expect(await commands.prepareToExit(), AppExitResponse.exit);
    commands.dispose();
  });

  test('a save that never finishes still lets the app quit', () async {
    final commands =
        DesktopCommands(saveBudget: const Duration(milliseconds: 20));
    final stuck = Completer<bool>();
    commands.registerEditor(() => stuck.future);
    var reached = false;
    commands.registerEditor(() async {
      reached = true;
      return true;
    });
    // macOS has no way to be told "still working", so an unanswerable save
    // must not be able to hold the quit open.
    expect(await commands.prepareToExit(), AppExitResponse.exit);
    expect(reached, isFalse);
    stuck.complete(true);
    commands.dispose();
  });

  test('a tracked save that never finishes is bounded too', () async {
    final commands =
        DesktopCommands(saveBudget: const Duration(milliseconds: 20));
    final stuck = Completer<bool>();
    commands.registerEditor(() async => true);
    commands.trackSave(stuck.future);
    expect(await commands.prepareToExit(), AppExitResponse.exit);
    stuck.complete(false);
    commands.dispose();
  });

  test('a slow save inside the budget still decides the answer', () async {
    final commands = DesktopCommands(saveBudget: const Duration(seconds: 30));
    commands.registerEditor(() async {
      await Future<void>.delayed(const Duration(milliseconds: 20));
      return false;
    });
    // The bound is a backstop, not a shortcut: a save that answers in time
    // still cancels the quit.
    expect(await commands.prepareToExit(), AppExitResponse.cancel);
    commands.dispose();
  });

  test('a quit that timed out can be retried once saves recover', () async {
    final commands =
        DesktopCommands(saveBudget: const Duration(milliseconds: 20));
    final stuck = Completer<bool>();
    var recovered = false;
    commands
        .registerEditor(() => recovered ? Future.value(true) : stuck.future);
    expect(await commands.prepareToExit(), AppExitResponse.exit);
    recovered = true;
    expect(await commands.prepareToExit(), AppExitResponse.exit);
    stuck.complete(true);
    commands.dispose();
  });
  test('external writes coalesce flushes and wait for every editor', () async {
    final commands = DesktopCommands();
    final pending = Completer<bool>();
    final flushed = <String>[];
    commands.registerEditor(() {
      flushed.add('covered');
      return pending.future;
    });
    commands.registerEditor(() async {
      flushed.add('current');
      return true;
    });
    final first = commands.prepareForExternalWrite();
    final repeated = commands.prepareForExternalWrite();
    expect(identical(first, repeated), isTrue);
    expect(flushed, ['covered']);
    pending.complete(true);
    expect(await first, isTrue);
    expect(flushed, ['covered', 'current']);
    commands.dispose();
  });

  test('external writes reject failed or thrown flushes and can retry',
      () async {
    final commands = DesktopCommands();
    var failing = true;
    var calls = 0;
    commands.registerEditor(() async {
      if (failing) throw StateError('Storage unavailable');
      return true;
    });
    commands.registerEditor(() async {
      calls++;
      return !failing;
    });
    expect(await commands.prepareForExternalWrite(), isFalse);
    expect(calls, 1);
    failing = false;
    expect(await commands.prepareForExternalWrite(), isTrue);
    expect(calls, 2);
    commands.dispose();
  });

  test('hung editors block external writes while quit keeps its timeout policy',
      () async {
    final commands =
        DesktopCommands(saveBudget: const Duration(milliseconds: 20));
    final pending = Completer<bool>();
    var calls = 0;
    commands.registerEditor(() {
      calls++;
      return pending.future;
    });
    final external = commands.prepareForExternalWrite();
    final quit = commands.prepareToExit();
    expect(await external, isFalse);
    expect(await quit, AppExitResponse.exit);
    expect(calls, 2);
    pending.complete(true);
    await Future<void>.delayed(Duration.zero);
    expect(await commands.prepareForExternalWrite(), isTrue);
    commands.dispose();
  });

  test(
      'removed-route pending save timeout blocks external writes and remains tracked',
      () async {
    final commands =
        DesktopCommands(saveBudget: const Duration(milliseconds: 20));
    final pending = Completer<bool>();
    final unregister = commands.registerEditor(() async => true);
    commands.trackSave(pending.future);
    unregister();
    expect(await commands.prepareForExternalWrite(), isFalse);
    expect(await commands.prepareToExit(), AppExitResponse.exit);
    // A timed out external check never cancels the original durable save.
    pending.complete(true);
    await Future<void>.delayed(Duration.zero);
    expect(await commands.prepareForExternalWrite(), isTrue);
    commands.dispose();
  });

  test('a removed-route pending failure blocks an external write', () async {
    final commands = DesktopCommands();
    final pending = Completer<bool>();
    commands.trackSave(pending.future);
    final external = commands.prepareForExternalWrite();
    pending.complete(false);
    expect(await external, isFalse);
    expect(await commands.prepareForExternalWrite(), isTrue);
    commands.dispose();
  });
}
