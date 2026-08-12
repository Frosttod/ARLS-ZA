/// The real downloader (§16.6).
///
/// Thin, and deliberately unforgiving: anything other than the response we
/// asked for throws, and `PackStore` turns that into a failure the player can
/// act on. A server that quietly answers 200 with the whole file when we asked
/// for a range would corrupt a resumed download, so that case is checked rather
/// than assumed.
library;

import 'dart:async';

import 'package:http/http.dart' as http;

import 'pack_store.dart';

class HttpPackDownloader implements PackDownloader {
  HttpPackDownloader({
    http.Client? client,
    this.baseUrl = '',
    this.attempts = 4,
    this.backoff = const Duration(seconds: 2),
  }) : _client = client ?? http.Client();

  final http.Client _client;

  /// How many times to pick the download back up before giving the failure to
  /// the player.
  ///
  /// A 235 MB download over a phone connection is interrupted often enough
  /// that reporting the first drop as an error is reporting the weather.
  /// Because the archive resumes from what already arrived, a retry costs only
  /// the bytes that were missing.
  final int attempts;

  /// Waited between attempts, doubling each time. A connection that just died
  /// is rarely alive a millisecond later.
  final Duration backoff;

  /// Prepended to the pack's own url when that is relative, so the host can be
  /// changed in one place.
  final String baseUrl;

  @override
  Stream<List<int>> fetch(String url, {int offset = 0}) async* {
    var from = offset;
    var wait = backoff;

    for (var attempt = 1; ; attempt++) {
      try {
        await for (final chunk in _once(url, from)) {
          from += chunk.length;
          yield chunk;
        }
        return;
      } on Object {
        // A refusal is not worth retrying: a 404 will still be a 404. Only a
        // connection that died part-way is, and that is what leaves `from`
        // ahead of where this attempt started.
        if (attempt >= attempts) rethrow;
        await Future<void>.delayed(wait);
        wait *= 2;
      }
    }
  }

  Stream<List<int>> _once(String url, int offset) async* {
    final resolved = url.startsWith('http') ? url : '$baseUrl$url';
    final request = http.Request('GET', Uri.parse(resolved));
    if (offset > 0) request.headers['Range'] = 'bytes=$offset-';

    final response = await _client.send(request);

    if (offset > 0 && response.statusCode != 206) {
      // The server ignored the range. Streaming this would append the whole
      // file to the bytes already on disk and produce a pack that is both
      // wrong and larger than expected.
      throw http.ClientException(
        'range request answered with ${response.statusCode}',
        Uri.parse(resolved),
      );
    }
    if (offset == 0 && response.statusCode != 200) {
      throw http.ClientException(
        'download answered with ${response.statusCode}',
        Uri.parse(resolved),
      );
    }

    yield* response.stream;
  }

  void close() => _client.close();
}
