/// The one moment the controllers learn whose things they are holding.
///
/// ⚠️ **Said once, and never again.** Every controller exists from the first
/// frame, because their notifiers are handed to screens long before there is a
/// character to fill them — the pack panel is built before anybody has a pack.
/// Binding is where a live, empty controller is told which profile on disk it
/// speaks for, and a controller that misses it is one that quietly holds
/// somebody else's run.
///
/// It lives out of `main.dart` because it is a list, not behaviour, and out of
/// `lib/game/controllers` because it is the one thing that has to know all of
/// them at once — which is exactly what a controller is not allowed to do.
library;

import '../items/item_catalogue.dart';
import '../sim/body.dart';
import 'controllers/craft_controller.dart';
import 'controllers/habit_controller.dart';
import 'controllers/hotspot_controller.dart';
import 'controllers/inventory_controller.dart';
import 'controllers/journal_controller.dart';
import 'controllers/loot_controller.dart';
import 'controllers/shelter_controller.dart';
import 'controllers/reading_controller.dart';
import 'controllers/skill_controller.dart';
import 'controllers/stash_controller.dart';

/// Everything a run needs pointed at one profile, in the order it needs it.
///
/// The awaited ones are awaited because something drawn a frame later asks
/// them a question: §7's skills decide what a recipe costs, §4.6.3's titles
/// decide what a book is worth, and §16.4's habit decides how fast the world
/// grows (§6.5.3).
Future<void> bindControllers({
  required int profileId,
  required ItemCatalogue catalogue,
  required BodyProfile body,
  required DateTime createdAt,
  required int seed,
  required InventoryController pack,
  required StashController shelf,
  required LootController loot,
  required ShelterController places,
  required CraftController workbench,
  required SkillController learned,
  required ReadingController books,
  required HabitController habit,
  required JournalController diary,
  required HotspotController fires,
}) async {
  pack.bind(profileId: profileId, catalogue: catalogue, body: body);
  shelf.bind(profileId: profileId);

  // ⚠️ The tables, not the world. §10.2's radius and §10.2.1's hidden places
  // are read off them, and that is all the loot needs to know — the world
  // itself plans, downloads and decodes, none of which is a question about
  // what is on the map right now.
  loot.bind(profileId: profileId);
  places.bind(profileId: profileId);
  workbench.bind(profileId: profileId);

  await learned.load(profileId);
  await books.load(profileId);

  // §16.4: the week behind this player, and the clock starts running on the
  // session that is beginning right now.
  await habit.load(profileId);
  habit.woke();

  // §3.6.1: read back, so a run reopens where it left off.
  await diary.bind(profileId: profileId, startedAt: createdAt);

  // §6.5: seeded from the character, so a run is the same world every time it
  // is opened (§11).
  fires.bind(profileId: profileId, seed: seed);
}
