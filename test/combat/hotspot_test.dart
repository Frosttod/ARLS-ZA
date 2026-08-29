import 'dart:math';

import 'package:arls_za/combat/enemy.dart';
import 'package:arls_za/combat/hotspot.dart';
import 'package:arls_za/map/geometry.dart';
import 'package:arls_za/sim/play_habit.dart';
import 'package:flutter_test/flutter_test.dart';

/// OGNISKA — PRESJA, KTÓRA ROŚNIE SAMA (§6.5).
///
/// Everything else in this game is something the player does. This is the one
/// thing the game does back, and every number in it is a difficulty curve —
/// so these tests are mostly arithmetic, and the arithmetic is the design.
void main() {
  final now = DateTime.utc(2026, 8, 20, 12);
  const centre = GeoPoint(52.4064, 16.9252);

  Hotspot at(int level, {int seed = 7, double integrity = -1}) => Hotspot(
    id: 'hs.0',
    seed: seed,
    centre: centre,
    level: level,
    integrity: integrity < 0 ? integrityMaxAt(level).toDouble() : integrity,
    bornAt: now,
    nextLevelAt: now.add(const Duration(hours: 8)),
  );

  group('the geometry closes (§6.5.1)', () {
    test('the worst case still leaves the door alone', () {
      // ⚠️ The check §6.5.1 does in prose, done in numbers: a hotspot at the
      // minimum distance, grown to its maximum radius, against §8.1's fifty
      // metre safe zone. If this ever fails, a level-ten hotspot can swallow
      // somebody's front door and the game becomes unplayable from home.
      const safeZoneM = 50.0;
      final edge = kHotspotMinFromShelterM - kHotspotMaxRadiusM;

      expect(edge, 300);
      expect(edge - safeZoneM, 250, reason: 'the buffer §6.5.1 promises');
    });

    test('two of them at the minimum spacing never touch', () {
      // Without this rule two level-ten hotspots merge into an impassable
      // area 800 m across.
      final gap = kHotspotMinApartM - 2 * kHotspotMaxRadiusM;

      expect(gap, 50);
    });
  });

  group('levels (§6.5.2)', () {
    test('the table has ten rows and they only get worse', () {
      expect(kHotspotLevels, hasLength(10));

      for (var i = 1; i < kHotspotLevels.length; i++) {
        expect(
          kHotspotLevels[i].enemyCap,
          greaterThanOrEqualTo(kHotspotLevels[i - 1].enemyCap),
          reason: 'level ${i + 1} holds no fewer than level $i',
        );
        expect(
          kHotspotLevels[i].respawn,
          lessThanOrEqualTo(kHotspotLevels[i - 1].respawn),
          reason: 'level ${i + 1} refills no slower than level $i',
        );
      }
    });

    test('a new one is twenty metres across the middle', () {
      expect(hotspotRadiusM(7, 1), kHotspotFirstRadiusM);
    });

    test(
      'and grows fourteen to twenty-six a level, never past two hundred',
      () {
        for (var seed = 0; seed < 50; seed++) {
          for (var level = 2; level <= 10; level++) {
            final step =
                hotspotRadiusM(seed, level) - hotspotRadiusM(seed, level - 1);
            if (hotspotRadiusM(seed, level) >= kHotspotMaxRadiusM) continue;

            expect(step, greaterThanOrEqualTo(14));
            expect(step, lessThanOrEqualTo(26));
          }
          expect(
            hotspotRadiusM(seed, 10),
            lessThanOrEqualTo(kHotspotMaxRadiusM),
          );
        }
      },
    );

    test('shrinking is the exact inverse of growing', () {
      // ⚠️ The reason the radius is derived from the seed rather than stored.
      // §6.5.4 shrinks a demoted hotspot "to the previous level's radius", and
      // a stored figure cannot give back metres whose random draw is gone.
      final grown = at(1).promoted(at: now, until: const Duration(hours: 8));
      final higher = grown.promoted(at: now, until: const Duration(hours: 8));

      final back = higher.demoted(at: now, restFor: const Duration(hours: 24));

      expect(back.level, 2);
      expect(back.radiusM, grown.radiusM);
    });

    test('nothing but Walkers below level four', () {
      for (var level = 1; level <= 3; level++) {
        expect(compositionAt(level).toSet(), {EnemyKind.walker});
      }
    });

    test('and Brutes only from level seven (§5, wniosek 3)', () {
      // The progression gate the ballistics appendix leans on: a Brute takes
      // nine axe swings, which is seventeen seconds of contact and death.
      for (var level = 1; level <= 6; level++) {
        expect(
          compositionAt(level),
          isNot(contains(EnemyKind.brute)),
          reason: 'level $level',
        );
      }
      expect(compositionAt(7), contains(EnemyKind.brute));
    });

    test('the shares in the bag are the shares in the table', () {
      final bag = compositionAt(9);
      final brutes = bag.where((k) => k == EnemyKind.brute).length;
      final leapers = bag.where((k) => k == EnemyKind.leaper).length;

      expect(bag, hasLength(100));
      expect(brutes, 20);
      expect(leapers, 35);
    });
  });

  group('neutralising one (§6.5.4)', () {
    test('integrity is sixty plus twenty a level', () {
      expect(integrityMaxAt(1), 80);
      expect(integrityMaxAt(10), 260);
    });

    test('a kill inside the circle is worth ten, outside five', () {
      // ⚠️ **Ten samo, niezależnie od gatunku.** Punktacja po gatunku —
      // Kroczący dziesięć, Skoczek piętnaście, Brutal trzydzieści pięć —
      // nagradzała wybieranie najgroźniejszego celu, czyli dokładnie to, czego
      // §6.5.4 nie chce: strefę zbija się wytrzymałością, nie jednym
      // bohaterskim zamachem. Kto to jest, decyduje o **koszcie** zabicia.
      for (final kind in EnemyKind.values) {
        expect(killPoints(kind, insideRadius: true), 10, reason: kind.name);
        expect(killPoints(kind, insideRadius: false), 5, reason: kind.name);
      }
    });

    test('luring them out is about twice as slow, and never faster', () {
      // The whole trade §6.5.4 offers, and the direction matters more than
      // the exact figure: if a kill outside the circle were ever worth as much
      // as one inside it, there would be no reason to fight inside — and the
      // circle is the thing being neutralised.
      //
      // Dokładnie dwa, odkąd punktacja jest jednakowa: dziesięć w kole i
      // pięć poza nim, dla każdego gatunku. The
      // rounding always favours the hotspot, which is the right way round.
      for (final kind in EnemyKind.values) {
        final inside = killPoints(kind, insideRadius: true);
        final outside = killPoints(kind, insideRadius: false);

        expect(outside, inside ~/ 2, reason: kind.name);
        expect(outside * 2, lessThanOrEqualTo(inside), reason: kind.name);
      }
    });

    test('a body outside the radius pays half, whatever the level', () {
      final hotspot = at(5);
      final far = GeoPoint(centre.latitude + 0.01, centre.longitude);

      final hit = hotspot.damagedBy(EnemyKind.leaper, at: far);

      expect(hotspot.integrity - hit.integrity, 5);
    });

    test('and inside it pays whole', () {
      final hotspot = at(5);

      final hit = hotspot.damagedBy(EnemyKind.leaper, at: centre);

      expect(hotspot.integrity - hit.integrity, 10);
    });

    test('integrity comes back at five per cent an hour, and stops full', () {
      final hurt = at(10, integrity: 100);

      final hour = hurt.regenerated(const Duration(hours: 1));
      expect(hour.integrity, closeTo(100 + 13, 0.01));

      final forever = hurt.regenerated(const Duration(days: 7));
      expect(forever.integrity, integrityMaxAt(10).toDouble());
    });
  });

  group('agitation (§6.5.4)', () {
    test('losing a level fills the wall back up at the lower one', () {
      // ⚠️ Otherwise a hotspot would be at its weakest the moment it became
      // hardest, and knocking it down would be a run of free levels.
      final knocked = at(
        8,
        integrity: 0,
      ).demoted(at: now, restFor: const Duration(hours: 24));

      expect(knocked.level, 7);
      expect(knocked.integrity, integrityMaxAt(7).toDouble());
    });

    test('and it is furious for ten minutes', () {
      final knocked = at(
        8,
        integrity: 0,
      ).demoted(at: now, restFor: const Duration(hours: 24));

      expect(knocked.isAgitatedAt(now), isTrue);
      expect(
        knocked.isAgitatedAt(now.add(const Duration(minutes: 11))),
        isFalse,
      );
    });

    test('fury is half again as many of them, three times as fast', () {
      final calm = at(8);
      final furious = calm.copyWith(
        agitatedUntil: now.add(const Duration(minutes: 5)),
      );

      expect(calm.enemyCapAt(now), 9);
      expect(furious.enemyCapAt(now), 14);
      expect(calm.respawnAt(now), const Duration(minutes: 5));
      expect(furious.respawnAt(now), const Duration(minutes: 5) ~/ 3);
    });

    test('and everything comes back one rung up the ladder', () {
      // This is what makes knocking a level off a level-ten hotspot a fight
      // against twelve Brutes rather than a victory lap.
      final furious = compositionAt(10, agitated: true);

      expect(furious, isNot(contains(EnemyKind.walker)));
      expect(furious.where((k) => k == EnemyKind.brute).length, 60);
    });

    test('walking four hundred metres away ends it (§6.5.4 valve)', () {
      // ⚠️ The one rule here that exists to let a player lose. Without it,
      // agitation is a death spiral with no exit — and the mechanic would
      // punish the attempt rather than the mistake.
      final furious = at(
        8,
      ).copyWith(agitatedUntil: now.add(const Duration(minutes: 9)));

      final near = GeoPoint(centre.latitude + 0.001, centre.longitude);
      final far = GeoPoint(centre.latitude + 0.006, centre.longitude);

      expect(near.distanceTo(centre), lessThan(kAgitationEscapeM));
      expect(far.distanceTo(centre), greaterThan(kAgitationEscapeM));

      expect(furious.settledIfAbandoned(near).isAgitatedAt(now), isTrue);
      expect(furious.settledIfAbandoned(far).isAgitatedAt(now), isFalse);
    });
  });

  group('clearing one (§6.5.4)', () {
    test('level one down is an empty slot, not a hotspot at nought', () {
      final gone = at(
        1,
        integrity: 0,
      ).demoted(at: now, restFor: const Duration(hours: 30));

      expect(gone.isResting, isTrue);
      expect(gone.radiusM, 0);
      expect(gone.enemyCapAt(now), 0, reason: 'an empty slot sends nothing');
      expect(gone.restingUntil, now.add(const Duration(hours: 30)));
    });

    test('a resting slot takes no damage and heals nothing', () {
      final resting = at(
        1,
        integrity: 0,
      ).demoted(at: now, restFor: const Duration(hours: 30));

      expect(resting.damagedBy(EnemyKind.brute, at: centre).integrity, 0);
      expect(resting.regenerated(const Duration(days: 1)).integrity, 0);
    });

    test('and comes back somewhere else at level one', () {
      const elsewhere = GeoPoint(52.42, 16.90);
      final resting = at(
        1,
        integrity: 0,
      ).demoted(at: now, restFor: const Duration(hours: 30));

      final fresh = resting.reborn(
        centre: elsewhere,
        seed: 42,
        at: now.add(const Duration(hours: 30)),
        until: const Duration(hours: 8),
      );

      expect(fresh.level, 1);
      expect(fresh.centre, elsewhere);
      expect(fresh.integrity, integrityMaxAt(1).toDouble());
      expect(fresh.isResting, isFalse);
    });
  });

  group('growth (§6.5.3, §16.4)', () {
    PlayHabit habitOf(int minutesPerDay) => PlayHabit([
      for (var i = 0; i < 7; i++)
        PlayDay(
          day: now.subtract(Duration(days: i)),
          activeMinutes: minutesPerDay,
        ),
    ]);

    test('the interval falls from eight hours to a floor of two', () {
      expect(promotionIntervalHours(1), closeTo(7.75, 0.01));
      expect(promotionIntervalHours(12), closeTo(5, 0.01));
      expect(promotionIntervalHours(24), 2);
      expect(promotionIntervalHours(100), 2, reason: 'the floor holds');
    });

    test('somebody who plays more meets it sooner', () {
      // §16.4's actual question. If this inverts, the world runs faster for
      // the player who opens the app less — which was the first version, and
      // it punished a small habit.
      final light = promotionDelay(
        survivalDay: 5,
        habit: habitOf(20),
        random: Random(1),
      );
      final heavy = promotionDelay(
        survivalDay: 5,
        habit: habitOf(180),
        random: Random(1),
      );

      expect(heavy, lessThan(light));
    });

    test('and nobody escapes it entirely', () {
      final absent = promotionDelay(
        survivalDay: 5,
        habit: const PlayHabit([]),
        random: Random(1),
      );

      expect(absent.inDays, lessThan(30), reason: 'the world moves regardless');
    });

    test('a promotion arrives with the wall repaired', () {
      final grown = at(
        4,
        integrity: 3,
      ).promoted(at: now, until: const Duration(hours: 6));

      expect(grown.level, 5);
      expect(grown.integrity, integrityMaxAt(5).toDouble());
      expect(grown.nextLevelAt, now.add(const Duration(hours: 6)));
    });

    test('level ten does not become eleven', () {
      final capped = at(10).promoted(at: now, until: const Duration(hours: 2));

      expect(capped.level, 10);
      expect(capped.nextLevelAt, now.add(const Duration(hours: 2)));
    });
  });

  group('§6.5.3, §6.5.4: STREFY ROZKŁADU — nowe reguły', () {
    final t0 = DateTime.utc(2026, 8, 30, 12);

    test('wzrost to doba do dwóch dób, nie osiem godzin świata', () {
      // ⚠️ Poprzednia formuła liczyła w godzinach świata i po przeliczeniu
      // przez tempo gry dawała strefę rosnącą szybciej, niż da się ją zbić.
      // Miasto ma się psuć przez tygodnie, nie przez popołudnie.
      final hour = PlayHabit([
        for (var day = 0; day < 7; day++)
          PlayDay(day: t0.subtract(Duration(days: day)), activeMinutes: 60),
      ]);

      for (var seed = 0; seed < 40; seed++) {
        final wait = promotionDelay(
          survivalDay: 1,
          habit: hour,
          random: Random(seed),
        ).inHours;

        expect(wait, greaterThanOrEqualTo(20));
        expect(wait, lessThanOrEqualTo(52));
      }
    });

    test('kto gra więcej, temu rośnie szybciej — i nikomu bez końca', () {
      PlayHabit habitOf(int minutes) => PlayHabit([
        for (var day = 0; day < 7; day++)
          PlayDay(
            day: t0.subtract(Duration(days: day)),
            activeMinutes: minutes,
          ),
      ]);

      final busy = promotionDelay(
        survivalDay: 1,
        habit: habitOf(240),
        random: Random(1),
      );
      final absent = promotionDelay(
        survivalDay: 1,
        habit: habitOf(0),
        random: Random(1),
      );

      expect(busy, lessThan(absent));
      expect(busy.inHours, greaterThanOrEqualTo(kZoneGrowthFloorHours.round()));
      expect(
        absent.inHours,
        lessThanOrEqualTo(kZoneGrowthCeilingHours.round()),
      );
    });

    test('bariera nie odrasta, kiedy gracz stoi w środku', () {
      // ⚠️ Pasek leczący się w trakcie walki czyta się jak błąd, nawet gdy
      // wobec tempa zabijania jest arytmetycznie bez znaczenia.
      final hurt = at(10, integrity: 100);

      final alone = hurt.regenerated(const Duration(hours: 1));
      final watched = hurt.regenerated(
        const Duration(hours: 1),
        playerAt: centre,
      );

      expect(alone.integrity, greaterThan(hurt.integrity));
      expect(watched.integrity, hurt.integrity);
    });

    test('a poza kołem odrasta normalnie', () {
      final hurt = at(5, integrity: 50);
      final far = GeoPoint(centre.latitude + 0.02, centre.longitude);

      expect(
        hurt.regenerated(const Duration(hours: 1), playerAt: far).integrity,
        greaterThan(hurt.integrity),
      );
    });

    group('§6.5.4: wysyp', () {
      test('wolno raz, potem godzina blokady', () {
        final spot = at(7);

        expect(spot.maySurgeAt(t0), isTrue);

        final after = spot.surged(at: t0);
        expect(after.maySurgeAt(t0.add(const Duration(minutes: 59))), isFalse);
        expect(after.maySurgeAt(t0.add(const Duration(minutes: 61))), isTrue);
      });

      test('i wypuszcza połowę limitu ponad limit', () {
        final spot = at(10).surged(at: t0);

        // Dziesiątka wypuszcza dwunastu; wysyp dokłada sześciu.
        expect(spot.surgeExtraAt(t0), 6);
      });

      test('ale tylko dopóki trwa furia', () {
        final spot = at(10).surged(at: t0);

        expect(spot.surgeExtraAt(t0.add(kAgitationLength * 2)), 0);
      });

      test('odpoczywający slot nie wysypuje niczego', () {
        final resting = at(
          1,
        ).demoted(at: t0, restFor: const Duration(hours: 24));

        expect(resting.isResting, isTrue);
        expect(resting.maySurgeAt(t0), isFalse);
      });
    });

    test('§10.3: i po zbitej strefie coś zostaje', () {
      // ⚠️ Dotąd nie zostawało nic: dwie godziny ciągłej walki przeciw
      // rosnącemu oporowi, a jedyną nagrodą był spokój, czyli brak czegoś.
      expect(kZoneCache, isNotEmpty);
      for (final entry in kZoneCache.entries) {
        final (low, high) = entry.value;
        expect(low, greaterThan(0), reason: entry.key);
        expect(high, greaterThanOrEqualTo(low), reason: entry.key);
      }
    });
  });
}
