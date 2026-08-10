/// Shared fixtures for the persistence tests.
library;

import 'package:arls_za/data/db/database.dart';
import 'package:arls_za/sim/tick.dart';
import 'package:drift/drift.dart';

/// The character sheet the design document uses as its worked example (§15.4):
/// male, 30 years, 180 cm, 80 kg.
const referenceConstants = SimConstants(
  bloodMaxMl: 5319,
  waterDailyMl: 2800,
  caloriesDailyKcal: 2450,
  restingHeartRate: 70,
  maxHeartRate: 187,
);

Future<int> insertProfile(
  SaveDatabase db, {
  String name = 'Ocalały',
  String deathMode = 'hardcore',
  int rngSeed = 42,
  DateTime? createdAt,
  bool isActive = true,
}) {
  final created = createdAt ?? DateTime.utc(2026, 8, 9, 12);
  return db.createProfile(
    profile: ProfilesCompanion.insert(
      name: name,
      sex: 'M',
      ageYears: 30,
      heightCm: 180,
      weightKg: 80,
      deathMode: deathMode,
      rngSeed: rngSeed,
      createdAt: created,
      isActive: Value(isActive),
    ),
    vitals: (id) => VitalsCompanion.insert(
      profileId: Value(id),
      lastUpdate: created,
      bloodMl: referenceConstants.bloodMaxMl,
      waterMl: referenceConstants.waterDailyMl,
      caloriesKcal: referenceConstants.caloriesDailyKcal,
      heartRateBpm: referenceConstants.restingHeartRate,
    ),
  );
}

VitalsCompanion vitalsFor(
  int profileId, {
  required DateTime lastUpdate,
  double bloodMl = 5319,
  double waterMl = 2800,
  double caloriesKcal = 2450,
  double heartRateBpm = 70,
  String zone = 'open',
}) => VitalsCompanion(
  profileId: Value(profileId),
  lastUpdate: Value(lastUpdate),
  bloodMl: Value(bloodMl),
  waterMl: Value(waterMl),
  caloriesKcal: Value(caloriesKcal),
  heartRateBpm: Value(heartRateBpm),
  zone: Value(zone),
);
