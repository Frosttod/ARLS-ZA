/// What a blackout costs, and where it leaves it (§9.2, §9.2.1).
///
/// ⚠️ **Caches, never a wipe.** Half the kit is on the ground where the
/// character fell, and it stays there rather than following the player — which
/// is what makes the whole of §9.2.1 work without a rule of its own: the
/// penalty grows with how far they have walked since, all by itself.
///
/// The weapon is the exception and goes nowhere. §9.2 is explicit about it,
/// and it is the one thing stopping a deliberate death from being a cheap way
/// home with the rifle still in hand.
library;

import 'dart:math';

import '../items/item_catalogue.dart';
import '../items/item.dart';
import '../loot/dropped_items.dart';
import '../map/geometry.dart';
import '../sim/death.dart' show kWakeLossFraction;
import 'inventory.dart';

/// Two or three caches in thirty to a hundred metres, so getting it back is a
/// walk rather than a button.
const (double, double) kCacheRangeM = (30, 100);

class WakeLoss {
  const WakeLoss({required this.kept, required this.caches});

  /// What the character wakes up still holding.
  final Inventory kept;

  /// What is on the ground, waiting to be written down.
  final List<DroppedItem> caches;
}

/// §9.2: takes the weapon, then half of everything else by the piece.
///
/// ⚠️ Worn as well as carried. §9.2 says "the rest of the kit worn", and
/// taking only what was in the pack meant a character woke up in the same
/// boots, coat and vest they went down in — the entire cost of a blackout fell
/// on whatever happened to be loose. Half of it *by the piece*: losing three
/// of five bandages and keeping two is what §9.2 describes, and a stack is one
/// piece.
WakeLoss scatterKit(
  Inventory pack, {
  required ItemCatalogue catalogue,
  required GeoPoint at,
  required DateTime now,
  required Random random,
}) {
  var kept = pack;

  for (final line in [...kept.worn]) {
    final item = catalogue[line.itemId];
    if (item == null) continue;
    if (item.kind == ItemKind.firearm || item.kind == ItemKind.melee) {
      kept = kept.removeLine(line, count: line.count) ?? kept;
    }
  }

  final (near, far) = kCacheRangeM;
  final caches = <DroppedItem>[];

  for (final line in [...kept.worn, ...kept.carried]) {
    if (random.nextDouble() >= kWakeLossFraction) continue;

    kept = kept.removeLine(line, count: line.count) ?? kept;
    caches.add(
      DroppedItem(
        id: 0,
        itemId: line.itemId,
        count: line.count,
        condition: line.condition,
        attachments: line.attachments,
        position: at.offsetBy(
          metres: near + random.nextDouble() * (far - near),
          bearingDeg: random.nextDouble() * 360,
        ),
        droppedAt: now,
      ),
    );
  }

  return WakeLoss(kept: kept, caches: caches);
}
