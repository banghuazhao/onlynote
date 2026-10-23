import 'dart:io';

import 'package:flutter/material.dart';
import 'package:onlynote/Tools/image_storage.dart';
import 'missing_note_photo.dart';

/// A note's photo, loaded from its stored (relative) path.
///
/// Files can go missing — a restore from a backup that skipped the images
/// directory, or a cleanup that ran while the note still pointed at them —
/// and a bare [Image.file] answers that with a console exception and an empty
/// grey box. This shows a torn-photo placeholder instead, and decodes
/// thumbnails at their display size rather than at camera resolution.
class NoteImage extends StatelessWidget {
  const NoteImage({
    super.key,
    required this.path,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.semanticLabel,
  });

  final String path;
  final double? width;
  final double? height;
  final BoxFit fit;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final devicePixelRatio = MediaQuery.devicePixelRatioOf(context);
    final cacheWidth =
        width == null ? null : (width! * devicePixelRatio).round();

    return Image.file(
      File(ImageStorage.resolvePath(path)),
      width: width,
      height: height,
      fit: fit,
      cacheWidth: cacheWidth,
      semanticLabel: semanticLabel,
      excludeFromSemantics: semanticLabel == null,
      gaplessPlayback: true,
      errorBuilder: (context, _, __) => MissingNotePhoto(
        width: width,
        height: height,
        semanticLabel: semanticLabel,
      ),
    );
  }
}
