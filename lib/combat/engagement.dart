/// How close a fight is, and what happens once it is close (§5.2, §5.4, §5.5).
///
/// The distances are not taste. §5.2 derives them from the receiver: a fix is
/// good to five or fifteen metres, so below thirty the error in both positions
/// is larger than the distance between them and a metre-by-metre fight would
/// be a fight against GPS noise. Under twenty metres the game stops pretending
/// to know where anybody is standing and settles it abstractly.
library;

/// §5.2: nothing is ever noticed closer than this.
///
/// A Walker that appeared at eighty metres would be a Walker that appeared out
/// of nothing, since that is inside the distance a shot is worth taking.
const double kDetectionMinM = 150;

/// §5.2: where a firefight belongs.
const double kRangedMinM = 50;
const double kRangedMaxM = 250;

/// §5.2: below this it is hands, not sights.
const double kMeleeM = 20;

/// §5.5.1: recovering the sight picture after changing target.
///
/// `1.2 s × (1 − 0.30 × skill)`, so a novice pays 1.2 s and a master 0.85 s.
/// §5.5.1 refuses to switch automatically when a target dies and charges the
/// same time for the "nearest threat" button, because automation would turn a
/// group fight into tapping.
Duration targetSwitchTime(double weaponSkill) => Duration(
  milliseconds: (1200 * (1 - 0.30 * weaponSkill.clamp(0.0, 1.0))).round(),
);

/// §5.5.1: while the sight picture is being recovered the group is at its
/// widest — two and a half times the settled figure.
const double kSwitchingSpreadMultiplier = 2.5;

/// Which kind of fight this distance is (§5.2).
enum EngagementBand {
  /// Nothing is here yet.
  none,

  /// Seen, and worth a shot: §5.2's fifty to two hundred and fifty metres.
  ranged,

  /// Too close to shoot well, too far to touch. The band a player should be
  /// walking backwards through.
  closing,

  /// §5.2: hands. GPS has nothing useful to say at this range.
  melee,
}

EngagementBand bandAt(double distanceM) {
  if (distanceM <= kMeleeM) return EngagementBand.melee;
  if (distanceM < kRangedMinM) return EngagementBand.closing;
  if (distanceM <= kRangedMaxM) return EngagementBand.ranged;
  return EngagementBand.none;
}

/// §5.4: `0.65 + 0.30 × skill − 0.25 × (load / max carry) − fatigue`.
///
/// ⚠️ §5.4 names a fatigue penalty without fixing its size. Taken here as the
/// same fraction §5.1.1 uses for the pulse — how far the heart is between rest
/// and maximum — because it is the one number the body already keeps and it
/// makes the two halves of combat agree: whatever ruins a shot ruins a swing.
double meleeHitChance({
  required double skill,
  required double carriedKg,
  required double maxCarryKg,
  double fatigue = 0,
}) {
  final load = maxCarryKg <= 0 ? 0.0 : (carriedKg / maxCarryKg).clamp(0.0, 1.0);

  final chance =
      0.65 +
      0.30 * skill.clamp(0.0, 1.0) -
      0.25 * load -
      fatigue.clamp(0.0, 1.0) * 0.25;

  return chance.clamp(0.0, 1.0);
}

/// §5.5.3: what being surrounded does to the enemies' odds against the player.
///
/// The player answers one of them at a time and the rest swing freely, so
/// letting a group close is very nearly a sentence — which is the intent, and
/// the reason §5.5.5 makes the tactical loop about never letting it happen.
double flankingMultiplier(int enemiesInReach) => switch (enemiesInReach) {
  <= 1 => 1.00,
  2 => 1.30,
  3 => 1.55,
  _ => 1.75,
};
