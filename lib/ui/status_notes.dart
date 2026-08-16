/// What a status is, and what to do about it.
///
/// Four lines, always in the same order, because a player looking at a red
/// stamp on their HUD is asking four questions in a fixed sequence: how bad is
/// it, what is it costing me, what fixes it, and where do I get that. Anything
/// else on the sheet is in the way of those four.
///
/// No section numbers here. The design document is where the numbers are
/// argued; a person standing on a street in the rain wants the answer, not the
/// citation.
library;

import '../l10n/app_localizations.dart';
import '../sim/physiology.dart';
import '../sim/tick.dart';

/// One status, in the words the sheet shows.
typedef StatusNote = ({
  /// What it is called, as on the chip.
  String name,

  /// How bad, where the model actually grades it. Null where it does not.
  String? level,

  /// What it is doing to the character right now.
  String effect,

  /// The thing that makes it stop.
  String fix,

  /// Where that thing is found.
  String where,
});

/// Everything currently wrong, worst first.
///
/// Blood before water before food before sleep: that is the order they kill
/// in, and it is the order a player should read them in.
List<StatusNote> statusNotes(
  L10n l10n,
  SimStatus status, {
  BleedTier bleeding = BleedTier.none,
}) => [
  // §2.6: first, because it is the only one on this list with a clock on it.
  // Everything else gets worse over hours; this one is millilitres a minute.
  if (bleeding != BleedTier.none)
    (
      name: l10n.statusBleeding,
      level: bleedingName(l10n, bleeding),
      effect: l10n.statusBleedingEffect(bleeding.mlPerMinute.round()),
      fix: bleeding == BleedTier.arterial
          ? l10n.statusBleedingFixArterial
          : l10n.statusBleedingFix,
      where: l10n.statusBleedingWhere,
    ),
  if (status.blood.shockClass != ShockClass.none)
    (
      name: l10n.statusShock,
      level: l10n.statusDegree(_shockDegree(status.blood.shockClass)),
      effect: l10n.statusShockEffect,
      fix: l10n.statusShockFix,
      where: l10n.statusShockWhere,
    ),
  if (status.thirst.accuracyPenalty < 1)
    (
      name: l10n.statusDehydrated,
      level: l10n.statusOfDaily((status.thirst.fraction * 100).round()),
      effect: l10n.statusDehydratedEffect,
      fix: l10n.statusDehydratedFix,
      where: l10n.statusDehydratedWhere,
    ),
  if (status.hunger.actionTimeMultiplier > 1)
    (
      name: l10n.statusStarving,
      level: l10n.statusOfDaily((status.hunger.fraction * 100).round()),
      effect: l10n.statusStarvingEffect,
      fix: l10n.statusStarvingFix,
      where: l10n.statusStarvingWhere,
    ),
  if (status.sleep.extraMoa > 0)
    (
      name: l10n.statusSleepDeprived,
      level: l10n.statusDebtHours(status.sleep.debt.inHours),
      effect: l10n.statusSleepDeprivedEffect,
      fix: l10n.statusSleepDeprivedFix,
      where: l10n.statusSleepDeprivedWhere,
    ),
];

/// §2.6's own four words for it.
String bleedingName(L10n l10n, BleedTier tier) => switch (tier) {
  BleedTier.none => '',
  BleedTier.superficial => l10n.bleedSuperficial,
  BleedTier.moderate => l10n.bleedModerate,
  BleedTier.severe => l10n.bleedSevere,
  BleedTier.arterial => l10n.bleedArterial,
};

/// The clinical grades, which start at II — class I is a donation.
String _shockDegree(ShockClass shock) => switch (shock) {
  ShockClass.none => 'I',
  ShockClass.compensated => 'II',
  ShockClass.decompensated => 'III',
  ShockClass.critical => 'IV',
};
