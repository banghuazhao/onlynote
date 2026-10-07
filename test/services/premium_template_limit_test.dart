import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/domain/model/custom_note_template.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/services/custom_note_template_store.dart';
import 'package:onlynote/services/premium_access.dart';

import '../support/memory_preferences.dart';
import '../support/premium_test_fakes.dart';
import '../support/template_images.dart';

class _Images extends MemoryTemplateImages {
  int templateCopyCalls = 0;

  @override
  Future<List<String>> copyToTemplate(List<String> sources) {
    templateCopyCalls++;
    return super.copyToTemplate(sources);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late PremiumTestFixture entitlement;
  late MemoryPreferences preferences;
  late _Images images;
  late CustomNoteTemplateStore store;

  Future<void> createStore({bool premium = false}) async {
    entitlement = PremiumTestFixture(premium: premium);
    await entitlement.init();
    preferences = MemoryPreferences();
    images = _Images();
    store = CustomNoteTemplateStore(
        preferences: preferences,
        images: images,
        premiumAccess: entitlement.access);
  }

  tearDown(() async {
    store.dispose();
    await entitlement.dispose();
  });

  test('free saves three templates then blocks before any media copy',
      () async {
    await createStore();
    for (var i = 0; i < PremiumAccess.freeTemplateLimit; i++) {
      await store.saveFromNote(Note(title: 'Note $i'), name: 'Template $i');
    }
    final saved = preferences.values[CustomNoteTemplateStore.storageKey];
    final copies = images.templateCopyCalls;
    await expectLater(
        store.saveFromNote(Note(imagePaths: ['note_images/new.jpg']),
            name: 'Fourth'),
        throwsA(isA<PremiumRequired>().having(
            (error) => error.feature, 'feature', PremiumFeature.templates)));
    expect(store.templates, hasLength(PremiumAccess.freeTemplateLimit));
    expect(preferences.values[CustomNoteTemplateStore.storageKey], saved);
    expect(images.templateCopyCalls, copies);
  });

  test('Premium can save more templates than the free limit', () async {
    await createStore(premium: true);
    for (var i = 0; i < 8; i++) {
      await store.saveFromNote(Note(title: 'Note $i'), name: 'Template $i');
    }
    expect(store.templates, hasLength(8));
  });

  test('serialized parallel saves cannot exceed the free limit', () async {
    await createStore();
    for (var i = 0; i < PremiumAccess.freeTemplateLimit - 1; i++) {
      await store.saveFromNote(Note(title: 'Note $i'), name: 'Template $i');
    }
    final results = await Future.wait([
      for (final name in ['Third', 'Fourth'])
        store.saveFromNote(Note(title: name), name: name).then<Object>(
            (template) => template,
            onError: (Object error) => error),
    ]);
    expect(results.whereType<CustomNoteTemplate>(), hasLength(1));
    expect(results.whereType<PremiumRequired>(), hasLength(1));
    expect(store.templates, hasLength(3));
    expect(store.templates.last.name, 'Third');
  });

  test('imported and existing templates remain usable above the free limit',
      () async {
    await createStore();
    final imported = [
      for (var i = 0; i < 5; i++)
        CustomNoteTemplate(
            id: 'import-$i',
            name: 'Imported $i',
            title: 'Keep $i',
            body: 'Existing content $i',
            createdAt: DateTime(2026)),
    ];
    await store.importTemplates(imported);
    final restarted = CustomNoteTemplateStore(
        preferences: preferences,
        images: images,
        premiumAccess: entitlement.access);
    addTearDown(restarted.dispose);
    await restarted.load();
    expect(restarted.templates.map((template) => template.id),
        imported.map((template) => template.id));
    await restarted.rename('import-0', 'Renamed');
    final note = await restarted.createNote('import-0');
    expect(note.title, 'Keep 0');
    expect(note.description, 'Existing content 0');
    await expectLater(restarted.saveFromNote(Note(title: 'New'), name: 'New'),
        throwsA(isA<PremiumRequired>()));
    await restarted.delete('import-4');
    expect(restarted.templates, hasLength(4));
    expect(restarted.templates.first.name, 'Renamed');
    expect(restarted.templates.first.body, 'Existing content 0');
  });

  test('an upgraded user can retry with the same live template store',
      () async {
    await createStore();
    for (var i = 0; i < 3; i++) {
      await store.saveFromNote(Note(title: 'Note $i'), name: 'Template $i');
    }
    await expectLater(store.saveFromNote(Note(title: 'Fourth'), name: 'Fourth'),
        throwsA(isA<PremiumRequired>()));
    entitlement.store.grant();
    await pumpEventQueue();
    await store.saveFromNote(Note(title: 'Fourth'), name: 'Fourth');
    expect(store.templates, hasLength(4));
  });
}
