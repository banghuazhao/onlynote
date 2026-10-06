import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// A website in the original note text. Offsets use Flutter's UTF-16 text
/// coordinates, so link decoration does not change selection or saved styles.
class NoteWebLink {
  const NoteWebLink({
    required this.start,
    required this.end,
    required this.uri,
  });

  final int start;
  final int end;
  final Uri uri;

  @override
  bool operator ==(Object other) =>
      other is NoteWebLink &&
      start == other.start &&
      end == other.end &&
      uri == other.uri;

  @override
  int get hashCode => Object.hash(start, end, uri);
}

typedef NoteWebLinkOpener = Future<bool> Function(Uri uri);

final _webLinkPattern = RegExp(
  r'''(?:https?://|www\.)[^\s<>"'‘’“”\u0000-\u001f\u007f\u200b，。；：！？、（）【】「」『』〈〉《》—–]+''',
  caseSensitive: false,
  unicode: true,
);
final _joinedPrefix = RegExp(r'[a-z0-9_@./:\-]', caseSensitive: false);
const _trailingPunctuation = '.,;:!?';
const _closingBrackets = {')': '(', ']': '[', '}': '{'};

/// Finds explicit HTTP(S) URLs and familiar www addresses. Punctuation around
/// a URL stays ordinary note text; balanced brackets inside its path stay in
/// the URL. Bare domains and other URI schemes remain plain text.
List<NoteWebLink> findNoteWebLinks(String text) {
  final result = <NoteWebLink>[];
  for (final match in _webLinkPattern.allMatches(text)) {
    if (match.start > 0 &&
        _joinedPrefix.hasMatch(text.substring(match.start - 1, match.start))) {
      continue;
    }
    final candidate = _trimWebLinkEnd(match[0]!);
    if (candidate.isEmpty) continue;
    final hasScheme = candidate.toLowerCase().startsWith('http');
    final uri = Uri.tryParse(hasScheme ? candidate : 'https://$candidate');
    if (uri == null || !_isWebsite(uri)) continue;
    if (!hasScheme &&
        (!uri.host.toLowerCase().startsWith('www.') || uri.host.length <= 4)) {
      continue;
    }
    result.add(NoteWebLink(
      start: match.start,
      end: match.start + candidate.length,
      uri: uri,
    ));
  }
  return List.unmodifiable(result);
}

String _trimWebLinkEnd(String candidate) {
  var end = candidate.length;
  while (end > 0) {
    final last = candidate.substring(end - 1, end);
    if (_trailingPunctuation.contains(last)) {
      end--;
      continue;
    }
    final opening = _closingBrackets[last];
    if (opening == null) break;
    var balance = 0;
    for (var index = 0; index < end; index++) {
      final character = candidate.substring(index, index + 1);
      if (character == opening) balance++;
      if (character == last) balance--;
    }
    if (balance >= 0) break;
    end--;
  }
  return candidate.substring(0, end);
}

bool _isWebsite(Uri uri) =>
    (uri.scheme == 'http' || uri.scheme == 'https') &&
    uri.hasAuthority &&
    uri.host.isNotEmpty &&
    !uri.host.startsWith('.') &&
    !uri.host.endsWith('.') &&
    !uri.host.contains('..');

/// Launches directly from the tap, without an asynchronous availability check
/// that can lose a browser's user gesture. Native devices use their browser;
/// web opens a new tab. Unsupported URLs and platform failures return false.
Future<bool> openNoteWebLink(Uri uri) async {
  if (!_isWebsite(uri)) return false;
  try {
    return await launchUrl(
      uri,
      mode:
          kIsWeb ? LaunchMode.platformDefault : LaunchMode.externalApplication,
      webOnlyWindowName: '_blank',
    );
  } catch (_) {
    return false;
  }
}
