import 'package:onlynote/Tools/pdf_glyphs.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:onlynote/Tools/image_storage.dart';
import 'package:onlynote/Tools/reminder_data.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/note_share_sheet.dart';
import 'package:onlynote/presentation/components/toast.dart';
import 'package:onlynote/services/note_export.dart';

import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

class ShareHelper {
  static bool _sharing = false;

  static Future<void> shareNote(
      BuildContext context, Note note, ScreenshotController controller,
      {Rect? sharePositionOrigin,
      Future<Uint8List?> Function()? captureImage}) async {
    if (_sharing) return;
    _sharing = true;
    ScaffoldFeatureController<SnackBar, SnackBarClosedReason>? progress;
    try {
      final format = await showNoteShareSheet(context);
      if (format == null || !context.mounted) return;
      final s = S.of(context);
      final reminder = ReminderData.shared.getCurrentReminder(note);
      final reminderText =
          reminder == null ? null : '${s.Reminder}: ${reminder.timeString}';
      final stem = NoteExport.fileStem(note);
      if (format == NoteShareFormat.plainText) {
        final text = NoteExport.plainText(note, reminder: reminderText);
        if (text.isEmpty) {
          context.showToast(s.Share_No_Text);
          return;
        }
        await SharePlus.instance.share(
            ShareParams(text: text, sharePositionOrigin: sharePositionOrigin));
        return;
      }
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      progress = messenger.showSnackBar(SnackBar(
        content: Row(children: [
          const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2)),
          const SizedBox(width: 12),
          Expanded(child: Text(s.Share_Preparing)),
        ]),
        duration: const Duration(minutes: 2),
      ));
      if (format == NoteShareFormat.image) {
        await shareWidgetAsImage(controller,
            captureImage: captureImage,
            fileName: '$stem.png',
            sharePositionOrigin: sharePositionOrigin);
        return;
      }
      final photos = <Uint8List>[];
      for (final path in note.imagePaths) {
        // Normalize images for portable attachments and cap export resolution.
        // Missing files fail visibly rather than silently dropping photos.
        final bytes = await File(ImageStorage.resolvePath(path)).readAsBytes();
        final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
        final descriptor = await ui.ImageDescriptor.encoded(buffer);
        final scale = 1800 /
            (descriptor.width > descriptor.height
                ? descriptor.width
                : descriptor.height);
        final codec = await descriptor.instantiateCodec(
          targetWidth:
              scale < 1 ? (descriptor.width * scale).round() : descriptor.width,
          targetHeight: scale < 1
              ? (descriptor.height * scale).round()
              : descriptor.height,
        );
        try {
          final frame = await codec.getNextFrame();
          try {
            final png =
                await frame.image.toByteData(format: ui.ImageByteFormat.png);
            if (png == null) throw StateError('Could not export photo');
            photos.add(png.buffer.asUint8List());
          } finally {
            frame.image.dispose();
          }
        } finally {
          codec.dispose();
          descriptor.dispose();
          buffer.dispose();
        }
      }
      final files = <XFile>[];
      final names = <String>[];
      if (format == NoteShareFormat.markdown) {
        final photoNames =
            List.generate(photos.length, (i) => '$stem-photo-${i + 1}.png');
        final md = NoteExport.markdown(note,
            reminder: reminderText, photos: photoNames);
        names.add('$stem.md');
        files.add(XFile.fromData(Uint8List.fromList(utf8.encode(md)),
            mimeType: 'text/markdown', name: names.first));
        for (var i = 0; i < photos.length; i++) {
          names.add(photoNames[i]);
          files.add(XFile.fromData(photos[i],
              mimeType: 'image/png', name: photoNames[i]));
        }
      } else {
        final fonts = await Future.wait([
          'Roboto-Regular.ttf',
          'Roboto-Bold.ttf',
          'DroidSansFallback.ttf'
        ].map((name) => rootBundle.load('assets/fonts/$name')));
        final glyphImages = await renderMissingPdfGlyphs(
            '${NoteExport.plainText(note, reminder: reminderText)}\n${note.dateWithTime}',
            fonts);
        final glyphs = <String, Uint8List>{};
        try {
          for (final entry in glyphImages.entries) {
            final png =
                await entry.value.toByteData(format: ui.ImageByteFormat.png);
            if (png != null) glyphs[entry.key] = png.buffer.asUint8List();
          }
        } finally {
          for (final image in glyphImages.values) {
            image.dispose();
          }
        }
        final pdf = await compute(
            buildNotePdf,
            NotePdfData(
              title: note.title ?? '',
              description: note.description ?? '',
              date: note.dateWithTime,
              todos:
                  note.todo.map((t) => (t.completed, t.title ?? '')).toList(),
              photos: photos,
              glyphs: glyphs,
              reminder: reminderText,
              regular: fonts[0].buffer.asUint8List(),
              bold: fonts[1].buffer.asUint8List(),
              fallback: fonts[2].buffer.asUint8List(),
            ));
        names.add('$stem.pdf');
        files.add(XFile.fromData(pdf,
            mimeType: 'application/pdf', name: names.first));
      }
      progress.close();
      progress = null;
      if (!context.mounted) return;
      await SharePlus.instance.share(ShareParams(
          files: files,
          fileNameOverrides: names,
          sharePositionOrigin: sharePositionOrigin));
    } catch (_) {
      progress?.close();
      progress = null;
      if (context.mounted) {
        context.showToast(S.of(context).Share_Note_Failed, isError: true);
      }
    } finally {
      progress?.close();
      _sharing = false;
    }
  }

  static Future<void> shareWidgetAsImage(
    ScreenshotController controller, {
    required String fileName,
    String? text,
    Rect? sharePositionOrigin,
    Future<Uint8List?> Function()? captureImage,
  }) async {
    final Uint8List? bytes = captureImage == null
        ? await controller.capture(pixelRatio: 3)
        : await captureImage();
    if (bytes == null) {
      throw Exception('Failed to capture note image');
    }

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile.fromData(bytes, mimeType: 'image/png', name: fileName)],
        fileNameOverrides: [fileName],
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
