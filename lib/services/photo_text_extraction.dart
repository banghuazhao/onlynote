import 'dart:async';

import 'package:flutter/services.dart';
import 'package:onlynote/Tools/image_storage.dart';

import 'photo_text_result.dart';

export 'photo_text_result.dart';

/// Reads a photo already owned by the note. Recognition runs on-device and
/// returns reviewable text; it never changes a note or requests permissions.
class PhotoTextExtraction {
  PhotoTextExtraction({
    MethodChannel? channel,
    String Function(String)? resolvePath,
    this.timeout = const Duration(seconds: 45),
  })  : _channel = channel ?? const MethodChannel(channelName),
        _resolvePath = resolvePath ?? ImageStorage.resolvePath;

  static const channelName = 'com.appsbay.onlynote/photo_text';
  static const maxTextLength = maxPhotoTextLength;
  final MethodChannel _channel;
  final String Function(String) _resolvePath;
  final Duration timeout;

  Future<PhotoTextResult> extract(String managedPath) async {
    if (!_isManagedImage(managedPath)) {
      return const PhotoTextResult(PhotoTextStatus.failed);
    }
    try {
      final path = _resolvePath(managedPath);
      if (!path.startsWith('/') || path.contains('\u0000')) {
        return const PhotoTextResult(PhotoTextStatus.failed);
      }
      final value = await _channel.invokeMapMethod<String, Object?>(
          'recognize', {'path': path}).timeout(timeout);
      switch (value?['status']) {
        case 'text':
          final raw = value?['text'];
          if (raw is! String || raw.length > maxTextLength) {
            return const PhotoTextResult(PhotoTextStatus.failed);
          }
          final text =
              raw.replaceAll('\r\n', '\n').replaceAll('\r', '\n').trim();
          return text.isEmpty
              ? const PhotoTextResult(PhotoTextStatus.noText)
              : PhotoTextResult(PhotoTextStatus.text, text: text);
        case 'no_text':
          return const PhotoTextResult(PhotoTextStatus.noText);
        case 'unsupported':
          return const PhotoTextResult(PhotoTextStatus.unsupported);
        default:
          return const PhotoTextResult(PhotoTextStatus.failed);
      }
    } on MissingPluginException {
      return const PhotoTextResult(PhotoTextStatus.unsupported);
    } on PlatformException catch (error) {
      return PhotoTextResult(error.code == 'unsupported'
          ? PhotoTextStatus.unsupported
          : PhotoTextStatus.failed);
    } catch (_) {
      return const PhotoTextResult(PhotoTextStatus.failed);
    }
  }

  bool _isManagedImage(String path) {
    if (path.contains('\u0000') || path.contains('\\')) return false;
    final relative = path.startsWith('/')
        ? path.substring(path.lastIndexOf('/note_images/') + 1)
        : path;
    if (!relative.startsWith('note_images/')) return false;
    final name = relative.substring('note_images/'.length);
    return name.isNotEmpty &&
        name != '.' &&
        name != '..' &&
        !name.contains('/');
  }
}
