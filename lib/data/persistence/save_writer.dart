/// Write policy for the three state layers (design doc §11.1.1).
///
/// Writing everything on every 1 Hz tick would grind the flash and the battery,
/// so each layer has its own cadence:
///
/// * **hot** — buffered in memory, flushed every 60 s and on every transition
///   to the background. Worst case a crash costs 60 seconds of physiology.
/// * **warm** — written through immediately, inside a transaction.
/// * **cold** — written on an explicit event (death, end of streak, settings).
///
/// Every path here goes through a transaction, so an interrupted write rolls
/// back rather than leaving a half-updated row (§11.1.2).
library;

import 'dart:convert';

import 'package:drift/drift.dart';

import '../../combat/pursuit.dart';
import '../../location/position_fix.dart';
import '../../map/geometry.dart';
import '../../sim/occupation.dart';
import '../../sim/physiology.dart';
import '../../sim/tick.dart';
import '../db/database.dart';

/// Reason a hot-layer flush happened. Recorded so the developer overlay can
/// show whether the cadence is behaving.
enum FlushReason {
  /// The 60 s cadence came round.
  cadence,

  /// App went to the background, or the foreground service is shutting down.
  lifecycle,

  /// A warm or cold write forced the hot layer out with it.
  coupled,

  /// Explicitly requested (export, snapshot, developer mode).
  manual,
}

class FlushResult {
  const FlushResult({
    required this.reason,
    required this.wrote,
    required this.at,
  });

  final FlushReason reason;

  /// False when there was nothing pending.
  final bool wrote;

  final DateTime at;

  @override
  String toString() => 'FlushResult($reason, wrote: $wrote)';
}

class SaveWriter {
  SaveWriter(this.db, {this.hotInterval = const Duration(seconds: 60)});

  final SaveDatabase db;

  /// How long the hot layer may stay unwritten (§11.1.1).
  final Duration hotInterval;

  VitalsCompanion? _pendingHot;
  DateTime? _lastHotFlush;

  /// Timestamp of the most recent hot-layer write.
  DateTime? get lastHotFlush => _lastHotFlush;

  bool get hasPendingHot => _pendingHot != null;

  /// Buffers hot state. Cheap: no I/O until a flush is due.
  void stageHot(VitalsCompanion vitals) => _pendingHot = vitals;

  /// True when the cadence has elapsed and something is pending.
  bool isFlushDue(DateTime now) {
    if (_pendingHot == null) return false;
    final last = _lastHotFlush;
    if (last == null) return true;
    return now.toUtc().difference(last) >= hotInterval;
  }

  /// Writes the pending hot state if the cadence is due.
  Future<FlushResult> flushIfDue(DateTime now) async {
    if (!isFlushDue(now)) {
      return FlushResult(
        reason: FlushReason.cadence,
        wrote: false,
        at: now.toUtc(),
      );
    }
    return flushHot(now, reason: FlushReason.cadence);
  }

  /// Writes the pending hot state unconditionally.
  ///
  /// Called from `onPause` and from the foreground service's `onDestroy`
  /// (§11.1.5) — the two moments when the process is most likely to be killed.
  Future<FlushResult> flushHot(
    DateTime now, {
    FlushReason reason = FlushReason.manual,
  }) async {
    final pending = _pendingHot;
    final at = now.toUtc();
    if (pending == null) {
      return FlushResult(reason: reason, wrote: false, at: at);
    }

    await db.writeVitals(pending);
    _pendingHot = null;
    _lastHotFlush = at;
    return FlushResult(reason: reason, wrote: true, at: at);
  }

  /// Runs a warm-layer change: inventory, skills, shelter, hotspots.
  ///
  /// Warm writes drag the hot layer along, because they mark a moment where
  /// the two must agree — picking an item up while the recorded position is a
  /// minute stale would put the loot in the wrong place after a crash.
  Future<T> writeWarm<T>(DateTime now, Future<T> Function() action) async {
    final result = await db.transaction(action);
    await flushHot(now, reason: FlushReason.coupled);
    return result;
  }

  /// Runs a cold-layer change: Chronicle, records, settings.
  Future<T> writeCold<T>(DateTime now, Future<T> Function() action) async {
    final result = await db.transaction(action);
    await flushHot(now, reason: FlushReason.coupled);
    await db.checkpoint();
    return result;
  }

  /// Flushes everything and checkpoints the WAL. Called when the app goes to
  /// the background so the `-wal` file never holds state the main file lacks.
  Future<FlushResult> quiesce(DateTime now) async {
    final result = await flushHot(now, reason: FlushReason.lifecycle);
    await db.checkpoint();
    return result;
  }

  /// Drops the buffer without writing. Used when a profile is deleted or a
  /// restore replaces the database underneath us.
  void discardPending() => _pendingHot = null;
}

/// Warstwa gorąca jako wiersz (§11.1.1).
///
/// ⚠️ **Mapowanie, nie logika — i dlatego mieszka tu, a nie w pętli.** Pętla
/// symuluje; to, którą kolumnę nazywa się jak, jest sprawą zapisu. Dopóki
/// siedziało w `GameLoop`, każda nowa kolumna rosła w pliku, który ma się
/// kurczyć (zapadka §16.1).
VitalsCompanion vitalsRow({
  required int profileId,
  required SimState state,
  required PositionFix? fix,
  required double speedKmh,
  required Occupation? occupation,
  required BleedTier bleeding,
  required DateTime? downUntil,
  required DateTime? graceUntil,
  required Pursuit? pursuit,

  /// §9.2.1: where the body actually dropped, for as long as it is on the
  /// ground. Null the rest of the time.
  GeoPoint? fellAt,
}) => VitalsCompanion(
  profileId: Value(profileId),
  lastUpdate: Value(state.lastUpdate),
  bloodMl: Value(state.bloodMl),
  waterMl: Value(state.waterMl),
  caloriesKcal: Value(state.caloriesKcal),
  pendingKcal: Value(state.pendingKcal),
  pendingWaterMl: Value(state.pendingWaterMl),
  heartRateBpm: Value(state.heartRateBpm),
  sleepDebtSeconds: Value(state.sleepDebtSeconds),
  sleepStrain: Value(state.sleepStrain),
  // §2.3: dwa zegary, na których wiszą reguły śmiertelne. Muszą przeżyć
  // ubicie procesu, inaczej zamknięcie aplikacji byłoby szklanką wody.
  bodyMassKg: Value(state.bodyMassKg),
  dryStreakSeconds: Value(state.dryStreakSeconds),
  starvedStreakSeconds: Value(state.starvedStreakSeconds),
  zone: Value(state.zone.wire),
  latitude: Value(fix?.latitude),
  longitude: Value(fix?.longitude),
  accuracyM: Value(fix?.accuracyM),
  speedKmh: Value(speedKmh),
  occupationJson: Value(
    occupation == null ? null : jsonEncode(occupation.toJson()),
  ),
  bleedTier: Value(bleeding.name),
  downUntil: Value(downUntil),
  graceUntil: Value(graceUntil),
  downLat: Value(fellAt?.latitude),
  downLon: Value(fellAt?.longitude),
  huntUntil: Value(pursuit?.until),
  huntLatitude: Value(pursuit?.at.latitude),
  huntLongitude: Value(pursuit?.at.longitude),
  huntCount: Value(pursuit?.count ?? 0),
);
