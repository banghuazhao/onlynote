import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:onlynote/Tools/image_storage.dart';
import 'note_image.dart';

Widget buildNoteBlockImage(BuildContext context, String path) => LayoutBuilder(
      builder: (context, constraints) => NoteImage(
        path: path,
        width: constraints.maxWidth.isFinite ? constraints.maxWidth : null,
        height: constraints.maxHeight.isFinite ? constraints.maxHeight : null,
        fit: BoxFit.contain,
      ),
    );

Future<double?> readNoteBlockAspectRatio(String path) async {
  ui.ImmutableBuffer? buffer;
  ui.ImageDescriptor? descriptor;
  try {
    buffer = await ui.ImmutableBuffer.fromUint8List(
        await File(ImageStorage.resolvePath(path)).readAsBytes());
    descriptor = await ui.ImageDescriptor.encoded(buffer);
    return descriptor.width / descriptor.height;
  } catch (_) {
    return null;
  } finally {
    descriptor?.dispose();
    buffer?.dispose();
  }
}
