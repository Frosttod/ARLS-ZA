/// Reading tiles out of a PMTiles pack (§16.6, and the foundation of §10).
///
/// The renderer reads the same file through MapLibre and never tells us what
/// is in it. The game has to know anyway: loot spawns from the places on the
/// map (§10) and the safety exclusions of §3.5 are decided by what a point sits
/// on top of — both of which have to work with the screen off and the map
/// nowhere near the player's current view.
///
/// So this opens the archive directly. A directory lookup and one tile read per
/// query, straight off disk: no cache warming, nothing held in memory but the
/// root directory, because a region pack is 235 MB and the phone has other uses
/// for its RAM.
///
/// Layout: https://github.com/protomaps/PMTiles/blob/main/spec/v3/spec.md
library;

import 'dart:io';
import 'dart:typed_data';

import 'pmtiles_header.dart';

/// One entry in a PMTiles directory.
///
/// A [runLength] of zero means this is not a tile at all but a pointer to a
/// leaf directory, which is how a pack with millions of tiles keeps its root
/// directory small enough to hold in memory.
class PmtilesEntry {
  const PmtilesEntry({
    required this.tileId,
    required this.offset,
    required this.length,
    required this.runLength,
  });

  final int tileId;
  final int offset;
  final int length;
  final int runLength;

  bool get isLeaf => runLength == 0;
}

/// Thrown when the archive is not shaped the way the spec says.
class PmtilesReadException implements Exception {
  const PmtilesReadException(this.message);

  final String message;

  @override
  String toString() => 'PmtilesReadException: $message';
}

class PmtilesArchive {
  PmtilesArchive._(this._file, this.header, this._root);

  final RandomAccessFile _file;
  final PmtilesHeader header;
  final List<PmtilesEntry> _root;

  /// Opens a pack and reads its header and root directory.
  static Future<PmtilesArchive> open(File file) async {
    final handle = await file.open();
    try {
      final headerBytes = await handle.read(kPmtilesHeaderBytes);
      final header = readPmtilesHeader(headerBytes);

      await handle.setPosition(header.rootDirectory.offset);
      final rootBytes = await handle.read(header.rootDirectory.length);

      return PmtilesArchive._(
        handle,
        header,
        _decodeDirectory(_decompress(rootBytes, header.internalCompression)),
      );
    } on Object {
      await handle.close();
      rethrow;
    }
  }

  Future<void> close() => _file.close();

  /// The tile at z/x/y, decompressed, or null where the pack has none.
  ///
  /// A missing tile is ordinary: an extract covers a region, and the sea has no
  /// buildings in it.
  Future<Uint8List?> tile(int z, int x, int y) async {
    final wanted = zxyToTileId(z, x, y);

    var directory = _root;
    // Two levels is what the format uses in practice; the loop bounds the
    // recursion so a malformed archive cannot spin here for ever.
    for (var depth = 0; depth < 4; depth++) {
      final entry = _find(directory, wanted);
      if (entry == null) return null;

      if (!entry.isLeaf) {
        await _file.setPosition(header.tileData.offset + entry.offset);
        final bytes = await _file.read(entry.length);
        return _decompress(bytes, header.tileCompression);
      }

      await _file.setPosition(header.leafDirectories.offset + entry.offset);
      final bytes = await _file.read(entry.length);
      directory = _decodeDirectory(
        _decompress(bytes, header.internalCompression),
      );
    }

    throw const PmtilesReadException('leaf directories nested too deeply');
  }

  /// Binary search for the entry covering [tileId].
  ///
  /// Entries are sorted and may cover a run of ids — identical tiles (all that
  /// empty sea) are stored once and pointed at many times.
  static PmtilesEntry? _find(List<PmtilesEntry> entries, int tileId) {
    var low = 0;
    var high = entries.length - 1;

    while (low <= high) {
      final middle = (low + high) ~/ 2;
      final entry = entries[middle];
      if (tileId < entry.tileId) {
        high = middle - 1;
      } else if (tileId >= entry.tileId + (entry.runLength.clamp(1, 1 << 40))) {
        low = middle + 1;
      } else {
        return entry;
      }
    }

    // A leaf pointer covers everything from its id up to the next entry, so a
    // miss above still has to consider the entry before the insertion point.
    if (high >= 0 && entries[high].isLeaf) return entries[high];
    return null;
  }

  static Uint8List _decompress(Uint8List bytes, PmtilesCompression how) =>
      switch (how) {
        PmtilesCompression.none => bytes,
        PmtilesCompression.gzip => Uint8List.fromList(gzip.decode(bytes)),
        _ => throw PmtilesReadException('cannot read $how compression'),
      };

  static List<PmtilesEntry> _decodeDirectory(Uint8List bytes) {
    final reader = _Varints(bytes);
    final count = reader.next();

    final tileIds = List<int>.filled(count, 0);
    final runLengths = List<int>.filled(count, 0);
    final lengths = List<int>.filled(count, 0);
    final offsets = List<int>.filled(count, 0);

    var previous = 0;
    for (var i = 0; i < count; i++) {
      previous += reader.next();
      tileIds[i] = previous;
    }
    for (var i = 0; i < count; i++) {
      runLengths[i] = reader.next();
    }
    for (var i = 0; i < count; i++) {
      lengths[i] = reader.next();
    }
    for (var i = 0; i < count; i++) {
      final value = reader.next();
      // Zero means "directly after the previous one", which is how a clustered
      // archive avoids storing an offset for every tile in a run.
      offsets[i] = value == 0 && i > 0
          ? offsets[i - 1] + lengths[i - 1]
          : value - 1;
    }

    return [
      for (var i = 0; i < count; i++)
        PmtilesEntry(
          tileId: tileIds[i],
          offset: offsets[i],
          length: lengths[i],
          runLength: runLengths[i],
        ),
    ];
  }
}

/// Tile coordinates to the archive's own ordering.
///
/// PMTiles numbers tiles along a Hilbert curve rather than row by row, so
/// neighbours on the ground are neighbours in the file. That is what makes a
/// range request over the network read one contiguous run instead of scattering
/// across a 235 MB file.
int zxyToTileId(int z, int x, int y) {
  if (z < 0 || z > 26) {
    throw PmtilesReadException('zoom $z is outside PMTiles range');
  }

  // Every zoom below this one, in full: 1 + 4 + 16 + ...
  var accumulated = 0;
  for (var level = 0; level < z; level++) {
    accumulated += 1 << (2 * level);
  }

  var tx = x;
  var ty = y;
  var distance = 0;

  for (var side = 1 << (z - 1); side > 0; side >>= 1) {
    final rx = (tx & side) > 0 ? 1 : 0;
    final ry = (ty & side) > 0 ? 1 : 0;
    distance += side * side * ((3 * rx) ^ ry);

    // Rotate the quadrant so the curve stays continuous across it.
    if (ry == 0) {
      if (rx == 1) {
        tx = side - 1 - tx;
        ty = side - 1 - ty;
      }
      final swap = tx;
      tx = ty;
      ty = swap;
    }
  }

  return accumulated + distance;
}

/// Protobuf-style base-128 varints, which is what the directories are made of.
class _Varints {
  _Varints(this._bytes);

  final Uint8List _bytes;
  int _at = 0;

  int next() {
    var result = 0;
    var shift = 0;

    while (_at < _bytes.length) {
      final byte = _bytes[_at++];
      result |= (byte & 0x7F) << shift;
      if (byte & 0x80 == 0) return result;
      shift += 7;
    }

    throw const PmtilesReadException('varint runs past the end of the buffer');
  }
}
