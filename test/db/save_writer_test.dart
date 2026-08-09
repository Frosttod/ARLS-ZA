import 'package:arls_za/data/db/database.dart';
import 'package:arls_za/data/persistence/save_writer.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:test/test.dart';

import 'db_fixture.dart';

/// Covers the write cadence of §11.1.1: the hot layer is buffered and flushed
/// every 60 s, warm and cold writes go through immediately and drag the hot
/// layer with them.
void main() {
  late SaveDatabase db;
  late SaveWriter writer;
  late int profileId;
  final t0 = DateTime.utc(2026, 8, 9, 12);

  setUp(() async {
    db = SaveDatabase.memory();
    profileId = await insertProfile(db);
    writer = SaveWriter(db);
  });

  tearDown(() => db.close());

  test('staging costs no I/O', () async {
    writer.stageHot(vitalsFor(profileId, lastUpdate: t0, waterMl: 1234));

    expect(writer.hasPendingHot, isTrue);
    expect(
      (await db.vitalsFor(profileId))!.waterMl,
      referenceConstants.waterDailyMl,
      reason: 'nothing should have reached the database yet',
    );
  });

  test('the first flush happens immediately, later ones wait 60 s', () async {
    writer.stageHot(vitalsFor(profileId, lastUpdate: t0, waterMl: 2000));
    expect(writer.isFlushDue(t0), isTrue);

    await writer.flushIfDue(t0);
    expect((await db.vitalsFor(profileId))!.waterMl, 2000);

    writer.stageHot(vitalsFor(profileId, lastUpdate: t0, waterMl: 1900));
    expect(writer.isFlushDue(t0.add(const Duration(seconds: 59))), isFalse);
    expect(writer.isFlushDue(t0.add(const Duration(seconds: 60))), isTrue);
  });

  test('a flush with nothing pending is a no-op', () async {
    final result = await writer.flushHot(t0);

    expect(result.wrote, isFalse);
    expect(writer.lastHotFlush, isNull);
  });

  test('at most 60 seconds of physiology can be lost', () async {
    // Simulate a run where the engine stages every second and the process dies
    // 59 seconds after the last flush.
    writer.stageHot(vitalsFor(profileId, lastUpdate: t0, waterMl: 2800));
    await writer.flushIfDue(t0);

    for (var second = 1; second <= 59; second++) {
      writer.stageHot(
        vitalsFor(
          profileId,
          lastUpdate: t0.add(Duration(seconds: second)),
          waterMl: 2800 - second.toDouble(),
        ),
      );
      await writer.flushIfDue(t0.add(Duration(seconds: second)));
    }

    // Process dies here. Whatever is on disk is what survives.
    final onDisk = await db.vitalsFor(profileId);
    final lost = onDisk!.lastUpdate.difference(t0).abs();

    expect(lost, lessThanOrEqualTo(const Duration(seconds: 60)));
    expect(
      onDisk.waterMl,
      2800,
      reason: 'the last committed state, not the staged one',
    );
  });

  test('quiesce flushes regardless of the cadence', () async {
    writer.stageHot(vitalsFor(profileId, lastUpdate: t0, waterMl: 2800));
    await writer.flushIfDue(t0);

    writer.stageHot(vitalsFor(profileId, lastUpdate: t0, waterMl: 2750));
    final result = await writer.quiesce(t0.add(const Duration(seconds: 5)));

    expect(result.wrote, isTrue);
    expect(result.reason, FlushReason.lifecycle);
    expect((await db.vitalsFor(profileId))!.waterMl, 2750);
  });

  test('a warm write drags the hot layer along', () async {
    writer.stageHot(vitalsFor(profileId, lastUpdate: t0, waterMl: 2500));

    await writer.writeWarm(t0, () async {
      await db
          .into(db.settings)
          .insert(
            SettingsCompanion.insert(key: 'locale', value: 'pl'),
            mode: InsertMode.insertOrReplace,
          );
    });

    expect(writer.hasPendingHot, isFalse);
    expect((await db.vitalsFor(profileId))!.waterMl, 2500);
  });

  test(
    'a failed warm write rolls back and leaves the hot layer staged',
    () async {
      writer.stageHot(vitalsFor(profileId, lastUpdate: t0, waterMl: 2400));

      await expectLater(
        writer.writeWarm(t0, () async {
          await db
              .into(db.settings)
              .insert(SettingsCompanion.insert(key: 'locale', value: 'pl'));
          throw StateError('boom');
        }),
        throwsA(isA<StateError>()),
      );

      expect(await db.select(db.settings).get(), isEmpty);
      expect(
        writer.hasPendingHot,
        isTrue,
        reason: 'a rolled-back warm write must not silently drop hot state',
      );
    },
  );

  test('a cold write checkpoints the WAL', () async {
    writer.stageHot(vitalsFor(profileId, lastUpdate: t0));

    await writer.writeCold(t0, () async {
      await db
          .into(db.chronicleEntries)
          .insert(
            ChronicleEntriesCompanion.insert(
              profileId: profileId,
              survivalDays: 12,
              startedAt: t0.subtract(const Duration(days: 12)),
              endedAt: t0,
              cause: 'wykrwawienie',
              deathMode: 'hardcore',
            ),
          );
    });

    final entries = await db.select(db.chronicleEntries).get();
    expect(entries.single.survivalDays, 12);
    expect(writer.hasPendingHot, isFalse);
  });

  test('discardPending throws away the buffer without writing', () async {
    writer.stageHot(vitalsFor(profileId, lastUpdate: t0, waterMl: 100));
    writer.discardPending();

    final result = await writer.flushHot(t0);

    expect(result.wrote, isFalse);
    expect(
      (await db.vitalsFor(profileId))!.waterMl,
      referenceConstants.waterDailyMl,
    );
  });
}
