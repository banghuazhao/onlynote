import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:onlynote/domain/model/note.dart';
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

Future<void> _openPicker(
  WidgetTester tester,
  List<NoteTemplateSelection?> results, {
  CustomNoteTemplateStore? store,
  Locale locale = const Locale('en'),
  Size size = const Size(390, 844),
  double textScale = 1,
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
        disableAnimations: true,
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
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() => initializeDateFormatting());
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
