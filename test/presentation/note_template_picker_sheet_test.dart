import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:onlynote/domain/model/custom_note_template.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/domain/model/voice_memo.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/note_template_picker_sheet.dart';
import 'package:onlynote/presentation/theme/theme.dart';
import 'package:onlynote/services/note_templates.dart';
import 'package:onlynote/services/custom_note_template_store.dart';

import '../support/memory_preferences.dart';
import '../support/template_images.dart';

class _WriteCheckedPreferences extends MemoryPreferences {
  _WriteCheckedPreferences(this.beforeWrite);
  final void Function() beforeWrite;

  @override
  Future<void> setString(String key, String value) async {
    beforeWrite();
    await super.setString(key, value);
  }
}

class _SearchPreferenceControls {
  Future<void>? readGate;
  Future<void>? writeGate;
  int reads = 0;
  int writes = 0;
}

class _SearchPreferences extends MemoryPreferences {
  final _controls = _SearchPreferenceControls();
  set readGate(Future<void>? gate) => _controls.readGate = gate;
  set writeGate(Future<void>? gate) => _controls.writeGate = gate;
  int get reads => _controls.reads;
  int get writes => _controls.writes;

  @override
  Future<String?> getString(String key) async {
    _controls.reads++;
    await _controls.readGate;
    return super.getString(key);
  }

  @override
  Future<void> setString(String key, String value) async {
    await _controls.writeGate;
    _controls.writes++;
    await super.setString(key, value);
  }
}

CustomNoteTemplate _searchTemplate(String id, String name) =>
    CustomNoteTemplate(
      id: id,
      name: name,
      title: 'Private content label',
      body: 'Private content body',
      items: const ['Private content task'],
      imagePaths: const ['template_images/unavailable.jpg'],
      voiceMemos: [
        VoiceMemo(
          id: 'memo',
          path: 'template_audio/unavailable.m4a',
          durationMs: 1000,
          createdAt: DateTime.utc(2026, 10, 13),
          transcript: 'Private content transcript',
        ),
      ],
      createdAt: DateTime.utc(2026, 10, 13),
    );

CustomNoteTemplateStore _searchStore(
    _SearchPreferences preferences, List<CustomNoteTemplate> templates) {
  preferences.values[CustomNoteTemplateStore.storageKey] = jsonEncode({
    'version': 1,
    'templates': [for (final template in templates) template.toJson()],
  });
  return CustomNoteTemplateStore(
      preferences: preferences, images: MemoryTemplateImages());
}

Finder get _search => find.byKey(const ValueKey('template-name-search'));
Finder get _clearSearch =>
    find.byKey(const ValueKey('template-name-clear-search'));
Finder get _searchEmpty =>
    find.byKey(const ValueKey('template-name-search-empty'));

Future<void> _query(WidgetTester tester, String value,
    {bool settle = true}) async {
  await tester.ensureVisible(_search);
  await tester.enterText(_search, value);
  await tester.testTextInput.receiveAction(TextInputAction.search);
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
}

Future<void> _openPicker(
  WidgetTester tester,
  List<NoteTemplateSelection?> results, {
  CustomNoteTemplateStore? store,
  Locale locale = const Locale('en'),
  Size size = const Size(390, 844),
  double textScale = 1,
  bool disableAnimations = true,
  bool settleLoading = true,
}) async {
  final templates = store ??
      CustomNoteTemplateStore(
          preferences: MemoryPreferences(), images: MemoryTemplateImages());
  addTearDown(templates.dispose);
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(MaterialApp(
    locale: locale,
    supportedLocales: S.delegate.supportedLocales,
    localizationsDelegates: const [
      S.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    theme: AppTheme.light,
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
            results.add(
                await showNoteTemplatePickerSheet(context, store: templates));
          },
          child: const Text('Open templates'),
        ),
      ),
    ),
  ));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Open templates'));
  if (settleLoading) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
}

