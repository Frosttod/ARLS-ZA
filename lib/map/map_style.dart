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

  /// Daylight. Not the dark palette inverted: paper-white ground would glare,
  /// so the background is warm off-white and the greens and blues keep enough
  /// saturation to be told apart from it in sunlight.
  static const MapPalette light = MapPalette(
    background: '#F2EFEA',
    water: '#BBD4E4',
    green: '#DCE6D4',
    building: '#E2DDD6',
    minorRoad: '#B4ADA3',
    majorRoad: '#8C837A',
    railway: '#A99B8E',
    boundary: '#C6BEB4',
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
      // §3.6: the city stands up.
      //
      // The same layer, extruded rather than filled. `render_height` and
      // `render_min_height` are two of the three fields the building layer
      // carries — see [omt_schema.dart], which counted them out of a real
      // pack — so the heights are the surveyed ones rather than a guess.
      //
      // ⚠️ Coalesced to eight metres. A footprint with no height on it is
      // common in OSM outside city centres, and `['get', ...]` on a missing
      // field gives null, which extrudes to nothing: a hole in the street
      // where a house is. Two storeys is the honest default for a building
      // nobody has measured.
      {
        'id': 'building',
        'type': 'fill-extrusion',
        'source': 'openmaptiles',
        'source-layer': 'building',

        // A storey of geometry is worth drawing only once it is worth
        // looking at. Below this the block is a smudge and the extrusion is
        // paid for in frames for nothing.
        'minzoom': 14,
        'paint': {
          'fill-extrusion-color': palette.building,
          'fill-extrusion-height': [
            'coalesce',
            ['get', 'render_height'],
            8,
          ],
          'fill-extrusion-base': [
            'coalesce',
            ['get', 'render_min_height'],
            0,
          ],

          // Not quite solid. §3.6 draws the markers on our side of the
          // platform view, so they are painted *over* the tiles whatever the
          // geometry does — a wholly opaque block would make a Walker behind
          // it read as a Walker in front of it. A little translucency is the
          // cheapest honest answer: the shape still reads, and what is behind
          // it is not hidden.
          'fill-extrusion-opacity': 0.85,
        },
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
