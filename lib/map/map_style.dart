/// The map's appearance, built rather than bundled (design doc §3.1, §3.6).
///
/// Generated in Dart instead of shipped as a JSON asset for one reason: the
/// only thing that varies is the path to the installed pack, and that path is
/// not known until the player has chosen a region. A template with a
/// placeholder to string-replace would be the same thing with more ways to go
/// wrong.
///
/// **Two rules this file exists to keep.**
///
/// *Nothing may reference a network host except the tile source itself.* The
/// game has no servers (§1.2); a style with a sprite or glyph URL renders fine
/// on a desk and fails in a forest. There is a test that walks the finished
/// style looking for `http` outside the source. The source may be remote when
/// the player has chosen to stream rather than install (see [MapSource]), and
/// that is the only address in the file.
///
/// *No text labels, and therefore no glyphs.* Labelled maps need a font stack
/// served as PBF ranges — several megabytes to bundle, for street names §3.6
/// does not ask for. The map is geometry: water, ground, buildings, roads. It
/// reads as a dark tactical plan, which is what the game wants, and it costs
/// nothing to carry. If names turn out to matter, glyphs are the thing to add.
///
/// The schema is OpenMapTiles, which is what Planetiler produces by default.
/// A pack built against another schema will render blank rather than wrong —
/// the layer names simply will not match.
library;

import 'dart:convert';

import 'map_source.dart';

/// The two map palettes.
///
/// The principle is the same in both and it is the only one that matters at
/// arm's length while walking: **roads carry the most contrast against the
/// ground**, and buildings sit close to the ground so a city block does not
/// read as a wall of shapes. What flips is the direction — on a dark map the
/// streets are the light thing, on a light map they are the dark one.
///
/// The dark palette is what the game is designed around (§3.6). The light one
/// exists because the same screen is read at noon in June, when a black map
/// under a bright sky cannot be read at all (§12).
class MapPalette {
  const MapPalette({
    required this.background,
    required this.water,
    required this.green,
    required this.building,
    required this.minorRoad,
    required this.majorRoad,
    required this.railway,
    required this.boundary,
  });

  /// Night, and the default.
  static const MapPalette dark = MapPalette(
    background: '#0b0d0e',
    water: '#0d1b24',
    green: '#0f1512',
    building: '#171a1c',
    minorRoad: '#2b3034',
    majorRoad: '#3c4348',
    railway: '#2a2320',
    boundary: '#232a2e',
  );

  /// Daylight, after CARTO's Voyager.
  ///
  /// ⚠️ The one inversion worth knowing: on this palette the **roads are the
  /// light thing** and the ground is the tint, which is the opposite of the
  /// dark map and the opposite of what the class comment above describes for
  /// a light one. Voyager works because white streets on a warm ground read
  /// as a street plan at any size, and because everything else can then be
  /// pale without competing.
  ///
  /// Not a copy — the layer set here is a tenth of Voyager's — but the same
  /// four decisions: warm off-white ground, white roads, desaturated blue
  /// water, and buildings barely separated from the ground so a block does
  /// not read as a wall.
  /// ⚠️ The ground is a shade deeper than Voyager's, and the trunk roads are
  /// pure white rather than its cream. Voyager separates a trunk road from a
  /// service road with **width and a casing**, at a desk; this style has
  /// neither layer, and a phone held at arm's length in the rain has contrast
  /// and nothing else. So the ground is dropped far enough to leave the white
  /// somewhere to stand.
  static const MapPalette light = MapPalette(
    background: '#F2EDE6',
    water: '#A5CBE0',
    green: '#D7E4C4',
    building: '#E7E0D5',
    minorRoad: '#FDFBF7',
    majorRoad: '#FFFFFF',
    railway: '#CFC7BB',
    boundary: '#DED6CA',
  );

  /// Which palette belongs with a screen is a widget's question, and this file
  /// deliberately knows nothing about Flutter — it has to stay loadable under
  /// `dart test`. The surface picks.

  final String background;
  final String water;
  final String green;
  final String building;
  final String minorRoad;
  final String majorRoad;
  final String railway;
  final String boundary;
}

