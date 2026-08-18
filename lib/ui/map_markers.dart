/// What sits on the map, and what it looks like (design doc §3.6).
///
/// §3.6 fixes the colour code: green is the player, red an enemy, yellow a
/// loot box, grey an item somebody dropped, blue the shelter. Colour alone is
/// never enough (§12), so every marker carries a label for the screen reader
/// and the shapes differ as well as the hues.
///
/// Pure data: no widget, no map plugin. The renderer reads this, and so will
/// the tests that check a marker is not being drawn somewhere §3.5 forbids.
library;

import 'dart:ui' show Offset;

import '../map/geometry.dart';

/// The kinds of thing §3.6 puts on the map.
enum MarkerKind {
  /// §3.6: red. Visible within a radius that depends on the Reconnaissance
  /// skill (§7), which is why the renderer is told what to draw rather than
  /// working it out.
  enemy,

  /// §3.6: yellow.
  loot,

  /// §3.6: grey. Dropped by the player, gone after 24 hours (§4.8).
  dropped,

  /// §10.3: a body, with its pockets still in it. Bone white, and marked with
  /// a skull rather than only a colour (§12).
  remains,

  /// §3.6: blue. There is only ever one (§8).
  shelter,
}

/// How much attention a marker is paying to the player (§6.1a).
///
/// §12: never colour alone. The ring is a shortcut for what the HUD already
/// says in words and what the cone shows in direction — three ways of reading
/// the same fact, so nobody has to be able to tell red from orange to play.
enum MarkerAlert {
  /// It has not noticed anything. Green, and steady.
  calm,

  /// Something was heard, or it is turning the place over (§5.6.2). Amber.
  searching,

  /// It has the player and is coming. Red, and pulsing, because this is the
  /// one that is a clock.
  hunting,
}

/// What kind of place a loot marker stands for (§3.6, §10).
///
/// A dot that says "something to search" sends a player three hundred metres
/// to a florist. What they are actually deciding is which errand is worth the
/// walk, and that decision needs the kind of place, not the fact of one.
///
/// Deliberately coarse. Eleven shapes on a map read at arm's length in the
/// rain is nothing; seven is a legend somebody can hold in their head.
enum PlaceIcon {
  /// Pharmacy, clinic, hospital, ambulance.
  medical,

  /// Police, military — the two places with ammunition in them.
  guarded,

  /// Groceries, restaurants, allotments.
  food,

  /// Hardware, garages, workshops, warehouses: where §18.2's kilograms are.
  tools,

  /// Sports and hunting: where a weapon might be.
  weapons,

  /// Libraries and schools (§4.6).
  books,

  /// Houses, barns, anywhere somebody lived.
  home,

  /// A vehicle somebody left.
  vehicle,

  /// Bins, skips, roadsides. Materials, and not much else.
  waste,
}

/// One thing on the map.
class MapMarker {
  const MapMarker({
    required this.id,
    required this.kind,
    required this.at,
    this.label,
    this.reachM,
    this.count = 1,
    this.headingDeg,
    this.alert,
    this.icon,
  });

  /// Stable across frames, so the renderer can move a marker instead of
  /// deleting and recreating it — a marker that blinks every second is a
  /// marker nobody can tap.
  final String id;

  final MarkerKind kind;
  final GeoPoint at;

  /// Read out by the screen reader, and shown on tap. §12 requires that
  /// nothing on this map is knowable by colour alone.
  final String? label;

  /// §3.6: what kind of place this is, for anything that is one. Null for
  /// enemies, bodies and dropped kit — those are what they are.
  final PlaceIcon? icon;

  /// §6.1a: how much attention it is paying, or null for anything that pays
  /// none — a lootbox does not notice people.
  final MarkerAlert? alert;

  /// Which way it is facing, as a compass bearing (§3.6). Null for anything
  /// that does not face — a lootbox has no front.
  ///
  /// ⚠️ Where it is going, not what it can see. §6.2 gives enemies a detection
  /// radius and nothing directional, so a cone drawn as a field of view would
  /// be a lie the player would plan around.
  final double? headingDeg;

  /// How many things this one dot stands for (§4.8).
  ///
  /// A player who emptied their pack on a corner left fourteen rows in one
  /// place, and fourteen overlapping circles is not a map — it is a smear. One
  /// dot with a number on it is the same information in a form somebody can
  /// use.
  final int count;

