/// Decoding Mapbox Vector Tiles (§10, §3.5).
///
/// Enough of the format to answer two questions the game cannot avoid: what
/// places are near the player, and what is the ground under a point made of.
/// The renderer answers neither — it draws tiles, it does not report them.
///
/// Deliberately partial. Geometry comes back as plain vertices in tile
/// coordinates: that is all a spawn point and a point-in-polygon test need, and
/// a full topological reader would be a great deal of code for no extra answer.
///
/// Format: https://github.com/mapbox/vector-tile-spec/tree/master/2.1
library;

import 'dart:convert';
import 'dart:typed_data';

/// What a feature is shaped like.
enum MvtGeometry { unknown, point, line, polygon }

class MvtFeature {
  const MvtFeature({
    required this.layer,
    required this.geometry,
    required this.properties,
    required this.points,
  });

  /// The OpenMapTiles layer it came from: `poi`, `landuse`, `transportation`…
  final String layer;

  final MvtGeometry geometry;

  /// Everything the tile carries about it. In the OpenMapTiles schema this is
  /// where `class`, `subclass` and `name` live.
  final Map<String, Object?> properties;

  /// Every vertex, in tile coordinates (0..extent). Rings are concatenated:
  /// for the uses here — a position, and whether a point falls inside — the
  /// distinction between one ring and two does not change the answer enough to
  /// justify carrying it.
  final List<({int x, int y})> points;

  /// Where to treat the feature as being. The vertex mean, which for a point is
  /// the point and for a building is close enough to the middle of it.
  ({double x, double y})? get centre {
    if (points.isEmpty) return null;
    var sx = 0.0;
    var sy = 0.0;
    for (final point in points) {
      sx += point.x;
      sy += point.y;
    }
    return (x: sx / points.length, y: sy / points.length);
  }
}

class MvtTile {
  const MvtTile(this.features, this.extent);

  final List<MvtFeature> features;

  /// The tile's coordinate space, 4096 in every tile anyone ships.
  final int extent;

  Iterable<MvtFeature> layer(String name) =>
      features.where((feature) => feature.layer == name);
}

/// Thrown when the bytes are not a vector tile.
class MvtFormatException implements Exception {
  const MvtFormatException(this.message);

  final String message;

  @override
  String toString() => 'MvtFormatException: $message';
}

/// Decodes a tile.
///
/// [layers] limits the work to the layers asked for. A tile in a city carries
/// tens of thousands of buildings, and decoding them to find four shops is time
/// spent with the screen on.
MvtTile decodeMvt(Uint8List bytes, {Set<String>? layers}) {
  final reader = _Reader(bytes);
  final features = <MvtFeature>[];
  var extent = 4096;

  while (!reader.isDone) {
    final (field, wire) = reader.tag();
    if (field == 3 && wire == 2) {
      final layer = _readLayer(reader.lengthDelimited(), layers);
      if (layer != null) {
        features.addAll(layer.features);
        extent = layer.extent;
      }
    } else {
      reader.skip(wire);
    }
  }

  return MvtTile(features, extent);
}

MvtTile? _readLayer(Uint8List bytes, Set<String>? wanted) {
  final reader = _Reader(bytes);

  var name = '';
  var extent = 4096;
  final keys = <String>[];
  final values = <Object?>[];
  final featureBodies = <Uint8List>[];

  while (!reader.isDone) {
    final (field, wire) = reader.tag();
    switch (field) {
      case 1 when wire == 2:
        name = utf8.decode(reader.lengthDelimited());
        // The caller already sliced this layer out of the tile, so dropping it
        // here costs nothing further: the outer reader is past it either way.
        if (wanted != null && !wanted.contains(name)) return null;
      case 2 when wire == 2:
        featureBodies.add(reader.lengthDelimited());
      case 3 when wire == 2:
        keys.add(utf8.decode(reader.lengthDelimited()));
      case 4 when wire == 2:
        values.add(_readValue(reader.lengthDelimited()));
      case 5 when wire == 0:
        extent = reader.varint();
      default:
        reader.skip(wire);
    }
  }

  return MvtTile([
    for (final body in featureBodies) _readFeature(body, name, keys, values),
  ], extent);
}

