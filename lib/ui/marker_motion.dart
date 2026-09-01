/// Making a one-second simulation look like a moving world (§3.6).
///
/// The tick runs at 1 Hz and the position source at 0,2 Hz on a walk, so
/// everything the map knows arrives in steps: a Walker at four kilometres an
/// hour jumps a metre at a time, a Runner at thirty jumps eight, and the map
/// itself slides five seconds of pavement whenever a fix lands. Nothing is
/// wrong with the simulation — it is the drawing that is telling the truth too
/// literally.
///
/// So the marker layer draws where a thing *is on its way to*, not where it
/// last was reported: each new position starts a glide from wherever the
/// marker is currently painted, and the painter asks for a position by clock
/// time rather than by index.
///
/// ⚠️ This is a lie, and a bounded one. Everything drawn here is up to one
/// glide behind what the simulation believes. Nothing in the game measures
/// anything from these coordinates — distance, reach, hit chance and the
/// safe zone all read the simulation directly (§5.2, §8.1) — so the lie stays
/// on the glass where it belongs.
library;

import '../map/geometry.dart';
import 'map_markers.dart';

/// How long a marker takes to reach a newly reported position.
///
/// One second, which is the tick. Matching the interval rather than choosing a
/// figure means the glide finishes exactly as the next one is reported: any
/// shorter and it arrives early and sits still, any longer and it never
/// catches up.
const Duration kMarkerGlide = Duration(seconds: 1);

/// How often the marker layer is redrawn while anything is moving.
///
/// ⚠️ Thirty, not the display rate. The ticker driving this runs at 90 or 120
/// Hz on the phones §3.3's high-refresh mode asks for, and repainting
/// sixty-five markers that often was most of what made the map stutter under a
/// thumb. At walking pace half of thirty of a second is under a metre — no eye
/// on a phone at arm's length can tell — and the frames go to the tiles, which
/// is what the player is actually reading.
const int kMarkerFps = 30;

/// §3.3, §6.1a: jak blisko coś musi być, żeby płynność przestała być luksusem.
///
/// ⚠️ **Poślizg chodził tylko poza trybem oszczędnym, a tryb oszczędny włącza
/// się przy słabej baterii — czyli pod koniec każdej dłuższej wyprawy.** Wtedy
/// markery zaczynały skakać raz na sekundę i dokładnie wtedy, kiedy z ruchu
/// przeciwnika odczytuje się, czy zdąży się przejść.
///
/// Siedemdziesiąt pięć metrów, bo tyle wynosi najdłuższy zasięg wzroku w grze
/// (Skakun, §6.2): wewnątrz tego kręgu wszystko, co widać, może już iść po
/// gracza. Zgłoszone z terenu jako „animacja ruchu musi być płynniejsza".
const double kSmoothWithinM = 75;

class _Leg {
  const _Leg({required this.from, required this.to, required this.startedAt});

  final GeoPoint from;
  final GeoPoint to;
  final DateTime startedAt;
}

/// Where each marker should be drawn right now.
class MarkerMotion {
  MarkerMotion({this.glide = kMarkerGlide});

  final Duration glide;
  final Map<String, _Leg> _legs = {};

  /// Takes a fresh set of positions and starts a glide for anything that moved.
  ///
  /// ⚠️ A new leg starts from where the marker is *painted*, not from where it
  /// was last reported. A thing whose position changes again mid-glide would
  /// otherwise snap back to the last reported point and set off again — which
  /// looks worse than not interpolating at all.
  void update(List<MapMarker> markers, DateTime now) {
    final seen = <String>{};

    for (final marker in markers) {
      seen.add(marker.id);
      final leg = _legs[marker.id];

      if (leg == null) {
        // First sight: no glide. Something appearing has nowhere to come from,
        // and sliding it in from an old position would invent a journey.
        _legs[marker.id] = _Leg(from: marker.at, to: marker.at, startedAt: now);
        continue;
      }

      if (_sameSpot(leg.to, marker.at)) continue;

      _legs[marker.id] = _Leg(
        from: _at(leg, now),
        to: marker.at,
        startedAt: now,
      );
    }

    _legs.removeWhere((id, _) => !seen.contains(id));
  }

  /// Where [id] is at [now], or null if nothing is tracking it.
  GeoPoint? positionAt(String id, DateTime now) {
    final leg = _legs[id];
    return leg == null ? null : _at(leg, now);
  }

  /// Whether anything is still on its way, and therefore worth a frame.
  ///
  /// What decides between repainting every frame and repainting when the data
  /// changes — a still street costs nothing.
  bool movingAt(DateTime now) {
    for (final leg in _legs.values) {
      if (_sameSpot(leg.from, leg.to)) continue;
      if (now.difference(leg.startedAt) < glide) return true;
    }
    return false;
  }

  void clear() => _legs.clear();

  GeoPoint _at(_Leg leg, DateTime now) {
    // Most markers are standing still on most frames — a loot box never moves
    // at all. Answering those without arithmetic is the difference between a
    // per-frame layer that costs something and one that does not.
    if (glide <= Duration.zero || _sameSpot(leg.from, leg.to)) return leg.to;

    final elapsed = now.difference(leg.startedAt);
    if (elapsed <= Duration.zero) return leg.from;
    if (elapsed >= glide) return leg.to;

    final t = elapsed.inMicroseconds / glide.inMicroseconds;

    // Linear, on degrees. Over one second of walking — or eight metres of
    // sprint — the difference between this and a great-circle path is far
    // below one pixel.
    return GeoPoint(
      leg.from.latitude + (leg.to.latitude - leg.from.latitude) * t,
      leg.from.longitude + (leg.to.longitude - leg.from.longitude) * t,
    );
  }

  /// Below this two positions are the same position.
  ///
  /// About a centimetre. Guards against restarting a glide on floating-point
  /// noise, which would keep the whole layer repainting over nothing.
  static bool _sameSpot(GeoPoint a, GeoPoint b) =>
      (a.latitude - b.latitude).abs() < 1e-7 &&
      (a.longitude - b.longitude).abs() < 1e-7;
}
