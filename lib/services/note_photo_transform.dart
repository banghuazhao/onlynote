import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

/// Crop coordinates are relative to the rotated photo, keeping device pixels
/// out of the editor's gestures and preserving the selected area on rotation.
class NotePhotoTransform {
  const NotePhotoTransform({
    this.crop = const ui.Rect.fromLTWH(0, 0, 1, 1),
    this.quarterTurns = 0,
  });

  final ui.Rect crop;
  final int quarterTurns;

  int get rotation => quarterTurns % 4;
  bool get isIdentity =>
      rotation == 0 && crop == const ui.Rect.fromLTWH(0, 0, 1, 1);

  NotePhotoTransform copyWith({ui.Rect? crop, int? quarterTurns}) =>
      NotePhotoTransform(
        crop: crop ?? this.crop,
        quarterTurns: quarterTurns ?? this.quarterTurns,
      );

  NotePhotoTransform rotateClockwise() => NotePhotoTransform(
        crop: ui.Rect.fromLTWH(
            1 - crop.bottom, crop.left, crop.height, crop.width),
        quarterTurns: rotation + 1,
      );
}

class NoteEditedPhoto {
  const NoteEditedPhoto({required this.path, required this.aspectRatio});
  final String path;
  final double aspectRatio;
}

class RenderedNotePhoto {
  const RenderedNotePhoto({required this.bytes, required this.aspectRatio});
  final Uint8List bytes;
  final double aspectRatio;
}

/// Flutter's decoded pixels already account for the source's EXIF orientation.
/// Encode a fresh PNG rather than overwriting a file used by older note versions.
Future<RenderedNotePhoto> renderNotePhotoEdit(
    ui.Image source, NotePhotoTransform transform) async {
  final rotation = transform.rotation;
  final rotatedWidth = rotation.isOdd ? source.height : source.width;
  final rotatedHeight = rotation.isOdd ? source.width : source.height;
  final crop = transform.crop;
  if (!crop.left.isFinite ||
      !crop.top.isFinite ||
      !crop.right.isFinite ||
      !crop.bottom.isFinite ||
      crop.width <= 0 ||
      crop.height <= 0) {
    throw ArgumentError.value(crop, 'crop', 'Crop must be finite and nonempty');
  }
  final left = (crop.left.clamp(0.0, 1.0) * rotatedWidth).floor();
  final top = (crop.top.clamp(0.0, 1.0) * rotatedHeight).floor();
  final right = (crop.right.clamp(0.0, 1.0) * rotatedWidth).ceil();
  final bottom = (crop.bottom.clamp(0.0, 1.0) * rotatedHeight).ceil();
  final width = right - left;
  final height = bottom - top;
  if (width <= 0 || height <= 0) {
    throw ArgumentError.value(crop, 'crop', 'Crop is outside the photo');
  }
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder)
    ..clipRect(ui.Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()))
    ..translate(-left.toDouble(), -top.toDouble());
  switch (rotation) {
    case 1:
      canvas.translate(source.height.toDouble(), 0);
      canvas.rotate(math.pi / 2);
    case 2:
      canvas.translate(source.width.toDouble(), source.height.toDouble());
      canvas.rotate(math.pi);
    case 3:
      canvas.translate(0, source.width.toDouble());
      canvas.rotate(3 * math.pi / 2);
  }
  // These transforms only move whole pixels and turn by 90 degrees. Cubic
  // filtering would blend neighboring pixels even at 1:1 scale, including
  // pixels outside the crop. Keep the source samples exact when exporting.
  canvas.drawImage(
      source,
      ui.Offset.zero,
      ui.Paint()
        ..isAntiAlias = false
        ..filterQuality = ui.FilterQuality.none);
  final picture = recorder.endRecording();
  ui.Image? rendered;
  try {
    rendered = await picture.toImage(width, height);
    final bytes = await rendered.toByteData(format: ui.ImageByteFormat.png);
    if (bytes == null) {
      throw StateError('The edited photo could not be encoded');
    }
    return RenderedNotePhoto(
      bytes: bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
      aspectRatio: width / height,
    );
  } finally {
    rendered?.dispose();
    picture.dispose();
  }
}
