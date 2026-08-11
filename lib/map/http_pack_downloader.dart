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
  HttpPackDownloader({http.Client? client, this.baseUrl = ''})
    : _client = client ?? http.Client();

  final http.Client _client;

  /// Prepended to the pack's own url when that is relative, so the host can be
  /// changed in one place.
  final String baseUrl;

  @override
  Stream<List<int>> fetch(String url, {int offset = 0}) async* {
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
