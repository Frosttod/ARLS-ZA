/// What the first-contact hints actually say, and where they are remembered.
///
/// The decision of *whether* a hint is owed belongs to [HintLog], which is pure
/// and tested on its own. This is the other half: the words, the database row,
/// and the anchor the fifty-metre rule is measured from.
///
/// ⚠️ **It lives here rather than in `main.dart` on purpose.** The entry point
/// has a size ratchet and a habit of absorbing anything with a `BuildContext`
/// in reach; six lines of wiring there and everything else here is the shape
/// that keeps it out.
library;

import 'package:flutter/foundation.dart' show ValueListenable;

import '../combat/hotspot.dart';
import '../data/db/database.dart';
import '../game/game_loop.dart';
import '../game/onboarding_hints.dart';
import '../l10n/app_localizations.dart';
import '../loot/loot_spawner.dart';
import '../map/geometry.dart';

/// The settings row the log is kept in. One key, because the log is one fact.
const String kHintsKey = 'onboarding.hints';

class HintNudger {
  HintNudger(
    this._db, {
    required this.say,
    required this.standingAt,
    required this.boxes,
    required this.zones,
  });

  final SaveDatabase _db;

  /// How a hint reaches the player: the same one line under the HUD every
  /// other message uses (§12). Not a dialog, and not a coach mark — a hint
  /// that stops the game is a hint the player closes without reading.
  final void Function(String) say;

  final ValueListenable<GeoPoint?> standingAt;
  final ValueListenable<List<LootBox>> boxes;
  final ValueListenable<List<Hotspot>> zones;

  HintLog _log = const HintLog();
  var _loaded = false;

  /// Where the player stood when the map hint went out. Session-only: if the
  /// app restarts before the first fifty metres, the walk hint simply waits for
  /// the next fifty. Persisting it would mean remembering a metre count that
  /// nobody will ever ask about again.
  GeoPoint? _anchor;

  Future<void> load() async {
    _log = HintLog.parse(await _db.readSetting(kHintsKey));
    _loaded = true;
  }

  /// Says whatever the current moment owes, through [say].
  ///
  /// Returns without touching the database when nothing is due, which is every
  /// tick after the first day.
  Future<void> nudge(L10n l10n, GameSnapshot snapshot) async {
    if (!_loaded) return;

    final now = snapshot.state.lastUpdate;
    final at = standingAt.value;
    final onMap = at != null;
    if (onMap && _anchor == null && _log.has(Hint.map)) _anchor = at;

    final anchor = _anchor;
    final due = _log.due(
      onMap: onMap,
      movedM: anchor == null || at == null ? 0 : anchor.distanceTo(at),
      lootInSight: boxes.value.isNotEmpty,
      zoneInSight: zones.value.isNotEmpty,
    );
    final dusks = _log.duskDue(now: now, dusk: snapshot.sky.dusk);
    if (due.isEmpty && !dusks) return;

    for (final hint in due) {
      say(hintText(hint, l10n));
      // §15.5: the fifty metres are counted from the map hint, so the anchor is
      // set the moment it goes out rather than at the first fix of the run.
      if (hint == Hint.map) _anchor = at;
    }
    if (dusks) say(l10n.hintDusk);

    _log = _log.take(due);
    if (dusks) _log = _log.saidDusk(now);
    await _db.writeSetting(kHintsKey, _log.wire);
  }

  /// §15.5: the pack is opened by the player, not noticed by a tick.
  Future<void> openedPack(L10n l10n) async {
    if (!_loaded || _log.has(Hint.pack)) return;

    say(hintText(Hint.pack, l10n));
    _log = _log.take(const [Hint.pack]);
    await _db.writeSetting(kHintsKey, _log.wire);
  }
}

String hintText(Hint hint, L10n l10n) => switch (hint) {
  Hint.map => l10n.hintMapTitle,
  Hint.walk => l10n.hintWalk,
  Hint.loot => l10n.hintLoot,
  Hint.pack => l10n.hintPack,
  Hint.zone => l10n.hintZone,
};
