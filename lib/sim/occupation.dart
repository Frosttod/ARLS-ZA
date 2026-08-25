/// One occupation at a time (design doc §2.1a).
///
/// The character cannot sleep, read and build at once. That is a realism
/// constraint, but far more importantly it is **the main mechanism of the
/// game's time economy**: without it every shelter system would run in
/// parallel and none of them would have a cost.
///
/// Three categories, and the difference between them is what ticks when:
///
/// | category   | examples                            | rule                          |
/// | ---------- | ----------------------------------- | ----------------------------- |
/// | occupation | sleep, reading, building, crafting  | one at a time; starting a new one cancels the old, progress is kept |
/// | action     | eating, drinking, dressing a wound  | suspends the occupation, which resumes afterwards |
/// | background | metabolism, bleeding, hotspot growth | always, independent of everything |
library;

import 'action_pace.dart';

/// What the character is doing. One at a time (§2.1a.1).
enum OccupationKind {
  /// Default state, not a choice. When the conditions of §2.5.1 hold and
  /// nothing else is running, the character sleeps.
  sleep('sen', isDefault: true),

  reading('lektura'),
  building('budowa'),
  crafting('wytwarzanie'),
  repairing('naprawa'),
  recycling('recykling'),
  reloadingAmmunition('elaboracja'),

  /// Nothing in particular — awake, outdoors, walking.
  idle('bezczynność', isDefault: true);

  const OccupationKind(this.label, {this.isDefault = false});

  final String label;

  /// Default states are entered automatically rather than chosen.
  final bool isDefault;

  /// §2.1a.3: what an occupation's clock does.
  ///
  /// Everything here that ticks with the app closed is [ActionPace.unattended]
  /// by definition — the character set it going and walked away. Idle is not
  /// an action and has no clock, so it gets the same answer and nobody asks.
  ActionPace get pace => ActionPace.unattended;

  /// Shelter occupations tick with the app closed, as long as the character
  /// stays in the zone (§2.1a.3). Field work does not.
  bool get ticksWhileClosed => switch (this) {
    OccupationKind.sleep ||
    OccupationKind.reading ||
    OccupationKind.building ||
    OccupationKind.crafting ||
    OccupationKind.repairing ||
    OccupationKind.recycling ||
    OccupationKind.reloadingAmmunition => true,
    OccupationKind.idle => false,
  };
}

/// Short things that suspend an occupation rather than cancelling it
/// (§2.1a.1). Durations are the realistic ones from §4.7.
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

/// Why an occupation ended.
enum OccupationEndReason {
  completed('ukończone'),

  /// The player started something else. Progress is kept (§2.1a.1).
  replaced('zastąpione przez inne zajęcie'),

  /// GPS says the character left the shelter zone (§2.1a.4).
  leftZone('opuszczenie strefy'),

  /// Suspended because the character left the shelter zone. Can be resumed.
  zoneSuspended('wstrzymane (poza strefą)'),

  /// A field occupation was running when the app went away (§2.1a.4).
  appClosed('zamknięcie aplikacji'),

  cancelled('przerwane przez gracza');

  const OccupationEndReason(this.label);

  final String label;
}

/// An occupation in progress.
class Occupation {
  const Occupation({
    required this.kind,
    required this.startedAt,
    required this.requiredWork,
    this.completedWork = Duration.zero,
    this.suspendedBy,
  });

  final OccupationKind kind;
  final DateTime startedAt;

  /// Total work the occupation needs. For sleep this is the nightly
  /// requirement; for building it is the construction time of §8.3.
  final Duration requiredWork;

  /// Work done so far. Survives being replaced, so a half-read book stays half
  /// read (§4.6.3).
  final Duration completedWork;

  /// Set while an action has the occupation paused.
  final ActionKind? suspendedBy;

  bool get isSuspended => suspendedBy != null;

  bool get isComplete => completedWork >= requiredWork;

  Duration get remaining {
    final left = requiredWork - completedWork;
    return left.isNegative ? Duration.zero : left;
  }

  double get progress => requiredWork.inMicroseconds <= 0
      ? 1.0
      : (completedWork.inMicroseconds / requiredWork.inMicroseconds).clamp(
          0.0,
          1.0,
        );

  Occupation copyWith({
    Duration? completedWork,
    ActionKind? suspendedBy,
    bool clearSuspension = false,
  }) => Occupation(
    kind: kind,
    startedAt: startedAt,
    requiredWork: requiredWork,
    completedWork: completedWork ?? this.completedWork,
    suspendedBy: clearSuspension ? null : (suspendedBy ?? this.suspendedBy),
  );