  /// How close a player has to be for this to be worth anything (§10.2,
  /// §4.8), drawn as a ring around it.
  ///
  /// Twenty-five metres for a place and fifteen for a pile at somebody's feet
  /// are numbers nobody can judge by eye on a map that zooms. A ring turns
  /// "am I close enough yet" from a guess into something to walk into.
  final double? reachM;

  MapMarker copyWith({
    GeoPoint? at,
    String? label,
    double? reachM,
    int? count,
    double? headingDeg,
    MarkerAlert? alert,
  }) => MapMarker(
    id: id,
    kind: kind,
    at: at ?? this.at,
    label: label ?? this.label,
    reachM: reachM ?? this.reachM,
    count: count ?? this.count,
    headingDeg: headingDeg ?? this.headingDeg,
    alert: alert ?? this.alert,
    icon: icon,
  );
}

/// The colour code of §3.6, as ARGB values.
///
/// Kept out of the widget so a test can assert the code rather than a shade of
/// paint chosen in a layout file.
const Map<MarkerKind, int> kMarkerColours = {
  MarkerKind.enemy: 0xFFD93A2B,
  MarkerKind.loot: 0xFFE8B33A,
  MarkerKind.dropped: 0xFF8C8F92,
  MarkerKind.remains: 0xFFE6E1D6,
  MarkerKind.shelter: 0xFF3A7BD9,
};

/// The player's own colour. Green, and not one of [kMarkerColours] — the player
/// is not a marker, it is the thing everything else is measured from.
const int kPlayerColour = 0xFF4CD964;

/// How large each kind is drawn, in logical pixels of radius.
///
/// The shelter is the largest: it is the one point on the map a player
/// navigates *to* from a distance (§8).
const Map<MarkerKind, double> kMarkerRadius = {
  MarkerKind.enemy: 7,
  MarkerKind.loot: 6,
  MarkerKind.dropped: 5,
  MarkerKind.remains: 6,
  MarkerKind.shelter: 9,
};

/// Where a point sits on screen, in logical pixels from the middle.
///
/// The inverse of [markerAtOffset], and the reason both live here: a badge
/// drawn a few pixels off the dot it counts is worse than no badge.
Offset offsetOf(
  GeoPoint point, {
  required GeoPoint centre,
  required double zoom,
}) {
  final scale = metresPerPixel(zoom, centre.latitude);

  return Offset(
    (point.longitude - centre.longitude) *
        metresPerDegreeLon(centre.latitude) /
        scale,
    // Screen y grows downwards, latitude grows upwards.
    -(point.latitude - centre.latitude) * metresPerDegreeLat / scale,
  );
}

/// Which marker the player meant, tapping [offset] logical pixels from the
/// centre of a map centred on [centre].
///
/// A finger is not a pixel: [slopPx] is what makes a marker tappable at all,
/// and the nearest one inside it wins so that two markers on one street corner
/// do not become one unreachable marker. Thirty-two logical pixels is about a
/// fingertip on a phone, and a dot is drawn at seven.
MapMarker? markerAtOffset(
  List<MapMarker> markers,
  Offset offset, {
  required GeoPoint centre,
  required double zoom,
  double slopPx = 32,
}) {
  final scale = metresPerPixel(zoom, centre.latitude);
  final slopM = slopPx * scale;

  // Screen y grows downwards, latitude grows upwards.
  final at = GeoPoint(
    centre.latitude - offset.dy * scale / metresPerDegreeLat,
    centre.longitude + offset.dx * scale / metresPerDegreeLon(centre.latitude),
  );

  MapMarker? best;
  var bestDistance = slopM;
  for (final marker in markers) {
    final distance = marker.at.distanceTo(at);
    if (distance > bestDistance) continue;
    best = marker;
    bestDistance = distance;
  }
  return best;
}

/// Folds markers that sit on top of each other into one (§4.8).
///
/// How close two markers have to be to become one dot (§4.8).
///
/// Also what a tap on that dot lists: the pile it stands for is exactly the
/// rows this radius gathered, so the two numbers have to be the same one.
const double kClusterM = 25;

