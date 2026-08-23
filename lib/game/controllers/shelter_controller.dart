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
