import 'dart:io';

import 'package:arls_za/journal/journal.dart';
import 'package:test/test.dart';

/// STREFA MÓWI, CO ZROBIŁA (§6.5.3, §6.5.4, §6.10).
///
/// ⚠️ **Awans był jedyną rzeczą, którą świat robił za plecami gracza — i nie
/// mówił o tym nikomu.** Strefa rośnie na własnym zegarze, także przez noc z
/// telefonem w szufladzie, więc gracz zastawał promień o osiemdziesiąt metrów
/// większy i nie miał skąd wiedzieć, że coś się zmieniło.
///
/// Zbicie strefy było drugą stroną tego samego: dwie godziny walki zostawiały
/// sam spokój i pustą kronikę.
void main() {
  group('§6.10: dwa zdarzenia, które kronika musiała umieć zapisać', () {
    test('awans i zbicie mają swoje rodzaje wpisu', () {
      expect(JournalKind.byWire('wzrost strefy'), JournalKind.zoneGrew);
      expect(JournalKind.byWire('strefa zbita'), JournalKind.zoneCleared);
    });

    test('awans nie budzi, zbicie budzi', () {
      // ⚠️ Strefa rośnie sama, także przez noc — wpis o awansie nie jest
      // dowodem, że ktoś wstał. Zbicie strefy jest dwiema godzinami walki i
      // nikt go nie przespał.
      expect(JournalKind.zoneGrew.wakes, isFalse);
      expect(JournalKind.zoneCleared.wakes, isTrue);
    });

    test('a nazwy na dysku są stałe', () {
      // §11.1: przemianowanie `wire` po cichu przeklasyfikowuje każdy wpis,
      // jaki gracz kiedykolwiek zapisał.
      expect(JournalKind.zoneGrew.wire, 'wzrost strefy');
      expect(JournalKind.zoneCleared.wire, 'strefa zbita');
    });
  });

  test('§6.5.3: i ktoś tego naprawdę używa', () {
    // ⚠️ Test źródłowy: trzynasty raz w tym projekcie łapiemy pole poprawne i
    // niewołane. Sam rodzaj wpisu bez pisania go jest właśnie tym.
    final main = File('lib/main.dart').readAsStringSync();
    final zones = File(
      'lib/game/controllers/hotspot_controller.dart',
    ).readAsStringSync();

    expect(zones.contains('grewTo.value = after'), isTrue);
    expect(main.contains('JournalKind.zoneGrew'), isTrue);
    expect(main.contains('JournalKind.zoneCleared'), isTrue);
    expect(
      main.contains('showZoneGrew('),
      isTrue,
      reason: 'okno, nie pasek na trzy sekundy — awansu nie da się przegapić',
    );
  });
}