/// Only within [withinM] and only among the same kind: a pile of dropped kit
/// and a shop are two different answers to "what is that", and merging them
/// would say neither. The dot lands on the first of the group rather than on
/// the average of it, so a marker never drifts off the thing it stands for
/// into the middle of a road.
List<MapMarker> clusterMarkers(
  List<MapMarker> markers, {
  double withinM = kClusterM,
}) {
  final clustered = <MapMarker>[];
  final taken = List<bool>.filled(markers.length, false);

  for (var i = 0; i < markers.length; i++) {
    if (taken[i]) continue;
    final first = markers[i];

    // ⚠️ Never enemies. A pile of kit is one thing to pick up; two Walkers
    // are two things to shoot, and folding them into one dot with a "2" on it
    // takes away the only way to aim at either.
    if (first.kind == MarkerKind.enemy) {
      clustered.add(first);
      continue;
    }

    var count = first.count;
    for (var j = i + 1; j < markers.length; j++) {
      if (taken[j] || markers[j].kind != first.kind) continue;
      if (first.at.distanceTo(markers[j].at) > withinM) continue;

      taken[j] = true;
      count += markers[j].count;
    }

    clustered.add(count == first.count ? first : first.copyWith(count: count));
  }

  return clustered;
}

/// The reach rings worth drawing, given what is on the map.
///
/// Reach is symmetric — being within twenty-five metres of a shop is the shop
/// being within twenty-five metres of you — so one ring around the player says
/// exactly what a ring around every marker said, at a fraction of the cost.
/// Found on a phone: sixty-five rings redrawn through the platform channel on
/// every frame of a pinch stopped the game answering.
///
/// Widest first, so a tight ring is drawn over a loose one rather than under.
List<double> reachRingsOf(List<MapMarker> markers) {
  final rings = <double>{
    for (final marker in markers)
      // ⚠️ Never a shelter. Reach is symmetric — being within twenty-five
      // metres of a shop is the shop being within twenty-five metres of you —
      // but a *safe zone* is not reach. It is a piece of ground around a
      // building, and drawing it round the player instead put a fifty-metre
      // circle on their feet that walked about with them. See [zonesOf].
      if (marker.kind != MarkerKind.shelter) ?marker.reachM,
  }.toList()..sort((a, b) => b.compareTo(a));

  return rings;
}

/// The circles that belong to a place rather than to the player (§8.1).
///
/// A shelter's fifty metres is ground: the dead do not walk into it and the
/// player does not shoot out of it, whether or not anybody is standing there.
/// It has to be drawn where it is.
List<({GeoPoint at, double radiusM})> zonesOf(List<MapMarker> markers) => [
  for (final marker in markers)
    if (marker.kind == MarkerKind.shelter && marker.reachM != null)
      (at: marker.at, radiusM: marker.reachM!),
];

/// §12's colours for [MarkerAlert], as ARGB.
const Map<MarkerAlert, int> kAlertColours = {
  MarkerAlert.calm: 0xFF4E8A4A,
  MarkerAlert.searching: 0xFFE8B33A,
  MarkerAlert.hunting: 0xFFA82D17,
};

/// A sound the player made, spreading (§5.6.5).
///
/// One and a half seconds of circle, at the radius the noise actually carried
/// — so the answer to "what did I just wake up" is on the screen rather than
/// in a number nobody was shown. §5.6.2's amber rings on the ones that heard
/// it are the other half of the same sentence.
class NoiseWave {
  const NoiseWave({
    required this.at,
    required this.radiusM,
    required this.startedAt,
  });

  final GeoPoint at;
  final double radiusM;
  final DateTime startedAt;

  /// §5.6.5: about a second and a half of spreading.
  static const Duration spread = Duration(milliseconds: 1500);

  /// How far out it has got, 0–1, or null once it is over.
  double? progressAt(DateTime now) {
    final elapsed = now.difference(startedAt);
    if (elapsed.isNegative) return 0;
    if (elapsed >= spread) return null;

    return elapsed.inMilliseconds / spread.inMilliseconds;
  }
}

/// §10: which of §3.6's shapes a loot table earns.
///
/// Read off the table id rather than the OSM tag, because the table is what
/// actually decides what is inside — and what is inside is the whole reason
/// anybody walks there.
PlaceIcon placeIconFor(String? tableId) => switch (tableId) {
  'poi_pharmacy' || 'poi_hospital' => PlaceIcon.medical,
  'poi_military' => PlaceIcon.guarded,
  'poi_grocery' => PlaceIcon.food,
  'poi_hardware' ||
  'poi_industrial' ||
  'poi_warehouse' ||
  'proc_garage' => PlaceIcon.tools,
  'poi_weapons' || 'poi_sports' || 'proc_hunting_stand' => PlaceIcon.weapons,
  'poi_library' || 'poi_school' => PlaceIcon.books,
  'proc_abandoned_house' || 'proc_barn' || 'proc_shelter' => PlaceIcon.home,
  'proc_abandoned_car' => PlaceIcon.vehicle,
  'proc_waste' || 'proc_roadside' => PlaceIcon.waste,
  _ => PlaceIcon.home,
};
