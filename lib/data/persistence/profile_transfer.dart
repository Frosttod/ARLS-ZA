/// Profile export and import (design doc §11.3).
///
/// No servers means losing the phone means losing hundreds of hours. The
/// export is a single JSON file the player controls: readable, checksummed and
/// versioned, so an import from an older build still loads.
///
/// The bundle carries the same body parameters the game refuses to upload
/// anywhere (§1.2). Writing it is therefore an explicit player action, never
/// automatic, and where the file goes is the player's decision.
library;

import 'dart:convert';

import 'package:drift/drift.dart';

import '../db/database.dart';
import '../db/snapshot_store.dart';

/// Bumped when the bundle layout changes. Import accepts anything up to this.
const int kBundleVersion = 1;

class ProfileBundleException implements Exception {
  ProfileBundleException(this.message);

  final String message;

  @override
  String toString() => 'ProfileBundleException: $message';
}

/// A profile, its vitals and its Chronicle, ready to be written to a file.
class ProfileBundle {
  const ProfileBundle({
    required this.bundleVersion,
    required this.schemaVersion,
    required this.exportedAt,
    required this.profile,
    required this.vitals,
    required this.chronicle,
    required this.settings,
  });

  final int bundleVersion;
  final int schemaVersion;
  final DateTime exportedAt;

  final Map<String, Object?> profile;
  final Map<String, Object?>? vitals;
  final List<Map<String, Object?>> chronicle;
  final Map<String, String> settings;

  Map<String, Object?> toPayload() => {
    'bundleVersion': bundleVersion,
    'schemaVersion': schemaVersion,
    'exportedAt': exportedAt.toUtc().toIso8601String(),
    'profile': profile,
    'vitals': vitals,
    'chronicle': chronicle,
    'settings': settings,
  };

  /// Encodes the bundle with a checksum over the payload.
  ///
  /// The checksum guards against a truncated file, not against tampering — a
  /// determined player can edit their own single-player save and that is their
  /// business (§3.4 takes the same view of position cheating).
  String encode() {
    final payload = toPayload();
    final canonical = jsonEncode(payload);
    return const JsonEncoder.withIndent(
      '  ',
    ).convert({'payload': payload, 'checksum': checksumOfString(canonical)});
  }

  static ProfileBundle decode(String source) {
    final Object? root;
    try {
      root = jsonDecode(source);
    } on FormatException catch (e) {
      throw ProfileBundleException('not valid JSON: ${e.message}');
    }

    if (root is! Map<String, Object?>) {
      throw ProfileBundleException('expected a JSON object at the top level');
    }

    final payload = root['payload'];
    final checksum = root['checksum'];
    if (payload is! Map<String, Object?> || checksum is! String) {
      throw ProfileBundleException('missing payload or checksum');
    }

    if (checksumOfString(jsonEncode(payload)) != checksum) {
      throw ProfileBundleException('checksum mismatch — the file is damaged');
    }

    final bundleVersion = (payload['bundleVersion'] as num?)?.toInt();
    if (bundleVersion == null) {
      throw ProfileBundleException('missing bundleVersion');
    }
    if (bundleVersion > kBundleVersion) {
      throw ProfileBundleException(
        'bundle version $bundleVersion is newer than this build supports '
        '($kBundleVersion) — update the app first',
      );
    }

    final profile = payload['profile'];
    if (profile is! Map<String, Object?>) {
      throw ProfileBundleException('missing profile');
    }

    return ProfileBundle(
      bundleVersion: bundleVersion,
      schemaVersion: (payload['schemaVersion'] as num?)?.toInt() ?? 0,
      exportedAt:
          DateTime.tryParse('${payload['exportedAt']}')?.toUtc() ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      profile: profile,
      vitals: payload['vitals'] as Map<String, Object?>?,
      chronicle: (payload['chronicle'] as List<Object?>? ?? const [])
          .whereType<Map<String, Object?>>()
          .toList(),
      settings: (payload['settings'] as Map<String, Object?>? ?? const {}).map(
        (k, v) => MapEntry(k, '$v'),
      ),
    );
  }
}

class ProfileTransfer {
  ProfileTransfer(this.db);

  final SaveDatabase db;

  /// Reads a profile out of the database into a bundle.
  Future<ProfileBundle> export(int profileId, {required DateTime now}) async {
    final profile = await db.profileById(profileId);
    if (profile == null) {
      throw ProfileBundleException('no profile with id $profileId');
    }

    final vitals = await db.vitalsFor(profileId);
    final chronicle = await (db.select(
      db.chronicleEntries,
    )..where((t) => t.profileId.equals(profileId))).get();
    final settings = await db.select(db.settings).get();

    return ProfileBundle(
      bundleVersion: kBundleVersion,
      schemaVersion: await db.storedSchemaVersion() ?? kSchemaVersion,
      exportedAt: now,
      profile: _profileToJson(profile),
      vitals: vitals == null ? null : _vitalsToJson(vitals),
      chronicle: chronicle.map(_chronicleToJson).toList(),
      settings: {for (final s in settings) s.key: s.value},
    );
  }

