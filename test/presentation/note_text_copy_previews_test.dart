import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/note_share_action_tile.dart';
import 'package:onlynote/presentation/components/note_text_copy_previews.dart';

void main() {
  for (final (name, preview, size, locale) in [
    (
      'light',
      noteTextCopyLightPreview,
      const Size(390, 620),
      const Locale('en')
    ),
    ('dark', noteTextCopyDarkPreview, const Size(390, 620), const Locale('en')),
    (
      'Chinese narrow 2x',
      noteTextCopyChinesePreview,
      const Size(280, 700),
      const Locale('zh', 'HK'),
    ),
  ]) {
    testWidgets('$name copy preview gives local feedback without clipboard I/O',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var clipboardCalls = 0;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method.startsWith('Clipboard.')) {
            clipboardCalls++;
            throw StateError('Previews must use local callbacks');
          }
          return null;
        },
      );
      addTearDown(() => tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null));

      await tester.pumpWidget(preview());
      await tester.pumpAndSettle();
      final action = find.byKey(const ValueKey('note-share-copyText'));
      expect(action, findsOneWidget);
      expect(Localizations.localeOf(tester.element(action)), locale);
      expect(find.text(S.current.Share_Copy_Text), findsOneWidget);
      expect(find.text(S.current.Share_Copy_Text_Description), findsOneWidget);
      await tester.ensureVisible(action);
      await tester.pumpAndSettle();
      expect(tester.getSize(action).height, greaterThanOrEqualTo(48));
      await tester.tap(action);
      await tester.pump();
      expect(find.text(S.current.Share_Text_Copied), findsOneWidget);
      expect(find.byType(SnackBar), findsOneWidget);
      expect(clipboardCalls, 0);
      expect(tester.takeException(), isNull);
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      expect(find.byType(SnackBar), findsNothing);
    });
  }

  testWidgets('share action tile invokes its supplied callback once per tap',
      (tester) async {
    tester.view.physicalSize = const Size(280, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var calls = 0;
    await tester.pumpWidget(MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: const TextScaler.linear(2)),
        child: child!,
      ),
      home: Scaffold(
        body: SingleChildScrollView(
          child: NoteShareActionTile(
            key: const ValueKey('copy-action'),
            icon: Icons.copy_outlined,
            title: 'Copy full note text',
            description: 'Copy the title, body, checklist and transcripts.',
            onPressed: () => calls++,
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    final action = find.byKey(const ValueKey('copy-action'));
    await tester.ensureVisible(action);
    expect(tester.getSize(action).height, greaterThanOrEqualTo(48));
    expect(calls, 0);
    await tester.tap(action);
    await tester.pump();
    expect(calls, 1);
    expect(tester.takeException(), isNull);
  });
}
