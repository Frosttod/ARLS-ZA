import 'package:arls_za/data/db/database.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift_dev/api/migrations_native.dart';
import 'package:test/test.dart';

import 'generated_migrations/schema.dart';

/// Guards the migration contract of §11.1.4.
///
/// The rule the whole save layer rests on: migrations are additive only. A
/// released column is never dropped and never renamed, because an old save has
/// to keep loading. These tests fail loudly the moment someone breaks that.
void main() {
  group('schema', () {
    test('kSchemaVersion matches the database declaration', () {
      final db = SaveDatabase.memory();
      addTearDown(db.close);

      expect(
        db.schemaVersion,
        kSchemaVersion,
        reason:
            'schemaVersion is a literal for drift_dev; keep it in step '
            'with kSchemaVersion or the dumped schema files go stale',
      );
    });

    test('a committed schema file exists for the current version', () {
      final verifier = SchemaVerifier(GeneratedHelper());

      expect(
        () => verifier.startAt(kSchemaVersion),
        returnsNormally,
        reason:
            'run: dart run drift_dev schema dump '
            'lib/data/db/database.dart drift_schemas',
      );
    });

    test('a fresh database records its schema version', () async {
      final db = SaveDatabase.memory();
      addTearDown(db.close);

      expect(await db.storedSchemaVersion(), kSchemaVersion);
    });

    test('a fresh database passes integrity check', () async {
      final db = SaveDatabase.memory();
      addTearDown(db.close);

      expect(await db.isHealthy(), isTrue);
    });

    test(
      'every released schema version can be opened and migrated to current',
      () async {
        // With one version this proves the harness works. From v2 on it becomes
        // the real thing: v1 -> v2 -> v3 on generated data, exactly as §11.1.4
        // requires.
        final verifier = SchemaVerifier(GeneratedHelper());

        for (var from = 1; from <= kSchemaVersion; from++) {
          final connection = await verifier.startAt(from);
          final db = SaveDatabase(connection);
          addTearDown(db.close);

          await verifier.migrateAndValidate(db, kSchemaVersion);
        }
      },
    );
  });

  group('foreign keys', () {
    test('vitals and chronicle cascade from profiles', () async {
      final db = SaveDatabase.memory();
      addTearDown(db.close);

      final rows = await db
          .customSelect(
            "SELECT name, sql FROM sqlite_master WHERE type='table' "
            "AND name IN ('vitals','chronicle_entries')",
          )
          .get();

      expect(rows, hasLength(2));
      for (final row in rows) {
        expect(
          row.data['sql'] as String,
          contains('FOREIGN KEY (profile_id) REFERENCES profiles (id)'),
          reason: 'orphan vitals would outlive the character they belong to',
        );
      }
    });

    test('deleting a profile removes its vitals', () async {
      final db = SaveDatabase.memory();
      addTearDown(db.close);
      await db.customStatement('PRAGMA foreign_keys = ON');

      final id = await _insertProfile(db);
      expect(await db.vitalsFor(id), isNotNull);

      await (db.delete(db.profiles)..where((t) => t.id.equals(id))).go();

      expect(await db.vitalsFor(id), isNull);
    });
  });

  group('transactions', () {
    test('a failed profile creation leaves nothing behind', () async {
      final db = SaveDatabase.memory();
      addTearDown(db.close);

      await expectLater(
        db.createProfile(
          profile: ProfilesCompanion.insert(
            name: 'Ocalały',
            sex: 'M',
            ageYears: 30,
            heightCm: 180,
            weightKg: 80,
            deathMode: 'hardcore',
            rngSeed: 42,
            createdAt: DateTime.utc(2026, 8, 9),
          ),
          vitals: (_) => throw StateError('boom'),
        ),
        throwsA(isA<StateError>()),
      );

      expect(await db.allProfiles(), isEmpty);
    });

    test('creating a profile deactivates the previous one', () async {
      final db = SaveDatabase.memory();
      addTearDown(db.close);

      final first = await _insertProfile(db, name: 'Pierwsza');
      final second = await _insertProfile(db, name: 'Druga');

      final active = await db.activeProfile();
      expect(active?.id, second);
      expect((await db.profileById(first))?.isActive, isFalse);
    });
  });

  group('meta', () {
    test('timestamps round-trip as UTC', () async {
      final db = SaveDatabase.memory();
      addTearDown(db.close);

      final now = DateTime.utc(2026, 8, 9, 21, 37, 5);
      await db.writeMetaTimestamp(MetaKeys.clockHighWaterMark, now);

      expect(await db.readMetaTimestamp(MetaKeys.clockHighWaterMark), now);
    });

    test('reading an absent key returns null rather than throwing', () async {
      final db = SaveDatabase.memory();
      addTearDown(db.close);

      expect(await db.readMeta('nothing_here'), isNull);
      expect(await db.readMetaTimestamp('nothing_here'), isNull);
    });
  });
}

Future<int> _insertProfile(SaveDatabase db, {String name = 'Ocalały'}) =>
    db.createProfile(
      profile: ProfilesCompanion.insert(
        name: name,
        sex: 'M',
        ageYears: 30,
        heightCm: 180,
        weightKg: 80,
        deathMode: 'hardcore',
        rngSeed: 42,
        createdAt: DateTime.utc(2026, 8, 9),
        isActive: const Value(true),
      ),
      vitals: (id) => VitalsCompanion.insert(
        profileId: Value(id),
        lastUpdate: DateTime.utc(2026, 8, 9),
        bloodMl: 5290,
        waterMl: 2800,
        caloriesKcal: 2450,
        heartRateBpm: 70,
      ),
    );
