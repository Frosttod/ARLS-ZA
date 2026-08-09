import 'dart:convert';

import 'package:arls_za/data/db/database.dart';
import 'package:arls_za/data/persistence/profile_transfer.dart';
import 'package:crypto/crypto.dart';
import 'package:test/test.dart';

import 'db_fixture.dart';

/// Covers §11.3: losing the phone must not mean losing the character. The
/// bundle is a plain JSON file the player owns, checksummed against truncation
/// and versioned so an older export still loads.
void main() {
  late SaveDatabase db;
  late ProfileTransfer transfer;
  final now = DateTime.utc(2026, 8, 9, 21);

  setUp(() {
    db = SaveDatabase.memory();
    transfer = ProfileTransfer(db);
  });

  tearDown(() => db.close());

  test('export then import reproduces the character', () async {
    final id = await insertProfile(db, name: 'Halina', rngSeed: 987654);
    await db
        .into(db.chronicleEntries)
        .insert(
          ChronicleEntriesCompanion.insert(
            profileId: id,
            survivalDays: 23,
            startedAt: now.subtract(const Duration(days: 23)),
            endedAt: now,
            cause: 'horda',
            deathMode: 'hardcore',
          ),
        );
    await db
        .into(db.settings)
        .insert(SettingsCompanion.insert(key: 'locale', value: 'pl'));

    final encoded = (await transfer.export(id, now: now)).encode();

    // Fresh device.
    final fresh = SaveDatabase.memory();
    addTearDown(fresh.close);
    final importedId = await ProfileTransfer(
      fresh,
    ).import(ProfileBundle.decode(encoded));

    final profile = await fresh.profileById(importedId);
    expect(profile!.name, 'Halina');
    expect(
      profile.rngSeed,
      987654,
      reason: 'the seed makes the run replayable',
    );
    expect(profile.heightCm, 180);
    expect(profile.isActive, isTrue);

    final vitals = await fresh.vitalsFor(importedId);
    expect(vitals!.bloodMl, referenceConstants.bloodMaxMl);

    final chronicle = await fresh.select(fresh.chronicleEntries).get();
    expect(chronicle.single.survivalDays, 23);
    expect(chronicle.single.cause, 'horda');

    final settings = await fresh.select(fresh.settings).get();
    expect(settings.single.value, 'pl');
  });

  test('the bundle is readable JSON, not an opaque blob', () async {
    final id = await insertProfile(db, name: 'Czytelna');
    final encoded = (await transfer.export(id, now: now)).encode();

    final decoded = jsonDecode(encoded) as Map<String, Object?>;
    final payload = decoded['payload']! as Map<String, Object?>;
    final profile = payload['profile']! as Map<String, Object?>;

    expect(payload['bundleVersion'], kBundleVersion);
    expect(profile['name'], 'Czytelna');
    expect(
      encoded,
      contains('\n'),
      reason: 'pretty-printed so a human can read it',
    );
  });

  test('a truncated file is rejected', () async {
    final id = await insertProfile(db);
    final encoded = (await transfer.export(id, now: now)).encode();

    expect(
      () => ProfileBundle.decode(encoded.substring(0, encoded.length ~/ 2)),
      throwsA(isA<ProfileBundleException>()),
    );
  });

  test('an edited payload fails the checksum', () async {
    final id = await insertProfile(db, name: 'Oryginal');
    final encoded = (await transfer.export(id, now: now)).encode();
    final tampered = encoded.replaceFirst('Oryginal', 'Podmiana');

    expect(
      () => ProfileBundle.decode(tampered),
      throwsA(
        isA<ProfileBundleException>().having(
          (e) => e.message,
          'message',
          contains('checksum'),
        ),
      ),
    );
  });

  test('a bundle from a newer build is refused with a clear reason', () {
    final payload = {
      'bundleVersion': kBundleVersion + 1,
      'schemaVersion': 99,
      'exportedAt': now.toIso8601String(),
      'profile': <String, Object?>{'name': 'Z przyszlosci'},
      'vitals': null,
      'chronicle': <Object?>[],
      'settings': <String, Object?>{},
    };
    final source = jsonEncode({
      'payload': payload,
      'checksum': _sha(jsonEncode(payload)),
    });

    expect(
      () => ProfileBundle.decode(source),
      throwsA(
        isA<ProfileBundleException>().having(
          (e) => e.message,
          'message',
          contains('update the app'),
        ),
      ),
    );
  });

  test('malformed input fails as an exception, not a crash', () {
    expect(
      () => ProfileBundle.decode('not json at all'),
      throwsA(isA<ProfileBundleException>()),
    );
    expect(
      () => ProfileBundle.decode('[]'),
      throwsA(isA<ProfileBundleException>()),
    );
    expect(
      () => ProfileBundle.decode('{"payload":{}}'),
      throwsA(isA<ProfileBundleException>()),
    );
  });

  test('importing never overwrites an existing character', () async {
    final existing = await insertProfile(db, name: 'Zyjaca');
    final encoded = (await transfer.export(existing, now: now)).encode();

    final importedId = await transfer.import(ProfileBundle.decode(encoded));

    expect(importedId, isNot(existing));
    expect(await db.allProfiles(), hasLength(2));
    expect(
      (await db.profileById(existing))!.name,
      'Zyjaca',
      reason: 'a mistaken restore must not destroy a live streak',
    );
  });

  test('import can be told not to take over as the active character', () async {
    final existing = await insertProfile(db, name: 'Aktywna');
    final encoded = (await transfer.export(existing, now: now)).encode();

    await transfer.import(ProfileBundle.decode(encoded), makeActive: false);

    expect((await db.activeProfile())!.id, existing);
  });

  test('exporting an unknown profile fails cleanly', () {
    expect(
      () => transfer.export(999, now: now),
      throwsA(isA<ProfileBundleException>()),
    );
  });
}

/// Computed independently of the export code, so a silent change of algorithm
/// would break this test rather than pass unnoticed.
String _sha(String value) => sha256.convert(utf8.encode(value)).toString();
