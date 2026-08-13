/// Between the design document's OSM tags and what the tiles actually carry.
///
/// §10 names places the way OpenStreetMap does — `amenity=pharmacy`,
/// `shop=doityourself`. The packs carry the OpenMapTiles schema instead, which
/// is a normalised subset: a `poi` layer with a coarse `class` and a `subclass`
/// holding the raw OSM value, a `landuse` layer of areas, and a
/// `transportation` layer of ways.
///
/// **This mapping was measured, not remembered.** `tool/probe_pack.dart` reads
/// a built pack and counts what is in it; the notes below are from a 25-tile
/// block over Poznań, about 12 km across.
///
/// What that measurement settled:
///
/// - `subclass` really is the raw OSM value, so `shop=supermarket` is
///   `poi.subclass=supermarket`. 251 of them in that block, 342 pharmacies,
///   712 convenience shops, 17 gun shops.
/// - **Buildings carry no type at all.** The `building` layer has
///   `render_height`, `render_min_height`, `colour` and nothing else — so
///   `building=house`, `building=barn` and `building=warehouse` from §10.1
///   cannot be matched. Those points have to be generated (§10.1's own last
///   layer) rather than found, and this file is where that is written down so
///   the next person does not go looking for a bug.
/// - `amenity=hunting_stand`, `man_made=water_tower` and
///   `amenity=waste_disposal` are not in the schema either. Recycling points
///   are (799), and they cover the same idea.
/// - `landuse` carries `garages`, `industrial`, `retail`, `military`,
///   `hospital` and the education classes, which is enough for the area-based
///   tables.
library;

import 'mvt.dart';

/// How a loot table names the places it applies to.
///
/// `layer.field=value`, e.g. `poi.subclass=pharmacy` or `landuse.class=retail`.
/// Written this way rather than as raw OSM tags because it is what can actually
/// be checked against a tile — a table matching on something the tiles do not
/// carry is a table that never fires, and that failure is silent.
Iterable<String> selectorsFor(MvtFeature feature) sync* {
  final klass = feature.properties['class'];
  if (klass is String && klass.isNotEmpty) {
    yield '${feature.layer}.class=$klass';
  }

  final subclass = feature.properties['subclass'];
  if (subclass is String && subclass.isNotEmpty) {
    yield '${feature.layer}.subclass=$subclass';
  }
}

/// The feature seen as OSM tags, for the safety exclusions of §3.5.
///
/// §3.5 decides whether a spawn point is somewhere a person can safely stand,
/// and it is written against OSM tags. The translation is deliberately generous
/// in the direction of refusing: a road that cannot be identified precisely is
/// still a road, and standing in it is the thing being prevented.
Map<String, String> osmTagsFor(MvtFeature feature) {
  final klass = '${feature.properties['class'] ?? ''}';
  final subclass = '${feature.properties['subclass'] ?? ''}';

  switch (feature.layer) {
    case 'transportation':
      if (klass == 'rail' || subclass == 'rail' || subclass == 'narrow_gauge') {
        return {'railway': subclass.isEmpty ? 'rail' : subclass};
      }
      // Everything else in this layer is something with traffic on it. The
      // footways and paths come back as highway too, which is correct: §3.5
      // keeps a buffer from the carriageway, not from the pavement.
      return {'highway': klass.isEmpty ? 'road' : klass};

    case 'water':
    case 'waterway':
      return {'natural': 'water'};

    case 'landuse':
      return switch (klass) {
        'military' => {'military': 'yes'},
        'hospital' => {'amenity': 'hospital'},
        'cemetery' => {'landuse': 'cemetery'},
        'railway' => {'landuse': 'railway'},
        _ => {'landuse': klass},
      };

    case 'poi':
      return switch (klass) {
        'hospital' => {'amenity': 'hospital'},
        'police' => {'amenity': 'police'},
        'fire_station' => {'amenity': 'fire_station'},
        'prison' => {'amenity': 'prison'},
        'school' || 'college' => {'amenity': 'school'},
        _ => {'amenity': subclass.isEmpty ? klass : subclass},
      };

    default:
      return const {};
  }
}

/// Layers worth decoding for the loot and safety work. Everything else in a
/// tile — landcover, boundaries, place labels — costs time to decode and
/// answers nothing either system asks.
const Set<String> kGameplayLayers = {
  'poi',
  'landuse',
  'transportation',
  'water',
  'waterway',
};

/// The zoom the POI live at.
///
/// Measured: at z14 one tile over central Poznań holds 7331 POI, at z13 it
/// holds nine. OpenMapTiles drops nearly all of them below z14, so there is
/// exactly one zoom worth reading and this is it.
const int kPoiZoom = 14;