  Map<String, Object?> toJson() => {
    'kind': kind.name,
    'startedAt': startedAt.toUtc().toIso8601String(),
    'requiredSeconds': requiredWork.inSeconds,
    'completedSeconds': completedWork.inSeconds,
    'suspendedBy': ?suspendedBy?.name,
  };

  static Occupation? fromJson(Map<String, Object?>? json) {
    if (json == null) return null;
    final kindName = json['kind'] as String?;
    if (kindName == null) return null;

    return Occupation(
      kind: OccupationKind.values.firstWhere(
        (k) => k.name == kindName,
        orElse: () => OccupationKind.idle,
      ),
      startedAt: DateTime.parse(json['startedAt']! as String).toUtc(),
      requiredWork: Duration(
        seconds: (json['requiredSeconds'] as num?)?.toInt() ?? 0,
      ),
      completedWork: Duration(
        seconds: (json['completedSeconds'] as num?)?.toInt() ?? 0,
      ),
      suspendedBy: switch (json['suspendedBy']) {
        final String name => ActionKind.values.firstWhere(
          (a) => a.name == name,
          orElse: () => ActionKind.eating,
        ),
        _ => null,
      },
    );
  }
}

/// Result of advancing an occupation.
class OccupationProgress {
  const OccupationProgress({
    required this.occupation,
    required this.workApplied,
    required this.finished,
    this.endReason,
  });

  /// Null once the occupation ended.
  final Occupation? occupation;

  final Duration workApplied;
  final bool finished;
  final OccupationEndReason? endReason;
}

/// Whether an occupation may accrue work over a span (§2.1a.3).
///
/// The rule that matters: shelter occupations tick with the app closed, field
/// ones do not. The player physically sleeps at night and cannot hold the app
/// open for eight hours — if sleep needed presence, the whole time economy of
/// §2.1a.2 would be fiction.
bool occupationTicks({
  required OccupationKind kind,
  required bool appOpen,
  required bool inShelterZone,
  required bool gpsHealthy,
}) {
  if (kind.ticksWhileClosed) {
    // Leaving the zone cancels it; that is handled by the caller. Here we only
    // decide whether work accrues.
    return inShelterZone;
  }
  return appOpen && gpsHealthy;
}

/// Advances an occupation by [elapsed].
///
/// Pure, like everything the tick engine composes. A suspended occupation
/// makes no progress, and one that ends returns the reason so the UI can say
/// what happened rather than silently dropping it.
OccupationProgress advanceOccupation({
  required Occupation occupation,
  required Duration elapsed,
  required bool appOpen,
  required bool inShelterZone,
  required bool gpsHealthy,
  double speedMultiplier = 1.0,
}) {
  if (elapsed <= Duration.zero) {
    return OccupationProgress(
      occupation: occupation,
      workApplied: Duration.zero,
      finished: false,
    );
  }

  // Leaving the shelter cancels a shelter occupation outright, keeping the
  // progress made so far (§2.1a.4).
  if (occupation.kind.ticksWhileClosed && !inShelterZone) {
    return OccupationProgress(
      occupation: null,
      workApplied: Duration.zero,
      finished: true,
      endReason: OccupationEndReason.zoneSuspended,
    );
  }

  // A field occupation dies when the app goes away (§2.1a.4).
  if (!occupation.kind.ticksWhileClosed && !appOpen) {
    return OccupationProgress(
      occupation: null,
      workApplied: Duration.zero,
      finished: true,
      endReason: OccupationEndReason.appClosed,
    );
  }

  if (occupation.isSuspended ||
      !occupationTicks(
        kind: occupation.kind,
        appOpen: appOpen,
        inShelterZone: inShelterZone,
        gpsHealthy: gpsHealthy,
      )) {
    return OccupationProgress(
      occupation: occupation,
      workApplied: Duration.zero,
      finished: false,
    );
  }

  final scaled = Duration(
    microseconds: (elapsed.inMicroseconds * speedMultiplier).round(),
  );
  final capped = scaled > occupation.remaining ? occupation.remaining : scaled;
  final updated = occupation.copyWith(
    completedWork: occupation.completedWork + capped,
  );

  return OccupationProgress(
    occupation: updated.isComplete ? null : updated,
    workApplied: capped,
    finished: updated.isComplete,
    endReason: updated.isComplete ? OccupationEndReason.completed : null,
  );
}

/// Starts [next], cancelling whatever was running.
///
/// Returns the reason the previous occupation ended, so the caller can tell
/// the player their reading was interrupted rather than leaving them to
/// discover it.
({Occupation started, OccupationEndReason? previousEnded}) startOccupation({
  required Occupation next,
  Occupation? current,
}) => (
  started: next,
  previousEnded: current == null ? null : OccupationEndReason.replaced,
);
