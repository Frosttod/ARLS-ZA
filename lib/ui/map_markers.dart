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

import 'dart:math' as math;
import 'dart:ui' show Offset;

import '../l10n/app_localizations.dart';
import '../map/geometry.dart';
import '../combat/enemy.dart';
import '../combat/hotspot.dart';
import 'hotspot_sheet.dart' show hotspotMarkerId;
import 'remains_sheet.dart' show remainsMarkerId;
import '../combat/noise.dart';
import '../combat/remains.dart';
import '../loot/dropped_items.dart';
import '../loot/loot_spawner.dart';
import '../loot/loot_table.dart';
import '../loot/search.dart';
import '../shelter/shelter.dart';

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

  /// §6.5.6: the circle that grows on its own.
  ///
  /// ⚠️ Not a dot with a ring round it — the *circle* is the marker. A hotspot
  /// has no body to point at: what the player needs to know is where the
  /// ground turns hostile and how far it reaches, and that is an area rather
  /// than a place.
  hotspot,
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
/// What the map's markers are made of, for deciding whether to make them again.
///
/// ⚠️ Every field is a value replaced wholesale when it changes, so reference
/// equality is exact: two of these are equal precisely when nothing the
/// markers are drawn from has moved. The same rule `_BenchInputs` lives by.
///
/// [revealed] is a count rather than the set, because the set is mutated in
/// place — §10.2.1 adds to it when reconnaissance turns something up — and a
/// reference comparison would never notice.
class MarkerInputs {
  const MarkerInputs({
    required this.boxes,
    required this.dropped,
    required this.remains,
    required this.shelters,
    required this.hotspots,
    required this.at,
    required this.enemies,
    required this.revealed,
    required this.shot,
  });

  final List<LootBox> boxes;
  final List<DroppedItem> dropped;
  final List<Remains> remains;
  final List<Shelter> shelters;

  /// §6.5.6: the circles. ⚠️ Left out when hotspots landed, which would have
  /// left the cache holding a map with no hotspot on it until something else
  /// happened to move — and a hotspot appearing is exactly the moment a player
  /// needs the map redrawn.
  final List<Hotspot> hotspots;

  final GeoPoint? at;
  final List<Enemy> enemies;
  final int revealed;
  final NoiseEvent? shot;

  @override
  bool operator ==(Object other) =>
      other is MarkerInputs &&
      identical(other.boxes, boxes) &&
      identical(other.dropped, dropped) &&
      identical(other.remains, remains) &&
      identical(other.shelters, shelters) &&
      identical(other.hotspots, hotspots) &&
      identical(other.at, at) &&
      identical(other.enemies, enemies) &&
      other.revealed == revealed &&
      identical(other.shot, shot);

  @override
  int get hashCode => Object.hash(
    identityHashCode(boxes),
    identityHashCode(dropped),
    identityHashCode(remains),
    identityHashCode(shelters),
    identityHashCode(hotspots),
    identityHashCode(at),
    identityHashCode(enemies),
    revealed,
    identityHashCode(shot),
  );
}

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
    this.spent = false,
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

  /// §10.2.1: turned over already, and drawn in grey.
  ///
  /// The dot stays because "I have been here" is worth knowing — it is the
  /// difference between a street the player has worked and one they have not.
  /// It is not a place to search: [spent] is what keeps the search panel from
  /// offering an empty shop, and what takes the colour off the icon.
  final bool spent;

  MapMarker copyWith({
    GeoPoint? at,
    String? label,
    double? reachM,
    int? count,
    double? headingDeg,
    MarkerAlert? alert,
    bool? spent,
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
    spent: spent ?? this.spent,
  );
}

/// The colour code of §3.6, as ARGB values.
///
/// Kept out of the widget so a test can assert the code rather than a shade of
/// paint chosen in a layout file.
/// §10.2.1, §12: what a place the player has already emptied is drawn in.
///
/// Grey and nothing else — not a faded version of the kind's own colour,
/// because a dimmer red is still red and §3.6's hues each mean something. A
/// place with nothing in it belongs to no category; it is a note the player
/// left themselves.
const int kSpentColour = 0xFF6B726E;

