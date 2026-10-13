import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/Tools/app_appearance_settings.dart';
import 'package:onlynote/Tools/app_card_style_settings.dart';
import 'package:onlynote/Tools/app_layout_settings.dart';
import 'package:onlynote/Tools/app_typography_settings.dart';
import 'package:onlynote/Tools/locator.dart';
import 'package:onlynote/data/dto/folder_dto.dart';
import 'package:onlynote/data/dto/note_dto.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/domain/model/note_card_style.dart';
import 'package:onlynote/domain/model/note_theme.dart';
import 'package:onlynote/domain/repository/folder_repository.dart';
import 'package:onlynote/domain/repository/note_repository.dart';
import 'package:onlynote/domain/usecase/usecase.dart';
import 'package:onlynote/presentation/screens/home/bloc/home_bloc.dart';
import 'package:onlynote/presentation/theme/note_card_typography.dart';
import 'package:onlynote/services/note_theme_access.dart';
import 'package:onlynote/services/premium_access.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:shared_preferences/shared_preferences.dart';
// The preference plugin exposes its test platform in a separate package.
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

import '../support/premium_test_fakes.dart';

class _Preferences extends InMemorySharedPreferencesStore {
  _Preferences(super.data) : super.withData();
  String? failNextKey;
  String? blockNextKey;
  Completer<void>? gate;
  final writes = <String>[];

