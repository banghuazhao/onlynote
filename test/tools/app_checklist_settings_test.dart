import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/Tools/app_checklist_settings.dart';

import '../support/checklist_preferences.dart';

void main() {
  test('completed items default to expanded and the preference loads once',
      () async {
    final preferences = ChecklistPreferences();
    final settings = AppChecklistSettings(preferences: preferences);
    addTearDown(settings.dispose);
    expect(settings.completedExpanded, isTrue);
    await Future.wait([settings.load(), settings.load()]);
    await settings.load();
    expect(settings.completedExpanded, isTrue);
    expect(preferences.reads, 1);
  });

  test('collapsed and expanded preferences survive reopening', () async {
    final preferences = ChecklistPreferences();
    for (final expanded in [false, true]) {
      final settings = AppChecklistSettings(preferences: preferences);
      addTearDown(settings.dispose);
      expect(await settings.setCompletedExpanded(expanded), isTrue);
      final reopened = AppChecklistSettings(preferences: preferences);
      addTearDown(reopened.dispose);
      await reopened.load();
      expect(reopened.completedExpanded, expanded);
      expect(preferences.values[AppChecklistSettings.storageKey], expanded);
    }
  });

  test('read and write errors fail softly and later writes can recover',
      () async {
    final preferences = ChecklistPreferences()
      ..failReads = true
      ..failWrites = true;
    final settings = AppChecklistSettings(preferences: preferences);
    addTearDown(settings.dispose);
    await settings.load();
    expect(settings.completedExpanded, isTrue);
    expect(await settings.setCompletedExpanded(false), isFalse);
    expect(settings.completedExpanded, isFalse);
    preferences.failWrites = false;
    expect(await settings.setCompletedExpanded(true), isTrue);
    expect(preferences.values[AppChecklistSettings.storageKey], isTrue);
  });

  test('an invalid stored value falls back to expanded', () async {
    final preferences = ChecklistPreferences()
      ..values[AppChecklistSettings.storageKey] = 'invalid';
    final settings = AppChecklistSettings(preferences: preferences);
    addTearDown(settings.dispose);
    await settings.load();
    expect(settings.completedExpanded, isTrue);
  });

  test('a delayed initial read cannot replace an explicit choice', () async {
    final pending = Completer<bool?>();
    final preferences = ChecklistPreferences()..pendingRead = pending;
    final settings = AppChecklistSettings(preferences: preferences);
    addTearDown(settings.dispose);
    final loading = settings.load();
    await settings.setCompletedExpanded(false);
    pending.complete(true);
    await loading;
    expect(settings.completedExpanded, isFalse);
    expect(preferences.values[AppChecklistSettings.storageKey], isFalse);
  });

  test('loading after a choice does not read an older pending value', () async {
    final pending = Completer<void>();
    final preferences = ChecklistPreferences()
      ..values[AppChecklistSettings.storageKey] = true
      ..pendingWrite = pending;
    final settings = AppChecklistSettings(preferences: preferences);
    addTearDown(settings.dispose);
    final writing = settings.setCompletedExpanded(false);
    await settings.load();
    expect(settings.completedExpanded, isFalse);
    expect(preferences.reads, 0);
    pending.complete();
    expect(await writing, isTrue);
  });

  test('rapid choices persist in order when the first write is slow', () async {
    final pending = Completer<void>();
    final preferences = ChecklistPreferences()..pendingWrite = pending;
    final settings = AppChecklistSettings(preferences: preferences);
    addTearDown(settings.dispose);
    final first = settings.setCompletedExpanded(false);
    final second = settings.setCompletedExpanded(true);
    await Future<void>.delayed(Duration.zero);
    expect(settings.completedExpanded, isTrue);
    expect(preferences.writes, [false]);
    pending.complete();
    expect(await Future.wait([first, second]), [true, true]);
    expect(preferences.writes, [false, true]);
    expect(preferences.values[AppChecklistSettings.storageKey], isTrue);
  });

  test('an unavailable plugin never prevents reading or changing the choice',
      () async {
    final settings = AppChecklistSettings();
    addTearDown(settings.dispose);
    await expectLater(settings.load(), completes);
    expect(settings.completedExpanded, isTrue);
    await expectLater(settings.setCompletedExpanded(false), completes);
    expect(settings.completedExpanded, isFalse);
  });

  test('a delayed read completes safely after the settings are disposed',
      () async {
    final pending = Completer<bool?>();
    final settings = AppChecklistSettings(
        preferences: ChecklistPreferences()..pendingRead = pending);
    final loading = settings.load();
    settings.dispose();
    pending.complete(false);
    await expectLater(loading, completes);
  });
}
