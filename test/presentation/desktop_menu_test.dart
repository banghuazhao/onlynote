import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/Tools/desktop_commands.dart';
import 'package:onlynote/generated/l10n.dart';

Widget _host(Widget child,
        {DesktopCommands? commands,
        VoidCallback? newNote,
        VoidCallback? settings,
        VoidCallback? quit}) =>
    MaterialApp(
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      locale: const Locale('en'),
      builder: (context, child) => DesktopAppMenu(
        commands: commands,
        onNewNote: newNote ?? () {},
        onSettings: settings ?? () {},
        onQuit: quit ?? () {},
        child: child!,
      ),
      home: Scaffold(body: child),
    );

PlatformMenuItem _item(WidgetTester tester, String label) {
  final bar = tester.widget<PlatformMenuBar>(find.byType(PlatformMenuBar));
  Iterable<PlatformMenuItem> visit(PlatformMenuItem item) sync* {
    yield item;
    for (final child in item is PlatformMenu ? item.menus : item.members) {
      yield* visit(child);
    }
  }

  return bar.menus.expand(visit).firstWhere((item) => item.label == label);
}

Future<void> _command(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
  await tester.sendKeyEvent(key);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
  await tester.pump();
}

void main() {
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.menu, (_) async => null);
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.menu, null);
  });

  testWidgets('Mac commands work while a text field has focus', (tester) async {
    final controller = TextEditingController(text: 'Keep my note');
    final commands = DesktopCommands();
    var notes = 0;
    var settings = 0;
    var quits = 0;
    var searches = 0;
    commands.registerCommand(DesktopCommand.searchNotes,
        invoke: () => searches++, isActive: () => true);
    await tester.pumpWidget(_host(TextField(controller: controller),
        commands: commands,
        newNote: () => notes++,
        settings: () => settings++,
        quit: () => quits++));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(TextField));
    await tester.pump();
    await _command(tester, LogicalKeyboardKey.keyN);
    await _command(tester, LogicalKeyboardKey.comma);
    await _command(tester, LogicalKeyboardKey.keyF);
    await _command(tester, LogicalKeyboardKey.keyQ);
    await _command(tester, LogicalKeyboardKey.keyW);
    expect([notes, settings, searches, quits], [1, 1, 1, 2]);
    expect(controller.text, 'Keep my note');
    expect(_item(tester, 'New Note').shortcut!.serializeForMenu().meta, isTrue);
    expect(_item(tester, 'Quit Onlynote').onSelected, isNotNull);
    expect(_item(tester, 'Close Window').onSelected, isNotNull);
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
    commands.dispose();
  }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));

  testWidgets('native Edit uses focused text selection and clipboard',
      (tester) async {
    String? clipboardText;
    final messenger = tester.binding.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      switch (call.method) {
        case 'Clipboard.setData':
          clipboardText = (call.arguments as Map)['text'] as String?;
          return null;
        case 'Clipboard.getData':
          return clipboardText == null ? null : {'text': clipboardText};
        case 'Clipboard.hasStrings':
          return {'value': clipboardText?.isNotEmpty ?? false};
        default:
          return null;
      }
    });
    addTearDown(() =>
        messenger.setMockMethodCallHandler(SystemChannels.platform, null));
    final controller = TextEditingController(text: 'alpha beta');
    await tester.pumpWidget(_host(TextField(controller: controller)));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(TextField));
    controller.selection = const TextSelection(baseOffset: 6, extentOffset: 10);
    await tester.pump();
    _item(tester, 'Copy').onSelected!();
    await tester.pump();
    expect(clipboardText, 'beta');
    _item(tester, 'Select all').onSelected!();
    await tester.pump();
    expect(controller.selection,
        const TextSelection(baseOffset: 0, extentOffset: 10));
    _item(tester, 'Paste').onSelected!();
    await tester.pumpAndSettle();
    expect(controller.text, 'beta');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));

  testWidgets('non-Mac platforms keep their existing app tree', (tester) async {
    var invoked = false;
    await tester
        .pumpWidget(_host(const TextField(), newNote: () => invoked = true));
    await tester.pumpAndSettle();
    expect(find.byType(PlatformMenuBar), findsNothing);
    expect(find.byType(TextField), findsOneWidget);
    await tester.tap(find.byType(TextField));
    await _command(tester, LogicalKeyboardKey.keyN);
    expect(invoked, isFalse);
    await tester.pumpWidget(const SizedBox());
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));
}
