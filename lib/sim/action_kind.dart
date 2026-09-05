/// What the player deliberately started, and what it costs (§2.1a.1, §4.7).
///
/// ⚠️ **This file is the half of `occupation.dart` that was actually used.**
/// The other half — `Occupation`, `OccupationKind`, `advanceOccupation`,
/// `startOccupation` — was a complete, tested model of long tasks that nothing
/// in the game ever started: `beginOccupation` had no caller outside its own
/// tests for the length of the project. Meanwhile the two facts it existed to
/// hold were already held elsewhere and better: the loop learns that hands are
/// busy through `setWorking` and `setActing`, the bench keeps its own clock
/// (§2.1a.3), and a build is paid for by standing on its site (§8.3).
///
/// Keeping it meant two records of one fact, which is the shape of defect this
/// project has spent months finding. So it is gone, and what a player actually
/// does — eat, drink, dress a wound — lives here under its own name.
library;

import 'action_pace.dart';

/// The short things a character does on purpose (§2.1a.1, §4.7).
///
/// Durations are the realistic ones from §4.7: seventy-five seconds for a
/// meal, ninety for a pressure dressing, sixteen minutes for stitches.
enum ActionKind {
  eating('jedzenie', Duration(seconds: 75)),
  drinking('picie', Duration(seconds: 25)),
  dressing('opatrunek uciskowy', Duration(seconds: 90)),
  tourniquet('staza', Duration(seconds: 45)),
  suturing('szycie rany', Duration(minutes: 16)),
  searching('przeszukanie', Duration(seconds: 45)),

  /// §4.6.1: one page, about seventy-six seconds of it.
  ///
  /// ⚠️ A page rather than a book, and that is the whole design. §4.6.1
  /// credits experience as it is read because a reward arriving only at the
  /// end of a forty-hour encyclopedia is many nights with no signal at all —
  /// so the unit of work is the unit of feedback, one page is one row on disk,
  /// and a process killed mid-sentence costs a minute rather than an evening.
  reading('lektura', Duration(seconds: 76)),
  reloading('przeładowanie', Duration(milliseconds: 3500)),
  shooting('strzał', Duration(milliseconds: 500));

  const ActionKind(this.label, this.baseDuration);

  final String label;
  final Duration baseDuration;

  /// Field actions need the app open and a good GPS signal (§2.1a.3); the rest
  /// can happen anywhere.
  bool get requiresPresence => switch (this) {
    ActionKind.searching || ActionKind.shooting || ActionKind.reloading => true,
    _ => false,
  };

  /// §2.1a.3: whether this goes on with the app shut.
  ///
  /// Only reading. Everything else here needs hands or a place, and §2.1a.3 is
  /// explicit that time nobody observed cannot be credited to either — but a
  /// book read in a shelter is the shelter occupation §2.1a names, and a night
  /// of it must survive the screen going off.
  bool get ticksWhileClosed => this == ActionKind.reading;

  /// §4.7, §10.2: what the character's feet do to this.
  ///
  /// ⚠️ **Eating and dressing a wound are slowed by walking, not cancelled by
  /// it.** They used to be cancelled — one step threw the whole meal away —
  /// which made the most ordinary thing in the game a thing you could only do
  /// by standing perfectly still in a street. §4.7 asks for hands, not for a
  /// statue.
  ///
  /// Searching is the opposite and stays that way: half a shop turned over
  /// from across the road is not a slower search, it is not a search.
  ActionPace get pace => switch (this) {
    ActionKind.eating ||
    ActionKind.drinking ||
    ActionKind.dressing ||
    ActionKind.tourniquet ||
    ActionKind.suturing => ActionPace.handsOn,

    ActionKind.searching ||
    ActionKind.reloading ||
    ActionKind.shooting => ActionPace.onTheSpot,

    // §2.1a.3: a book goes on being read with the phone face down.
    ActionKind.reading => ActionPace.unattended,
  };

  /// §4.7, §7.2.1: whether this is somebody working on a wound.
  ///
  /// The three that teach medicine. Eating and drinking are not treatment and
  /// searching is somebody else's skill — a single list, so the journal and
  /// the experience table cannot come to disagree about what a dressing is.
  bool get isTreatment =>
      this == ActionKind.dressing ||
      this == ActionKind.tourniquet ||
      this == ActionKind.suturing;

  /// §4.7: whether running ends this rather than pausing it.
  ///
  /// ⚠️ One exception, and it is a decision rather than a rule: sixteen
  /// minutes of suturing (§4.7) is not something anybody picks up again after
  /// sprinting away from a Brute with the needle still in. Everything else is
  /// kept and gone back to, exactly as §18.6's dismantling is.
  bool get ruinedByRunning => this == ActionKind.suturing;
}
