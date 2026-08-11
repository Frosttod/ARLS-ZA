import 'dart:convert';

import 'package:arls_za/map/http_pack_downloader.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

/// The one failure a downloader must not paper over: a server that answers a
/// range request with the whole file. Streaming that onto a partial download
/// produces a pack that is both wrong and larger than expected, and the
/// checksum failure that follows looks like a corrupted disk.
void main() {
  Stream<List<int>> body(String text) => Stream.value(utf8.encode(text));

  test('a plain download is streamed through', () async {
    final downloader = HttpPackDownloader(
      client: MockClient.streaming(
        (request, _) async => http.StreamedResponse(body('tiles'), 200),
      ),
    );

    final bytes = await downloader.fetch('https://example.invalid/a').toList();

    expect(utf8.decode(bytes.expand((chunk) => chunk).toList()), 'tiles');
  });

  test('a resumed download asks for the range it needs', () async {
    String? sentRange;
    final downloader = HttpPackDownloader(
      client: MockClient.streaming((request, _) async {
        sentRange = request.headers['Range'];
        return http.StreamedResponse(body('rest'), 206);
      }),
    );

    await downloader.fetch('https://example.invalid/a', offset: 2048).toList();

    expect(sentRange, 'bytes=2048-');
  });

  test('a server that ignores the range is refused, not appended', () async {
    final downloader = HttpPackDownloader(
      client: MockClient.streaming(
        (request, _) async => http.StreamedResponse(body('whole file'), 200),
      ),
    );

    expect(
      downloader.fetch('https://example.invalid/a', offset: 2048).toList(),
      throwsA(isA<http.ClientException>()),
    );
  });

  test('a missing pack is an error the store can report', () async {
    final downloader = HttpPackDownloader(
      client: MockClient.streaming(
        (request, _) async => http.StreamedResponse(body('nope'), 404),
      ),
    );

    expect(
      downloader.fetch('https://example.invalid/a').toList(),
      throwsA(isA<http.ClientException>()),
    );
  });

  test('a relative url is resolved against the base', () async {
    Uri? asked;
    final downloader = HttpPackDownloader(
      baseUrl: 'https://example.invalid/maps/',
      client: MockClient.streaming((request, _) async {
        asked = request.url;
        return http.StreamedResponse(body('tiles'), 200);
      }),
    );

    await downloader.fetch('mazowieckie.pmtiles').toList();

    expect(
      asked.toString(),
      'https://example.invalid/maps/mazowieckie.pmtiles',
    );
  });
}