MvtFeature _readFeature(
  Uint8List bytes,
  String layer,
  List<String> keys,
  List<Object?> values,
) {
  final reader = _Reader(bytes);

  final properties = <String, Object?>{};
  var geometry = MvtGeometry.unknown;
  var commands = const <int>[];

  while (!reader.isDone) {
    final (field, wire) = reader.tag();
    switch (field) {
      case 2 when wire == 2:
        final pairs = _packed(reader.lengthDelimited());
        for (var i = 0; i + 1 < pairs.length; i += 2) {
          final key = pairs[i];
          final value = pairs[i + 1];
          if (key < keys.length && value < values.length) {
            properties[keys[key]] = values[value];
          }
        }
      case 3 when wire == 0:
        geometry = switch (reader.varint()) {
          1 => MvtGeometry.point,
          2 => MvtGeometry.line,
          3 => MvtGeometry.polygon,
          _ => MvtGeometry.unknown,
        };
      case 4 when wire == 2:
        commands = _packed(reader.lengthDelimited());
      default:
        reader.skip(wire);
    }
  }

  return MvtFeature(
    layer: layer,
    geometry: geometry,
    properties: properties,
    points: _decodeGeometry(commands),
  );
}

/// Walks the command stream into vertices.
///
/// Commands are a count and an id packed together; parameters are zigzagged
/// deltas from the previous vertex, which is what makes a tile small.
List<({int x, int y})> _decodeGeometry(List<int> commands) {
  final points = <({int x, int y})>[];
  var x = 0;
  var y = 0;
  var at = 0;

  while (at < commands.length) {
    final header = commands[at++];
    final id = header & 0x7;
    final count = header >> 3;

    if (id == 7) continue; // ClosePath carries no parameters.

    for (var i = 0; i < count && at + 1 < commands.length; i++) {
      x += _zigzag(commands[at++]);
      y += _zigzag(commands[at++]);
      points.add((x: x, y: y));
    }
  }

  return points;
}

int _zigzag(int value) => (value >> 1) ^ (-(value & 1));

Object? _readValue(Uint8List bytes) {
  final reader = _Reader(bytes);

  while (!reader.isDone) {
    final (field, wire) = reader.tag();
    switch (field) {
      case 1 when wire == 2:
        return utf8.decode(reader.lengthDelimited());
      case 2 when wire == 5:
        return reader.float32();
      case 3 when wire == 1:
        return reader.double64();
      case 4 when wire == 0:
      case 5 when wire == 0:
        return reader.varint();
      case 6 when wire == 0:
        final raw = reader.varint();
        return (raw >> 1) ^ (-(raw & 1));
      case 7 when wire == 0:
        return reader.varint() != 0;
      default:
        reader.skip(wire);
    }
  }

  return null;
}

List<int> _packed(Uint8List bytes) {
  final reader = _Reader(bytes);
  final values = <int>[];
  while (!reader.isDone) {
    values.add(reader.varint());
  }
  return values;
}

/// Just enough protobuf to read the fields above.
class _Reader {
  _Reader(this._bytes);

  final Uint8List _bytes;
  int _at = 0;

  bool get isDone => _at >= _bytes.length;

  (int field, int wire) tag() {
    final value = varint();
    return (value >> 3, value & 0x7);
  }

  int varint() {
    var result = 0;
    var shift = 0;

    while (_at < _bytes.length) {
      final byte = _bytes[_at++];
      result |= (byte & 0x7F) << shift;
      if (byte & 0x80 == 0) return result;
      shift += 7;
      if (shift > 63) throw const MvtFormatException('varint too long');
    }

    throw const MvtFormatException('varint runs past the end of the tile');
  }

  Uint8List lengthDelimited() {
    final length = varint();
    if (_at + length > _bytes.length) {
      throw const MvtFormatException('field runs past the end of the tile');
    }
    final view = Uint8List.sublistView(_bytes, _at, _at + length);
    _at += length;
    return view;
  }

  double float32() {
    final value = ByteData.sublistView(
      _bytes,
      _at,
      _at + 4,
    ).getFloat32(0, Endian.little);
    _at += 4;
    return value;
  }

  double double64() {
    final value = ByteData.sublistView(
      _bytes,
      _at,
      _at + 8,
    ).getFloat64(0, Endian.little);
    _at += 8;
    return value;
  }

  void skip(int wire) {
    switch (wire) {
      case 0:
        varint();
      case 1:
        _at += 8;
      case 2:
        _at += varint();
      case 5:
        _at += 4;
      default:
        throw MvtFormatException('unknown wire type $wire');
    }
  }
}
