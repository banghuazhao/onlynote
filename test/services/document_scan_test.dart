import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/services/document_scan.dart';

const _id = '12345678-1234-1234-1234-123456789abc';
const _otherId = '87654321-1234-1234-1234-123456789abc';
const _root = '/app/support/document_scans/$_id';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('onlynote.test/document-scan');
  late DocumentScanner scanner;
  final calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    scanner = DocumentScanner(channel: channel);
  });
  tearDown(() {
    scanner.dispose();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  void native(Future<Object?> Function(MethodCall) handler) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) {
      calls.add(call);
      return handler(call);
    });
  }

  test('reviewed pages preserve native order and bound the scan request',
      () async {
    native((call) async => {
          'id': _id,
          'status': 'pages',
          'paths': ['$_root/page_0.jpg', '$_root/page_1.jpg'],
        });
    final result = await scanner.scan(id: _id);
    expect(result.status, DocumentScanStatus.pages);
    expect(result.paths, ['$_root/page_0.jpg', '$_root/page_1.jpg']);
    expect(calls.single.method, 'scan');
    expect(calls.single.arguments, {'id': _id, 'pageLimit': 20});
    expect(() => result.paths.add('other'), throwsUnsupportedError);
  });

  test('invalid IDs and page limits never open native UI', () async {
    native((call) async => null);
    for (final id in ['', '../scan', 'not-a-uuid']) {
      expect((await scanner.scan(id: id)).status, DocumentScanStatus.failed);
    }
    for (final limit in [0, 21]) {
      expect((await scanner.scan(id: _id, pageLimit: limit)).status,
          DocumentScanStatus.failed);
    }
    expect(calls, isEmpty);
  });

  test('different request IDs or unowned paths are rejected before adoption',
      () async {
    final invalid = [
      '/etc/private.jpg',
      '$_root/../page_0.jpg',
      '$_root/./page_0.jpg',
      '$_root/page_0.jpg/extra',
      '$_root/page_0.png',
      '$_root/page_0\u0000.jpg',
      '$_root/page_0\\.jpg',
      '/app/document_scans/$_otherId/page_0.jpg',
      'document_scans/$_id/page_0.jpg',
    ];
    for (final path in invalid) {
      native((_) async => {
            'id': _id,
            'status': 'pages',
            'paths': [path]
          });
      final result = await scanner.scan(id: _id);
      expect(result.status, DocumentScanStatus.failed, reason: path);
      expect(result.paths, isEmpty);
    }
    native((_) async => {
          'id': _otherId,
          'status': 'pages',
          'paths': ['/app/document_scans/$_otherId/page_0.jpg'],
        });
    expect((await scanner.scan(id: _id)).status, DocumentScanStatus.failed);
  });

  test('empty, duplicate, excessive, or unreviewed pages cannot be delivered',
      () async {
    for (final value in [
      {'id': _id, 'status': 'pages', 'paths': []},
      {
        'id': _id,
        'status': 'pages',
        'paths': ['$_root/page_0.jpg', '$_root/page_0.jpg'],
      },
      {
        'id': _id,
        'status': 'pages',
        'paths': List.generate(21, (index) => '$_root/page_$index.jpg'),
      },
      {
        'id': _id,
        'status': 'pending',
        'paths': ['$_root/page_0.jpg'],
      },
      {'id': _id, 'status': 'something_unknown'},
    ]) {
      native((_) async => value);
      expect((await scanner.scan(id: _id)).status, DocumentScanStatus.failed);
    }
  });

  for (final entry in {
    'cancelled': DocumentScanStatus.cancelled,
    'unsupported': DocumentScanStatus.unsupported,
    'failed': DocumentScanStatus.failed,
    'pending': DocumentScanStatus.pending,
    'too_many_pages': DocumentScanStatus.tooManyPages,
    'permission_denied': DocumentScanStatus.permissionDenied,
  }.entries) {
    test('native ${entry.key} is preserved without inventing pages', () async {
      native((_) async => {'id': _id, 'status': entry.key, 'paths': []});
      final result = await scanner.scan(id: _id);
      expect(result.status, entry.value);
      expect(result.paths, isEmpty);
    });
  }

  test('missing plugin reports unsupported and acknowledgement can finish',
      () async {
    native((_) async => throw MissingPluginException());
    expect(
        (await scanner.scan(id: _id)).status, DocumentScanStatus.unsupported);
    expect(await scanner.pending(), isEmpty);
    await scanner.acknowledge(_id);
    expect(calls.last.method, 'acknowledge');
  });

  test('platform permissions and errors become explicit scan results',
      () async {
    native((_) async => throw PlatformException(code: 'permission_denied'));
    expect((await scanner.scan(id: _id)).status,
        DocumentScanStatus.permissionDenied);
    native((_) async => throw PlatformException(code: 'too_many_pages'));
    expect(
        (await scanner.scan(id: _id)).status, DocumentScanStatus.tooManyPages);
    native((_) async => throw PlatformException(code: 'scanner_failed'));
    final failed = await scanner.scan(id: _id);
    expect(failed.status, DocumentScanStatus.failed);
    expect(failed.error, isA<PlatformException>());
  });

  test('inbox keeps pending records, validates pages, and deduplicates IDs',
      () async {
    native((_) async => [
          {'id': _id, 'status': 'pending', 'paths': []},
          {'id': _id, 'status': 'cancelled', 'paths': []},
          {'id': 'unsafe', 'status': 'pending', 'paths': []},
          {
            'id': _otherId,
            'status': 'pages',
            'paths': ['/app/document_scans/$_otherId/page_0.jpg'],
          },
        ]);
    final result = await scanner.pending();
    expect(result.map((entry) => entry.id), [_id, _otherId]);
    expect(result.first.status, DocumentScanStatus.pending);
    expect(result.last.status, DocumentScanStatus.pages);
  });

  test('acknowledgement forwards only valid IDs and retains native failures',
      () async {
    native((_) async => throw PlatformException(code: 'ack_failed'));
    await expectLater(
        scanner.acknowledge(_id), throwsA(isA<PlatformException>()));
    expect(calls.single.arguments, {'id': _id});
    await expectLater(
        scanner.acknowledge('../outside'), throwsA(isA<FormatException>()));
    expect(calls.length, 1);
  });

  test('scanReady notifies with validated durable results only', () async {
    var updates = 0;
    scanner.addListener(() => updates++);
    Future<void> event(Object value) async {
      await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .handlePlatformMessage(
        channel.name,
        const StandardMethodCodec()
            .encodeMethodCall(MethodCall('scanReady', value)),
        (_) {},
      );
    }

    await event({'id': '../bad', 'status': 'pages', 'paths': []});
    expect(updates, 0);
    await event({
      'id': _id,
      'status': 'pages',
      'paths': ['$_root/page_0.jpg'],
    });
    expect(updates, 1);
    expect(scanner.lastReady?.paths, ['$_root/page_0.jpg']);
  });
}
