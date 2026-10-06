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

  test('gallery saves multiple photos in picker order with one picker launch',
      () async {
    var picks = 0;
    final capture = NotePhotoCapture(
      pickMany: () async {
        picks++;
        return [XFile('/tmp/one.jpg'), XFile('/tmp/two.jpg')];
      },
      save: (source) async => 'note_images/${source.path.split('/').last}',
    );
    final result = await capture.captureMany(ImageSource.gallery);
    expect(result.savedPaths, ['note_images/one.jpg', 'note_images/two.jpg']);
    expect(result.error, isNull);
    expect(capture.canRetry, isFalse);
    expect(picks, 1);
  });

  test('partial gallery failure retains successes and retries remaining once',
      () async {
    var picks = 0;
    var fail = true;
    final copies = <String>[];
    final capture = NotePhotoCapture(
      pickMany: () async {
        picks++;
        return [
          XFile('/tmp/one.jpg'),
          XFile('/tmp/two.jpg'),
          XFile('/tmp/three.jpg'),
        ];
      },
      save: (source) async {
        copies.add(source.path);
        if (source.path.endsWith('two.jpg') && fail) {
          throw StateError('Disk temporarily full');
        }
        return 'note_images/${source.path.split('/').last}';
      },
    );
    final first = await capture.captureMany(ImageSource.gallery);
    expect(first.savedPaths, ['note_images/one.jpg']);
    expect(first.error, isA<StateError>());
    expect(capture.canRetry, isTrue);
    fail = false;
    final retry = await capture.retryMany();
    expect(retry.savedPaths, ['note_images/two.jpg', 'note_images/three.jpg']);
    expect(retry.error, isNull);
    expect(copies,
        ['/tmp/one.jpg', '/tmp/two.jpg', '/tmp/two.jpg', '/tmp/three.jpg']);
    expect(picks, 1);
    expect(capture.canRetry, isFalse);
    expect((await capture.retryMany()).savedPaths, isEmpty);
  });

  test('multi-photo cancellation and duplicate sources create no duplicates',
      () async {
    var selected = <XFile>[];
    var copies = 0;
    final capture = NotePhotoCapture(
      pickMany: () async => selected,
      save: (_) async => 'note_images/${++copies}.jpg',
    );
    expect(
        (await capture.captureMany(ImageSource.gallery)).savedPaths, isEmpty);
    expect(copies, 0);
    selected = [XFile('/tmp/one.jpg'), XFile('/tmp/one.jpg')];
    expect((await capture.captureMany(ImageSource.gallery)).savedPaths,
        ['note_images/1.jpg']);
    expect(copies, 1);
  });
}
