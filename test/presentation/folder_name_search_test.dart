import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/domain/model/folder.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/app_sheet.dart';
import 'package:onlynote/presentation/components/folder_name_search.dart';
import 'package:onlynote/presentation/components/folder_name_search_previews.dart';

Finder _key(String value) => find.byKey(ValueKey(value));

Future<void> _capture(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('CAPTURE_UI')) return;
  final boundary = tester
      .renderObject<RenderRepaintBoundary>(_key('folder-name-search-capture'));
  await tester.runAsync(() async {
    final image = await boundary.toImage();
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final directory = Directory('/tmp/onlynote-release-feedback');
      await directory.create(recursive: true);
      await File('${directory.path}/folder-search-$name.png')
          .writeAsBytes(bytes!.buffer.asUint8List());
    } finally {
      image.dispose();
    }
  });
}

class _Pops extends NavigatorObserver {
  int count = 0;
  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    count++;
    super.didPop(route, previousRoute);
  }
}

final _folders = [
  Folder(id: 'z', name: 'Work'),
  Folder(id: 'a', name: 'C++ [2026]'),
  Folder(id: 'duplicate', name: 'WORK projects'),
  Folder(id: 'cjk', name: '閱讀與研究筆記'),
  Folder(id: 'unicode', name: 'Ångström'),
];

Widget _host(Widget child, {Locale locale = const Locale('en')}) => MaterialApp(
      locale: locale,
      supportedLocales: S.delegate.supportedLocales,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(body: child),
    );

