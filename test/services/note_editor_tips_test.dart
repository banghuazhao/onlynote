import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/services/note_editor_tips.dart';
// The preference plugin exposes its test platform in a separate package.
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../support/memory_preferences.dart';

class _TipPreferences extends MemoryPreferences {
  @override
  Future<bool?> getBool(String key) async => values[key] as bool?;

  @override
  Future<void> setBool(String key, bool value) async {
    values[key] = value;
  }
}

class _UnavailablePreferences extends _TipPreferences {
  @override
  Future<bool?> getBool(String key) async => throw StateError('No preferences');

  @override
  Future<void> setBool(String key, bool value) async =>
      throw StateError('No preferences');
}

class _DelayedPreferences extends _TipPreferences {
  final read = Completer<bool?>();
  final write = Completer<void>();

  @override
  Future<bool?> getBool(String key) => read.future;

  @override
  Future<void> setBool(String key, bool value) => write.future;
}

void main() {
  test('querying a tip leaves it available until explicitly dismissed',
      () async {
    final preferences = _TipPreferences();
    final tips = NoteEditorTips(preferences: preferences);

    expect(await tips.shouldShow(NoteEditorTipKind.formatting), isTrue);
    expect(await tips.shouldShow(NoteEditorTipKind.formatting), isTrue);
    expect(preferences.values, isEmpty);
  });

  test('dismissals persist across editors and keep other tips available',
      () async {
    final preferences = _TipPreferences();
    final first = NoteEditorTips(preferences: preferences);
    final otherOpenEditor = NoteEditorTips(preferences: preferences);
    expect(
        await otherOpenEditor.shouldShow(NoteEditorTipKind.formatting), isTrue);

    await first.dismiss(NoteEditorTipKind.formatting);

    expect(await otherOpenEditor.shouldShow(NoteEditorTipKind.formatting),
        isFalse);
    final reopened = NoteEditorTips(preferences: preferences);
    expect(await reopened.shouldShow(NoteEditorTipKind.formatting), isFalse);
    expect(await reopened.shouldShow(NoteEditorTipKind.imageLayout), isTrue);
    expect(preferences.values,
        {NoteEditorTips.storageKey(NoteEditorTipKind.formatting): true});
  });

  test('a pending read cannot make a dismissed tip reappear', () async {
    final preferences = _DelayedPreferences();
    final tips = NoteEditorTips(preferences: preferences);
    final pendingQuery = tips.shouldShow(NoteEditorTipKind.imageLayout);
    final pendingDismissal = tips.dismiss(NoteEditorTipKind.imageLayout);

    // Dismissal is effective before the slow preference write finishes.
    expect(await tips.shouldShow(NoteEditorTipKind.imageLayout), isFalse);
    preferences.read.complete(false);
    expect(await pendingQuery, isFalse);
    preferences.write.complete();
    await pendingDismissal;
  });

  test('unavailable preferences hide optional tips without failing dismissal',
      () async {
    final tips = NoteEditorTips(preferences: _UnavailablePreferences());

    expect(await tips.shouldShow(NoteEditorTipKind.formatting), isFalse);
    await tips.dismiss(NoteEditorTipKind.formatting);
    expect(await tips.shouldShow(NoteEditorTipKind.formatting), isFalse);
  });

  test('default preferences initialize lazily and tolerate absent platform',
      () async {
    final previous = SharedPreferencesAsyncPlatform.instance;
    try {
      SharedPreferencesAsyncPlatform.instance = null;
      final tips = NoteEditorTips();
      expect(await tips.shouldShow(NoteEditorTipKind.formatting), isFalse);
      await tips.dismiss(NoteEditorTipKind.imageLayout);
      expect(await tips.shouldShow(NoteEditorTipKind.imageLayout), isFalse);
    } finally {
      SharedPreferencesAsyncPlatform.instance = previous;
    }
  });
}