const Map<MarkerKind, int> kMarkerColours = {
  MarkerKind.enemy: 0xFFD93A2B,
  MarkerKind.loot: 0xFFE8B33A,
  MarkerKind.dropped: 0xFF8C8F92,
  MarkerKind.remains: 0xFFE6E1D6,
  MarkerKind.shelter: 0xFF3A7BD9,

  // §6.5.6: deep red, a shade past the enemy's. The dots inside it are the
  // enemy colour, so the ground has to read as related and darker — the same
  // thing, but the place rather than the body.
  MarkerKind.hotspot: 0xFF8C1F14,
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

  // ⚠️ Small on purpose: the circle is the marker (§6.5.6), and a fat dot at
  // its centre would compete with the bodies actually standing in it.
  MarkerKind.hotspot: 4,
};

/// §3.6: how far the camera leans back from straight down.
///
/// Zero is the map every phone draws: a plan, seen from directly above.
/// Anything above that is a city with height in it — the buildings stand up,
/// the streets run away towards the top of the screen, and a player can see
/// the shape of the block they are walking into rather than its footprint.
///
/// ⚠️ Everything the game paints on the map — dots, rings, cones, glyphs,
/// noise waves — is painted by Flutter, not by MapLibre (§3.6). Two projections
/// that disagree by a few pixels put every marker off its own street, so this
/// is the one place the perspective is worked out and both directions of it
/// live side by side.
class MapTilt {
  const MapTilt({required this.degrees, required this.viewportHeightPx});

  /// The plan view, and the maths every version of this game had until now.
  static const flat = MapTilt(degrees: 0, viewportHeightPx: 0);

  final double degrees;

  /// How tall the map is on screen, in logical pixels.
  ///
  /// Needed because perspective has a scale: how strongly a tilt foreshortens
  /// depends on how far the camera stands from the ground, and MapLibre sets
  /// that from the viewport rather than from a constant.
  final double viewportHeightPx;

  bool get isFlat => degrees.abs() < 0.01 || viewportHeightPx <= 0;

  double get radians => degrees * math.pi / 180;

  /// How far the camera sits from the point it is looking at, in pixels.
  ///
  /// MapLibre's own figure: `0.5 / tan(fov / 2) × height`, with the default
  /// field of view of 0.6435 rad. That works out at exactly one and a half
  /// screens, which is the number below — written as the division it comes
  /// from so it stays true if the field of view is ever changed.
  double get cameraDistancePx =>
      0.5 / math.tan(kMapFovRad / 2) * viewportHeightPx;
}

/// MapLibre's default field of view, in radians.
const double kMapFovRad = 0.6435011087932844;

