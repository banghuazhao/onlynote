import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/Tools/in_app_reviewer_helper.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferences prefs;
  late DateTime now;
  late InAppReviewHelper helper;
  late int requests;
  late bool available;
  late bool failRequest;

  Note note(String id) => Note(id: id, title: 'Note $id');

  InAppReviewHelper newHelper({bool allowPrompts = true}) => InAppReviewHelper(
        preferences: () async => prefs,
        clock: () => now,
        isAvailable: () async => available,
        requestReview: () async {
          requests++;
          if (failRequest) throw StateError('platform failure');
        },
        allowPrompts: allowPrompts,
      );

  Future<void> qualifyWithNotes() async {
    await helper.recordAppOpen();
    await helper.recordSavedNote(note('one'));
    now = DateTime(2026, 10, 2, 12);
    await helper.recordAppOpen();
    await helper.recordSavedNote(note('two'));
    now = DateTime(2026, 10, 8, 12);
    await helper.recordAppOpen();
    await helper.recordSavedNote(note('three'));
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    now = DateTime(2026, 10, 1, 12);
    requests = 0;
    available = true;
    failRequest = false;
    helper = newHelper();
  });

  test('upgraded launch count never prompts on startup or before seven days',
      () async {
    await prefs.setInt('openCount', 100);
    await helper.recordAppOpen();
    await helper.recordSavedNote(note('one'));
    now = DateTime(2026, 10, 2, 12);
    await helper.recordAppOpen();
    await helper.recordSavedNote(note('two'));
    now = DateTime(2026, 10, 3, 12);
    await helper.recordAppOpen();
    await helper.recordSavedNote(note('three'));
    await helper.requestReviewIfEligible();
    expect(requests, 0);

    now = DateTime(2026, 10, 8, 12);
    await helper.recordAppOpen();
    expect(requests, 0);
    await helper.requestReviewIfEligible();
    expect(requests, 1);
  });

  test('empty notes and repeated saves do not reach the three-note threshold',
      () async {
    await helper.recordAppOpen();
    await helper.recordSavedNote(note('one'));
    await helper.recordSavedNote(note('one'));
    await helper.recordSavedNote(Note(id: 'empty', title: '  '));
    now = DateTime(2026, 10, 2, 12);
    await helper.recordAppOpen();
    await helper.recordSavedNote(note('two'));
    now = DateTime(2026, 10, 8, 12);
    await helper.recordAppOpen();
    await helper.requestReviewIfEligible();
    expect(requests, 0);

    await helper.recordSavedNote(note('three'));
    expect(requests, 0, reason: 'recording should not prompt by default');
    await helper.requestReviewIfEligible();
    expect(requests, 1);
  });

  test('seven elapsed days and three notes still need a third use date',
      () async {
    await helper.recordAppOpen();
    await Future.wait([
      helper.recordSavedNote(note('one')),
      helper.recordSavedNote(note('two')),
      helper.recordSavedNote(note('three')),
    ]);
    now = DateTime(2026, 10, 8, 12);
    await helper.recordAppOpen();
    await helper.requestReviewIfEligible();
    expect(requests, 0);

    now = DateTime(2026, 10, 9, 12);
    await helper.recordAppOpen();
    await helper.requestReviewIfEligible();
    expect(requests, 1);
  });

  test('three different calendar dates count even around a short day',
      () async {
    now = DateTime(2026, 4, 4, 23, 55);
    await helper.recordAppOpen();
    await helper.recordSavedNote(note('one'));
    now = DateTime(2026, 4, 5, 0, 5);
    await helper.recordAppOpen();
    await helper.recordSavedNote(note('two'));
    // A second visit on the same local date does not add a fourth use day.
    now = DateTime(2026, 4, 5, 23, 55);
    await helper.recordAppOpen();
    now = DateTime(2026, 4, 11, 23, 56);
    await helper.recordSavedNote(note('three'));
    await helper.requestReviewIfEligible();
    expect(requests, 1);
  });

  test('a completed checklist can qualify with two notes after established use',
      () async {
    await helper.recordAppOpen();
    await helper.recordSavedNote(note('one'));
    now = DateTime(2026, 10, 2, 12);
    await helper.recordAppOpen();
    await helper.recordSavedNote(note('two'));
    now = DateTime(2026, 10, 8, 12);
    await helper.recordAppOpen();
    await helper.requestReviewIfEligible();
    expect(requests, 0);
    await helper.requestReviewIfEligible(afterChecklistCompletion: true);
    expect(requests, 0);

    expect(await helper.recordChecklistCompleted(noteId: 'two'), isTrue);
    expect(await helper.recordChecklistCompleted(noteId: 'two'), isFalse);
    expect(requests, 0);
    await helper.requestReviewIfEligible(afterChecklistCompletion: true);
    expect(requests, 1);
    await helper.requestReviewIfEligible(afterChecklistCompletion: true);
    expect(requests, 1);

    // Reusing a completed list later is an action, while the milestone counter
    // remains deduplicated. The cooldown still controls another prompt.
    now = DateTime(2027, 1, 7, 12);
    expect(await helper.recordChecklistCompleted(noteId: 'two'), isFalse);
    await helper.requestReviewIfEligible(afterChecklistCompletion: true);
    expect(requests, 2);
  });

  test('failed SDK call remains an attempted request across helper instances',
      () async {
    await qualifyWithNotes();
    failRequest = true;
    await helper.requestReviewIfEligible();
    expect(requests, 1);

    helper = newHelper();
    failRequest = false;
    await helper.requestReviewIfEligible();
    expect(requests, 1);
  });

  test('unavailable review API does not consume a request attempt', () async {
    await qualifyWithNotes();
    available = false;
    await helper.requestReviewIfEligible();
    expect(requests, 0);

    available = true;
    await helper.requestReviewIfEligible();
    expect(requests, 1);
  });

  test('cooldown and rolling limit apply to concurrent calls', () async {
    await qualifyWithNotes();
    await Future.wait([
      helper.requestReviewIfEligible(),
      helper.requestReviewIfEligible(),
    ]);
    expect(requests, 1);

    now = DateTime(2027, 1, 5, 12); // 89 days after the first request.
    await helper.requestReviewIfEligible();
    expect(requests, 1);
    now = DateTime(2027, 1, 6, 12);
    await helper.requestReviewIfEligible();
    expect(requests, 2);
    now = DateTime(2027, 4, 6, 12);
    await helper.requestReviewIfEligible();
    expect(requests, 3);
    now = DateTime(2027, 7, 5, 12);
    await helper.requestReviewIfEligible();
    expect(requests, 3, reason: 'three attempts remain inside 365 days');
    now = DateTime(2027, 10, 9, 12);
    await helper.requestReviewIfEligible();
    expect(requests, 4, reason: 'the oldest attempt has left the window');
  });

  test('normal debug or test runtime cannot request a review', () async {
    helper = newHelper(allowPrompts: false);
    await qualifyWithNotes();
    await helper.requestReviewIfEligible();
    expect(requests, 0);
  });
}
