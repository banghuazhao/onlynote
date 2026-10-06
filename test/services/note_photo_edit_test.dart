import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/services/note_photo_edit.dart';
import 'package:onlynote/services/note_photo_transform.dart';

Future<ui.Image> _pixels() async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.drawRect(const ui.Rect.fromLTWH(0, 0, 2, 2),
      ui.Paint()..color = const ui.Color(0xffff0000));
  canvas.drawRect(const ui.Rect.fromLTWH(2, 0, 2, 2),
      ui.Paint()..color = const ui.Color(0xff0000ff));
  final picture = recorder.endRecording();
  final image = await picture.toImage(4, 2);
  picture.dispose();
  return image;
}

Future<ui.Image> _decode(Uint8List bytes) async {
  final codec = await ui.instantiateImageCodec(bytes);
  try {
    return (await codec.getNextFrame()).image;
  } finally {
    codec.dispose();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('clockwise crop rotates its selected region without losing it', () {
    const initial = NotePhotoTransform(crop: ui.Rect.fromLTWH(.1, .2, .3, .4));
    final rotated = initial.rotateClockwise();
    expect(rotated.rotation, 1);
    expect(rotated.crop.left, closeTo(.4, 1e-9));
    expect(rotated.crop.top, .1);
    expect(rotated.crop.width, closeTo(.4, 1e-9));
    expect(rotated.crop.height, closeTo(.3, 1e-9));
    final restored =
        rotated.rotateClockwise().rotateClockwise().rotateClockwise();
    expect(restored.rotation, 0);
    expect(restored.crop.left, closeTo(initial.crop.left, 1e-9));
    expect(restored.crop.top, closeTo(initial.crop.top, 1e-9));
    expect(restored.crop.width, closeTo(initial.crop.width, 1e-9));
    expect(restored.crop.height, closeTo(initial.crop.height, 1e-9));
  });

  test('canvas crop exports selected pixels and a matching aspect ratio',
      () async {
    final image = await _pixels();
    addTearDown(image.dispose);
    final edited = await renderNotePhotoEdit(
        image, const NotePhotoTransform(crop: ui.Rect.fromLTWH(.5, 0, .5, 1)));
    expect(edited.aspectRatio, 1);
    final decoded = await _decode(edited.bytes);
    addTearDown(decoded.dispose);
    expect(decoded.width, 2);
    expect(decoded.height, 2);
    final pixels =
        (await decoded.toByteData(format: ui.ImageByteFormat.rawRgba))!;
    expect(pixels.buffer.asUint8List().take(4), [0, 0, 255, 255]);
  });

  test('clockwise rotation exports the same pixels in their rotated positions',
      () async {
    final image = await _pixels();
    addTearDown(image.dispose);
    final edited = await renderNotePhotoEdit(
        image, const NotePhotoTransform(quarterTurns: 1));
    expect(edited.aspectRatio, .5);
    final decoded = await _decode(edited.bytes);
    addTearDown(decoded.dispose);
    expect(decoded.width, 2);
    expect(decoded.height, 4);
    final pixels =
        (await decoded.toByteData(format: ui.ImageByteFormat.rawRgba))!
            .buffer
            .asUint8List();
    expect(pixels.take(4), [255, 0, 0, 255]);
    expect(pixels.skip(2 * 2 * 4).take(4), [0, 0, 255, 255]);
  });

  test('EXIF-oriented photo opens upright and edited output stays upright',
      () async {
    final service = NotePhotoEditService(
        readBytes: (_) =>
            File('test/fixtures/clockwise_exif_photo.jpg').readAsBytes());
    final image = await service.load('note_images/oriented.jpg');
    addTearDown(image.dispose);
    expect(image.width, 4);
    expect(image.height, 8);
    final edited = await renderNotePhotoEdit(
        image, const NotePhotoTransform(crop: ui.Rect.fromLTWH(0, .5, 1, .5)));
    final decoded = await _decode(edited.bytes);
    addTearDown(decoded.dispose);
    expect(decoded.width, 4);
    expect(decoded.height, 4);
    final pixels =
        (await decoded.toByteData(format: ui.ImageByteFormat.rawRgba))!
            .buffer
            .asUint8List();
    expect(pixels[0], lessThan(10));
    expect(pixels[1], lessThan(10));
    expect(pixels[2], greaterThan(245));
  });

  test('oversized photo decoding bounds the longest edge without upscaling',
      () async {
    // A narrow strip exercises an oversized dimension with only 50,000 pixels.
    final recorder = ui.PictureRecorder();
    ui.Canvas(recorder).drawRect(const ui.Rect.fromLTWH(0, 0, 5000, 10),
        ui.Paint()..color = const ui.Color(0xff86b8ae));
    final picture = recorder.endRecording();
    final strip = await picture.toImage(5000, 10);
    picture.dispose();
    addTearDown(strip.dispose);
    final bytes = (await strip.toByteData(format: ui.ImageByteFormat.png))!
        .buffer
        .asUint8List();
    final service = NotePhotoEditService(readBytes: (_) async => bytes);
    final decoded = await service.load('note_images/panorama.png');
    addTearDown(decoded.dispose);
    expect(decoded.width, 4096);
    expect(decoded.height, 8);
  });

  test('oversized EXIF orientation stays upright after bounded decoding',
      () async {
    final service = NotePhotoEditService(
        readBytes: (_) =>
            File('test/fixtures/oversized_exif_photo.jpg').readAsBytes());
    final decoded = await service.load('note_images/oriented-panorama.jpg');
    addTearDown(decoded.dispose);
    expect(decoded.width, 8);
    expect(decoded.height, 4096);
  });

  test('new crop file is published only after the durable writer succeeds',
      () async {
    final original = await _pixels();
    addTearDown(original.dispose);
    final source = (await original.toByteData(format: ui.ImageByteFormat.png))!
        .buffer
        .asUint8List();
    final writes = <Uint8List>[];
    final service = NotePhotoEditService(
      readBytes: (path) async {
        expect(path, 'note_images/original.png');
        return source;
      },
      saveBytes: (bytes) async {
        writes.add(bytes);
        return 'note_images/fresh-copy.png';
      },
    );
    final decoded = await service.load('note_images/original.png');
    addTearDown(decoded.dispose);
    final result = await service.save(
        decoded, const NotePhotoTransform(crop: ui.Rect.fromLTWH(0, 0, .5, 1)));
    expect(result.path, 'note_images/fresh-copy.png');
    expect(result.aspectRatio, 1);
    expect(writes, hasLength(1));
    expect(
        source,
        (await original.toByteData(format: ui.ImageByteFormat.png))!
            .buffer
            .asUint8List());
    final failing = NotePhotoEditService(saveBytes: (_) async {
      throw StateError('Disk unavailable');
    });
    await expectLater(
        failing.save(decoded, const NotePhotoTransform(quarterTurns: 1)),
        throwsStateError);
  });

  test('invalid and outside crops fail before attempting a rendered copy',
      () async {
    final image = await _pixels();
    addTearDown(image.dispose);
    for (final crop in [
      const ui.Rect.fromLTWH(1.5, 0, .5, 1),
      const ui.Rect.fromLTWH(0, 0, 0, 1),
      const ui.Rect.fromLTWH(double.nan, 0, .5, 1),
    ]) {
      await expectLater(
          renderNotePhotoEdit(image, NotePhotoTransform(crop: crop)),
          throwsArgumentError);
    }
  });
}
