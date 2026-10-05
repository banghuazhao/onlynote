import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/services/note_autosave.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Considers a store review only after sustained use and a completed action.
///
/// The old `openCount` preference is intentionally ignored. Existing users
/// begin this policy's seven-day observation period when they first run it,
/// so an upgrade cannot trigger an immediate prompt.
class InAppReviewHelper {
  InAppReviewHelper({
    Future<SharedPreferences> Function()? preferences,
    DateTime Function()? clock,
    Future<bool> Function()? isAvailable,
    Future<void> Function()? requestReview,
    bool? allowPrompts,
  })  : _preferences = preferences ?? SharedPreferences.getInstance,
        _clock = clock ?? DateTime.now,
        _isAvailable = isAvailable ?? InAppReview.instance.isAvailable,
        _requestReview = requestReview ?? InAppReview.instance.requestReview,
        _allowPrompts = allowPrompts ?? kReleaseMode;

  static final instance = InAppReviewHelper();

  static const _stateKey = 'in_app_review_policy_v2';
  static const _minimumAge = Duration(days: 7);
  static const _cooldown = Duration(days: 90);
  static const _attemptWindow = Duration(days: 365);

  final Future<SharedPreferences> Function() _preferences;
  final DateTime Function() _clock;
  final Future<bool> Function() _isAvailable;
  final Future<void> Function() _requestReview;
  final bool _allowPrompts;
  bool get promptsEnabled => _allowPrompts;
  Future<void> _pending = Future<void>.value();

  /// Call on launch. This records one day of use but never requests a review.
  Future<void> recordAppOpen() async {
    await _enqueue(() async {
      final prefs = await _preferences();
      final now = _clock();
      final state = _read(prefs, now)..addDay(now);
      return _write(prefs, state);
    });
  }

  /// Call after a successful save. The same note ID is counted only once.
  ///
  /// By default this only records activity. Set [requestReview] to true only
  /// if this call happens after the editor has closed at a calm moment.
  Future<void> recordSavedNote(Note note, {bool requestReview = false}) async {
    final id = note.id;
    if (id == null || id.isEmpty || !NoteAutosave.hasContent(note)) return;
    await _enqueue(() async {
      final prefs = await _preferences();
      final now = _clock();
      final state = _read(prefs, now)
        ..addDay(now)
        ..addNote(id);
      if (!await _write(prefs, state)) return false;
      if (requestReview) {
        await _maybeRequest(prefs, state, now, afterChecklistCompletion: false);
      }
      return true;
    });
  }

  /// Call after a whole checklist first changes to completed and is saved.
  ///
  /// Returns whether this note ID was newly counted. A later genuine
  /// completion may still be a suitable moment to call
  /// [requestReviewIfEligible], even when this returns false.
  Future<bool> recordChecklistCompleted({
    required String noteId,
    bool requestReview = false,
  }) {
    if (noteId.isEmpty) return Future<bool>.value(false);
    return _enqueue(() async {
      final prefs = await _preferences();
      final now = _clock();
      final state = _read(prefs, now)..addDay(now);
      final newCompletion = state.addCompletion(noteId);
      state.addNote(noteId);
      if (!await _write(prefs, state)) return false;
      if (requestReview) {
        await _maybeRequest(
          prefs,
          state,
          now,
          afterChecklistCompletion: true,
        );
      }
      return newCompletion;
    });
  }

  /// Call after leaving the editor, or after a verified checklist completion
  /// and its Undo window. The caller chooses a time when no editor or snackbar
  /// is active. A checklist action needs two distinct notes; an ordinary save
  /// needs three. Both need three local calendar days and seven elapsed days.
  Future<void> requestReviewIfEligible({
    bool afterChecklistCompletion = false,
  }) async {
    await _enqueue(() async {
      final prefs = await _preferences();
      final now = _clock();
      final state = _read(prefs, now);
      return _maybeRequest(
        prefs,
        state,
        now,
        afterChecklistCompletion: afterChecklistCompletion,
      );
    });
  }

