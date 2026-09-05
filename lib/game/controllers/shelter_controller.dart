/// The places this character has built, and what is going up (§8.3, §8.4).
///
/// One list, and it is the shortest controller in the game on purpose: a
/// shelter is a row on disk with a clock on it, and almost everything a player
/// *does* to one — starting it, cancelling it, demolishing a module — is a
/// question that has to be asked out loud before it is answered. Those live
/// where the words live.
///
/// What is here is the list, who owns it, and reading it back.
library;

import 'package:flutter/foundation.dart';

import '../../data/db/database.dart';
import '../../map/geometry.dart';
import '../../shelter/shelter.dart';
import '../../shelter/shelter_store.dart';

/// What one crediting pass did, and whether anybody was standing there for it.
class ShelterWork {
  const ShelterWork({
    required this.finished,
    required this.changed,
    required this.running,
    required this.onSite,
  });

  /// Modules that reached their level on this pass.
  final List<ShelterModule> finished;

  /// Whether the list moved enough to be worth re-reading.
  final bool changed;

  /// Whether anything is going up at all.
  final bool running;

  /// §2.1a.3: whether the player was on the site to be paid for it.
  final bool onSite;
}

class ShelterController extends ChangeNotifier {
  ShelterController(this._db);

  final SaveDatabase _db;

  /// ⚠️ Created here and never replaced, so a screen that took a reference to
  /// it at boot still has the right one an hour later.
  final ValueNotifier<List<Shelter>> shelters = ValueNotifier(const []);

  int? _profileId;

  void bind({required int profileId}) => _profileId = profileId;

  List<Shelter> get places => shelters.value;

  set places(List<Shelter> next) {
    shelters.value = next;
    notifyListeners();
  }

  // ------------------------------------------------------------- reading ---

  /// §8.2: the one place that is home, or null before there is one.
  Shelter? get home => shelters.value
      .where((place) => place.kind == ShelterKind.main)
      .firstOrNull;

  Shelter? byId(int id) =>
      shelters.value.where((place) => place.id == id).firstOrNull;

  /// §18.2: whether the shelves are within arm's reach right now.
  ///
  /// The main shelter's own site, not a camp's: §18.2 gives the shelves to a
  /// building, and a camp chest is reached by opening the camp.
  bool shelvesInReach(GeoPoint? at) {
    if (at == null) return false;

    return shelters.value.any(
      (place) => place.kind == ShelterKind.main && place.atSite(at),
    );
  }

  /// §2.1a: whether the player is standing somewhere their own things are.
  ///
  /// Any shelter or camp will do — making is something done where you keep
  /// your things, and a camp is one of those places (§8.5).
  bool atOwnPlace(GeoPoint? at, DateTime now) =>
      at != null && shelters.value.any((place) => place.coversAt(at, now));

  // ------------------------------------------------------------- writing ---

  /// §2.1a.3, §8.3: pays the hours into whatever is going up here.
  ///
  /// ⚠️ **Lived in `main.dart`, and belongs here**: it is a clock on a row
  /// this class already owns. What did *not* move is the talking — the caller
  /// still says the words, writes the journal and marks the practice, because
  /// those are things a player is told and this class has no language.
  ///
  /// Returns what finished on this pass, whether anybody was on site for it,
  /// and whether the table is worth re-reading.
  Future<ShelterWork> creditWork({
    required GeoPoint? at,
    required DateTime now,
    required Duration writeEvery,
  }) async {
    final places = [...shelters.value];
    final finished = <ShelterModule>[];
    var changed = false;
    var working = false;
    bool? onSiteFor;

    for (var i = 0; i < places.length; i++) {
      final place = places[i];
      if (place.buildLeft == null && place.buildingLeft == null) continue;
      if ((place.buildLeft ?? Duration.zero) <= Duration.zero &&
          (place.buildingLeft ?? Duration.zero) <= Duration.zero) {
        continue;
      }

      working = true;
      onSiteFor ??= at != null && place.atSite(at);

      // ⚠️ A row that has never been credited starts its clock, and does not
      // simply fall through. Found on a phone, twice over: a shelter carried
      // across the migration that added this column had no stamp, the gap
      // came out as nothing, and nothing was ever written — so the gap stayed
      // nothing and the build never moved again. A missing stamp is "start
      // counting", not "count nothing".
      final since = place.workedAt;
      if (since == null) {
        final started = place.worked(Duration.zero, at: now);
        places[i] = started;
        shelters.value = [...places];
        await ShelterStore(_db).saveWork(started);
        continue;
      }

      final gap = now.isAfter(since) ? now.difference(since) : Duration.zero;
      final onSite = at != null && place.atSite(at);

      // In chunks rather than every tick: three hours of one-second writes is
      // ten thousand of them for a bar nobody is watching. The stamp only
      // moves when something is written, so nothing is lost by waiting.
      if (gap < writeEvery) continue;

      // The stamp moves whether or not anything was earned. Without that, a
      // walk to the shops and back would bank the whole walk.
      final worked = place.worked(onSite ? gap : Duration.zero, at: now);
      places[i] = worked;
      shelters.value = [...places];
      await ShelterStore(_db).saveWork(worked);

      // Only a finished job is worth re-reading the table for: that is when a
      // module turns into a level and the row has to be settled.
      final up =
          place.building != null &&
          (worked.buildingLeft ?? Duration.zero) <= Duration.zero;
      if (up) finished.add(place.building!);

      changed =
          changed || (place.isReadyAt(now) != worked.isReadyAt(now)) || up;
    }

    return ShelterWork(
      finished: finished,
      changed: changed,
      running: working,
      onSite: onSiteFor ?? false,
    );
  }

  Future<List<Shelter>> reload(DateTime now) async {
    final profileId = _profileId;
    if (profileId == null) return const [];

    final places = await ShelterStore(_db).load(profileId, now);

    // ⚠️ A copy, because the caller hands the same list to the game loop and
    // a list two owners can both edit is a list neither of them owns.
    this.places = [...places];
    return places;
  }

  /// Puts [place] back in the list in place of the one with its id.
  ///
  /// By id rather than by position: a reload can land between a build being
  /// worked on and the work being written down.
  /// §2.1a, §8.3: puts the work down here, or picks it back up.
  ///
  /// ⚠️ Only the flag moves. The materials stay in the walls and the hours
  /// already spent stay on the row — that is the whole difference between this
  /// and cancelling, which hands the timber back and throws the hours away.
  ///
  /// [now] restarts the crediting clock on the way back, so the stretch spent
  /// doing something else is not paid in as work.
  Future<void> setPaused(Shelter place, DateTime now) =>
      ShelterStore(_db).setPaused(place.id, paused: !place.paused, now: now);

  void replace(Shelter place) {
    places = [
      for (final other in shelters.value)
        if (other.id == place.id) place else other,
    ];
  }

  @override
  void dispose() {
    shelters.dispose();
    super.dispose();
  }
}