/// Builds the style for [source].
Map<String, Object?> mapStyle({
  required MapSource source,
  MapPalette palette = MapPalette.dark,
  int maxZoom = 15,
}) {
  return {
    'version': 8,
    'name': 'ARLS-ZA',
    'sources': {
      'openmaptiles': {'type': 'vector', 'url': source.url},
    },
    'layers': [
      {
        'id': 'background',
        'type': 'background',
        'paint': {'background-color': palette.background},
      },
      {
        'id': 'landcover',
        'type': 'fill',
        'source': 'openmaptiles',
        'source-layer': 'landcover',
        'paint': {'fill-color': palette.green, 'fill-opacity': 0.6},
      },
      {
        'id': 'park',
        'type': 'fill',
        'source': 'openmaptiles',
        'source-layer': 'park',
        'paint': {'fill-color': palette.green, 'fill-opacity': 0.5},
      },
      {
        'id': 'water',
        'type': 'fill',
        'source': 'openmaptiles',
        'source-layer': 'water',
        'paint': {'fill-color': palette.water},
      },
      {
        'id': 'waterway',
        'type': 'line',
        'source': 'openmaptiles',
        'source-layer': 'waterway',
        'paint': {'line-color': palette.water, 'line-width': 1.5},
      },
      // ⚠️ Flat, and it was extruded for two days.
      //
      // The 3D city read well and cost too much: measured on a phone, panning
      // and pinching a block of extruded buildings dropped frames badly enough
      // that the map stuttered under a thumb — on a game whose whole interface
      // is that map, held while walking. §3.6 asks for a map that can be read
      // at arm's length in the rain, and a smooth flat one does that better
      // than a stuttering tall one.
      //
      // Everything needed to bring it back is still in the tiles:
      // `render_height` and `render_min_height` are two of the three fields
      // the building layer carries (see [omt_schema.dart]). It is a paint
      // block away if the frames are ever there.
      {
        'id': 'building',
        'type': 'fill',
        'source': 'openmaptiles',
        'source-layer': 'building',
        'minzoom': 14,
        'paint': {'fill-color': palette.building},
      },
      // Roads are drawn in three passes so the hierarchy survives at a glance:
      // everything, then the ones §3.5 keeps spawns away from, then rails.
      {
        'id': 'road-minor',
        'type': 'line',
        'source': 'openmaptiles',
        'source-layer': 'transportation',
        'minzoom': 12,
        'filter': [
          'in',
          'class',
          'minor',
          'service',
          'path',
          'track',
          'tertiary',
        ],
        'paint': {
          'line-color': palette.minorRoad,
          'line-width': _zoomWidth(0.6, 2.5),
        },
      },
      {
        'id': 'road-major',
        'type': 'line',
        'source': 'openmaptiles',
        'source-layer': 'transportation',
        'filter': ['in', 'class', 'motorway', 'trunk', 'primary', 'secondary'],
        'paint': {
          'line-color': palette.majorRoad,
          'line-width': _zoomWidth(1.2, 6),
        },
      },
      {
        'id': 'railway',
        'type': 'line',
        'source': 'openmaptiles',
        'source-layer': 'transportation',
        'filter': ['==', 'class', 'rail'],
        'paint': {
          'line-color': palette.railway,
          'line-width': _zoomWidth(0.8, 3),
        },
      },
      {
        'id': 'boundary',
        'type': 'line',
        'source': 'openmaptiles',
        'source-layer': 'boundary',
        'filter': ['<=', 'admin_level', 4],
        'paint': {
          'line-color': palette.boundary,
          'line-width': 1,
          'line-dasharray': [3, 2],
        },
      },
    ],
    'maxzoom': maxZoom,
  };
}

String mapStyleJson({
  required MapSource source,
  MapPalette palette = MapPalette.dark,
  int maxZoom = 15,
}) => jsonEncode(mapStyle(source: source, palette: palette, maxZoom: maxZoom));

/// A width that grows with zoom, so a street is a hairline on a district view
/// and a walkable ribbon at street level.
Map<String, Object?> _zoomWidth(double atZoom10, double atZoom17) => {
  'stops': [
    [10, atZoom10],
    [17, atZoom17],
  ],
};
