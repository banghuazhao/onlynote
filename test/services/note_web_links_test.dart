import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/services/note_web_links.dart';

void main() {
  test('HTTP(S) and www links retain original UTF-16 ranges', () {
    const text = '📝資料 https://例子.测试/筆記?q=茶 和 WWW.example.org/path';
    final links = findNoteWebLinks(text);
    expect(links, hasLength(2));
    expect(links.first.start, text.indexOf('https://'));
    expect(text.substring(links.first.start, links.first.end),
        'https://例子.测试/筆記?q=茶');
    expect(links.first.uri.scheme, 'https');
    // Dart serializes international hosts as percent-encoded UTF-8; the
    // intended host and exact visible note text both remain intact.
    expect(Uri.decodeComponent(links.first.uri.host), '例子.测试');
    expect(text.substring(links.last.start, links.last.end),
        'WWW.example.org/path');
    expect(links.last.uri, Uri.parse('https://www.example.org/path'));
    expect(() => links.clear(), throwsUnsupportedError);
  });

  test('sentence punctuation and wrapping brackets remain note text', () {
    const text = '(https://example.com/a(b)). [www.example.org/path]. '
        '{https://example.net/a{b}}; https://example.edu/search?q=(tea)! '
        'https://example.io，還有https://example.nz。';
    final links = findNoteWebLinks(text);
    expect(
      links.map((link) => text.substring(link.start, link.end)),
      [
        'https://example.com/a(b)',
        'www.example.org/path',
        'https://example.net/a{b}',
        'https://example.edu/search?q=(tea)',
        'https://example.io',
        'https://example.nz',
      ],
    );
  });

  test('local addresses, query punctuation and IPv6 are valid websites', () {
    const text = 'http://localhost:8080/a https://[::1]:8080/a '
        'https://example.com?q=a,b&x=1#part';
    expect(findNoteWebLinks(text).map((link) => link.uri.toString()), [
      'http://localhost:8080/a',
      'https://[::1]:8080/a',
      'https://example.com?q=a,b&x=1#part',
    ]);
  });

  test('non-web schemes, email addresses and malformed links stay plain', () {
    const text = 'example.com mailto:hello@example.com ftp://example.com '
        'file:///example.com javascript:alert(1) tel:123 '
        'name@www.example.com ftp://www.example.org '
        'https:// https:///broken https://.bad https://bad..host '
        'www. nothttps://example.com';
    expect(findNoteWebLinks(text), isEmpty);
  });

  test('website launcher rejects non-web schemes before invoking a plugin',
      () async {
    for (final value in [
      'mailto:hello@example.com',
      'tel:123',
      'file:///tmp/test',
      'javascript:alert(1)',
      'https:///missing-host',
    ]) {
      expect(await openNoteWebLink(Uri.parse(value)), isFalse);
    }
  });
}
