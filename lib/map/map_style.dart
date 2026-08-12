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

/// Colours for the night-time, low-light reading the game is played in.
///
/// Deliberately low contrast between ground and buildings, with roads brighter
/// than either: at arm's length while walking, the only thing that has to be
/// legible at a glance is where the streets go.
class MapPalette {
  const MapPalette({
    this.background = '#0b0d0e',
    this.water = '#0d1b24',
    this.green = '#0f1512',
    this.building = '#171a1c',
    this.minorRoad = '#2b3034',
    this.majorRoad = '#3c4348',
    this.railway = '#2a2320',
    this.boundary = '#232a2e',
  });

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
  MapPalette palette = const MapPalette(),
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
      {
        'id': 'building',
        'type': 'fill',
        'source': 'openmaptiles',
        'source-layer': 'building',
        'minzoom': 13,
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
  MapPalette palette = const MapPalette(),
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
