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

import '../combat/attachment.dart';
import '../l10n/app_localizations.dart';
import '../sim/action_kind.dart';
import '../items/item.dart';
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
  // ⚠️ §2.3: its own note, because it is its own thing.
  //
  // Hunger above is the day's larder and comes back with one tin. This is what
  // weeks of that did to the body, and it does *not* come back with one tin —
  // a player who eats their fill and finds the game still slow is owed the
  // reason, or the penalty reads as a bug.
  if (status.wasting.actionTimeMultiplier > 1)
    (
      name: l10n.statusWasting,
      level: l10n.statusWastingLevel(
        (status.wasting.lostFraction * 100).round(),
      ),
      effect: l10n.statusWastingEffect,
      fix: l10n.statusWastingFix,
      where: l10n.statusWastingWhere,
    ),
  // ⚠️ §2.5.5, §12: its own note, and it has to be.
  //
  // Under chronic restriction subjective sleepiness plateaus while performance
  // goes on falling — which is exactly what makes this a good mechanic and
  // exactly what makes it unfair without a caption. The sleep bar reads full
  // after one good night; a player who is still worse than they were is owed
  // the reason, or the penalty reads as a bug.
  if (status.chronicSleep.strain >= 1)
    (
      name: l10n.statusWornOut,
      level: l10n.statusWornOutLevel(status.chronicSleep.strain.round()),
      effect: l10n.statusWornOutEffect,
      fix: l10n.statusWornOutFix,
      where: l10n.statusWornOutWhere,
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

/// §12: the action and the thing it is being done to, in one line.
///
/// ⚠️ The item's name, not the kind of action. A strip that says "jedzenie"
/// tells a player what sort of thing is happening; one that says "Jesz:
/// Kanapka" tells them what they tapped and what it will cost — which is what
/// somebody glancing at a phone while walking actually needs.
///
/// [nameOf] is handed in because §4.1 lets a content pack rename anything, and
/// resolving a name is the catalogue's job rather than a label's.
String useLabel(
  L10n l10n,
  ActionKind kind,
  ItemDefinition? item, {
  required String Function(ItemDefinition item) nameOf,
}) {
  final name = item == null ? '' : nameOf(item);

  return switch (kind) {
    ActionKind.eating => l10n.actionEating(name),
    ActionKind.drinking => l10n.actionDrinking(name),
    _ => l10n.actionUsing(name),
  };
}

/// The same, for a kind that arrived as the string a row on disk holds.
///
/// A row naming something this version does not know about is a row that still
/// has to say *something* — §2.1a's one-action rule reads this to explain a
/// refusal, and "busy" with no reason is worse than a vague one.
String useLabelFor(
  L10n l10n,
  String kind,
  ItemDefinition? item, {
  required String Function(ItemDefinition item) nameOf,
}) {
  for (final known in ActionKind.values) {
    if (known.name == kind) return useLabel(l10n, known, item, nameOf: nameOf);
  }
  return l10n.searchAreaRunning;
}

/// Gdzie na broni siedzi dodatek, w słowach ekranu (§5.5.4).
String attachmentPlaceName(L10n l10n, AttachmentSlot place) => switch (place) {
  AttachmentSlot.magazine => l10n.slotMagazine,
  AttachmentSlot.optic => l10n.slotOptic,
  AttachmentSlot.barrel => l10n.slotBarrel,
  AttachmentSlot.grip => l10n.slotGrip,
  AttachmentSlot.rail => l10n.slotRail,
};