void main() {
  setUpAll(() async {
    if (!const bool.fromEnvironment('CAPTURE_UI')) return;
    for (final (family, asset) in [
      ('Roboto', 'assets/fonts/Roboto-Regular.ttf'),
      ('DroidSansFallback', 'assets/fonts/DroidSansFallback.ttf'),
      ('MaterialIcons', 'fonts/MaterialIcons-Regular.otf'),
    ]) {
      final loader = FontLoader(family);
      loader.addFont(rootBundle.load(asset));
      await loader.load();
    }
  });

  test('literal folder search preserves IDs, object identity and input order',
      () {
    for (final query in ['', '   ', '\u3000']) {
      expect(filterFoldersByName(_folders, query), _folders);
    }
    final matching = filterFoldersByName(_folders, '  wOrK  ');
    expect(matching.map((folder) => folder.id), ['z', 'duplicate']);
    expect(identical(matching.first, _folders.first), isTrue);
    expect(filterFoldersByName(_folders, 'C++').single.id, 'a');
    expect(filterFoldersByName(_folders, '[2026]').single.id, 'a');
    expect(filterFoldersByName(_folders, '.*'), isEmpty);
    expect(filterFoldersByName(_folders, '  研究  ').single.id, 'cjk');
    expect(filterFoldersByName(_folders, 'ångström').single.id, 'unicode');
    expect(_folders.map((folder) => folder.id),
        ['z', 'a', 'duplicate', 'cjk', 'unicode']);
  });

  testWidgets('search and clear leave selection alone; fixed choices remain',
      (tester) async {
    final chosen = <String?>[];
    var cancelled = 0;
    await tester.pumpWidget(_host(MoveToFolderSheet(
      folders: _folders,
      selectedFolderId: 'z',
      onSelected: chosen.add,
      onCancel: () => cancelled++,
    )));
    await tester.pumpAndSettle();
    expect(tester.widget<ListTile>(_key('move-to-folder-folder-z')).selected,
        isTrue);
    await tester.enterText(_key('move-to-folder-search'), 'absent');
    await tester.pump();
    expect(_key('move-to-folder-search-empty'), findsOneWidget);
    expect(_key('move-to-folder-folder-z'), findsNothing);
    expect(_key('move-to-folder-none'), findsOneWidget);
    expect(_key('move-to-folder-cancel'), findsOneWidget);
    expect(chosen, isEmpty);
    await tester.tap(_key('move-to-folder-clear-search'));
    await tester.pumpAndSettle();
    expect(_key('move-to-folder-search-empty'), findsNothing);
    expect(tester.widget<ListTile>(_key('move-to-folder-folder-z')).selected,
        isTrue);
    await tester.enterText(_key('move-to-folder-search'), ' C++ ');
    await tester.pump();
    expect(_key('move-to-folder-folder-a'), findsOneWidget);
    expect(_key('move-to-folder-folder-z'), findsNothing);
    await tester.ensureVisible(_key('move-to-folder-cancel'));
    await tester.tap(_key('move-to-folder-cancel'));
    await tester.pump();
    expect(cancelled, 1);
    expect(chosen, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a filtered row returns its original ID once on rapid callbacks',
      (tester) async {
    final chosen = <String?>[];
    await tester.pumpWidget(_host(MoveToFolderSheet(
      folders: _folders,
      onSelected: chosen.add,
    )));
    await tester.pumpAndSettle();
    await tester.enterText(_key('move-to-folder-search'), '[2026]');
    await tester.pump();
    final callback =
        tester.widget<ListTile>(_key('move-to-folder-folder-a')).onTap!;
    callback();
    callback();
    expect(chosen, ['a']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('folder updates retain a query and refresh matches and selection',
      (tester) async {
    final updates = ValueNotifier<List<Folder>>(_folders);
    addTearDown(updates.dispose);
    final chosen = <String?>[];
    await tester.pumpWidget(_host(ValueListenableBuilder<List<Folder>>(
      valueListenable: updates,
      builder: (_, folders, __) => MoveToFolderSheet(
        folders: folders,
        selectedFolderId: 'duplicate',
        onSelected: chosen.add,
      ),
    )));
    await tester.pumpAndSettle();
    await tester.enterText(_key('move-to-folder-search'), 'work');
    await tester.pump();
    updates.value = [Folder(id: 'a-new', name: 'Work archive')];
    await tester.pump();
    expect(
        tester
            .widget<TextField>(_key('move-to-folder-search'))
            .controller!
            .text,
        'work');
    expect(_key('move-to-folder-folder-z'), findsNothing);
    expect(_key('move-to-folder-folder-duplicate'), findsNothing);
    expect(_key('move-to-folder-folder-a-new'), findsOneWidget);
    expect(chosen, isEmpty);
    updates.value = [];
    await tester.pump();
    expect(_key('move-to-folder-search-empty'), findsOneWidget);
    expect(_key('move-to-folder-none'), findsOneWidget);
  });

  testWidgets(
      'cancelled sheet rejects captured row and repeated cancel actions',
      (tester) async {
    final chosen = <String?>[];
    final pops = _Pops();
    await tester.pumpWidget(MaterialApp(
      navigatorObservers: [pops],
      localizationsDelegates: const [S.delegate],
      supportedLocales: S.delegate.supportedLocales,
      home: Scaffold(body: Builder(builder: (context) {
        return TextButton(
          onPressed: () => showAppSheet<void>(
            context: context,
            builder: (sheetContext) => MoveToFolderSheet(
              folders: _folders,
              onSelected: (id) {
                Navigator.pop(sheetContext);
                chosen.add(id);
              },
            ),
          ),
          child: const Text('Open'),
        );
      })),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    final select =
        tester.widget<ListTile>(_key('move-to-folder-folder-z')).onTap!;
    final cancel =
        tester.widget<OutlinedButton>(_key('move-to-folder-cancel')).onPressed!;
    cancel();
    select();
    cancel();
    await tester.pumpAndSettle();
    expect(chosen, isEmpty);
    expect(pops.count, 1);
    expect(find.text('Open'), findsOneWidget);
    expect(_key('move-to-folder-search'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('covered and closing sheets reject captured choice callbacks',
      (tester) async {
    final chosen = <String?>[];
    final pops = _Pops();
    late BuildContext sheetContext;
    await tester.pumpWidget(MaterialApp(
      navigatorObservers: [pops],
      localizationsDelegates: const [S.delegate],
      supportedLocales: S.delegate.supportedLocales,
      home: Scaffold(body: Builder(builder: (context) {
        return TextButton(
          onPressed: () => showAppSheet<void>(
            context: context,
            builder: (context) {
              sheetContext = context;
              return MoveToFolderSheet(
                folders: _folders,
                onSelected: (id) {
                  Navigator.pop(context);
                  chosen.add(id);
                },
              );
            },
          ),
          child: const Text('Open'),
        );
      })),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    final select =
        tester.widget<ListTile>(_key('move-to-folder-folder-z')).onTap!;
    final cancel =
        tester.widget<OutlinedButton>(_key('move-to-folder-cancel')).onPressed!;
    showDialog<void>(
      context: sheetContext,
      builder: (_) => const AlertDialog(content: Text('Covered')),
    );
    await tester.pumpAndSettle();
    select();
    cancel();
    await tester.pump();
    expect(find.text('Covered'), findsOneWidget);
    expect(chosen, isEmpty);
    expect(pops.count, 0);
    Navigator.pop(tester.element(find.text('Covered')));
    await tester.pumpAndSettle();
    // The shared AppSheet close control bypasses the leaf's cancel callback.
    // The captured row must also be safe during this exit animation.
    Navigator.pop(sheetContext);
    select();
    cancel();
    await tester.pumpAndSettle();
    expect(chosen, isEmpty);
    expect(pops.count, 2);
    expect(find.text('Open'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final locale in S.delegate.supportedLocales) {
    testWidgets('clear action and no-match feedback are localized in $locale',
        (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(_host(
            MoveToFolderSheet(folders: _folders, onSelected: (_) {}),
            locale: locale));
        await tester.pumpAndSettle();
        await tester.enterText(_key('move-to-folder-search'), 'missing');
        await tester.pump();
        final clear = _key('move-to-folder-clear-search');
        expect(
            tester.widget<IconButton>(clear).tooltip, S.current.Clear_Search);
        expect(tester.getSize(clear).shortestSide, greaterThanOrEqualTo(48));
        expect(find.text(S.current.Folder_Search_Empty), findsOneWidget);
        expect(find.text(S.current.Search_Folders), findsOneWidget);
        await tester.testTextInput.receiveAction(TextInputAction.search);
        await tester.pumpAndSettle();
        expect(tester.testTextInput.isVisible, isFalse);
        expect(
            tester
                .widget<TextField>(_key('move-to-folder-search'))
                .controller!
                .text,
            'missing');
      } finally {
        semantics.dispose();
      }
    });
  }

  for (final preview in <(String, Size, Widget Function())>[
    ('light', const Size(390, 700), folderNameSearchLightPreview),
    ('dark', const Size(390, 700), folderNameSearchDarkPreview),
    ('chinese-narrow-2x', const Size(180, 700), folderNameSearchChinesePreview),
    (
      'hong-kong-chinese-keyboard',
      const Size(568, 320),
      folderNameSearchKeyboardPreview
    ),
  ]) {
    testWidgets('${preview.$1} folder preview searches without native APIs',
        (tester) async {
      tester.view.physicalSize = preview.$2;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(RepaintBoundary(
        key: const ValueKey('folder-name-search-capture'),
        child: preview.$3(),
      ));
      await tester.pumpAndSettle();
      await tester.enterText(_key('move-to-folder-search'), 'C++');
      await tester.pumpAndSettle();
      expect(_key('move-to-folder-folder-literal'), findsOneWidget);
      expect(_key('move-to-folder-folder-work'), findsNothing);
      expect(_key('move-to-folder-none'), findsOneWidget);
      expect(_key('move-to-folder-cancel'), findsOneWidget);
      await _capture(tester, preview.$1);
      await tester.ensureVisible(_key('move-to-folder-clear-search'));
      await tester.tap(_key('move-to-folder-clear-search'));
      await tester.pumpAndSettle();
      expect(_key('move-to-folder-folder-work'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
