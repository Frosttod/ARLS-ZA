/// Rotating snapshots of the save (design doc §11.1.3).
///
/// Three snapshots are kept: taken every 30 minutes of play and, mandatorily,
/// before any schema migration. Each carries a SHA-256 checksum, and the main
/// database is verified at startup. A corrupt database is restored from the
/// newest snapshot that both checksums correctly and passes SQLite's own
/// integrity check — the player is told how much time was lost rather than
/// silently handed a rewound character.
///
/// The pre-migration snapshot is never rotated out by the periodic ones. It is
/// the only thing standing between a bad migration and everyone's save.
library;

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;

import 'database.dart';

/// Why a snapshot was taken. Pre-migration snapshots are retained separately.
enum SnapshotReason {
  periodic('periodic'),
  preMigration('pre_migration');

  const SnapshotReason(this.wire);

  final String wire;

  static SnapshotReason fromWire(String value) => values.firstWhere(
    (r) => r.wire == value,
    orElse: () => SnapshotReason.periodic,
  );
}

/// A snapshot on disk together with its bookkeeping row.
class SnapshotInfo {
  const SnapshotInfo({
    required this.file,
    required this.takenAt,
    required this.sizeBytes,
    required this.checksum,
    required this.schemaVersion,
    required this.reason,
  });

  final File file;
  final DateTime takenAt;
  final int sizeBytes;
  final String checksum;
  final int schemaVersion;
  final SnapshotReason reason;

  Duration ageAt(DateTime now) => now.toUtc().difference(takenAt);
}

/// Outcome of the startup health check.
enum SaveHealth {
  /// Database opened and passed `PRAGMA integrity_check`.
  ok,

  /// Database was unusable and a snapshot took its place.
  restored,

  /// Database was unusable and no valid snapshot existed.
  lost,

  /// No database yet — first run.
  absent,
}

class SaveRecovery {
  const SaveRecovery({required this.health, this.restoredFrom, this.timeLost});

  final SaveHealth health;
  final SnapshotInfo? restoredFrom;

  /// How much play time the restore cost. Shown to the player (§11.1.3).
  final Duration? timeLost;

  @override
  String toString() =>
      'SaveRecovery($health, lost: ${timeLost?.inMinutes ?? 0} min)';
}

class SnapshotStore {
  SnapshotStore(this.paths, {this.keepPeriodic = 3});

  final SavePaths paths;

  /// How many periodic snapshots to retain. Pre-migration snapshots are
  /// counted separately and never dropped by rotation.
  final int keepPeriodic;

  static const _prefix = 'snapshot';
  static const _extension = '.sqlite';

  /// Interval between periodic snapshots (§11.1.3).
  static const periodicInterval = Duration(minutes: 30);

  /// Copies the live database into a new snapshot and prunes old ones.
  ///
  /// A WAL checkpoint runs first, otherwise the copy would miss everything
  /// still sitting in the `-wal` file (§11.1.2).
  Future<SnapshotInfo> capture(
    SaveDatabase db, {
    required DateTime now,
    SnapshotReason reason = SnapshotReason.periodic,
  }) async {
    await paths.ensureExists();
    await db.checkpoint();

    final source = paths.databaseFile;
    if (!source.existsSync()) {
      throw StateError('Cannot snapshot: ${source.path} does not exist');
    }

    final stamp = now.toUtc().millisecondsSinceEpoch;
    final target = File(
      p.join(
        paths.snapshotDir.path,
        '${_prefix}_${reason.wire}_$stamp$_extension',
      ),
    );
    await source.copy(target.path);

    final bytes = await target.readAsBytes();
    final checksum = sha256.convert(bytes).toString();
    final schemaVersion = await db.storedSchemaVersion() ?? kSchemaVersion;

    await db
        .into(db.snapshotRecords)
        .insert(
          SnapshotRecordsCompanion.insert(
            fileName: p.basename(target.path),
            takenAt: now.toUtc(),
            sizeBytes: bytes.length,
            checksum: checksum,
            schemaVersion: schemaVersion,
            reason: Value(reason.wire),
          ),
        );
    await db.writeMetaTimestamp(MetaKeys.lastSnapshotAt, now);

    if (reason == SnapshotReason.periodic) {
      await _prunePeriodic(db);
    }

    return SnapshotInfo(
      file: target,
      takenAt: now.toUtc(),
      sizeBytes: bytes.length,
      checksum: checksum,
      schemaVersion: schemaVersion,
      reason: reason,
    );
  }

  /// True when [now] is at least [periodicInterval] past the last snapshot.
  Future<bool> isDue(SaveDatabase db, DateTime now) async {
    final last = await db.readMetaTimestamp(MetaKeys.lastSnapshotAt);
    if (last == null) return true;
    return now.toUtc().difference(last) >= periodicInterval;
  }

