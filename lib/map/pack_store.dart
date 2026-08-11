/// Getting a map pack onto the device and knowing it arrived intact (§16.6).
///
/// A 200 MB download over a phone connection fails often enough that resuming
/// is not a refinement. The rules here:
///
/// * **Free space is checked before the first byte, with a margin.** Finding
///   out at 180 MB is not a design.
/// * **Download to a partial file, verify, then rename.** The game only ever
///   sees a file that has passed its checksum, so a half-written pack cannot
///   render as grey squares.
/// * **A failed checksum deletes the file.** Keeping it would make the next
///   attempt resume from a body of bytes already known to be wrong.
///
/// The filesystem and the network are injected, so all of this is testable
/// without a phone or a server.
library;

import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart';

import 'pmtiles_header.dart';
import 'region_pack.dart';

/// How a pack install ended.
enum InstallOutcome {
  installed,

  /// Already on disk and verified. Not an error — the picker offers a pack the
  /// player may already have.
  alreadyPresent,

  /// Not enough room, including the margin. Nothing was downloaded.
  notEnoughSpace,

  /// The connection failed or the server refused. The partial file is kept, so
  /// the next attempt resumes.
  networkFailed,

  /// The bytes arrived but are not the bytes we asked for. The partial file is
  /// deleted.
  corrupted,

  cancelled,
}

/// Progress of an install, for the screen that has to hold a player's attention
/// for several minutes.
class InstallProgress {
  const InstallProgress({required this.received, required this.total});

  final int received;
  final int total;

  double get fraction => total <= 0 ? 0 : received / total;
}

/// Fetches bytes, with the range support that makes resuming possible.
abstract class PackDownloader {
  /// Bytes from [url], starting at [offset]. Throws on any failure; the store
  /// turns that into [InstallOutcome.networkFailed].
  Stream<List<int>> fetch(String url, {int offset = 0});
}

/// Where packs live, and what is currently installed.
class PackStore {
  PackStore({
    required this.directory,
    required this.downloader,
    this.freeSpaceMargin = 64 * 1024 * 1024,
  });

  final Directory directory;
  final PackDownloader downloader;

  /// Room left over after the pack. A device filled to the last byte cannot
  /// write its own save file, which would be a far worse failure than a
  /// refused download.
  final int freeSpaceMargin;

  File fileFor(RegionPack pack) =>
      File('${directory.path}${Platform.pathSeparator}${pack.fileName}');

  File _partialFor(RegionPack pack) => File('${fileFor(pack).path}.part');

  Future<bool> isInstalled(RegionPack pack) => fileFor(pack).exists();

  /// Every pack id currently on disk, whether or not it is in the catalogue.
  ///
  /// Reads the directory rather than a record of what was installed: a file
  /// deleted by the system storage cleaner leaves no other trace.
  Future<Set<String>> installedIds() async {
    if (!directory.existsSync()) return {};
    final ids = <String>{};
    await for (final entry in directory.list()) {
      final name = entry.path.split(Platform.pathSeparator).last;
      if (name.endsWith('.pmtiles')) {
        ids.add(name.substring(0, name.length - '.pmtiles'.length));
      }
    }
    return ids;
  }

  /// The installed pack's own description of itself (§16.6), or null if it is
  /// not installed.
  ///
  /// Reads 127 bytes, not 235 MB: everything the game needs to know about a
  /// pack is in the fixed header.
  Future<PmtilesHeader?> headerFor(RegionPack pack) async {
    final file = fileFor(pack);
    if (!file.existsSync()) return null;

    final handle = await file.open();
    try {
      final bytes = await handle.read(kPmtilesHeaderBytes);
      return readPmtilesHeader(bytes);
    } finally {
      await handle.close();
    }
  }

  Future<void> delete(RegionPack pack) async {
    for (final file in [fileFor(pack), _partialFor(pack)]) {
      if (file.existsSync()) await file.delete();
    }
  }

  /// Downloads [pack] if it is not already here, verifies it and puts it in
  /// place.
  ///
  /// [freeBytes] is passed in rather than measured, because there is no
  /// portable way to ask, and the platform call belongs at the edge.
  Future<InstallOutcome> install(
    RegionPack pack, {
    required int freeBytes,
    void Function(InstallProgress)? onProgress,
    Future<bool> Function()? isCancelled,
  }) async {
    if (await isInstalled(pack)) return InstallOutcome.alreadyPresent;

    if (!directory.existsSync()) {
      await directory.create(recursive: true);
    }

    final partial = _partialFor(pack);
    final resumeFrom = partial.existsSync() ? await partial.length() : 0;

    // The margin is measured against what is still to come, not against the
    // whole pack: a download resuming at 180 of 200 MB needs 20 MB, not 200.
    final needed = pack.bytes - resumeFrom + freeSpaceMargin;
    if (freeBytes < needed) return InstallOutcome.notEnoughSpace;

    final sink = partial.openWrite(mode: FileMode.append);
    var received = resumeFrom;

    try {
      await for (final chunk in downloader.fetch(
        pack.url,
        offset: resumeFrom,
      )) {
        if (isCancelled != null && await isCancelled()) {
          await sink.close();
          return InstallOutcome.cancelled;
        }
        sink.add(chunk);
        received += chunk.length;
        onProgress?.call(
          InstallProgress(received: received, total: pack.bytes),
        );
      }
      await sink.close();
    } on Object {
      await sink.close();
      // The partial file stays. Those bytes were paid for once already.
      return InstallOutcome.networkFailed;
    }

    if (!await _verify(partial, pack.sha256)) {
      await partial.delete();
      return InstallOutcome.corrupted;
    }

    await partial.rename(fileFor(pack).path);
    return InstallOutcome.installed;
  }

  /// Streams the file rather than reading it: a 200 MB pack does not fit in the
  /// heap of a phone that is also running a map.
  Future<bool> _verify(File file, String expected) async {
    // An empty checksum means the catalogue was published without one. Refuse
    // rather than accept: a pack nobody can verify is a pack nobody should
    // trust to be the map they are about to walk into a city with.
    if (expected.isEmpty) return false;

    final digest = await sha256.bind(file.openRead()).first;
    return digest.toString() == expected.toLowerCase();
  }
}
