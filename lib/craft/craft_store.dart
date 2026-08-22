/// Reading and writing what is on the bench (§18.4, §18.6, §11.1).
///
/// One row per profile, replaced rather than appended: §18 never asks for a
/// queue, and a person has one pair of hands.
library;

import 'package:drift/drift.dart' show Value;

import '../data/db/database.dart';
import 'craft_job.dart';
import 'salvage_batch.dart';

class CraftStore {
  const CraftStore(this.db);

  final SaveDatabase db;

  Future<CraftJob?> load(int profileId) async {
    final row = await db.craftJobFor(profileId);
    if (row == null) return null;

    return CraftJob(
      recipeId: row.recipeId,
      salvageItemId: row.salvageItemId,
      salvageCondition: row.salvageCondition,
      batch: SalvageBatch.decode(row.salvageBatch),
      startedAt: row.startedAt.toUtc(),
      readyAt: row.readyAt.toUtc(),
    );
  }

  /// §18.4: starts making something.
  Future<void> beginCraft(
    int profileId, {
    required String recipeId,
    required DateTime now,
    required Duration work,
  }) => db.beginCraftJob(
    CraftJobsCompanion.insert(
      profileId: profileId,
      startedAt: now,
      readyAt: now.add(work),
      recipeId: Value(recipeId),
    ),
  );

  /// §18.6: starts taking something apart.
  ///
  /// The condition travels with the job because the item itself is already
  /// gone from the pack — it left when the work started, so that a rifle
  /// being dismantled cannot also be fired.
  Future<void> beginSalvage(
    int profileId, {
    required String itemId,
    required double condition,
    required DateTime now,
    required Duration work,
  }) => db.beginCraftJob(
    CraftJobsCompanion.insert(
      profileId: profileId,
      startedAt: now,
      readyAt: now.add(work),
      salvageItemId: Value(itemId),
      salvageCondition: Value(condition),
    ),
  );

  /// §18.6: starts a sitting of several things, in order.
  ///
  /// ⚠️ Still one row. The head of the batch is written to the same two
  /// columns a single dismantling uses, so everything that already knows how
  /// to read a dismantling goes on working and only the parts that care about
  /// the rest of the list have to look at [CraftJob.batch].
  Future<void> beginBatchSalvage(
    int profileId,
    SalvageBatch batch, {
    required DateTime now,
  }) {
    final head = batch.head;
    if (head == null) return clear(profileId);

    return db.beginCraftJob(
      CraftJobsCompanion.insert(
        profileId: profileId,
        startedAt: now,
        readyAt: now.add(batch.total),
        salvageItemId: Value(head.itemId),
        salvageCondition: Value(head.condition),
        salvageBatch: Value(batch.encode()),
      ),
    );
  }

  Future<void> clear(int profileId) => db.clearCraftJob(profileId);
}