  /// Writes a bundle into the database as a new profile.
  ///
  /// Always inserts; importing never overwrites an existing character, so a
  /// mistaken restore cannot destroy a live streak. Returns the new id.
  Future<int> import(ProfileBundle bundle, {bool makeActive = true}) async {
    final profile = bundle.profile;

    return db.transaction(() async {
      if (makeActive) {
        await (db.update(db.profiles)..where((t) => t.isActive.equals(true)))
            .write(const ProfilesCompanion(isActive: Value(false)));
      }

      final id = await db
          .into(db.profiles)
          .insert(
            ProfilesCompanion.insert(
              name: '${profile['name']}',
              sex: '${profile['sex']}',
              ageYears: (profile['ageYears'] as num).toInt(),
              heightCm: (profile['heightCm'] as num).toInt(),
              weightKg: (profile['weightKg'] as num).toDouble(),
              deathMode: '${profile['deathMode']}',
              rngSeed: (profile['rngSeed'] as num).toInt(),
              createdAt: DateTime.parse('${profile['createdAt']}').toUtc(),
              diedAt: Value(
                profile['diedAt'] == null
                    ? null
                    : DateTime.parse('${profile['diedAt']}').toUtc(),
              ),
              deathCause: Value(profile['deathCause'] as String?),
              isActive: Value(makeActive),
            ),
          );

      final vitals = bundle.vitals;
      if (vitals != null) {
        await db
            .into(db.vitals)
            .insert(
              VitalsCompanion.insert(
                profileId: Value(id),
                lastUpdate: DateTime.parse('${vitals['lastUpdate']}').toUtc(),
                bloodMl: (vitals['bloodMl'] as num).toDouble(),
                waterMl: (vitals['waterMl'] as num).toDouble(),
                caloriesKcal: (vitals['caloriesKcal'] as num).toDouble(),
                heartRateBpm: (vitals['heartRateBpm'] as num).toDouble(),
                sleepDebtSeconds: Value(
                  (vitals['sleepDebtSeconds'] as num?)?.toInt() ?? 0,
                ),
                zone: Value('${vitals['zone'] ?? 'open'}'),
                latitude: Value((vitals['latitude'] as num?)?.toDouble()),
                longitude: Value((vitals['longitude'] as num?)?.toDouble()),
                accuracyM: Value((vitals['accuracyM'] as num?)?.toDouble()),
                rngCursors: Value('${vitals['rngCursors'] ?? '{}'}'),
              ),
            );
      }

      for (final entry in bundle.chronicle) {
        await db
            .into(db.chronicleEntries)
            .insert(
              ChronicleEntriesCompanion.insert(
                profileId: id,
                survivalDays: (entry['survivalDays'] as num).toInt(),
                startedAt: DateTime.parse('${entry['startedAt']}').toUtc(),
                endedAt: DateTime.parse('${entry['endedAt']}').toUtc(),
                cause: '${entry['cause']}',
                deathMode: '${entry['deathMode']}',
                snapshotJson: Value('${entry['snapshotJson'] ?? '{}'}'),
              ),
            );
      }

      for (final entry in bundle.settings.entries) {
        await db
            .into(db.settings)
            .insert(
              SettingsCompanion.insert(key: entry.key, value: entry.value),
              mode: InsertMode.insertOrReplace,
            );
      }

      return id;
    });
  }

  static Map<String, Object?> _profileToJson(Profile p) => {
    'name': p.name,
    'sex': p.sex,
    'ageYears': p.ageYears,
    'heightCm': p.heightCm,
    'weightKg': p.weightKg,
    'deathMode': p.deathMode,
    'rngSeed': p.rngSeed,
    'createdAt': p.createdAt.toUtc().toIso8601String(),
    'diedAt': p.diedAt?.toUtc().toIso8601String(),
    'deathCause': p.deathCause,
  };

  static Map<String, Object?> _vitalsToJson(Vital v) => {
    'lastUpdate': v.lastUpdate.toUtc().toIso8601String(),
    'bloodMl': v.bloodMl,
    'waterMl': v.waterMl,
    'caloriesKcal': v.caloriesKcal,
    'heartRateBpm': v.heartRateBpm,
    'sleepDebtSeconds': v.sleepDebtSeconds,
    'zone': v.zone,
    'latitude': v.latitude,
    'longitude': v.longitude,
    'accuracyM': v.accuracyM,
    'rngCursors': v.rngCursors,
  };

  static Map<String, Object?> _chronicleToJson(ChronicleEntry e) => {
    'survivalDays': e.survivalDays,
    'startedAt': e.startedAt.toUtc().toIso8601String(),
    'endedAt': e.endedAt.toUtc().toIso8601String(),
    'cause': e.cause,
    'deathMode': e.deathMode,
    'snapshotJson': e.snapshotJson,
  };
}
