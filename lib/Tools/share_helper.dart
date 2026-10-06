import 'package:onlynote/Tools/pdf_glyphs.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:onlynote/Tools/image_storage.dart';
import 'package:onlynote/Tools/reminder_data.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/domain/model/voice_memo.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/note_share_sheet.dart';
import 'package:onlynote/presentation/components/toast.dart';
import 'package:onlynote/services/note_export.dart';
import 'package:onlynote/services/audio_storage.dart';

import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

class ShareHelper {
  static bool _sharing = false;

  static Future<void> shareNote(
      BuildContext context, Note note, ScreenshotController controller,
      {Rect? sharePositionOrigin,
      Future<Uint8List?> Function()? captureImage,
      Future<String> Function(String)? resolveAudioPath,
      Future<ShareResult> Function(ShareParams)? share}) async {
    if (_sharing) return;
    _sharing = true;
    ScaffoldFeatureController<SnackBar, SnackBarClosedReason>? progress;
    try {
      final format = await showNoteShareSheet(context,
          hasRecordings: note.voiceMemos.isNotEmpty);
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
        await (share ?? SharePlus.instance.share)(
            ShareParams(text: text, sharePositionOrigin: sharePositionOrigin));
        return;
      }
      if (format == NoteShareFormat.audio) {
        final recordingNames = List.generate(note.voiceMemos.length,
            (index) => '$stem-recording-${index + 1}.m4a');
        final files = await _recordingFiles(note.voiceMemos, recordingNames,
            resolvePath: resolveAudioPath);
        final transcript = _transcripts(note.voiceMemos, recordingNames);
        if (transcript.isNotEmpty) {
          recordingNames.add('$stem-transcripts.txt');
          files.add(XFile.fromData(Uint8List.fromList(utf8.encode(transcript)),
              mimeType: 'text/plain', name: recordingNames.last));
        }
        if (!context.mounted) return;
        await (share ?? SharePlus.instance.share)(ShareParams(
            files: files,
            fileNameOverrides: recordingNames,
            text: transcript.isEmpty ? null : transcript,
            sharePositionOrigin: sharePositionOrigin ?? _shareOrigin(context)));
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
            share: share,
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
        final recordingNames = List.generate(note.voiceMemos.length,
            (index) => '$stem-recording-${index + 1}.m4a');
        final recordings = await _recordingFiles(
            note.voiceMemos, recordingNames,
            resolvePath: resolveAudioPath);
        final md = NoteExport.markdown(note,
            reminder: reminderText,
            photos: photoNames,
            recordings: recordingNames,
            recordingLabel: s.Voice_Memo);
        names.add('$stem.md');
        files.add(XFile.fromData(Uint8List.fromList(utf8.encode(md)),
            mimeType: 'text/markdown', name: names.first));
        for (var i = 0; i < photos.length; i++) {
          names.add(photoNames[i]);
          files.add(XFile.fromData(photos[i],
              mimeType: 'image/png', name: photoNames[i]));
        }
        names.addAll(recordingNames);
        files.addAll(recordings);
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
              description: [
                if (note.description?.isNotEmpty == true) note.description!,
                ...note.voiceMemos
                    .map((memo) => memo.transcript ?? '')
                    .where((text) => text.isNotEmpty),
              ].join('\n\n'),
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
      await (share ?? SharePlus.instance.share)(ShareParams(
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
    Future<ShareResult> Function(ShareParams)? share,
  }) async {
    final Uint8List? bytes = captureImage == null
        ? await controller.capture(pixelRatio: 3)
        : await captureImage();
    if (bytes == null) {
      throw Exception('Failed to capture note image');
    }

    await (share ?? SharePlus.instance.share)(
      ShareParams(
        files: [XFile.fromData(bytes, mimeType: 'image/png', name: fileName)],
        fileNameOverrides: [fileName],
        text: text,
        sharePositionOrigin: sharePositionOrigin,
      ),
    );
  }

  /// Exports a snapshot of the recording. The owned note file is never moved
  /// or deleted, and filename overrides are used for share_plus cache copies.
  static Future<void> shareVoiceMemo(
    BuildContext context,
    VoiceMemo memo, {
    Rect? sharePositionOrigin,
    Future<String> Function(String)? resolvePath,
    Future<ShareResult> Function(ShareParams)? share,
  }) async {
    if (_sharing) return;
    _sharing = true;
    try {
      final date = memo.createdAt
          .toIso8601String()
          .split('.')
          .first
          .replaceAll(':', '-');
      final names = ['voice-memo-$date.m4a'];
      final files =
          await _recordingFiles([memo], names, resolvePath: resolvePath);
      final transcript = memo.transcript?.trim() ?? '';
      if (transcript.isNotEmpty) {
        names.add('voice-memo-$date.txt');
        files.add(XFile.fromData(Uint8List.fromList(utf8.encode(transcript)),
            mimeType: 'text/plain', name: names.last));
      }
      if (!context.mounted) return;
      await (share ?? SharePlus.instance.share)(ShareParams(
          files: files,
          fileNameOverrides: names,
          text: transcript.isEmpty ? null : transcript,
          sharePositionOrigin: sharePositionOrigin ?? _shareOrigin(context)));
    } catch (_) {
      if (context.mounted) {
        context.showToast(S.of(context).Share_Audio_Failed, isError: true);
      }
    } finally {
      _sharing = false;
    }
  }

  static Future<List<XFile>> _recordingFiles(
      List<VoiceMemo> memos, List<String> names,
      {Future<String> Function(String)? resolvePath}) async {
    final files = <XFile>[];
    for (var index = 0; index < memos.length; index++) {
      final memo = memos[index];
      if (!VoiceMemo.isManagedPath(memo.path)) {
        throw const FormatException('Invalid recording path');
      }
      final path =
          await (resolvePath ?? AudioStorage.instance.resolvePath)(memo.path);
      final source = File(path);
      final length = await source.length();
      if (length <= 0 || length > 32 * 1024 * 1024) {
        throw const FormatException('Invalid recording file');
      }
      files.add(XFile.fromData(await source.readAsBytes(),
          mimeType: 'audio/mp4', name: names[index]));
    }
    return files;
  }

  static String _transcripts(List<VoiceMemo> memos, List<String> names) => [
        for (var index = 0; index < memos.length; index++)
          if (memos[index].transcript?.trim().isNotEmpty == true)
            '${names[index]}\n${memos[index].transcript!.trim()}',
      ].join('\n\n');

  static Rect? _shareOrigin(BuildContext context) {
    final object = context.findRenderObject();
    if (object is! RenderBox || !object.hasSize || object.size.isEmpty) {
      return null;
    }
    return object.localToGlobal(Offset.zero) & object.size;
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
