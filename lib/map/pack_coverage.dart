/// Whether the player is still on the map they downloaded (§16.6).
///
/// Leaving the pack is not a failure — people travel — but it changes what the
/// game can honestly do. Without tiles there is no map to render, and §10 has
/// no POI to spawn loot from, so the run pauses rather than quietly generating
/// a world out of nothing.
///
/// The hard part is the edge. A player walking along a boundary crosses it
/// several times a minute, and a message that appears and disappears with each
/// step is worse than no message. Two defences:
///
/// * **Hysteresis.** Leaving is declared once the position is a margin *past*
///   the edge; coming back is declared only once it is a margin *inside* it.
/// * **Persistence.** The state has to hold for a while before it counts, so a
///   single wild fix cannot end a session.
library;

import 'region_pack.dart';

/// Where the player stands relative to the installed pack.
enum Coverage {
  /// Inside, with room to spare.
  inside,

  /// Past the edge, and it has held long enough to act on.
  outside,

  /// No pack installed at all. The first run, or one the storage cleaner ate.
  missing,
}

/// Tracks coverage across a session.
class PackCoverage {
  PackCoverage({
    this.bounds,
    this.marginM = 500,
    this.settleFor = const Duration(seconds: 30),
  });

  /// The extent of the installed pack, from the file's own header. Null when
  /// nothing is installed.
  final GeoBounds? bounds;

  /// How far past the edge counts as gone, and how far inside counts as back.
  /// Five hundred metres is several minutes of walking, so the state cannot
  /// flap; it is also well inside the distance at which missing tiles would be
  /// visible on screen.
  final double marginM;

  /// How long the new state has to hold. A single fix 2 km away is a GPS
  /// artefact, not a car journey.
  final Duration settleFor;

  Coverage _state = Coverage.inside;
  Coverage? _pending;
  DateTime? _pendingSince;

  Coverage get state => bounds == null ? Coverage.missing : _state;

  /// Reports a position and returns the coverage after it.
  Coverage update(double latitude, double longitude, DateTime at) {
    final extent = bounds;
    if (extent == null) return Coverage.missing;

    final outside = extent.metresOutside(latitude, longitude);
    final candidate = switch (_state) {
      // Already outside: only a position properly back inside brings us home.
      Coverage.outside =>
        outside == 0 && extent.inflated(-marginM).contains(latitude, longitude)
            ? Coverage.inside
            : Coverage.outside,
      // Inside: only a position properly past the edge counts as leaving.
      _ => outside > marginM ? Coverage.outside : Coverage.inside,
    };

    if (candidate == _state) {
      _pending = null;
      _pendingSince = null;
      return _state;
    }

    if (_pending != candidate) {
      _pending = candidate;
      _pendingSince = at;
      return _state;
    }

    if (at.difference(_pendingSince!) >= settleFor) {
      _state = candidate;
      _pending = null;
      _pendingSince = null;
    }
    return _state;
  }
}