  @override
  Future<bool> setValue(String valueType, String key, Object value) async {
    writes.add(key);
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

class _Notes implements NoteRepository {
  _Notes(Note note) : value = NoteDto.fromNote(note);
  NoteDto value;
  int writes = 0;
  Completer<void>? gate;

  @override
  List<NoteDto> getAllNotes() => [value];
  @override
  Future<NoteDto> getNote(String id) async {
    if (id != value.id) throw StateError('Missing note');
    return value;
  }

  @override
  Future<void> addUpdateNote(NoteDto note) async {
    writes++;
    await gate?.future;
    value = note;
  }

  @override
  Future<void> deleteNote(String id) async {}
  @override
  Future<void> deleteMultiNotes(List<String> ids) async {}
}

class _Folders implements FolderRepository {
  @override
  List<FolderDto> getAllFolders() => [];
  @override
  Future<void> addUpdateFolder(FolderDto folder) async {}
  @override
  Future<void> deleteFolder(String id) async {}
}

Note _note({NoteCardStyle style = const NoteCardStyle()}) => Note(
      id: 'theme-note',
      title: 'Keep this note',
      description: 'Original content',
      dateTime: DateTime.utc(2026, 10, 1),
      folderId: 'work',
      isArchived: true,
      isPinned: true,
      tags: ['Research'],
      todo: [Todo(id: 'keep-task', title: 'Existing task', completed: true)],
      cardStyle: style,
    );

HomeBloc _home(_Notes notes, PremiumAccess access) {
  final folders = _Folders();
  return HomeBloc(
    ShowAllNotesUsecase(notes, folders),
    AddNoteUsecase(notes),
    ReorderNotesUsecase(notes),
    TogglePinUsecase(notes),
    RestoreNotesUsecase(notes),
    PermanentDeleteNotesUsecase(notes),
    CreateFolderUsecase(folders),
    RenameFolderUsecase(folders),
    DeleteFolderUsecase(folders, notes),
    MoveNoteToFolderUsecase(notes),
    GetNoteUsecase(notes),
    UpdateNoteUsecase(notes),
    premiumAccess: access,
  );
}

Matcher _premium(PremiumFeature feature) => throwsA(isA<PremiumRequired>()
    .having((error) => error.feature, 'feature', feature));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() {
    if (!locator.isRegistered<S>()) locator.registerSingleton(S());
  });
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppTypographySettings.instance.load();
    await AppLayoutSettings.instance.load();
    await AppAppearanceSettings.instance.load();
    await AppCardStyleSettings.instance.load();
  });

  Future<PremiumTestFixture> entitlement({bool premium = false}) async {
    final fixture = PremiumTestFixture(premium: premium);
    await fixture.init();
    addTearDown(fixture.dispose);
    return fixture;
  }

  test('basic themes and clearing inheritance do not require Premium', () {
    const before = NoteCardStyle();
    for (final theme in NoteTheme.values.where((theme) => !theme.isPremium)) {
      expect(
          requiredNoteStyleFeature(before, before.copyWith(noteTheme: theme)),
          isNull);
    }
    expect(
        requiredNoteStyleFeature(
            const NoteCardStyle(noteTheme: NoteTheme.parchment), before),
        isNull);
  });

  test('only newly selected advanced themes require noteThemes', () {
    for (final theme in NoteTheme.values.where((theme) => theme.isPremium)) {
      final after = NoteCardStyle(noteTheme: theme);
      expect(requiredNoteStyleFeature(const NoteCardStyle(), after),
          PremiumFeature.noteThemes);
      expect(requiredNoteStyleFeature(after, after), isNull);
      expect(requiredNoteStyleFeature(after, after, isGlobalDefault: true),
          isNull);
      expect(
          requiredNoteStyleFeature(
              const NoteCardStyle(noteTheme: NoteTheme.classic), after,
              isGlobalDefault: true),
          PremiumFeature.noteThemes);
    }
  });

  test('existing non-theme per-note overrides retain their Premium policy', () {
    const before = NoteCardStyle(noteTheme: NoteTheme.gridPaper);
    for (final after in [
      before.copyWith(fontFamily: 'Kalam'),
      before.copyWith(fontSize: AppFontSize.large),
      before.copyWith(cardSize: NoteCardSize.large),
      before.copyWith(paperStyle: NoteCardPaperStyle.plain),
      before.copyWith(showDate: false),
    ]) {
      expect(requiredNoteStyleFeature(before, after),
          PremiumFeature.individualCardStyle);
      expect(requiredNoteStyleFeature(before, after, isGlobalDefault: true),
          isNull);
    }
  });

  test('free theme-only changes preserve imported typography without a gate',
      () {
    const before = NoteCardStyle(
        noteTheme: NoteTheme.parchment, fontFamily: 'Kalam', showDate: false);
    expect(
        requiredNoteStyleFeature(
            before, before.copyWith(noteTheme: NoteTheme.sticky)),
        isNull);
    expect(
        requiredNoteStyleFeature(before,
            before.copyWith(clearFontFamily: true, clearShowDate: true)),
        isNull);
    expect(
        requiredNoteStyleFeature(
            before, before.copyWith(noteTheme: NoteTheme.kraftNotebook)),
        PremiumFeature.noteThemes);
  });

  test('advanced theme and typography change use the advanced theme gate', () {
    expect(
        requiredNoteStyleFeature(
            const NoteCardStyle(),
            const NoteCardStyle(
                noteTheme: NoteTheme.parchment, fontFamily: 'Kalam')),
        PremiumFeature.noteThemes);
  });

  test('theme entitlement follows Premium and supported purchase platforms',
      () async {
    for (final (premium, supported, allowed) in [
      (false, true, false),
      (true, true, true),
      (false, false, true),
    ]) {
      final fixture =
          PremiumTestFixture(premium: premium, supported: supported);
      await fixture.init();
      try {
        expect(fixture.access.allows(PremiumFeature.noteThemes), allowed);
      } finally {
        await fixture.dispose();
      }
    }
    expect(NoteTheme.values.where((theme) => !theme.isPremium).toList(), [
      NoteTheme.classic,
      NoteTheme.sticky,
      NoteTheme.legalPad,
      NoteTheme.ruledNotebook,
      NoteTheme.gridPaper,
    ]);
  });

  test('resolver inherits default theme and explicit Classic overrides it',
      () async {
    SharedPreferences.setMockInitialValues({'app_note_theme': 'parchment'});
    await AppCardStyleSettings.instance.load();
    final inherited = resolveNoteCardStyle(const NoteCardStyle());
    expect(inherited.noteTheme, NoteTheme.parchment);
    final classic = resolveNoteCardStyle(const NoteCardStyle(
        noteTheme: NoteTheme.classic,
        fontFamily: 'Kalam',
        paperStyle: NoteCardPaperStyle.plain,
        showDate: false));
    expect(classic.noteTheme, NoteTheme.classic);
    expect(classic.fontFamily, 'Kalam');
    expect(classic.paperStyle, NoteCardPaperStyle.plain);
    expect(classic.showDate, isFalse);
  });

  test('missing unknown and malformed default themes use Classic', () async {
    for (final value in [
      null,
      'futureTheme',
      17,
      true,
      <String>['sticky']
    ]) {
      SharedPreferences.setMockInitialValues({
        if (value != null) 'app_note_theme': value,
      });
      final settings = AppCardStyleSettings();
      try {
        await settings.load();
        expect(settings.noteTheme, NoteTheme.classic);
        expect(settings.defaults.noteTheme, NoteTheme.classic);
      } finally {
        settings.dispose();
      }
    }
  });

  test('global advanced backend rejects bypass before any preference write',
      () async {
    final fixture = await entitlement();
    final settings = AppCardStyleSettings();
    addTearDown(settings.dispose);
    await settings.load();
    final previousPlatform = SharedPreferencesStorePlatform.instance;
    final before = await previousPlatform.getAll();
    final platform = _Preferences(before);
    SharedPreferencesStorePlatform.instance = platform;
    addTearDown(
        () => SharedPreferencesStorePlatform.instance = previousPlatform);
    final previous = settings.defaults;
    var notifications = 0;
    settings.addListener(() => notifications++);
    await expectLater(
        settings.saveDefaults(
            const NoteCardStyle(noteTheme: NoteTheme.parchment),
            premiumAccess: fixture.access),
        _premium(PremiumFeature.noteThemes));
    expect(platform.writes, isEmpty);
    expect(await platform.getAll(), before);
    expect(settings.defaults, previous);
    expect(notifications, 0);
  });

  test('free global themes save and existing advanced defaults remain usable',
      () async {
    final fixture = await entitlement();
    SharedPreferences.setMockInitialValues({'app_note_theme': 'dottedJournal'});
    final settings = AppCardStyleSettings();
    addTearDown(settings.dispose);
    await settings.load();
    await settings.saveDefaults(const NoteCardStyle(showDate: false),
        premiumAccess: fixture.access);
    expect(settings.noteTheme, NoteTheme.dottedJournal);
    expect(settings.showDate, isFalse);
    expect((await SharedPreferences.getInstance()).getString('app_note_theme'),
        'dottedJournal');
    for (final theme in NoteTheme.values.where((theme) => !theme.isPremium)) {
      await settings.saveDefaults(NoteCardStyle(noteTheme: theme),
          premiumAccess: fixture.access);
      expect(settings.noteTheme, theme);
    }
  });

  test('failed theme preference write rolls back the whole default transaction',
      () async {
    final fixture = await entitlement(premium: true);
    SharedPreferences.setMockInitialValues({
      'app_font_family': 'Roboto',
      'app_font_size': 'medium',
      'app_note_card_size': 'medium',
      'app_note_card_paper_style': 'textured',
      'app_note_card_show_date': true,
      'app_note_theme': 'classic',
    });
    await AppTypographySettings.instance.load();
    await AppLayoutSettings.instance.load();
    final settings = AppCardStyleSettings();
    addTearDown(settings.dispose);
    await settings.load();
    final previousPlatform = SharedPreferencesStorePlatform.instance;
    final before = await previousPlatform.getAll();
    final platform = _Preferences(before)
      ..failNextKey = 'flutter.app_note_theme';
    SharedPreferencesStorePlatform.instance = platform;
    addTearDown(
        () => SharedPreferencesStorePlatform.instance = previousPlatform);
    final previous = settings.defaults;
    var notifications = 0;
    settings.addListener(() => notifications++);
    const proposed = NoteCardStyle(
        noteTheme: NoteTheme.parchment,
        fontFamily: 'Kalam',
        fontSize: AppFontSize.large,
        cardSize: NoteCardSize.small,
        paperStyle: NoteCardPaperStyle.plain,
        showDate: false);
    await expectLater(
        settings.saveDefaults(proposed, premiumAccess: fixture.access),
        throwsStateError);
    expect(await platform.getAll(), before);
    expect(settings.defaults, previous);
    expect(notifications, 0);
    await settings.saveDefaults(proposed, premiumAccess: fixture.access);
    expect(settings.defaults, proposed);
    expect(notifications, 1);
  });

  test('queued global saves compare latest default and preserve omitted theme',
      () async {
    final premium = await entitlement(premium: true);
    final free = await entitlement();
    final settings = AppCardStyleSettings();
    addTearDown(settings.dispose);
    await settings.load();
    final previousPlatform = SharedPreferencesStorePlatform.instance;
    final platform = _Preferences(await previousPlatform.getAll())
      ..blockNextKey = 'flutter.app_font_family'
      ..gate = Completer<void>();
    SharedPreferencesStorePlatform.instance = platform;
    addTearDown(
        () => SharedPreferencesStorePlatform.instance = previousPlatform);
    final first = settings.saveDefaults(
        const NoteCardStyle(noteTheme: NoteTheme.parchment),
        premiumAccess: premium.access);
    final second = settings.saveDefaults(const NoteCardStyle(showDate: false),
        premiumAccess: free.access);
    await pumpEventQueue();
    expect(settings.noteTheme, NoteTheme.classic);
    expect(platform.writes, ['flutter.app_font_family']);
    platform.gate!.complete();
    await Future.wait([first, second]);
    expect(settings.noteTheme, NoteTheme.parchment);
    expect(settings.showDate, isFalse);
    expect((await SharedPreferences.getInstance()).getString('app_note_theme'),
        'parchment');
  });

  for (final theme in NoteTheme.values.where((theme) => !theme.isPremium)) {
    test('Home free backend saves $theme and preserves all other note metadata',
        () async {
      final fixture = await entitlement();
      final original = _note(
          style: const NoteCardStyle(fontFamily: 'Kalam', showDate: false));
      final notes = _Notes(original);
      final home = _home(notes, fixture.access);
      addTearDown(home.close);
      final next = original.cardStyle.copyWith(noteTheme: theme);
      expect(await home.setCardStyle(original.id!, next), isNull);
      expect(notes.value.toDomain(), original.copyWith(cardStyle: next));
      expect(notes.writes, 1);
    });
  }

  test('Home free backend blocks advanced changes and non-theme overrides',
      () async {
    final fixture = await entitlement();
    final original = _note();
    final notes = _Notes(original);
    final home = _home(notes, fixture.access);
    addTearDown(home.close);
    for (final theme in NoteTheme.values.where((theme) => theme.isPremium)) {
      await expectLater(
          home.setCardStyle(original.id!, NoteCardStyle(noteTheme: theme)),
          _premium(PremiumFeature.noteThemes));
    }
    await expectLater(
        home.setCardStyle(
            original.id!, const NoteCardStyle(fontFamily: 'Kalam')),
        _premium(PremiumFeature.individualCardStyle));
    expect(notes.value.toDomain(), original);
    expect(notes.writes, 0);
  });

  test('Home keeps imported advanced appearance and permits inheritance reset',
      () async {
    final fixture = await entitlement();
    final original =
        _note(style: const NoteCardStyle(noteTheme: NoteTheme.parchment));
    final notes = _Notes(original);
    final home = _home(notes, fixture.access);
    addTearDown(home.close);
    expect(await home.setCardStyle(original.id!, original.cardStyle), isNull);
    expect(notes.value.toDomain(), original);
    expect(
        await home.setCardStyle(original.id!, const NoteCardStyle()), isNull);
    expect(notes.value.toDomain(),
        original.copyWith(cardStyle: const NoteCardStyle()));
    expect(notes.writes, 2);
  });

  test('Home Premium backend saves advanced theme plus typography', () async {
    final fixture = await entitlement(premium: true);
    final original = _note();
    final notes = _Notes(original);
    final home = _home(notes, fixture.access);
    addTearDown(home.close);
    const style =
        NoteCardStyle(noteTheme: NoteTheme.parchment, fontFamily: 'Kalam');
    expect(await home.setCardStyle(original.id!, style), isNull);
    expect(notes.value.toDomain(), original.copyWith(cardStyle: style));
    expect(notes.writes, 1);
  });
}
