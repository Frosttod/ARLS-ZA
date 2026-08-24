import 'dart:io';
import 'dart:math';

import 'package:arls_za/combat/aim.dart';
import 'package:arls_za/combat/ballistics.dart';
import 'package:arls_za/combat/enemy.dart';
import 'package:arls_za/combat/magazine.dart';
import 'package:arls_za/craft/item_recipe.dart';
import 'package:arls_za/inventory/item_use.dart';
import 'package:arls_za/items/item_catalogue.dart';
import 'package:arls_za/loot/search.dart';
import 'package:arls_za/map/geometry.dart';
import 'package:arls_za/sim/body.dart';
import 'package:arls_za/sim/tick.dart';
import 'package:test/test.dart';

/// UMIEJĘTNOŚCI MUSZĄ GRYŹĆ (§7).
///
/// ⚠️ **The same defect the physiology stage was built to fix, one section
/// later.** Eight functions in this codebase took a skill and defaulted it to
/// nought, and not one call site filled it in — so §7's whole table was a
/// column of figures nothing could reach.
///
/// A number nobody reads is worse than a missing feature: the interface says
/// the bonus is happening, so the player plays around a rule that is not
/// there. These tests hold every one of §7's effects to a consumer, and the
/// last one holds the wiring itself at source level — because that is where
/// the defect lives. A parameter with a harmless default is always correct in
/// isolation.
void main() {
  final catalogue = ItemCatalogue.load([
    for (final asset in kBundledItemAssets)
      ItemSource(asset, File(asset).readAsStringSync()),
  ]);

  group('§7: Zwiad', () {
    test('§10.2.2: the radius doubles at full mastery', () {
      // The strongest single effect in §7, and the one §10.2.2 warns about:
      // twice the radius is four times the ground looked over.
      expect(searchRadiusM(scouting: 1), searchRadiusM() * 2);
      expect(searchRadiusM(scouting: 0.5), searchRadiusM() * 1.5);
    });

    test('a search takes less of §10.2\'s forty-five seconds', () {
      final novice = Search.area(at: _here, now: _t0);
      final master = Search.area(at: _here, now: _t0, scouting: 1);

      expect(
        master.requiredTime.inSeconds,
        (novice.requiredTime.inSeconds * (1 - kScoutingSpeed)).round(),
      );
    });

    test('and it never goes free', () {
      // §10.2's stillness is the decision the whole system is built on. A
      // skill that removed it would remove the decision.
      expect(
        Search.area(at: _here, now: _t0, scouting: 1).requiredTime,
        greaterThan(Duration.zero),
      );
    });

    test('§6.2: a Walker notices a master later', () {
      final walker = Enemy.spawn(
        id: 'w',
        kind: EnemyKind.walker,
        at: _here,
        home: _here,
        random: Random(1),
      );

      expect(walker.sightAgainst(0), walker.sightM);
      expect(
        walker.sightAgainst(1),
        closeTo(walker.sightM * (1 - kScoutingStealth), 0.001),
      );
    });
  });

  group('§7: Walka', () {
    test('§5.1.1: the hands go from 25 MOA to 4', () {
      expect(skillMoa(0), 25);
      expect(skillMoa(1), 4);
    });

    test('a reload is shorter', () {
      final rifle = catalogue['weapon_rifle_545']!;

      expect(
        reloadTime(rifle, weapons: 1).inMilliseconds,
        (reloadTime(rifle).inMilliseconds * (1 - kWeaponsSpeed)).round(),
      );
    });

    test('§5.3: and the sights settle faster', () {
      final novice = settleTime(heartRate: 70, rest: 70, max: 190);
      final master = settleTime(heartRate: 70, rest: 70, max: 190, weapons: 1);

      expect(master, lessThan(novice));
      expect(
        master.inMilliseconds,
        (novice.inMilliseconds * (1 - kWeaponsSpeed)).round(),
      );
    });

    test('§2.4 still applies on top of it', () {
      // ⚠️ A master out of breath is slower than a master standing still.
      // That is the point of §2.4 having a penalty at all, and a skill that
      // cancelled it would delete the section.
      final calm = settleTime(heartRate: 70, rest: 70, max: 190, weapons: 1);
      final racing = settleTime(heartRate: 180, rest: 70, max: 190, weapons: 1);

      expect(racing, greaterThan(calm));
    });
  });

  group('§7: Leczenie', () {
    test('§4.7: a dressing takes less time', () {
      final bandage = catalogue['med_bandage']!;

      final novice = useOf(bandage)!;
      final master = useOf(bandage, medicine: 1)!;

      expect(
        master.duration.inMilliseconds,
        closeTo(novice.duration.inMilliseconds * (1 - kMedicineSpeed), 20),
      );
    });

    test('and nothing else does (§7.1)', () {
      // ⚠️ §7.1 is explicit about the shape of this mistake in the other
      // direction — reading a weapons encyclopaedia must not depend on
      // medical knowledge. The same rule holds here: knowing how to pack a
      // wound does not help anybody open a tin.
      final tin = catalogue['food_canned_meat']!;

      expect(useOf(tin, medicine: 1)!.duration, useOf(tin)!.duration);
    });

    test('§2.6: and a wound mends faster while asleep', () {
      final body = BodyProfile.from(
        const BodySpec(
          sex: Sex.male,
          ageYears: 35,
          heightCm: 180,
          weightKg: 80,
        ),
      );
      final constants = body.toSimConstants();

      double bloodAfter(double medicine) => advanceInChunks(
        state: SimState.fresh(
          at: DateTime.utc(2026),
          constants: constants,
          massKg: 80,
        ).copyWith(bloodMl: constants.bloodMaxMl * 0.75),
        constants: constants,
        input: TickInput(sleeping: true, medicine: medicine),
        elapsed: const Duration(hours: 8),
      ).state.bloodMl;

      expect(bloodAfter(1), greaterThan(bloodAfter(0)));
    });
  });

  group('§7: Inżynieria', () {
    test('§18.6: a better share comes back', () {
      expect(salvageShare(), kSalvageReturn);
      expect(salvageShare(engineering: 1), kSalvageReturnSkilled);
    });
  });

  test('§7: nothing may take the skills back out again', () {
    // ⚠️ Source-level, in the same spirit as the one-action and
    // penalties-bite budgets. The defect these guard against is not a wrong
    // number — it is a parameter with a harmless default that nobody fills
    // in, which no test of the function itself can ever catch.
    final main = File('lib/main.dart').readAsStringSync();

    for (final wiring in [
      'skill: _learned.weapons', // §5.1.1 and §5.4
      // §5.5.1's target switch, the reload and the settling. The switch used
      // to read `weaponSkill:` here; it moved into aimedAt() with the rest of
      // §5.1's inputs, so the screen can no longer forget one of them.
      'weapons: _learned.weapons',
      'scouting: _learned.scouting', // radius, rare share, search time, stealth
      'medicine: _learned.medicine', // §4.7's dressings
      'engineering: _learned.engineering', // §8.3, §18.4, §18.6
      'loop.medicine = _learned.medicine', // §2.6's regeneration
      'await _learned.load(', // or none of it is there at boot
      'aimedAt(', // §5.5.1: and the switch still goes through the model
    ]) {
      expect(
        main.contains(wiring),
        isTrue,
        reason: '$wiring is gone — that skill stopped doing anything',
      );
    }
  });
}

const _here = GeoPoint(52.4, 16.9);
final _t0 = DateTime.utc(2026);