/// Where a point sits on screen, in logical pixels from the middle.
///
/// The inverse of [markerAtOffset], and the reason both live here: a badge
/// drawn a few pixels off the dot it counts is worse than no badge.
///
/// With [tilt] flat this is the plain thing it always was — metres east and
/// north, divided by the scale. With a tilt it is a perspective projection of
/// the ground plane, derived rather than guessed:
///
///     right   = x
///     up      = y · cos θ
///     forward = D + y · sin θ
///
/// for a ground point `x` east and `y` north of the centre, a camera distance
/// `D`, and a pitch `θ`. Dividing the first two by the third is the whole of
/// it. At θ = 0 the forward term is just `D`, the division cancels, and what
/// is left is the flat formula — which is what keeps the two from drifting
/// apart as one of them is edited.
Offset offsetOf(
  GeoPoint point, {
  required GeoPoint centre,
  required double zoom,
  MapTilt tilt = MapTilt.flat,
}) {
  final scale = metresPerPixel(zoom, centre.latitude);

  final east =
      (point.longitude - centre.longitude) *
      metresPerDegreeLon(centre.latitude) /
      scale;
  final north = (point.latitude - centre.latitude) * metresPerDegreeLat / scale;

  // Screen y grows downwards, latitude grows upwards.
  if (tilt.isFlat) return Offset(east, -north);

  final distance = tilt.cameraDistancePx;
  final forward = distance + north * math.sin(tilt.radians);

  // Behind the camera, or on the horizon. Nothing sensible can be drawn for
  // it, so it is sent far enough off screen to be clipped rather than folded
  // back into view as a ghost on the wrong side of the player.
  if (forward <= 1) return const Offset(0, -1e6);

  return Offset(
    east * distance / forward,
    -north * math.cos(tilt.radians) * distance / forward,
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
  MapTilt tilt = MapTilt.flat,
}) {
  final scale = metresPerPixel(zoom, centre.latitude);

  // ⚠️ The slop is measured on screen and spent on the ground, and under a
  // tilt those are not the same distance. A finger near the top of a tilted
  // map covers far more ground than the same finger at the bottom, so the
  // circle is grown by however much this particular point was shrunk —
  // otherwise the far half of the map is untappable and the near half has
  // markers stealing each other's taps.
  final at = _groundAt(offset, centre: centre, zoom: zoom, tilt: tilt);
  final spread = tilt.isFlat
      ? 1.0
      : _foreshortening(at, centre: centre, zoom: zoom, tilt: tilt);
  final slopM = slopPx * scale * spread;

  MapMarker? best;
  var bestDistance = slopM;
  for (final marker in markers) {
    final distance = marker.at.distanceTo(at);
    if (distance > bestDistance) continue;
    best = marker;
    bestDistance = distance;
  }
  if (best != null) return best;

  // ⚠️ §6.5.6: a hotspot is an **area**, and its dot is four pixels at the
  // middle of a circle up to two hundred metres across. Nothing else on this
  // map works that way, so nothing else needed this — but a ring the player
  // cannot tap is a ring that cannot explain itself, and §6.5.4's operation is
  // the one thing in the game that has to be explained rather than compared.
  //
  // Last, deliberately. Anything standing *in* the circle wins the tap: a
  // Walker three metres from a finger is a more specific answer than the
  // ground it is standing on.
  for (final marker in markers) {
    if (marker.kind != MarkerKind.hotspot) continue;

    final radius = marker.reachM;
    if (radius != null && marker.at.distanceTo(at) <= radius) return marker;
  }

  return null;
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

    // ⚠️ Never enemies, and never dropped kit. Two Walkers are two things to
    // shoot, and folding them into one dot with a "2" on it takes away the
    // only way to aim at either. §10.2 scatters a haul over a metre to three
    // for the same reason: a dot standing for fourteen things says where none
    // of them is, and the walk to each of them is the game.
    if (first.kind == MarkerKind.enemy || first.kind == MarkerKind.dropped) {
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
/// ⚠️ Empty, and it used to be the whole story.
///
/// The argument for rings around the player was symmetry: being within
/// twenty-five metres of a shop is the shop being within twenty-five metres of
/// you, so one ring said what sixty-five said and cost a fraction. That held
/// exactly as long as every place had the *same* reach.
///
/// §10.2 now gives a bin thirty metres and a supermarket fifty, because a
/// building's door is not where the map puts its dot and a shop behind a fence
/// was unreachable rather than awkward. With two radii a ring on the player's
/// feet cannot say which place it belongs to — so the circles moved to the
/// places, where they answer "can I open *that* one" instead. See [zonesOf].
List<double> reachRingsOf(List<MapMarker> markers) => const [];

/// §10.2: how near a place has to be before its reach is worth drawing.
///
/// ⚠️ A circle per place is honest and, at any distance, a smear. Fifteen
/// active boxes each with a ring turns a zoomed-out map into overlapping
/// bubbles that say nothing — the question a reach ring answers is "can I open
/// *this* one", and that is only ever asked about somewhere the player is
/// nearly at. Beyond this the dot alone is the answer.
const double kReachRingVisibleM = 75;

/// §6.2: and how near something has to be before its eyes are worth drawing.
///
/// Twice the reach ring, because this one is a warning rather than an
/// invitation: what a player wants to know is how close they can get before it
/// notices, and that decision is made well before they are on top of it.
const double kSightRingVisibleM = 150;

/// The circles that belong to a place rather than to the player (§8.1).
///
/// A shelter's fifty metres is ground: the dead do not walk into it and the
/// player does not shoot out of it, whether or not anybody is standing there.
/// It has to be drawn where it is.
/// ⚠️ Each circle says which kind it is, because they mean opposite things.
/// A reach ring is an invitation — step inside and you can open this. An
/// enemy's sight is the reverse: step inside and it can see you. Drawn in one
/// colour, the second reads as the first, which is the worst possible way to
/// be wrong about a Walker.
List<({GeoPoint at, double radiusM, bool danger})> zonesOf(
  List<MapMarker> markers,
) => [
  for (final marker in markers)
    if (marker.reachM != null)
      (
        at: marker.at,
        radiusM: marker.reachM!,
        // ⚠️ §6.5.6's circle is the strongest warning on the map and would
        // otherwise be drawn as an *invitation* — the same colour as a shop
        // you can reach. Being wrong about that one is being wrong about the
        // only area in the game that gets harder while you look at it.
        danger:
            marker.kind == MarkerKind.enemy ||
            marker.kind == MarkerKind.hotspot,
      ),
];

/// The ground point under a screen offset — the inverse of [offsetOf].
///
/// Solved rather than searched for. Writing the forward projection out and
/// rearranging for the northing gives
///
///     y = −sy · D / (D · cos θ + sy · sin θ)
///
/// and the easting falls out of it, so a tap costs the same as a draw.
GeoPoint _groundAt(
  Offset offset, {
  required GeoPoint centre,
  required double zoom,
  required MapTilt tilt,
}) {
  final scale = metresPerPixel(zoom, centre.latitude);

  var east = offset.dx;
  var north = -offset.dy;

  if (!tilt.isFlat) {
    final distance = tilt.cameraDistancePx;
    final denominator =
        distance * math.cos(tilt.radians) + offset.dy * math.sin(tilt.radians);

    // Above the horizon: there is no ground under that pixel at all.
    if (denominator.abs() < 1) return centre;

    north = -offset.dy * distance / denominator;
    east = offset.dx * (distance + north * math.sin(tilt.radians)) / distance;
  }

  // Screen y grows downwards, latitude grows upwards.
  return GeoPoint(
    centre.latitude + north * scale / metresPerDegreeLat,
    centre.longitude + east * scale / metresPerDegreeLon(centre.latitude),
  );
}

/// How many metres one screen pixel is worth at [at], as a multiple of what it
/// is worth at the centre.
///
/// One at the middle of the screen, more towards the top, less towards the
/// bottom — which is what perspective is.
double _foreshortening(
  GeoPoint at, {
  required GeoPoint centre,
  required double zoom,
  required MapTilt tilt,
}) {
  final scale = metresPerPixel(zoom, centre.latitude);
  final north = (at.latitude - centre.latitude) * metresPerDegreeLat / scale;
  final distance = tilt.cameraDistancePx;

  final forward = distance + north * math.sin(tilt.radians);
  if (forward <= 1) return 1;

  return forward / distance;
}

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
/// §5.6.5: zdarzenie hałasowe jako fala do narysowania, albo null.
///
/// Tutaj, bo zamiana [NoiseEvent] na [NoiseWave] jest faktem o fali, a nie o
/// ekranie: to samo zdarzenie rysuje się tak samo, ktokolwiek o nie pyta.
NoiseWave? waveOf(NoiseEvent? open) => open == null
    ? null
    : NoiseWave(
        at: open.at,
        radiusM: open.radiusM,
        startedAt: open.startedAt.toLocal(),
      );

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
/// What a place is called, when OpenStreetMap did not name it (§3.6).
///
/// ⚠️ Every loot place used to read "Skrzynia" — one word for a pharmacy, a
/// wheelie bin and an abandoned car alike. Reported from a walk, and it was
/// worse than untidy: the whole point of §3.6's icons is that a player decides
/// which errand is worth the walk, and a panel that says "crate" while the map
/// shows a car takes that decision back off them.
///
/// Named tables keep OSM's own name where there is one; this is the fallback,
/// which for the generated places of §10.1 is the only name they will ever
/// have.
String placeName(L10n l10n, String? tableId) => switch (tableId) {
  'poi_pharmacy' => l10n.placePharmacy,
  'poi_hardware' => l10n.placeHardware,
  'poi_grocery' => l10n.placeGrocery,
  'poi_sports' => l10n.placeSports,
  'poi_weapons' => l10n.placeWeapons,
  'poi_library' => l10n.placeLibrary,
  'poi_industrial' => l10n.placeIndustrial,
  'poi_hospital' => l10n.placeHospital,
  'poi_military' => l10n.placeMilitary,
  'poi_school' => l10n.placeSchool,
  'poi_warehouse' => l10n.placeWarehouse,
  'proc_abandoned_car' => l10n.placeCar,
  'proc_abandoned_house' => l10n.placeHouse,
  'proc_barn' => l10n.placeBarn,
  'proc_garage' => l10n.placeGarage,
  'proc_waste' => l10n.placeWaste,
  'proc_shelter' => l10n.placePicnic,
  'proc_hunting_stand' => l10n.placeHuntingStand,
  'proc_water_point' => l10n.placeWaterPoint,
  'proc_roadside' => l10n.placeRoadside,
  'proc_ambulance' => l10n.placeAmbulance,
  'proc_police_car' => l10n.placePoliceCar,

  // A crate is what is left when nothing else fits, which is the one place
  // the old word was ever right.
  _ => l10n.mapMarkerLoot,
};

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

/// §3.6: how far the map leans back, everywhere it is drawn.
///
/// One number, in one place. The camera is given it, the markers are drawn
/// with it, and taps are read back through it — three things that have to
/// agree to the pixel, so none of them gets to hold its own copy.
///
/// ⚠️ Zero, and it was forty-five for two days. A tilted map over extruded
/// buildings stuttered on a phone, and the map is this game's whole
/// interface — it is held in one hand while walking, and smooth matters more
/// than tall. [MapTilt] and its arithmetic stay: they are tested, they cost
/// nothing at zero (the perspective terms cancel and the flat formula is what
/// is left), and this is one number away from coming back.
const double kMapTiltDeg = 0;

/// The tilt for a map [viewportHeightPx] logical pixels tall.
MapTilt mapTilt(double viewportHeightPx) =>
    MapTilt(degrees: kMapTiltDeg, viewportHeightPx: viewportHeightPx);

/// §3.6: everything that goes on the map, in one pass.
///
/// ⚠️ A rule rather than a widget concern. Which dots exist, what they are
/// called and how far their rings reach comes out of §3.6, §10.2, §6.2 and
/// §6.5.6 — none of which is about how a canvas is painted, and all of which
/// was being decided inside the screen that paints it.
///
/// Everything it needs arrives explicitly. The list is cached against
/// [MarkerInputs] by the caller, and a hidden dependency is a cache that goes
/// stale without anybody noticing.
List<MapMarker> markersFrom({
  required L10n l10n,
  required DateTime now,
  required GeoPoint? here,
  required List<LootBox> boxes,
  required List<Enemy> enemies,
  required List<Shelter> shelters,
  required List<Hotspot> hotspots,
  required List<Remains> remains,
  required List<DroppedItem> dropped,
  required bool Function(LootBox box) isVisible,
  required PlaceSize Function(LootBox box) sizeOf,
  required double Function(GeoPoint at) pileReachM,
}) {
  /// §10.2: the reach ring, but only once the place is nearly underfoot.
  ///
  /// A circle per place is honest and, at any distance, a smear — fifteen
  /// of them overlapping say nothing. The question a ring answers is "can I
  /// open *this* one", and that is only asked about somewhere the player is
  /// nearly at.
  double? ringFor(GeoPoint at, double radiusM, double visibleWithinM) {
    if (here == null) return null;
    return at.distanceTo(here) <= visibleWithinM ? radiusM : null;
  }

  return [
    // §10.2.1: what is there, and what was there. A place the player
    // emptied keeps its dot in grey for a week — "I have been here" is the
    // difference between a street they have worked and one they have not,
    // and it costs nothing to say.
    for (final box in boxes)
      if (box.isKnownAt(now) && isVisible(box))
        MapMarker(
          id: box.poiId,
          kind: MarkerKind.loot,
          at: box.position,
          spent: !box.isActiveAt(now),
          // ⚠️ OSM's name where there is one, and what the place *is* where
          // there is not. Everything generated by §10.1 has no name at all,
          // so every car and every bin read "Skrzynia" — on a map whose
          // icons exist precisely so a player can tell them apart.
          label: box.name ?? placeName(l10n, box.tableId),
          // §10.2: how close is close enough to search *this* place.
          // Judging thirty or fifty metres by eye on a map that zooms is
          // guesswork, and the two are now different numbers.
          reachM: ringFor(
            box.position,
            searchReachFor(sizeOf(box)),
            kReachRingVisibleM,
          ),
          // §3.6: what kind of place it is. A dot that only says "something
          // to search" sends a player three hundred metres to a florist —
          // the decision they are making is which errand is worth the walk.
          icon: placeIconFor(box.tableId),
        ),

    // §3.6: red, and only what is near enough to be part of the fight
    // (§5.5.6). Seeing every Walker in the district would answer the one
    // question §7's Reconnaissance is there to ask.
    // ⚠️ The last place the player was, never a default of nought — an
    // island off Africa is further than the forget radius from everything,
    // so a single fix without a position wiped every enemy off the map.
    for (final enemy in enemies)
      MapMarker(
        id: enemy.id,
        kind: MarkerKind.enemy,
        at: enemy.position,
        // §6.2: which way it is looking, and now that is exactly what it
        // means — the wedge on the map is the cone [seesPlayer] asks about.
        // Standing outside it is the whole of the approach, so the picture and
        // the rule are one number (`kFieldOfViewDeg`).
        headingDeg: enemy.headingDeg,
        // §6.2: what it can see, drawn only once it is near enough for that
        // to be a decision. The question is how close a player can get
        // before it notices, and it is answered well before they are on
        // top of it — so this ring shows twice as far out as a reach ring.
        reachM: ringFor(enemy.position, enemy.sightM, kSightRingVisibleM),
        alert: switch (enemy.state) {
          EnemyState.chase || EnemyState.spent => MarkerAlert.hunting,
          EnemyState.alert => MarkerAlert.searching,
          EnemyState.idle || EnemyState.returning => MarkerAlert.calm,
        },
      ),

    // §3.6: blue, and there is only ever one of them plus the camps.
    for (final place in shelters)
      MapMarker(
        id: 'shelter.${place.id}',
        kind: MarkerKind.shelter,
        at: place.position,
        reachM: place.kind.safeRadiusM,
        icon: PlaceIcon.home,
      ),

    // §6.5.6: the circle *is* the marker. A hotspot has no body to point
    // at — what a player needs is where the ground turns hostile and how
    // far that reaches, which is an area rather than a place.
    for (final fire in hotspots)
      MapMarker(
        id: hotspotMarkerId(fire),
        kind: MarkerKind.hotspot,
        at: fire.centre,
        reachM: fire.radiusM,
        label: l10n.hotspotLevel(fire.level),
      ),

    // §10.3: bone white, with a skull on it. Stays until it is not worth
    // walking back to.
    for (final body in remains)
      MapMarker(
        id: remainsMarkerId(body),
        kind: MarkerKind.remains,
        at: body.position,
        reachM: kStillnessM,
      ),

    // §4.8: grey, and gone after a day.
    for (final item in dropped)
      MapMarker(
        id: 'dropped.${item.id}',
        kind: MarkerKind.dropped,
        at: item.position,
        // §4.8: a pile the player dropped is picked up from arm's reach.
        //
        // ⚠️ But §10.2 gives a shop fifty metres *because its door is not
        // where the dot is*, and a search drops what it found at the dot.
        // Drawing a fifteen-metre ring round that pile drew a promise the
        // pickup rule does not make — reported from a school, where the
        // find could be taken but the ring said it could not.
        reachM: pileReachM(item.position),
      ),
  ];
}
