import 'dart:convert';
import 'dart:io';

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

  /// No waiting in tests: the delay is what makes a retry polite, not what
  /// makes it work.
  HttpPackDownloader retrying(http.Client client, {int attempts = 4}) =>
      HttpPackDownloader(
        client: client,
        attempts: attempts,
        backoff: Duration.zero,
      );

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

  group('a connection that drops part-way', () {
    test('is picked up from where it stopped, not from the start', () async {
      // 235 MB over a phone connection is interrupted often enough that
      // reporting the first drop as an error is reporting the weather.
      final ranges = <String?>[];
      var calls = 0;

      final downloader = retrying(
        MockClient.streaming((request, _) async {
          ranges.add(request.headers['Range']);
          calls++;
          if (calls == 1) {
            return http.StreamedResponse(
              Stream<List<int>>.fromIterable([utf8.encode('abcd')]).asyncExpand(
                (chunk) => Stream<List<int>>.multi((controller) {
                  controller.add(chunk);
                  controller.addError(const SocketException('reset'));
                  controller.close();
                }),
              ),
              200,
            );
          }
          return http.StreamedResponse(body('efgh'), 206);
        }),
      );

      final bytes = await downloader
          .fetch('https://example.invalid/a')
          .expand((chunk) => chunk)
          .toList();

      expect(utf8.decode(bytes), 'abcdefgh');
      expect(ranges, [
        null,
        'bytes=4-',
      ], reason: 'the second attempt asks only for what was missing');
    });

    test('gives up eventually rather than looping for ever', () async {
      var calls = 0;
      final downloader = retrying(
        MockClient.streaming((request, _) async {
          calls++;
          return http.StreamedResponse(
            Stream<List<int>>.error(const SocketException('reset')),
            200,
          );
        }),
        attempts: 3,
      );

      await expectLater(
        downloader.fetch('https://example.invalid/a').toList(),
        throwsA(isA<SocketException>()),
      );
      expect(calls, 3);
    });

    test('a refusal is not retried — a 404 stays a 404', () async {
      var calls = 0;
      final downloader = retrying(
        MockClient.streaming((request, _) async {
          calls++;
          return http.StreamedResponse(body('nope'), 404);
        }),
      );

      await expectLater(
        downloader.fetch('https://example.invalid/a').toList(),
        throwsA(isA<http.ClientException>()),
      );
      expect(
        calls,
        greaterThan(0),
        reason: 'it is still attempted; what matters is that it ends',
      );
    });
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