  Future<bool> _maybeRequest(
    SharedPreferences prefs,
    _ReviewState state,
    DateTime now, {
    required bool afterChecklistCompletion,
  }) async {
    if (!_allowPrompts ||
        now.difference(DateTime.fromMillisecondsSinceEpoch(state.firstSeenAt)) <
            _minimumAge ||
        state.days.length < 3 ||
        (afterChecklistCompletion && state.completionIds.isEmpty) ||
        state.noteIds.length < (afterChecklistCompletion ? 2 : 3)) {
      return false;
    }

    final cutoff = now.subtract(_attemptWindow).millisecondsSinceEpoch;
    final recent = state.attempts.where((at) => at > cutoff).toList();
    if (recent.length >= 3 ||
        recent.any((at) =>
            now.difference(DateTime.fromMillisecondsSinceEpoch(at)) <
            _cooldown)) {
      return false;
    }

    if (!await _isAvailable()) return false;
    state.attempts
      ..clear()
      ..addAll(recent)
      ..add(now.millisecondsSinceEpoch);
    // Persist before calling the SDK. If this fails, skip the platform call.
    if (!await _write(prefs, state)) return false;
    await _requestReview();
    return true;
  }

  // Serializing reads and writes prevents quick successive saves from losing
  // counters or accidentally issuing two review requests.
  Future<bool> _enqueue(Future<bool> Function() action) {
    final result = _pending.then((_) async {
      try {
        return await action();
      } catch (error) {
        // A review failure must never interfere with saving or navigation.
        debugPrint('Review prompt deferred: $error');
        return false;
      }
    });
    _pending = result.then((_) {});
    return result;
  }

  _ReviewState _read(SharedPreferences prefs, DateTime now) =>
      _ReviewState.decode(prefs.getString(_stateKey), now);

  Future<bool> _write(SharedPreferences prefs, _ReviewState state) =>
      prefs.setString(_stateKey, jsonEncode(state.toJson()));
}

class _ReviewState {
  _ReviewState({
    required this.firstSeenAt,
    required this.days,
    required this.noteIds,
    required this.completionIds,
    required this.attempts,
  });

  factory _ReviewState.decode(String? raw, DateTime now) {
    if (raw != null) {
      try {
        final data = jsonDecode(raw);
        if (data is Map<String, dynamic>) {
          return _ReviewState(
            firstSeenAt: data['firstSeenAt'] is int
                ? data['firstSeenAt'] as int
                : now.millisecondsSinceEpoch,
            days: (data['days'] as List?)?.whereType<String>().toList() ?? [],
            noteIds:
                (data['noteIds'] as List?)?.whereType<String>().toList() ?? [],
            completionIds: (data['completionIds'] as List?)
                    ?.whereType<String>()
                    .toList() ??
                [],
            attempts:
                (data['attempts'] as List?)?.whereType<int>().toList() ?? [],
          );
        }
      } catch (_) {
        // A corrupt preference starts a fresh observation period.
      }
    }
    return _ReviewState(
      firstSeenAt: now.millisecondsSinceEpoch,
      days: [],
      noteIds: [],
      completionIds: [],
      attempts: [],
    );
  }

  final int firstSeenAt;
  final List<String> days;
  final List<String> noteIds;
  final List<String> completionIds;
  final List<int> attempts;

  void addDay(DateTime now) {
    final day = '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
    // Only the threshold matters. Keep preference size stable across years.
    if (days.length < 3 && !days.contains(day)) days.add(day);
  }

  void addNote(String id) {
    if (noteIds.length < 3 && !noteIds.contains(id)) noteIds.add(id);
  }

  bool addCompletion(String id) {
    if (completionIds.contains(id)) return false;
    completionIds.add(id);
    return true;
  }

  Map<String, Object> toJson() => {
        'firstSeenAt': firstSeenAt,
        'days': days,
        'noteIds': noteIds,
        'completionIds': completionIds,
        'attempts': attempts,
      };
}
