import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/note_tags_sheet.dart';

Future<void> _open(
  WidgetTester tester, {
  List<String> tags = const [],
  List<String> suggestions = const [],
  void Function(List<String>?)? onClosed,
  Locale locale = const Locale('en'),
  double textScale = 1,
  bool disableAnimations = false,
}) async {
  await tester.pumpWidget(MaterialApp(
    locale: locale,
    supportedLocales: S.delegate.supportedLocales,
    localizationsDelegates: const [
      S.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(textScale),
        disableAnimations: disableAnimations,
      ),
      child: child!,
    ),
    home: Scaffold(
      body: Builder(
        builder: (context) => TextButton(
          onPressed: () async {
            final result = await showNoteTagsSheet(
              context,
              tags: tags,
              suggestions: suggestions,
            );
            onClosed?.call(result);
          },
          child: const Text('Open tags'),
        ),
      ),
    ),
  ));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Open tags'));
  await tester.pumpAndSettle();
}

Finder _key(String key) => find.byKey(ValueKey(key));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'adding normalizes duplicates and only explicit save returns tags',
      (tester) async {
    final original = ['Work'];
    List<String>? result;
    var closed = false;
    await _open(tester, tags: original, onClosed: (value) {
      result = value;
      closed = true;
    });
    await tester.enterText(_key('note-tag-input'), '  Home\t ideas  ');
    await tester.pump();
    await tester.tap(_key('note-tags-add'));
    await tester.pumpAndSettle();
    await tester.enterText(_key('note-tag-input'), 'WORK');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(_key('note-tag-home ideas'), findsOneWidget);
    expect(find.byType(InputChip), findsNWidgets(2));
    expect(closed, isFalse);
    expect(original, ['Work']);
    await tester.tap(_key('note-tags-save'));
    await tester.pumpAndSettle();
    expect(closed, isTrue);
    expect(result, ['Work', 'Home ideas']);
    expect(() => result!.add('Other'), throwsUnsupportedError);
  });

  testWidgets('remove and suggestion selection stay in the editable sheet',
      (tester) async {
    List<String>? result;
    await _open(tester,
        tags: ['Work'],
        suggestions: ['work', 'Home', ' HOME '],
        onClosed: (value) => result = value);
    expect(_key('note-tag-suggestion-work'), findsNothing);
    expect(find.byType(ActionChip), findsOneWidget);
    await tester.tap(_key('note-tag-remove-work'));
    await tester.pumpAndSettle();
    expect(_key('note-tag-work'), findsNothing);
    expect(_key('note-tag-suggestion-work'), findsOneWidget);
    await tester.tap(_key('note-tag-suggestion-home'));
    await tester.pumpAndSettle();
    expect(_key('note-tag-home'), findsOneWidget);
    expect(_key('note-tag-suggestion-home'), findsNothing);
    expect(result, isNull);
    await tester.tap(_key('note-tags-save'));
    await tester.pumpAndSettle();
    expect(result, ['Home']);
  });

  testWidgets('cancel discards edits and dismissal returns null',
      (tester) async {
    final original = ['Work'];
    final results = <List<String>?>[];
    await _open(tester, tags: original, onClosed: results.add);
    await tester.enterText(_key('note-tag-input'), 'Personal');
    await tester.pump();
    await tester.tap(_key('note-tags-add'));
    await tester.pumpAndSettle();
    await tester.tap(_key('note-tags-cancel'));
    await tester.pumpAndSettle();
    expect(results, [null]);
    expect(original, ['Work']);
    await tester.tap(find.text('Open tags'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(results, [null, null]);
    expect(original, ['Work']);
  });

  testWidgets('save includes a tag still in the input field', (tester) async {
    List<String>? result;
    await _open(tester, onClosed: (value) => result = value);
    await tester.enterText(_key('note-tag-input'), '  Quick capture ');
    await tester.tap(_key('note-tags-save'));
    await tester.pumpAndSettle();
    expect(result, ['Quick capture']);
  });

  testWidgets(
      'invalid length preserves input and allows correction before save',
      (tester) async {
    List<String>? result;
    await _open(tester, onClosed: (value) => result = value);
    final invalid = 'a' * 41;
    await tester.enterText(_key('note-tag-input'), invalid);
    await tester.tap(_key('note-tags-save'));
    await tester.pumpAndSettle();
    expect(result, isNull);
    expect(_key('note-tags-error'), findsOneWidget);
    expect(tester.widget<TextField>(_key('note-tag-input')).controller!.text,
        invalid);
    await tester.enterText(_key('note-tag-input'), 'Valid');
    await tester.pump();
    expect(_key('note-tags-error'), findsNothing);
    await tester.tap(_key('note-tags-save'));
    await tester.pumpAndSettle();
    expect(result, ['Valid']);
  });

  testWidgets('tag count limit keeps existing tags and recovers after removal',
      (tester) async {
    final tags = List.generate(20, (index) => 'Tag $index');
    List<String>? result;
    await _open(tester, tags: tags, onClosed: (value) => result = value);
    await tester.enterText(_key('note-tag-input'), 'New tag');
    await tester.pump();
    await tester.tap(_key('note-tags-add'));
    await tester.pumpAndSettle();
    expect(find.byType(InputChip), findsNWidgets(20));
    expect(_key('note-tags-error'), findsOneWidget);
    await tester.ensureVisible(_key('note-tag-remove-tag 0'));
    await tester.pumpAndSettle();
    await tester.tap(_key('note-tag-remove-tag 0'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(_key('note-tags-add'));
    await tester.pumpAndSettle();
    await tester.tap(_key('note-tags-add'));
    await tester.pumpAndSettle();
    expect(_key('note-tags-error'), findsNothing);
    expect(_key('note-tag-new tag'), findsOneWidget);
    await tester.ensureVisible(_key('note-tags-save'));
    await tester.pumpAndSettle();
    await tester.tap(_key('note-tags-save'));
    await tester.pumpAndSettle();
    expect(result, [...tags.skip(1), 'New tag']);
  });

  testWidgets(
      'invalid suggestions are ignored and valid suggestions deduplicate',
      (tester) async {
    await _open(tester, suggestions: ['', 'a' * 41, 'Work', ' WORK ', 'Home']);
    expect(find.byType(ActionChip), findsNWidgets(2));
    expect(_key('note-tag-suggestion-work'), findsOneWidget);
    expect(_key('note-tag-suggestion-home'), findsOneWidget);
  });

  testWidgets(
      'long Chinese tags wrap and reduced motion disables chip animation',
      (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final tag = '個人工作計劃' * 6;
    final suggestion = '整理本週重要事項' * 4;
    await _open(tester,
        tags: [tag],
        suggestions: [suggestion],
        locale: const Locale('zh'),
        textScale: 2,
        disableAnimations: true);
    final chip = tester.widget<InputChip>(_key('note-tag-$tag'));
    expect(chip.chipAnimationStyle!.enableAnimation!.duration, Duration.zero);
    final label = tester.getRect(find.text(tag));
    final bounds = tester.getRect(_key('note-tag-$tag'));
    expect(label.top, greaterThanOrEqualTo(bounds.top));
    expect(label.bottom, lessThanOrEqualTo(bounds.bottom));
    expect(label.right, lessThanOrEqualTo(bounds.right));
    await tester.ensureVisible(_key('note-tags-save'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(_key('note-tags-save'), findsOneWidget);
  });
}
