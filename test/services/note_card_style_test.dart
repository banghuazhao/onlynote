import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:onlynote/Tools/app_appearance_settings.dart';
import 'package:onlynote/Tools/app_card_style_settings.dart';
import 'package:onlynote/Tools/app_layout_settings.dart';
import 'package:onlynote/Tools/app_typography_settings.dart';
import 'package:onlynote/data/dto/note_dto.dart';
import 'package:onlynote/domain/model/custom_note_template.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/domain/model/note_card_style.dart';
import 'package:onlynote/domain/model/note_theme.dart';
import 'package:onlynote/domain/repository/note_repository.dart';
import 'package:onlynote/services/backup/backup_contents.dart';
import 'package:onlynote/services/note_autosave.dart';
import 'package:onlynote/services/note_history.dart';
import 'package:shared_preferences/shared_preferences.dart';
// The preference plugin exposes its test platform in a separate package.
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

class _StylePreferences extends InMemorySharedPreferencesStore {
  _StylePreferences(super.data) : super.withData();
  String? failNextKey;
  String? blockNextKey;
  Completer<void>? gate;

  @override
  Future<bool> setValue(String valueType, String key, Object value) async {
    if (key == blockNextKey) {
      blockNextKey = null;
      await gate?.future;
    }
    if (key == failNextKey) {
      failNextKey = null;
      throw StateError('Storage unavailable');
    }
    return super.setValue(valueType, key, value);
  }
}

class _CardStyleNotes implements NoteRepository {
  _CardStyleNotes(this.box);
  final Box box;
  NoteHistory? history;

  @override
  List<NoteDto> getAllNotes() => box.values.cast<NoteDto>().toList();
  @override
  Future<NoteDto> getNote(String id) async => box.get(id) as NoteDto;
  @override
  Future<void> addUpdateNote(NoteDto note) async {
    final previous = box.get(note.id);
    if (previous is NoteDto) await history?.recordBeforeSave(previous, note);
    await box.put(note.id, note);
  }

