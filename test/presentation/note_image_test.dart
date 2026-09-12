import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/presentation/components/note_image.dart';

void main() {
  testWidgets('a missing image file renders a placeholder, not a crash',
      (tester) async {
    // Image.file reports a missing file through real async file I/O, which
    // only runs outside the fake-async test zone.
    await tester.runAsync(() async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NoteImage(
              path: 'note_images/does-not-exist.jpg',
              width: 64,
              height: 52,
            ),
          ),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byIcon(Icons.image_not_supported_outlined), findsOneWidget);
  });

  test('note timestamps pad the minutes', () {
    final note = Note(dateTime: DateTime(2026, 9, 9, 15, 5));

    expect(note.dateWithTime, contains('3:05 PM'));
  });
}
