import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/note_body_editor.dart';
import 'package:onlynote/presentation/components/note_divider_block.dart';
import 'package:onlynote/presentation/components/note_document_view.dart';
import 'package:onlynote/presentation/components/simple_formatting_controller.dart';
import 'package:onlynote/presentation/theme/theme.dart';

Future<void> _pump(WidgetTester tester, Widget child,
    {double scale = 1, bool dark = false}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(320, 700);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(MaterialApp(
      theme: dark ? AppTheme.dark : AppTheme.light,
      supportedLocales: S.delegate.supportedLocales,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate
      ],
      builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: child!),
      home: Scaffold(
          body: SingleChildScrollView(
              padding: const EdgeInsets.all(20), child: child))));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('divider is a real block with editable text before and after',
      (tester) async {
    final controller = SimpleFormattingController(text: 'Before\nAfter');
    final focus = FocusNode();
    addTearDown(controller.dispose);
    addTearDown(focus.dispose);
    controller.selection = const TextSelection.collapsed(offset: 7);
    controller.insertDivider();
    await _pump(
        tester,
        NoteBodyEditor(
            controller: controller,
            focusNode: focus,
            imagePaths: const [],
            imageLayouts: const [],
            onImageLayoutsChanged: (_) {},
            onRemoveImage: (_) {},
            showFormattingToolbar: false));
    expect(find.byType(NoteDividerBlock), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2));
    await tester.enterText(
        find.byKey(const ValueKey('note-body-end')), 'After writing');
    await tester.pumpAndSettle();
    expect(controller.text, 'Before\n─\nAfter writing');
    await tester.tap(find.byTooltip('Delete Divider line'));
    await tester.pumpAndSettle();
    expect(find.byType(NoteDividerBlock), findsNothing);
    expect(controller.text, 'Before\nAfter writing');
    expect(find.byType(TextField), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reader and image-sharing layout render rules at large text',
      (tester) async {
    final controller = SimpleFormattingController(text: 'Before\nAfter');
    addTearDown(controller.dispose);
    controller.selection = const TextSelection.collapsed(offset: 7);
    controller.insertDivider();
    await _pump(
        tester,
        NoteDocumentView(
            text: controller.text,
            styles: controller.styles,
            selectable: false),
        scale: 2,
        dark: true);
    expect(find.byType(NoteDividerBlock), findsOneWidget);
    expect(find.byTooltip('Delete Divider line'), findsNothing);
    expect(find.textContaining('─'), findsNothing);
    expect(find.textContaining('Before'), findsOneWidget);
    expect(find.textContaining('After'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
