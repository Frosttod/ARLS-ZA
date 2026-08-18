import 'package:arls_za/ui/refresh_rate.dart';
import 'package:test/test.dart';

/// CZĘSTOTLIWOŚĆ ODŚWIEŻANIA (§3.3, §3.6).
///
/// Smoothness is a luxury bought with battery, and this game is played on a
/// walk that has to outlast it. So it goes at exactly the moment §3.3's other
/// luxuries go — no second setting, no second idea for the player to hold.
void main() {
  test('smooth while the battery can afford it', () async {
    final asked = <bool>[];
    final refresh = ScreenRefresh(
      apply: ({required bool high}) async => asked.add(high),
    );

    await refresh.want(economy: false);

    expect(asked, [true]);
  });

  test('and slow the moment §3.3 says the animations stop', () async {
    final asked = <bool>[];
    final refresh = ScreenRefresh(
      apply: ({required bool high}) async => asked.add(high),
    );

    await refresh.want(economy: false);
    await refresh.want(economy: true);

    expect(asked, [true, false]);
  });

  test('asked once, not every tick', () async {
    // ⚠️ The snapshot listener runs this on every publication of the loop —
    // several a second — and each call is a platform channel round trip.
    final asked = <bool>[];
    final refresh = ScreenRefresh(
      apply: ({required bool high}) async => asked.add(high),
    );

    for (var i = 0; i < 20; i++) {
      await refresh.want(economy: false);
    }

    expect(asked, hasLength(1));
  });

  test('a phone that refuses is asked again', () async {
    // A display mode that cannot be set is not worth a message to anybody —
    // the game plays fine at whatever the panel chose. But the memory of
    // having asked is dropped, so a later attempt is not skipped as a repeat.
    var attempts = 0;
    final refresh = ScreenRefresh(
      apply: ({required bool high}) async {
        attempts++;
        throw StateError('no such display mode');
      },
    );

    await refresh.want(economy: false);
    await refresh.want(economy: false);

    expect(attempts, 2);
  });
}
