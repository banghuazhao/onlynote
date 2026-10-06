import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

enum DocumentScanStatus {
  pages,
  cancelled,
  unsupported,
  failed,
  pending,
  tooManyPages,
  permissionDenied,
}

/// Native scanner pages stay in an app-owned inbox until acknowledged.
class DocumentScanResult {
  const DocumentScanResult({
    required this.id,
    required this.status,
    this.paths = const [],
    this.error,
  });

  final String id;
  final DocumentScanStatus status;
  final List<String> paths;
  final Object? error;

  static final _idPattern = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');
  static bool validId(String id) => _idPattern.hasMatch(id);

  static bool validSource(String path, String id) {
    if (!validId(id) ||
        !path.startsWith('/') ||
        path.length > 4096 ||
        path.contains('\\') ||
        RegExp(r'[\x00-\x1f\x7f]').hasMatch(path) ||
        path.split('/').any((part) => part == '..' || part == '.')) {
      return false;
    }
    return RegExp('/document_scans/${RegExp.escape(id)}/page_[0-9]+\\.jpg\$')
        .hasMatch(path);
  }

  static DocumentScanResult? parse(Object? value,
      {String? expectedId, int pageLimit = DocumentScanner.maxPageCount}) {
    if (value is! Map) return null;
    final id = value['id'];
    final rawStatus = value['status'];
    final paths = value['paths'] ?? const <String>[];
    if (id is! String ||
        !validId(id) ||
        (expectedId != null && id.toLowerCase() != expectedId.toLowerCase()) ||
        paths is! List ||
        paths.length > pageLimit ||
        paths.any((path) => path is! String || !validSource(path, id)) ||
        paths.toSet().length != paths.length) {
      return null;
    }
    final status = switch (rawStatus) {
      'pages' => DocumentScanStatus.pages,
      'cancelled' => DocumentScanStatus.cancelled,
      'unsupported' => DocumentScanStatus.unsupported,
      'failed' => DocumentScanStatus.failed,
      'pending' => DocumentScanStatus.pending,
      'too_many_pages' => DocumentScanStatus.tooManyPages,
      'permission_denied' => DocumentScanStatus.permissionDenied,
      _ => null,
    };
    if (status == null ||
        (status == DocumentScanStatus.pages && paths.isEmpty) ||
        (status != DocumentScanStatus.pages && paths.isNotEmpty)) {
      return null;
    }
    return DocumentScanResult(
        id: id.toLowerCase(),
        status: status,
        paths: List.unmodifiable(paths.cast<String>()));
  }
}

/// Opens the platform's reviewed document scanner and observes its durable
/// inbox. Recognition and document scanning use separate native channels.
class DocumentScanner extends ChangeNotifier {
  DocumentScanner({MethodChannel? channel})
      : _channel = channel ?? const MethodChannel(channelName) {
    _channel.setMethodCallHandler(_onNativeCall);
  }

  static const channelName = 'com.appsbay.onlynote/document_scan';
  static const maxPageCount = 20;
  static DocumentScanner? _instance;
  static DocumentScanner get instance => _instance ??= DocumentScanner();
  static void configure(DocumentScanner scanner) => _instance = scanner;

  final MethodChannel _channel;
  DocumentScanResult? _lastReady;
  bool _disposed = false;
  DocumentScanResult? get lastReady => _lastReady;

  Future<void> _onNativeCall(MethodCall call) async {
    if (_disposed || call.method != 'scanReady') return;
    final result = DocumentScanResult.parse(call.arguments);
    if (result == null) return;
    _lastReady = result;
    notifyListeners();
  }

  Future<DocumentScanResult> scan(
      {required String id, int pageLimit = maxPageCount}) async {
    if (_disposed ||
        !DocumentScanResult.validId(id) ||
        pageLimit < 1 ||
        pageLimit > maxPageCount) {
      return DocumentScanResult(
          id: id,
          status: DocumentScanStatus.failed,
          error: const FormatException('Invalid document scan request'));
    }
    try {
      final value = await _channel
          .invokeMethod<Object?>('scan', {'id': id, 'pageLimit': pageLimit});
      return DocumentScanResult.parse(value,
              expectedId: id, pageLimit: pageLimit) ??
          DocumentScanResult(
              id: id,
              status: DocumentScanStatus.failed,
              error: const FormatException('Invalid document scan response'));
    } on MissingPluginException {
      return DocumentScanResult(id: id, status: DocumentScanStatus.unsupported);
    } on PlatformException catch (error) {
      return DocumentScanResult(
          id: id,
          status: switch (error.code) {
            'unsupported' => DocumentScanStatus.unsupported,
            'permission_denied' => DocumentScanStatus.permissionDenied,
            'too_many_pages' => DocumentScanStatus.tooManyPages,
            _ => DocumentScanStatus.failed,
          },
          error: error);
    } catch (error) {
      return DocumentScanResult(
          id: id, status: DocumentScanStatus.failed, error: error);
    }
  }

  Future<List<DocumentScanResult>> pending() async {
    if (_disposed) return const [];
    try {
      final value = await _channel.invokeMethod<Object?>('pending');
      if (value is! List) {
        throw const FormatException('Invalid document scan inbox');
      }
      final results = <DocumentScanResult>[];
      final seen = <String>{};
      for (final entry in value) {
        final result = DocumentScanResult.parse(entry);
        if (result != null && seen.add(result.id)) results.add(result);
      }
      return results;
    } on MissingPluginException {
      return const [];
    }
  }

  Future<void> acknowledge(String id) async {
    if (_disposed || !DocumentScanResult.validId(id)) {
      throw const FormatException('Invalid document scan acknowledgement');
    }
    try {
      await _channel.invokeMethod<Object?>('acknowledge', {'id': id});
    } on MissingPluginException {
      // An unavailable plugin has no native inbox to retain or acknowledge.
    }
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _channel.setMethodCallHandler(null);
    if (identical(_instance, this)) _instance = null;
    super.dispose();
  }
}
