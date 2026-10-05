import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:onlynote/services/note_photo_capture.dart';

void main() {
  test('camera cancellation creates no durable image', () async {
    var writes = 0;
    final capture = NotePhotoCapture(
      pick: (_) async => null,
      save: (_) async {
        writes++;
        return 'note_images/unused.jpg';
      },
    );
    expect(await capture.capture(ImageSource.camera), isNull);
    expect(writes, 0);
    expect(capture.canRetry, isFalse);
  });

  test(
      'failed durable copy retries the selected image without reopening camera',
      () async {
    var picks = 0;
    var writes = 0;
    final capture = NotePhotoCapture(
      pick: (source) async {
        expect(source, ImageSource.camera);
        picks++;
        return XFile('/tmp/original-camera-image.jpg');
      },
      save: (source) async {
        expect(source.path, '/tmp/original-camera-image.jpg');
        if (++writes == 1) {
          throw StateError('Storage is temporarily unavailable');
        }
        return 'note_images/durable.jpg';
      },
    );
    await expectLater(capture.capture(ImageSource.camera), throwsStateError);
    expect(capture.canRetry, isTrue);
    expect(await capture.retry(), 'note_images/durable.jpg');
    expect(picks, 1);
    expect(writes, 2);
    expect(capture.canRetry, isFalse);
    expect(await capture.retry(), isNull);
  });
}
