import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

class ShareHelper {
  static Future<void> shareWidgetAsImage(
    ScreenshotController controller, {
    required String fileName,
    String? text,
    Rect? sharePositionOrigin,
  }) async {
    final Uint8List? bytes = await controller.capture(pixelRatio: 3);
    if (bytes == null) {
      throw Exception('Failed to capture note image');
    }

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile.fromData(bytes, mimeType: 'image/png', name: fileName)],
        text: text,
        sharePositionOrigin: sharePositionOrigin,
      ),
    );
  }

  /// Finds the on-screen [Rect] of the widget attached to [key].
  ///
  /// Required on iPad so the share sheet popover has an anchor point;
  /// without it, `Share.shareXFiles` can crash on iPad.
  static Rect? shareOriginFromKey(GlobalKey key) {
    final renderObject = key.currentContext?.findRenderObject();
    if (renderObject is! RenderBox) return null;
    return renderObject.localToGlobal(Offset.zero) & renderObject.size;
  }
}
