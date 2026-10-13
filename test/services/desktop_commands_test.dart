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
}