  @override
  Future<void> deleteNote(String id) => box.delete(id);
  @override
  Future<void> deleteMultiNotes(List<String> ids) => box.deleteAll(ids);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const style = NoteCardStyle(
    fontFamily: 'Kalam',
    fontSize: AppFontSize.large,
    cardSize: NoteCardSize.large,
    paperStyle: NoteCardPaperStyle.plain,
    showDate: false,
    noteTheme: NoteTheme.gridPaper,
  );
  late Directory directory;
  late Box notes;
  late Box drafts;
  late Box histories;
  late _CardStyleNotes repository;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('onlynote-card-style-');
    Hive.init(directory.path);
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(TodoDtoAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(NoteDtoAdapter());
    notes = await Hive.openBox('card_style_notes');
    drafts = await Hive.openBox('card_style_drafts');
    histories = await Hive.openBox('card_style_history');
    repository = _CardStyleNotes(notes);
  });

  tearDown(() async {
    await histories.close();
    await drafts.close();
    await notes.close();
    await directory.delete(recursive: true);
  });

  test('partial appearance maps retain inheritance and can reset fields', () {
    const partial = NoteCardStyle(fontFamily: 'Kalam', showDate: false);
    expect(NoteCardStyle.fromMap(partial.toMap()), partial);
    expect(partial.copyWith(clearFontFamily: true).fontFamily, isNull);
    expect(partial.copyWith(clearShowDate: true).showDate, isNull);
    expect(const NoteCardStyle().isDefault, isTrue);
    expect(NoteCardStyle.fromMap(null).isDefault, isTrue);
    expect(
        NoteCardStyle.fromMap({
          'fontSize': 'huge',
          'cardSize': -1,
          'paperStyle': 'unknown',
          'showDate': 'false',
          'fontFamily': '',
          'noteTheme': 'unknown',
        }).isDefault,
        isTrue);
    final note = Note(id: 'custom', title: 'Keep', cardStyle: partial);
    expect(note.copyWith(title: 'Changed').cardStyle, partial);
    expect(note.copyWith(cardStyle: const NoteCardStyle()).cardStyle.isDefault,
        isTrue);
  });

  test('every note theme roundtrips by name and participates in style identity',
      () {
    final distinct = <NoteCardStyle>{};
    for (final theme in NoteTheme.values) {
      final themed = style.copyWith(noteTheme: theme);
      final serialized = themed.toMap();
      expect(serialized['noteTheme'], theme.name);
      final reopened = NoteCardStyle.fromMap(serialized);
      expect(reopened, themed);
      expect(reopened.hashCode, themed.hashCode);
      expect(themed.copyWith(showDate: true).noteTheme, theme);
      distinct.add(themed);
    }
    expect(distinct.length, NoteTheme.values.length);
    const inherited = NoteCardStyle();
    const explicitClassic = NoteCardStyle(noteTheme: NoteTheme.classic);
    expect(inherited.isDefault, isTrue);
    expect(explicitClassic.isDefault, isFalse);
    expect(explicitClassic, isNot(inherited));
    expect(explicitClassic.copyWith(clearNoteTheme: true), inherited);
    final cleared =
        style.copyWith(noteTheme: NoteTheme.parchment, clearNoteTheme: true);
    expect(cleared.noteTheme, isNull);
    expect(cleared.toMap().containsKey('noteTheme'), isFalse);
    expect(
        cleared,
        const NoteCardStyle(
          fontFamily: 'Kalam',
          fontSize: AppFontSize.large,
          cardSize: NoteCardSize.large,
          paperStyle: NoteCardPaperStyle.plain,
          showDate: false,
        ));
  });

  test('missing and malformed themes inherit without discarding other choices',
      () {
    final legacy = style.copyWith(clearNoteTheme: true);
    expect(NoteCardStyle.fromMap(legacy.toMap()), legacy);
    for (final value in <Object?>[
      null,
      'future-theme',
      'GridPaper',
      0,
      false,
      <String>['gridPaper'],
      <String, String>{'name': 'gridPaper'},
    ]) {
      final decoded = NoteCardStyle.fromMap({
        ...legacy.toMap(),
        'noteTheme': value,
      });
      expect(decoded.noteTheme, isNull);
      expect(decoded, legacy);
      expect(decoded.hashCode, legacy.hashCode);
      expect(decoded.toMap().containsKey('noteTheme'), isFalse);
    }
  });

  test('Hive reopen and library copies preserve style and legacy defaults',
      () async {
    final note = Note(id: 'custom', title: 'Keep', cardStyle: style);
    await notes.put('custom', NoteDto.fromNote(note));
    await notes.put('legacy', NoteDto(id: 'legacy', title: 'Older note'));
    final legacyAppearance = style.copyWith(clearNoteTheme: true);
    await notes.put(
        'legacy-appearance',
        NoteDto(
          id: 'legacy-appearance',
          title: 'Older styled note',
          cardStyle: legacyAppearance.toMap(),
        ));
    await notes.flush();
    await notes.close();
    notes = await Hive.openBox('card_style_notes');
    final saved = notes.get('custom') as NoteDto;
    expect(saved.toDomain().cardStyle, style);
    expect(
        saved.copyWith(isPinned: true, folderId: 'folder').toDomain().cardStyle,
        style);
    expect(saved.copyWith(clearCardStyle: true).toDomain().cardStyle.isDefault,
        isTrue);
    expect((notes.get('legacy') as NoteDto).toDomain().cardStyle.isDefault,
        isTrue);
    expect((notes.get('legacy-appearance') as NoteDto).toDomain().cardStyle,
        legacyAppearance);
  });

  test('template storage and new copies preserve the chosen appearance', () {
    final template = CustomNoteTemplate.fromNote(
      Note(id: 'source', title: 'Keep', cardStyle: style),
      name: 'My style',
      imageCopies: const [],
    );
    final reopened = CustomNoteTemplate.fromJson(template.toJson());
    expect(reopened.cardStyle, style);
    expect(reopened.copyWith(name: 'Renamed').cardStyle, style);
    final newNote = reopened.createNote(imageCopies: const []);
    expect(newNote.id, isNot('source'));
    expect(newNote.cardStyle, style);
    final legacy = Map<String, dynamic>.from(template.toJson())
      ..remove('cardStyle');
    expect(CustomNoteTemplate.fromJson(legacy).cardStyle.isDefault, isTrue);
  });

  test('portable backup preserves note, history and template card appearance',
      () {
    final note =
        NoteDto.fromNote(Note(id: 'custom', title: 'Keep', cardStyle: style));
    final template = CustomNoteTemplate.fromNote(note.toDomain(),
        name: 'My style', imageCopies: const []);
    final contents = BackupContents(
      createdAt: DateTime.utc(2026, 10, 7),
      notes: [note],
      folders: [],
      photos: {},
      reminders: [],
      templates: [template],
      histories: {
        'custom': [
          NoteHistoryVersion(
              id: 'version', savedAt: DateTime.utc(2026, 10, 7), note: note)
        ]
      },
    );
    final portable = decodeBackup(encodeBackup(contents));
    expect(portable.toJson()['version'], 9);
    expect(portable.notes.single.toDomain().cardStyle, style);
    expect(portable.templates.single.cardStyle, style);
    expect(
        portable.histories['custom']!.single.note.toDomain().cardStyle, style);
    final legacy = contents.toJson()..['version'] = 7;
    final older = BackupContents.fromJson(legacy);
    expect(older.notes.single.toDomain().cardStyle.isDefault, isTrue);
    expect(older.templates.single.cardStyle.isDefault, isTrue);
  });

  for (final latestStyle in [
    style.copyWith(noteTheme: NoteTheme.legalPad),
    const NoteCardStyle(),
  ]) {
    test('restoring note content retains the latest appearance $latestStyle',
        () async {
      final history = NoteHistory(box: histories, repository: repository);
      repository.history = history;
      addTearDown(history.dispose);
      final before = NoteDto.fromNote(
          Note(id: 'custom', title: 'Before', cardStyle: style));
      await repository.addUpdateNote(before);
      await repository.addUpdateNote(before.copyWith(title: 'After'));
      final version = history.versionsFor('custom').single;
      expect(version.note.toDomain().cardStyle, style);
      await repository.addUpdateNote(NoteDto.fromNote(
        (await repository.getNote('custom'))
            .toDomain()
            .copyWith(cardStyle: latestStyle),
      ));
      expect(history.versionsFor('custom').length, 1);
      expect(await history.restore('custom', version.id),
          NoteHistoryRestoreResult.restored);
      final restored = (await repository.getNote('custom')).toDomain();
      expect(restored.title, 'Before');
      expect(restored.cardStyle, latestStyle);
    });
  }

  for (final latestStyle in [style, const NoteCardStyle()]) {
    test('draft recovery retains latest saved appearance $latestStyle',
        () async {
      await notes.put(
          'custom',
          NoteDto.fromNote(
              Note(id: 'custom', title: 'Saved', cardStyle: latestStyle)));
      await drafts.put(
          'custom',
          NoteDto.fromNote(Note(
              id: 'custom',
              title: 'Draft',
              cardStyle: style.copyWith(
                  noteTheme: NoteTheme.sticky, showDate: true))));
      await HiveNoteAutosaveStore(repository, drafts).recover();
      final recovered = (notes.get('custom') as NoteDto).toDomain();
      expect(recovered.title, 'Draft');
      expect(recovered.cardStyle, latestStyle);
      expect(drafts.isEmpty, isTrue);
    });
  }

  test('card defaults migrate existing preferences and save all choices',
      () async {
    SharedPreferences.setMockInitialValues({
      'app_font_family': 'Kalam',
      'app_font_size': 'large',
      'app_note_card_size': 'small',
      'app_plain_paper': true,
    });
    await AppTypographySettings.instance.load();
    await AppLayoutSettings.instance.load();
    await AppAppearanceSettings.instance.load();
    final settings = AppCardStyleSettings();
    addTearDown(settings.dispose);
    await settings.load();
    expect(settings.paperStyle, isNull);
    expect(
        settings.defaults,
        const NoteCardStyle(
            fontFamily: 'Kalam',
            fontSize: AppFontSize.large,
            cardSize: NoteCardSize.small,
            paperStyle: NoteCardPaperStyle.plain,
            showDate: true,
            noteTheme: NoteTheme.classic));
    await settings.saveDefaults(style);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('app_font_family'), 'Kalam');
    expect(prefs.getString('app_note_card_size'), 'large');
    expect(prefs.getBool('app_note_card_show_date'), isFalse);
    expect(settings.defaults, style);
    await settings.saveDefaults(style.copyWith(clearPaperStyle: true));
    expect(settings.paperStyle, isNull);
    expect(prefs.containsKey('app_note_card_paper_style'), isFalse);
    await AppAppearanceSettings.instance.setPlainPaper(false);
    expect(settings.defaults.paperStyle, NoteCardPaperStyle.textured);
    final reopened = AppCardStyleSettings();
    addTearDown(reopened.dispose);
    await reopened.load();
    expect(reopened.paperStyle, isNull);
    expect(reopened.showDate, isFalse);
    expect(reopened.noteTheme, NoteTheme.gridPaper);
    await reopened
        .saveDefaults(const NoteCardStyle(noteTheme: NoteTheme.classic));
    expect(reopened.noteTheme, NoteTheme.classic);
  });

  test(
      'failed default saves roll back preferences without publishing partial choices',
      () async {
    SharedPreferences.setMockInitialValues({
      'app_font_family': 'Roboto',
      'app_font_size': 'medium',
      'app_note_card_size': 'medium',
    });
    await AppTypographySettings.instance.load();
    await AppLayoutSettings.instance.load();
    final settings = AppCardStyleSettings();
    addTearDown(settings.dispose);
    await settings.load();
    final beforeDefaults = settings.defaults;
    final previousPlatform = SharedPreferencesStorePlatform.instance;
    final beforePreferences = await previousPlatform.getAll();
    final platform = _StylePreferences(beforePreferences)
      ..failNextKey = 'flutter.app_note_card_size';
    SharedPreferencesStorePlatform.instance = platform;
    addTearDown(
        () => SharedPreferencesStorePlatform.instance = previousPlatform);
    var notifications = 0;
    settings.addListener(() => notifications++);

    await expectLater(settings.saveDefaults(style), throwsStateError);

    expect(settings.defaults, beforeDefaults);
    expect(notifications, 0);
    expect(await platform.getAll(), beforePreferences);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('app_font_family'), 'Roboto');
    expect(prefs.getString('app_font_size'), 'medium');
    expect(prefs.getString('app_note_card_size'), 'medium');
    await settings.saveDefaults(style);
    expect(settings.defaults, style);
    expect(notifications, 1);
  });

  test(
      'concurrent default saves serialize complete styles and use latest defaults',
      () async {
    SharedPreferences.setMockInitialValues({});
    await AppTypographySettings.instance.load();
    await AppLayoutSettings.instance.load();
    final settings = AppCardStyleSettings();
    addTearDown(settings.dispose);
    await settings.load();
    final before = settings.defaults;
    final previousPlatform = SharedPreferencesStorePlatform.instance;
    final platform = _StylePreferences(await previousPlatform.getAll())
      ..blockNextKey = 'flutter.app_font_family'
      ..gate = Completer<void>();
    SharedPreferencesStorePlatform.instance = platform;
    addTearDown(
        () => SharedPreferencesStorePlatform.instance = previousPlatform);
    var notifications = 0;
    settings.addListener(() => notifications++);
    final first = settings.saveDefaults(style);
    final second = settings.saveDefaults(const NoteCardStyle(
        fontSize: AppFontSize.small, paperStyle: NoteCardPaperStyle.plain));
    await Future<void>.delayed(Duration.zero);
    expect(settings.defaults, before);
    expect(notifications, 0);
    platform.gate!.complete();
    await Future.wait([first, second]);

    expect(settings.defaults, style.copyWith(fontSize: AppFontSize.small));
    expect(notifications, 2);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('app_font_family'), 'Kalam');
    expect(prefs.getString('app_font_size'), 'small');
    expect(prefs.getString('app_note_card_size'), 'large');
    expect(prefs.getBool('app_note_card_show_date'), isFalse);
  });
}
