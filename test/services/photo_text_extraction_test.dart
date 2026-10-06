import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/services/photo_text_extraction.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('photo-text-test');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late List<MethodCall> calls;
  late Object? response;
  late PhotoTextExtraction extraction;

  setUp(() {
    calls = [];
    response = {'status': 'text', 'text': ' Shopping list\r\n牛奶\r面包 '};
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return response;
    });
    extraction = PhotoTextExtraction(
        channel: channel, resolvePath: (path) => '/documents/$path');
  });
  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('resolves managed photo and preserves English/Chinese line breaks',
      () async {
    final result = await extraction.extract('note_images/photo.jpg');
    expect(result.status, PhotoTextStatus.text);
    expect(result.text, 'Shopping list\n牛奶\n面包');
    expect(calls.single.method, 'recognize');
    expect(
        calls.single.arguments, {'path': '/documents/note_images/photo.jpg'});
  });

  test('legacy absolute photo is passed through injected path repair',
      () async {
    var input = '';
    final service = PhotoTextExtraction(
        channel: channel,
        resolvePath: (path) {
          input = path;
          return '/new/Documents/note_images/photo.jpg';
        });
    await service.extract('/old/Documents/note_images/photo.jpg');
    expect(input, '/old/Documents/note_images/photo.jpg');
    expect(calls.single.arguments,
        {'path': '/new/Documents/note_images/photo.jpg'});
  });

  for (final path in [
    '../photo.jpg',
    'note_images/../photo.jpg',
    'template_images/photo.jpg',
    '/tmp/photo.jpg',
    'note_images/',
    'note_images/..',
    'note_images/photo\u0000.jpg',
    'note_images\\photo.jpg'
  ]) {
    test('rejects unmanaged path $path before native invocation', () async {
      expect((await extraction.extract(path)).status, PhotoTextStatus.failed);
      expect(calls, isEmpty);
    });
  }

  for (final entry in {
    'no_text': PhotoTextStatus.noText,
    'unsupported': PhotoTextStatus.unsupported,
    'failed': PhotoTextStatus.failed,
    'unknown': PhotoTextStatus.failed,
  }.entries) {
    test('maps explicit native ${entry.key} response', () async {
      response = {'status': entry.key};
      expect((await extraction.extract('note_images/photo.jpg')).status,
          entry.value);
    });
  }

  test('empty recognition is no-text rather than an insertable success',
      () async {
    response = {'status': 'text', 'text': '  \n '};
    expect((await extraction.extract('note_images/photo.jpg')).status,
        PhotoTextStatus.noText);
  });
  test('malformed and excessive native text fail without truncation', () async {
    for (final value in [
      null,
      42,
      'x' * (PhotoTextExtraction.maxTextLength + 1)
    ]) {
      response = {'status': 'text', 'text': value};
      expect((await extraction.extract('note_images/photo.jpg')).status,
          PhotoTextStatus.failed);
    }
  });
  test('missing native bridge reports unsupported', () async {
    messenger.setMockMethodCallHandler(channel, null);
    expect((await extraction.extract('note_images/photo.jpg')).status,
        PhotoTextStatus.unsupported);
  });
  test('native failures become reviewable result states', () async {
    messenger.setMockMethodCallHandler(channel, (_) async {
      throw PlatformException(code: 'decode_failed');
    });
    expect((await extraction.extract('note_images/photo.jpg')).status,
        PhotoTextStatus.failed);
  });
  test('unresolved relative file is not sent to native recognition', () async {
    final service =
        PhotoTextExtraction(channel: channel, resolvePath: (path) => path);
    expect((await service.extract('note_images/photo.jpg')).status,
        PhotoTextStatus.failed);
    expect(calls, isEmpty);
  });
  test('path resolution failure is reported without native recognition',
      () async {
    final service = PhotoTextExtraction(
        channel: channel,
        resolvePath: (_) => throw StateError('Documents unavailable'));
    expect((await service.extract('note_images/photo.jpg')).status,
        PhotoTextStatus.failed);
    expect(calls, isEmpty);
  });
  test('recognition timeout releases the caller for retry', () async {
    final pending = Completer<Object?>();
    messenger.setMockMethodCallHandler(channel, (_) => pending.future);
    final service = PhotoTextExtraction(
        channel: channel,
        resolvePath: (path) => '/documents/$path',
        timeout: const Duration(milliseconds: 5));
    expect((await service.extract('note_images/photo.jpg')).status,
        PhotoTextStatus.failed);
    pending.complete({'status': 'no_text'});
  });
}
