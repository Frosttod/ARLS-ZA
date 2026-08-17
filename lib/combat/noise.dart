/// What a sound reaches, and who walks towards it (§5.6).
///
/// §0.1 calls this the main tactical decision of the game and it only works
/// because of one rule: **enemies walk to where the sound was, not to the
/// player.** A shot that summoned everything straight onto the shooter would
/// leave nothing to decide. A shot that draws six of them to a street corner
/// three hundred metres away leaves room to move, watch, and shoot again from
/// somewhere else.
///
/// It is also what makes the weapon choice real (§5.6.3): a rifle kills at
/// distance and calls seven hundred metres of city; a knife is silent to
/// twenty-five and demands the clinch, which §5.5.3 prices at very nearly a
/// sentence. A suppressor is the long-term prize precisely because it changes
/// how the game is played rather than adding a percentage.
library;

import '../map/geometry.dart';
import 'enemy.dart';

/// §5.6.1's table, in metres.
enum NoiseKind {
  walking(15),
  running(40),
  melee(25),
  shotgun(900),
  rifle(700),
  pistol(450),
  suppressedPistol(120),
  suppressedRifle(200),

  /// §19.3: glass, or a door coming off its hinges.
  breaching(150),

  /// §8.3: a hammer, which is why building is not free.
  building(100);

  const NoiseKind(this.baseM);

  final double baseM;
}

/// §5.6.2: at most six of them per event, nearest first.
///
/// Without the cap, one shot beside a level-ten hotspot would bring twelve and
/// turn every mistake into a death sentence.
const int kNoiseRespondersMax = 6;

/// §5.6.2: further shots inside this do not multiply the reaction.
const Duration kNoiseWindow = Duration(seconds: 30);

/// §5.6.2: a burst is one event a little louder, not five events.
const double kBurstRadiusMultiplier = 1.15;

/// §5.6.1: `base × night × built-up × weather`.
///
/// Night is louder rather than quieter — less background noise and a
/// temperature inversion carry a shot further, which is the opposite of what
/// most games assume and the reason it is worth modelling at all.
double noiseRadiusM(
  double baseM, {
  bool night = false,
  bool denseUrban = false,
  bool openGround = false,
  bool badWeather = false,
}) {
  var radius = baseM;

  if (night) radius *= 1.3;
  // §5.6.1 gives the built-up damping as a daytime figure: at night the
  // inversion is carrying the sound over the same rooftops.
  if (denseUrban && !night) radius *= 0.7;
  if (openGround) radius *= 1.2;
  if (badWeather) radius *= 0.75;

  return radius;
}

/// §5.6.2: what one enemy does about a sound.
enum NoiseReaction {
  /// Inside a third of the radius: they work out where the player is.
  chase,

  /// Out to the full radius: they walk to the sound and search.
  alert,

  /// Beyond it: nothing at all.
  none,
}

NoiseReaction reactionAt(double distanceM, double radiusM) {
  if (radiusM <= 0 || distanceM > radiusM) return NoiseReaction.none;
  return distanceM <= radiusM / 3 ? NoiseReaction.chase : NoiseReaction.alert;
}

/// How loud a sound has to be before it is worth running towards (§5.6.1).
///
/// A gunshot is heard from seven hundred metres and a knife from twenty-five.
/// Anything at the loud end is a bang, and a bang is startling — which is the
/// difference between a body that strolls over to look and one that arrives.
const double kStartlingNoiseM = 200;

/// One thing heard, at one place.
class NoiseEvent {
  const NoiseEvent({
    required this.at,
    required this.radiusM,
    required this.startedAt,
    this.shots = 1,
  });

  final GeoPoint at;
  final double radiusM;
  final DateTime startedAt;

  /// How many sounds have folded into this one (§5.6.2).
  final int shots;

  bool isOpenAt(DateTime now) => now.difference(startedAt) < kNoiseWindow;

  /// §5.6.2: whether this is the kind of sound that gets bodies moving.
  ///
  /// ⚠️ A deliberate step past §5.6.2's own wording, which says "walk to the
  /// point of the noise" for everything alike. Found on a walk: a shot that
  /// missed brought them ambling over from four hundred metres, which reads as
  /// a world that did not hear it. A shot is startling and a footstep is not,
  /// and the whole cost of a firearm (§5.6.3) is that everything comes — the
  /// speed at which it comes is what makes that a cost rather than a note.
  bool get isStartling => radiusM >= kStartlingNoiseM;

  /// §5.6.2: another shot inside thirty seconds moves the point and holds
  /// their attention, rather than calling a second crowd.
  NoiseEvent plus(NoiseEvent later) => NoiseEvent(
    at: later.at,
    radiusM: shots == 1
        ? later.radiusM * kBurstRadiusMultiplier
        : later.radiusM > radiusM
        ? later.radiusM
        : radiusM,
    startedAt: later.startedAt,
    shots: shots + 1,
  );
}

/// Folds a new sound into whatever is still ringing (§5.6.2).
NoiseEvent accumulate(NoiseEvent? open, NoiseEvent fresh) =>
    open != null && open.isOpenAt(fresh.startedAt)
    ? open.plus(fresh)
    : fresh;

/// Who turns towards it, and what they do about it (§5.6.2).
///
/// Not the ones already chasing: §5.6.2 is explicit that an enemy that has the
/// player does not change target, and a group that abandoned its pursuit every
/// time something clattered would be a group nobody could ever escape.
///
/// ⚠️ But the ones *investigating* a previous sound do turn. A second shot is
/// a fresher answer to the question they are already asking, and walking to
/// where the last one came from while the next one goes off somewhere else is
/// how a thing behaves that cannot hear. What this buys is the whole economy
/// of shooting: every round pulls the street to wherever the player is
/// standing now, so a firearm is for a fight you can finish, not for keeping
/// one going.
List<Enemy> respondToNoise(
  List<Enemy> enemies, {
  required NoiseEvent event,
  required GeoPoint playerAt,
}) {
  final candidates =
      enemies
          .where(
            (enemy) =>
                !enemy.isDead &&
                (enemy.state == EnemyState.idle ||
                    enemy.state == EnemyState.returning ||
                    enemy.state == EnemyState.alert),
          )
          .map(
            (enemy) => (
              enemy: enemy,
              distance: enemy.position.distanceTo(event.at),
            ),
          )
          .where(
            (entry) =>
                reactionAt(entry.distance, event.radiusM) != NoiseReaction.none,
          )
          .toList()
        ..sort((a, b) => a.distance.compareTo(b.distance));

  final answering = candidates.take(kNoiseRespondersMax).toSet();

  return [
    for (final enemy in enemies)
      switch (answering.where((entry) => identical(entry.enemy, enemy)).firstOrNull) {
        null => enemy,
        final entry
            when reactionAt(entry.distance, event.radiusM) ==
                NoiseReaction.chase =>
          // Close enough to place the player themselves, which is what makes
          // shooting from cover a bad idea when they are already near.
          enemy.hears(playerAt, chasing: true),
        _ => enemy.hears(event.at, hurrying: event.isStartling),
      },
  ];
}
