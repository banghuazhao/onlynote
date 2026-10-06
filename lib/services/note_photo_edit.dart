import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:onlynote/Tools/image_storage.dart';
import 'note_photo_transform.dart';

class NotePhotoEditService {
  const NotePhotoEditService({
    Future<Uint8List> Function(String path)? readBytes,
    Future<String> Function(Uint8List bytes)? saveBytes,
  })  : _readBytes = readBytes,
        _saveBytes = saveBytes;

  final Future<Uint8List> Function(String path)? _readBytes;
  final Future<String> Function(Uint8List bytes)? _saveBytes;

  Future<ui.Image> load(String path) async {
    final bytes = _readBytes != null
        ? await _readBytes(path)
        : await File(ImageStorage.resolvePath(path)).readAsBytes();
    final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    ui.ImageDescriptor? descriptor;
    ui.Codec? codec;
    try {
      descriptor = await ui.ImageDescriptor.encoded(buffer);
      // A phone photo stays sharp in a note while very large panoramas remain
      // safe to decode, crop, and export on devices with limited memory.
      final longestEdge = math.max(descriptor.width, descriptor.height);
      final scale = math.min(1.0, 4096 / longestEdge);
      codec = await descriptor.instantiateCodec(
        targetWidth:
            scale < 1 ? math.max(1, (descriptor.width * scale).round()) : null,
        targetHeight:
            scale < 1 ? math.max(1, (descriptor.height * scale).round()) : null,
      );
      return (await codec.getNextFrame()).image;
    } finally {
      codec?.dispose();
      descriptor?.dispose();
      buffer.dispose();
    }
  }

  Future<NoteEditedPhoto> save(
      ui.Image image, NotePhotoTransform transform) async {
    final rendered = await renderNotePhotoEdit(image, transform);
    final path =
        await (_saveBytes ?? ImageStorage.saveImageBytes)(rendered.bytes);
    return NoteEditedPhoto(path: path, aspectRatio: rendered.aspectRatio);
  }
}
