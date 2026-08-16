/// Where a garment goes, in the order a person is dressed (§4.4).
///
/// The slots are not invented here: they are the `slot` values already written
/// into `armor.json` and `backpacks.json` in stage 4.1, and the screen reads
/// them rather than keeping a second list that could disagree.
///
/// The order is the order the items sit in on a body, from the head down, with
/// the pack last. That is what lets a flat list read as a figure: nobody has
/// to be told that boots are below trousers.
library;

/// One place on the body, and what the data calls it.
enum BodySlot {
  head('head'),
  torsoBase('torso_base'),
  torsoMid('torso_mid'),
  torsoOuter('torso_outer'),
  torsoArmor('torso_armor'),
  arms('arms'),
  hands('hands'),
  legs('legs'),
  feet('feet'),

  /// What is in the hand right now (§5.5.1). Not a garment and not in the
  /// data: a knife has no `slot` prop because §4.4 only dresses a body. The
  /// game still has to know which weapon is out, because that is the one that
  /// fires and the one a clinch is fought with.
  hand('weapon'),

  /// The pack. Not a garment, but it is worn, it is the thing that changes
  /// both carry limits (§18.1a), and a player looking for it looks here.
  back('backpack');

  const BodySlot(this.wire);

  /// The value in the item's `slot` prop.
  final String wire;

  static BodySlot? fromWire(String? value) =>
      values.where((slot) => slot.wire == value).firstOrNull;
}
