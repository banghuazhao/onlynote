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

  testWidgets(
      'suggestions filter normalized literal text without hiding selected tags',
      (tester) async {
    await _open(tester, tags: [
      'Pinned'
    ], suggestions: [
      'Work plan',
      'Homework',
      '[Draft]',
      'a.b',
      'aXb',
      '茶室',
      '茶葉',
      ' work PLAN ',
      'PINNED',
    ]);
    final allSuggestions = tester
        .widgetList<ActionChip>(find.byType(ActionChip))
        .map((chip) => (chip.label as ConstrainedBox).child)
        .cast<Text>()
        .map((label) => label.data)
        .toList();
    expect(allSuggestions,
        ['Work plan', 'Homework', '[Draft]', 'a.b', 'aXb', '茶室', '茶葉']);
    await tester.enterText(_key('note-tag-input'), '  wOrK\t ');
    await tester.pumpAndSettle();
    expect(find.byType(ActionChip), findsNWidgets(2));
    expect(_key('note-tag-suggestion-work plan'), findsOneWidget);
    expect(_key('note-tag-suggestion-homework'), findsOneWidget);
    expect(_key('note-tag-pinned'), findsOneWidget);
    expect(find.byType(InputChip), findsOneWidget);

    await tester.enterText(_key('note-tag-input'), '[');
    await tester.pumpAndSettle();
    expect(find.byType(ActionChip), findsOneWidget);
    expect(_key('note-tag-suggestion-[draft]'), findsOneWidget);
    await tester.enterText(_key('note-tag-input'), '.');
    await tester.pumpAndSettle();
    expect(find.byType(ActionChip), findsOneWidget);
    expect(_key('note-tag-suggestion-a.b'), findsOneWidget);
    await tester.enterText(_key('note-tag-input'), '茶');
    await tester.pumpAndSettle();
    expect(find.byType(ActionChip), findsNWidgets(2));
    expect(_key('note-tag-suggestion-茶室'), findsOneWidget);
    expect(_key('note-tag-suggestion-茶葉'), findsOneWidget);

    await tester.enterText(_key('note-tag-input'), ' \t ');
    await tester.pumpAndSettle();
    expect(find.byType(ActionChip), findsNWidgets(7));
    expect(tester.widget<IconButton>(_key('note-tags-add')).onPressed, isNull);
    await tester.enterText(_key('note-tag-input'), 'Missing');
    await tester.pumpAndSettle();
    expect(find.byType(ActionChip), findsNothing);
    expect(_key('note-tag-suggestions-empty'), findsOneWidget);
    expect(_key('note-tag-pinned'), findsOneWidget);
    await tester.tap(_key('note-tags-clear-input'));
    await tester.pumpAndSettle();
    expect(find.byType(ActionChip), findsNWidgets(7));
    expect(_key('note-tag-suggestions-empty'), findsNothing);
    expect(_key('note-tags-clear-input'), findsNothing);
    expect(find.byType(InputChip), findsOneWidget);
  });

  testWidgets('choosing a suggestion clears the prefix before Done',
      (tester) async {
    List<String>? result;
    var closed = false;
    await _open(tester, tags: ['Work'], suggestions: ['Project plans', 'Home'],
        onClosed: (value) {
      result = value;
      closed = true;
    });
    await tester.enterText(_key('note-tag-input'), 'pro');
    await tester.pumpAndSettle();
    expect(_key('note-tag-suggestion-home'), findsNothing);
    await tester.tap(_key('note-tag-suggestion-project plans'));
    await tester.pumpAndSettle();
    expect(_key('note-tag-project plans'), findsOneWidget);
    expect(_key('note-tag-suggestion-home'), findsOneWidget);
    expect(tester.widget<TextField>(_key('note-tag-input')).controller!.text,
        isEmpty);
    expect(closed, isFalse);
    await tester.tap(_key('note-tags-save'));
    await tester.pumpAndSettle();
    expect(result, ['Work', 'Project plans']);
    expect(closed, isTrue);
  });

  testWidgets('filtering and cancelling never save an input or matching tag',
      (tester) async {
    final original = ['Work'];
    final results = <List<String>?>[];
    await _open(tester,
        tags: original, suggestions: ['Personal'], onClosed: results.add);
    await tester.enterText(_key('note-tag-input'), 'per');
    await tester.pumpAndSettle();
    expect(_key('note-tag-suggestion-personal'), findsOneWidget);
    expect(find.byType(InputChip), findsOneWidget);
    expect(results, isEmpty);
    expect(original, ['Work']);
    await tester.tap(_key('note-tags-cancel'));
    await tester.pumpAndSettle();
    expect(results, [null]);
    expect(original, ['Work']);
  });

  testWidgets('no matching suggestion still permits an explicit new tag',
      (tester) async {
    List<String>? result;
    await _open(tester,
        suggestions: ['Work'], onClosed: (value) => result = value);
    await tester.enterText(_key('note-tag-input'), 'New tag');
    await tester.pumpAndSettle();
    expect(_key('note-tag-suggestions-empty'), findsOneWidget);
    expect(find.byType(InputChip), findsNothing);
    await tester.tap(_key('note-tags-add'));
    await tester.pumpAndSettle();
    expect(_key('note-tag-new tag'), findsOneWidget);
    expect(_key('note-tag-suggestion-work'), findsOneWidget);
    expect(result, isNull);
    await tester.tap(_key('note-tags-save'));
    await tester.pumpAndSettle();
    expect(result, ['New tag']);
  });

  testWidgets('a suggestion at the tag limit preserves its prefix on failure',
      (tester) async {
    final tags = List.generate(20, (index) => 'Tag $index');
    List<String>? result;
    await _open(tester,
        tags: tags,
        suggestions: ['Project plans'],
        onClosed: (value) => result = value);
    await tester.enterText(_key('note-tag-input'), 'pro');
    await tester.pumpAndSettle();
    await tester.ensureVisible(_key('note-tag-suggestion-project plans'));
    await tester.pumpAndSettle();
    await tester.tap(_key('note-tag-suggestion-project plans'));
    await tester.pumpAndSettle();
    expect(_key('note-tags-error'), findsOneWidget);
    expect(find.byType(InputChip), findsNWidgets(20));
    expect(tester.widget<TextField>(_key('note-tag-input')).controller!.text,
        'pro');
    expect(result, isNull);
    await tester.ensureVisible(_key('note-tag-remove-tag 0'));
    await tester.pumpAndSettle();
    await tester.tap(_key('note-tag-remove-tag 0'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(_key('note-tag-suggestion-project plans'));
    await tester.pumpAndSettle();
    await tester.tap(_key('note-tag-suggestion-project plans'));
    await tester.pumpAndSettle();
    expect(_key('note-tags-error'), findsNothing);
    expect(tester.widget<TextField>(_key('note-tag-input')).controller!.text,
        isEmpty);
    await tester.ensureVisible(_key('note-tags-save'));
    await tester.pumpAndSettle();
    await tester.tap(_key('note-tags-save'));
    await tester.pumpAndSettle();
    expect(result, [...tags.skip(1), 'Project plans']);
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

  testWidgets('filtered Chinese tags fit narrow large text with the keyboard',
      (tester) async {
    tester.view.physicalSize = const Size(280, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    await _open(tester,
        tags: ['個人工作計劃'],
        suggestions: ['本週重要事項', '茶室計劃', '茶葉清單'],
        locale: const Locale('zh', 'HK'),
        textScale: 2,
        disableAnimations: true);
    tester.view.viewInsets = const FakeViewPadding(bottom: 260);
    await tester.enterText(_key('note-tag-input'), '茶');
    await tester.pumpAndSettle();
    expect(_key('note-tag-個人工作計劃'), findsOneWidget);
    expect(find.byType(ActionChip), findsNWidgets(2));
    await tester.ensureVisible(_key('note-tags-clear-input'));
    await tester.pumpAndSettle();
    final field = tester.getRect(_key('note-tag-input'));
    for (final key in ['note-tags-clear-input', 'note-tags-add']) {
      final button = tester.getRect(_key(key));
      expect(button.left, greaterThanOrEqualTo(field.left));
      expect(button.right, lessThanOrEqualTo(field.right));
      expect(button.width, greaterThanOrEqualTo(48));
    }
    await tester.tap(_key('note-tags-clear-input'));
    await tester.pumpAndSettle();
    expect(find.byType(ActionChip), findsNWidgets(3));
    await tester.enterText(_key('note-tag-input'), '無符合結果');
    await tester.pumpAndSettle();
    expect(_key('note-tag-suggestions-empty'), findsOneWidget);
    await tester.ensureVisible(_key('note-tags-save'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(_key('note-tags-save'), findsOneWidget);
  });
}