void main() {
  setUpAll(() => initializeDateFormatting());

  testWidgets(
      'custom snippet retains counts, selection identity and stored content',
      (tester) async {
    final preferences = _SearchPreferences();
    final store = _searchStore(preferences, [
      _searchTemplate('chosen', 'Weekly planning'),
      CustomNoteTemplate(
        id: 'blank',
        name: 'Blank content',
        body: ' \t\n',
        items: const ['\u3000'],
        createdAt: DateTime.utc(2026, 10, 20),
      ),
    ]);
    final saved = preferences.values[CustomNoteTemplateStore.storageKey];
    final results = <NoteTemplateSelection?>[];
    await _openPicker(tester, results,
        store: store, size: const Size(280, 700), textScale: 2);
    expect(find.text('Private content body'), findsOneWidget);
    expect(find.text(S.current.Template_Details(1, 1)), findsOneWidget);
    expect(find.text(S.current.Template_Details(1, 0)), findsOneWidget);
    expect(find.byKey(const ValueKey('template-content-snippet-blank')),
        findsNothing);
    final chosen = store.templates.first;
    final tile = find.byKey(const ValueKey('custom-template-chosen'));
    await tester.ensureVisible(tile);
    await tester.pumpAndSettle();
    expect(tile.hitTestable(), findsOneWidget);
    await tester.tap(tile);
    await tester.pumpAndSettle();
    expect(results.single!.custom, same(chosen));
    expect(results.single!.custom!.body, 'Private content body');
    expect(results.single!.custom!.voiceMemos.single.path,
        'template_audio/unavailable.m4a');
    expect(preferences.writes, 0);
    expect(preferences.values[CustomNoteTemplateStore.storageKey], saved);
    expect(tester.takeException(), isNull);
  });

  testWidgets('name search is literal, ordered and never searches note content',
      (tester) async {
    final preferences = _SearchPreferences();
    final store = _searchStore(preferences, [
      _searchTemplate('z-work', 'Work routine'),
      _searchTemplate('a-work', 'WORK projects'),
      _searchTemplate('literal', 'C++ [2026]'),
      _searchTemplate('cjk', '閱讀與研究茶😀'),
    ]);
    final saved = preferences.values[CustomNoteTemplateStore.storageKey];
    final results = <NoteTemplateSelection?>[];
    await _openPicker(tester, results, store: store);
    final originals = store.templates;
    final reads = preferences.reads;
    for (final (query, ids) in [
      ('  wOrK  ', ['z-work', 'a-work']),
      ('C++', ['literal']),
      ('[2026]', ['literal']),
      ('研究茶😀', ['cjk']),
      ('.*', <String>[]),
      ('Private content', <String>[]),
    ]) {
      await _query(tester, query);
      final displayed = tester
          .widgetList<ListTile>(find.byType(ListTile))
          .map((tile) => tile.key)
          .whereType<ValueKey<String>>()
          .where((key) => key.value.startsWith('custom-template-'))
          .map((key) => key.value.replaceFirst('custom-template-', ''));
      expect(displayed, ids);
      expect(_searchEmpty, ids.isEmpty ? findsOneWidget : findsNothing);
      expect(find.text(S.current.My_Templates), findsOneWidget);
      expect(find.text(S.current.Starter_Templates), findsOneWidget);
      expect(preferences.writes, 0);
      expect(preferences.reads, reads);
      expect(preferences.values[CustomNoteTemplateStore.storageKey], saved);
      expect(store.templates, originals);
      expect(results, isEmpty);
    }
    await tester.tap(_clearSearch);
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(_search).controller!.text, isEmpty);
    expect(_searchEmpty, findsNothing);
    for (final template in originals) {
      expect(find.byKey(ValueKey('custom-template-${template.id}')),
          findsOneWidget);
    }
    expect(find.byKey(const ValueKey('template-shopping')), findsOneWidget);
    await _query(tester, '\u3000');
    expect(_searchEmpty, findsNothing);
    expect(find.byKey(const ValueKey('template-meeting')), findsOneWidget);
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(results, [null]);
    expect(preferences.writes, 0);
    expect(preferences.values[CustomNoteTemplateStore.storageKey], saved);
    expect(tester.takeException(), isNull);
  });

  for (final locale in S.delegate.supportedLocales) {
    testWidgets('starter search uses its displayed localized title in $locale',
        (tester) async {
      final preferences = _SearchPreferences();
      final store = _searchStore(preferences, []);
      final results = <NoteTemplateSelection?>[];
      await _openPicker(tester, results, store: store, locale: locale);
      await _query(
          tester, ' ${S.current.Template_Meeting_Title.toUpperCase()} ');
      expect(find.byKey(const ValueKey('template-shopping')), findsNothing);
      expect(find.byKey(const ValueKey('template-packing')), findsNothing);
      expect(find.byKey(const ValueKey('template-dailyPlan')), findsNothing);
      expect(_searchEmpty, findsNothing);
      expect(find.text(S.current.Search_Templates), findsOneWidget);
      final meeting = find.byKey(const ValueKey('template-meeting'));
      await tester.ensureVisible(meeting);
      await tester.tap(meeting);
      await tester.pumpAndSettle();
      expect(results.single!.builtIn, NoteTemplate.meeting);
      expect(preferences.writes, 0);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
      'filtered custom selection keeps its identity and guards stale taps',
      (tester) async {
    final preferences = _SearchPreferences();
    final store = _searchStore(preferences, [
      _searchTemplate('other', 'Work routine'),
      _searchTemplate('chosen', 'C++ [2026]'),
    ]);
    final saved = preferences.values[CustomNoteTemplateStore.storageKey];
    final results = <NoteTemplateSelection?>[];
    await _openPicker(tester, results, store: store, disableAnimations: false);
    await _query(tester, 'C++');
    final chosen = store.templates.last;
    final callback = tester
        .widget<ListTile>(find.byKey(const ValueKey('custom-template-chosen')))
        .onTap!;
    callback();
    callback();
    await tester.pumpAndSettle();
    callback();
    expect(results, hasLength(1));
    expect(results.single!.custom, same(chosen));
    expect(results.single!.custom!.id, 'chosen');
    expect(results.single!.custom!.body, 'Private content body');
    expect(find.text('Open templates'), findsOneWidget);
    expect(preferences.writes, 0);
    expect(preferences.values[CustomNoteTemplateStore.storageKey], saved);
    expect(tester.takeException(), isNull);
  });

  testWidgets('cancelled filtered picker rejects captured selection and manage',
      (tester) async {
    final preferences = _SearchPreferences();
    final store = _searchStore(preferences, [_searchTemplate('chosen', 'C++')]);
    final results = <NoteTemplateSelection?>[];
    await _openPicker(tester, results, store: store, disableAnimations: false);
    await _query(tester, 'C++');
    final select = tester
        .widget<ListTile>(find.byKey(const ValueKey('custom-template-chosen')))
        .onTap!;
    final manage = tester
        .widget<IconButton>(
            find.byKey(const ValueKey('manage-template-chosen')))
        .onPressed!;
    await tester.tap(find.byTooltip('Close'));
    select();
    manage();
    await tester.pumpAndSettle();
    select();
    manage();
    expect(results, [null]);
    expect(find.text('Open templates'), findsOneWidget);
    expect(find.text(S.current.Rename_Template), findsNothing);
    expect(preferences.writes, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('search keeps pending-load feedback until stored names arrive',
      (tester) async {
    final gate = Completer<void>();
    final preferences = _SearchPreferences()..readGate = gate.future;
    final store = _searchStore(preferences, [_searchTemplate('new', 'Later')]);
    final results = <NoteTemplateSelection?>[];
    await _openPicker(tester, results, store: store, settleLoading: false);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    await _query(tester, 'missing', settle: false);
    expect(_searchEmpty, findsNothing);
    expect(results, isEmpty);
    gate.complete();
    await tester.pumpAndSettle();
    expect(_searchEmpty, findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);
    await _query(tester, 'Later');
    expect(find.byKey(const ValueKey('custom-template-new')), findsOneWidget);
    expect(_searchEmpty, findsNothing);
    expect(preferences.writes, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'search retains loading errors and retry refreshes the same query',
      (tester) async {
    final preferences = _SearchPreferences();
    final store =
        _searchStore(preferences, [_searchTemplate('fixed', 'Fixed')]);
    final stored = preferences.values[CustomNoteTemplateStore.storageKey];
    preferences.values[CustomNoteTemplateStore.storageKey] = 'not-json';
    await _openPicker(tester, [], store: store);
    await _query(tester, 'Fixed');
    expect(find.text(S.current.Template_Load_Failed), findsOneWidget);
    expect(_searchEmpty, findsNothing);
    expect(find.text(S.current.Retry), findsOneWidget);
    preferences.values[CustomNoteTemplateStore.storageKey] = stored!;
    await tester.ensureVisible(find.text(S.current.Retry));
    await tester.tap(find.text(S.current.Retry));
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(_search).controller!.text, 'Fixed');
    expect(find.byKey(const ValueKey('custom-template-fixed')), findsOneWidget);
    expect(find.text(S.current.Template_Load_Failed), findsNothing);
    expect(_searchEmpty, findsNothing);
    expect(preferences.writes, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('live store updates refresh matches without resetting search',
      (tester) async {
    final preferences = _SearchPreferences();
    final store = _searchStore(preferences, [
      _searchTemplate('first', 'Work routine'),
      _searchTemplate('second', 'Travel'),
    ]);
    final results = <NoteTemplateSelection?>[];
    await _openPicker(tester, results, store: store);
    await _query(tester, 'Work');
    expect(find.byKey(const ValueKey('custom-template-first')), findsOneWidget);
    expect(find.byKey(const ValueKey('custom-template-second')), findsNothing);
    expect(preferences.writes, 0);
    await store.rename('second', 'Work trip');
    await tester.pumpAndSettle();
    expect(
        find.byKey(const ValueKey('custom-template-second')), findsOneWidget);
    expect(tester.widget<TextField>(_search).controller!.text, 'Work');
    await store.rename('first', 'Other routine');
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('custom-template-first')), findsNothing);
    expect(
        find.byKey(const ValueKey('custom-template-second')), findsOneWidget);
    await store.rename('second', 'Trip');
    await tester.pumpAndSettle();
    expect(_searchEmpty, findsOneWidget);
    expect(tester.widget<TextField>(_search).controller!.text, 'Work');
    expect(results, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('filtered rename uses original ID and busy guards remain active',
      (tester) async {
    final preferences = _SearchPreferences();
    final store = _searchStore(preferences, [
      _searchTemplate('first', 'Work routine'),
      _searchTemplate('chosen', 'Work target'),
    ]);
    final results = <NoteTemplateSelection?>[];
    await _openPicker(tester, results, store: store);
    await _query(tester, 'Work');
    final capturedSelect = tester
        .widget<ListTile>(find.byKey(const ValueKey('custom-template-first')))
        .onTap!;
    final capturedManage = tester
        .widget<IconButton>(find.byKey(const ValueKey('manage-template-first')))
        .onPressed!;
    final manage = find.byKey(const ValueKey('manage-template-chosen'));
    await tester.ensureVisible(manage);
    await tester.tap(manage);
    await tester.pumpAndSettle();
    await tester.tap(find.text(S.current.Rename_Template));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const ValueKey('template-name')), 'Work renamed');
    final gate = Completer<void>();
    preferences.writeGate = gate.future;
    try {
      await tester.tap(find.text(S.current.OK));
      await tester.pump();
      // The dialog result precedes its reverse animation. Keep the write
      // pending while finishing that animation without settling the spinner.
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(tester.widget<TextField>(_search).enabled, isFalse);
      expect(tester.widget<IconButton>(_clearSearch).onPressed, isNull);
      expect(
          tester
              .widget<ListTile>(
                  find.byKey(const ValueKey('custom-template-first')))
              .onTap,
          isNull);
      capturedSelect();
      capturedManage();
      await tester.pump();
      expect(results, isEmpty);
      expect(find.byType(NoteTemplatePickerSheet), findsOneWidget);
      expect(find.text(S.current.Rename_Template), findsNothing);
      expect(preferences.writes, 0);
      gate.complete();
      await tester.pumpAndSettle();
      expect(
          store.templates.map((template) => template.id), ['first', 'chosen']);
      expect(store.templates.first.name, 'Work routine');
      expect(store.templates.last.name, 'Work renamed');
      expect(store.templates.last.body, 'Private content body');
      expect(preferences.writes, 1);
      expect(tester.widget<TextField>(_search).enabled, isTrue);
      expect(tester.widget<TextField>(_search).controller!.text, 'Work');
      expect(results, isEmpty);
      expect(tester.takeException(), isNull);
    } finally {
      if (!gate.isCompleted) gate.complete();
      await tester.pumpAndSettle();
    }
  });

  testWidgets(
      'filtered delete cancellation and confirmation keep the correct ID',
      (tester) async {
    final preferences = _SearchPreferences();
    final store = _searchStore(preferences, [
      CustomNoteTemplate(
          id: 'keep', name: 'Work routine', createdAt: DateTime.utc(2026)),
      CustomNoteTemplate(
          id: 'delete', name: 'C++ [2026]', createdAt: DateTime.utc(2026)),
    ]);
    final results = <NoteTemplateSelection?>[];
    await _openPicker(tester, results, store: store);
    await _query(tester, '[2026]');
    Future<void> requestDelete() async {
      final manage = find.byKey(const ValueKey('manage-template-delete'));
      await tester.ensureVisible(manage);
      await tester.tap(manage);
      await tester.pumpAndSettle();
      await tester.tap(find.text(S.current.Delete_Template));
      await tester.pumpAndSettle();
    }

    await requestDelete();
    await tester.tap(find.text(S.current.Cancel));
    await tester.pumpAndSettle();
    expect(store.templates.map((template) => template.id), ['keep', 'delete']);
    expect(preferences.writes, 0);
    await requestDelete();
    await tester.tap(find.text(S.current.Delete));
    await tester.pumpAndSettle();
    expect(store.templates.single.id, 'keep');
    expect(store.templates.single.name, 'Work routine');
    expect(tester.widget<TextField>(_search).controller!.text, '[2026]');
    expect(_searchEmpty, findsOneWidget);
    expect(preferences.writes, 1);
    expect(results, isEmpty);
    expect(tester.takeException(), isNull);
  });
  testWidgets('selection returns only after the picker overlay is removed',
      (tester) async {
    final results = <NoteTemplateSelection?>[];
    await _openPicker(tester, results, disableAnimations: false);
    await tester.tap(find.byKey(const ValueKey('template-packing')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 30));
    expect(results, isEmpty);
    expect(find.byType(NoteTemplatePickerSheet), findsOneWidget);
    await tester.pumpAndSettle();
    expect(results.single!.builtIn, NoteTemplate.packing);
    expect(find.byType(NoteTemplatePickerSheet), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('repeated template selections cannot pop the underlying page',
      (tester) async {
    final results = <NoteTemplateSelection?>[];
    await _openPicker(tester, results, disableAnimations: false);
    final select = tester
        .widget<ListTile>(find.byKey(const ValueKey('template-packing')))
        .onTap!;
    select();
    select();
    await tester.pumpAndSettle();
    expect(results, hasLength(1));
    expect(results.single!.builtIn, NoteTemplate.packing);
    expect(find.text('Open templates'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('picker previews each template and returns the chosen type',
      (tester) async {
    final results = <NoteTemplateSelection?>[];
    await _openPicker(tester, results);
    expect(find.text('Shopping list'), findsOneWidget);
    expect(find.text('Packing list'), findsOneWidget);
    expect(find.text('Daily plan'), findsOneWidget);
    expect(find.text('Meeting notes'), findsOneWidget);
    expect(find.text('An outline for the agenda, decisions, and follow-up.'),
        findsOneWidget);
    expect(results, isEmpty);

    final meeting = find.byKey(const ValueKey('template-meeting'));
    await tester.ensureVisible(meeting);
    await tester.tap(meeting);
    await tester.pumpAndSettle();

    expect(results.single!.builtIn, NoteTemplate.meeting);
    expect(find.byType(NoteTemplatePickerSheet), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('closing template discovery leaves the choice empty',
      (tester) async {
    final results = <NoteTemplateSelection?>[];
    await _openPicker(tester, results);
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();
    expect(results, [null]);
    expect(find.byType(NoteTemplatePickerSheet), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('narrow layout with large Chinese text remains selectable',
      (tester) async {
    final results = <NoteTemplateSelection?>[];
    await _openPicker(
      tester,
      results,
      locale: const Locale('zh', 'HK'),
      size: const Size(320, 640),
      textScale: 2,
    );
    expect(find.text('範本'), findsOneWidget);
    expect(find.text('購物清單'), findsOneWidget);
    expect(tester.takeException(), isNull);
    final meeting = find.byKey(const ValueKey('template-meeting'));
    await tester.ensureVisible(meeting);
    await tester.tap(meeting);
    await tester.pumpAndSettle();
    expect(results.single!.builtIn, NoteTemplate.meeting);
    expect(tester.takeException(), isNull);
  });

  testWidgets('custom template selection retains independent name and content',
      (tester) async {
    final store = CustomNoteTemplateStore(
        preferences: MemoryPreferences(), images: MemoryTemplateImages());
    final template = await store.saveFromNote(
      Note(title: 'Trip', todo: [Todo(title: 'Passport', completed: true)]),
      name: 'Packing routine',
    );
    final results = <NoteTemplateSelection?>[];
    await _openPicker(tester, results, store: store);
    expect(find.text('My templates'), findsOneWidget);
    expect(find.text('Starter templates'), findsOneWidget);
    expect(find.text('Packing routine'), findsOneWidget);
    await tester.tap(find.byKey(ValueKey('custom-template-${template.id}')));
    await tester.pumpAndSettle();
    expect(results.single!.custom!.id, template.id);
    expect(results.single!.custom!.title, 'Trip');
    expect(results.single!.builtIn, isNull);
  });

  testWidgets(
      'rename and confirmed delete manage templates without changing content',
      (tester) async {
    final store = CustomNoteTemplateStore(
        preferences: MemoryPreferences(), images: MemoryTemplateImages());
    final template =
        await store.saveFromNote(Note(title: 'Trip'), name: 'Packing routine');
    final results = <NoteTemplateSelection?>[];
    await _openPicker(tester, results, store: store);
    Future<void> manage(String action) async {
      await tester.tap(find.byKey(ValueKey('manage-template-${template.id}')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(action));
      await tester.pumpAndSettle();
    }

    await manage('Rename template');
    await tester.enterText(
        find.byKey(const ValueKey('template-name')), 'Holiday packing');
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(store.templates.single.name, 'Holiday packing');
    expect(store.templates.single.title, 'Trip');
    expect(find.text('Holiday packing'), findsOneWidget);

    await manage('Delete template');
    expect(find.text('Delete template?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(store.templates, hasLength(1));
    await manage('Delete template');
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(store.templates, isEmpty);
    expect(find.text('Holiday packing'), findsNothing);
    expect(find.text('Save any note as a template from its menu.'),
        findsOneWidget);
    expect(results, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'unreadable custom storage surfaces an error while starter templates work',
      (tester) async {
    final preferences = MemoryPreferences();
    preferences.values[CustomNoteTemplateStore.storageKey] = 'not-json';
    final store = CustomNoteTemplateStore(
        preferences: preferences, images: MemoryTemplateImages());
    final results = <NoteTemplateSelection?>[];
    await _openPicker(tester, results, store: store);
    expect(find.text("Couldn't load your templates. Please try again."),
        findsOneWidget);
    final shopping = find.byKey(const ValueKey('template-shopping'));
    await tester.ensureVisible(shopping);
    await tester.tap(shopping);
    await tester.pumpAndSettle();
    expect(results.single!.builtIn, NoteTemplate.shopping);
    expect(preferences.values[CustomNoteTemplateStore.storageKey], 'not-json');
    expect(tester.takeException(), isNull);
  });

  testWidgets('failed template delete stays visible with an inline error',
      (tester) async {
    var failWrites = false;
    final preferences = _WriteCheckedPreferences(() {
      if (failWrites) throw StateError('Storage unavailable');
    });
    final store = CustomNoteTemplateStore(
        preferences: preferences, images: MemoryTemplateImages());
    final template =
        await store.saveFromNote(Note(title: 'Trip'), name: 'Packing routine');
    final saved = preferences.values[CustomNoteTemplateStore.storageKey];
    failWrites = true;
    await _openPicker(tester, [], store: store);
    await tester.tap(find.byKey(ValueKey('manage-template-${template.id}')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete template'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(store.templates.single.id, template.id);
    expect(find.text('Packing routine'), findsOneWidget);
    expect(find.text(S.current.Template_Change_Failed), findsOneWidget);
    expect(preferences.values[CustomNoteTemplateStore.storageKey], saved);
    expect(tester.takeException(), isNull);
  });
}