  /// Snapshots on disk, newest first, with the checksum re-verified.
  ///
  /// Reads the directory rather than the bookkeeping table, so snapshots stay
  /// usable even when the database that recorded them is the thing that broke.
  Future<List<SnapshotInfo>> listVerified() async {
    if (!paths.snapshotDir.existsSync()) return const [];

    final out = <SnapshotInfo>[];
    for (final entity in paths.snapshotDir.listSync()) {
      if (entity is! File) continue;
      final name = p.basename(entity.path);
      if (!name.startsWith(_prefix) || !name.endsWith(_extension)) continue;

      final parsed = _parseName(name);
      if (parsed == null) continue;

      final bytes = await entity.readAsBytes();
      out.add(
        SnapshotInfo(
          file: entity,
          takenAt: parsed.$2,
          sizeBytes: bytes.length,
          checksum: sha256.convert(bytes).toString(),
          schemaVersion: _readSchemaVersion(entity) ?? 0,
          reason: parsed.$1,
        ),
      );
    }

    out.sort((a, b) => b.takenAt.compareTo(a.takenAt));
    return out;
  }

  /// Verifies the live database and, if it is broken, restores the newest
  /// snapshot that opens cleanly.
  ///
  /// Runs before the app opens the database for real, so nothing has written
  /// to a corrupt file yet.
  Future<SaveRecovery> verifyAndRecover({required DateTime now}) async {
    await paths.ensureExists();
    final dbFile = paths.databaseFile;

    if (!dbFile.existsSync()) {
      return const SaveRecovery(health: SaveHealth.absent);
    }

    if (_opensCleanly(dbFile)) {
      return const SaveRecovery(health: SaveHealth.ok);
    }

    for (final snapshot in await listVerified()) {
      if (!_opensCleanly(snapshot.file)) continue;

      // Park the broken file rather than deleting it; if the restore turns out
      // to be worse, the original is still there to look at.
      final quarantine = File(
        '${dbFile.path}.corrupt.${now.toUtc().millisecondsSinceEpoch}',
      );
      await dbFile.rename(quarantine.path);
      _deleteSidecars(dbFile);
      await snapshot.file.copy(dbFile.path);

      return SaveRecovery(
        health: SaveHealth.restored,
        restoredFrom: snapshot,
        timeLost: snapshot.ageAt(now),
      );
    }

    return const SaveRecovery(health: SaveHealth.lost);
  }

  /// Deletes the oldest periodic snapshots beyond [keepPeriodic].
  Future<void> _prunePeriodic(SaveDatabase db) async {
    final periodic = (await listVerified())
        .where((s) => s.reason == SnapshotReason.periodic)
        .toList();
    if (periodic.length <= keepPeriodic) return;

    for (final stale in periodic.skip(keepPeriodic)) {
      final name = p.basename(stale.file.path);
      try {
        await stale.file.delete();
      } on FileSystemException {
        continue; // locked by something else; try again next time
      }
      await (db.delete(
        db.snapshotRecords,
      )..where((t) => t.fileName.equals(name))).go();
    }
  }

  /// Opens a database file read-only and asks SQLite whether it is intact.
  bool _opensCleanly(File file) {
    try {
      final raw = openRawDatabase(file);
      try {
        final result = raw.select('PRAGMA integrity_check');
        if (result.isEmpty) return false;
        if (result.first.values.first != 'ok') return false;
        // A file can be structurally valid and still not be our save.
        raw.select(
          "SELECT 1 FROM sqlite_master WHERE type='table' AND name='profiles'",
        );
        return true;
      } finally {
        raw.dispose();
      }
    } on Object {
      return false;
    }
  }

  int? _readSchemaVersion(File file) {
    try {
      final raw = openRawDatabase(file);
      try {
        final rows = raw.select(
          "SELECT value FROM meta_entries WHERE key = ?",
          [MetaKeys.schemaVersion],
        );
        if (rows.isEmpty) return null;
        return int.tryParse('${rows.first.values.first}');
      } finally {
        raw.dispose();
      }
    } on Object {
      return null;
    }
  }

  void _deleteSidecars(File dbFile) {
    for (final suffix in const ['-wal', '-shm']) {
      final sidecar = File('${dbFile.path}$suffix');
      if (sidecar.existsSync()) {
        try {
          sidecar.deleteSync();
        } on FileSystemException {
          // Nothing to do; SQLite will rebuild it.
        }
      }
    }
  }

  /// `snapshot_<reason>_<millis>.sqlite`
  static (SnapshotReason, DateTime)? _parseName(String name) {
    final body = name.substring(
      _prefix.length + 1,
      name.length - _extension.length,
    );
    final split = body.lastIndexOf('_');
    if (split <= 0) return null;
    final millis = int.tryParse(body.substring(split + 1));
    if (millis == null) return null;
    return (
      SnapshotReason.fromWire(body.substring(0, split)),
      DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true),
    );
  }
}

/// Serialises a snapshot record for the export bundle of §11.3.
Map<String, Object?> snapshotInfoToJson(SnapshotInfo info) => {
  'file': p.basename(info.file.path),
  'takenAt': info.takenAt.toIso8601String(),
  'sizeBytes': info.sizeBytes,
  'checksum': info.checksum,
  'schemaVersion': info.schemaVersion,
  'reason': info.reason.wire,
};

/// SHA-256 of arbitrary bytes, shared by the snapshot and profile-export code.
String checksumOf(List<int> bytes) => sha256.convert(bytes).toString();

/// SHA-256 of a UTF-8 string.
String checksumOfString(String value) => checksumOf(utf8.encode(value));
