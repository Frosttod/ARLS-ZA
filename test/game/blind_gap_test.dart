import 'package:arls_za/game/blind_gap.dart';
import 'package:test/test.dart';

/// NOCY W SCHRONIE NIE LICZY SIĘ Z ULICY (§2.5.1, §2.1a.3, §11.1.2).
///
/// ⚠️ **Zgłoszone z terenu: „noc 100% w schronie, a dług senny został".** Gracz
/// wyszedł ze schronu wieczorem, aplikacja zgasła na ulicy, wrócił do domu i
/// przespał noc. Odtworzenie przerwy brało ostatnią zapisaną pozycję — tę
/// ulicę — więc osiem godzin snu wracało jako osiem godzin czuwania na dworze.
void main() {
  final now = DateTime.utc(2026, 8, 31, 4, 30);
  DateTime ago(Duration back) => now.subtract(back);

  bool holds({
    Duration gap = const Duration(hours: 8),
    bool hasShelters = true,
    bool inShelter = false,
    DateTime? fixAt,
    DateTime? waitingSince,
  }) => holdsBlindGap(
    now: now,
    lastUpdate: ago(gap),
    hasShelters: hasShelters,
    inShelter: inShelter,
    fixAt: fixAt,
    waitingSince: waitingSince,
  );

  group('§2.5.1: kiedy warto poczekać na odczyt', () {
    test('po nocy z zamkniętą aplikacją, z pozycją sprzed nocy', () {
      expect(holds(), isTrue);
    });

    test('ale nie po kwadransie — to nie jest noc', () {
      expect(holds(gap: const Duration(minutes: 10)), isFalse);
    });

    test('i nie wtedy, gdy nie ma schronu, o który można by pytać', () {
      expect(holds(hasShelters: false), isFalse);
    });

    test('ani wtedy, gdy postać i tak stoi w swoim', () {
      // Ta przerwa jest policzona dobrze i czekanie nic by nie zmieniło.
      expect(holds(inShelter: true), isFalse);
    });
  });

  group('§2.5.1: i kiedy przestać czekać', () {
    test('świeży odczyt kończy czekanie', () {
      expect(holds(fixAt: ago(const Duration(minutes: 1))), isFalse);
    });

    test('a odczyt sprzed przerwy nie jest świeży', () {
      // ⚠️ To jest dokładnie ten odczyt, który wprowadził w błąd: ostatni z
      // wieczora, sprzed ośmiu godzin.
      expect(holds(fixAt: ago(const Duration(hours: 9))), isTrue);
    });

    test('a po dwudziestu sekundach liczy się to, co jest', () {
      // ⚠️ Pod dachem odbiornik bywa głuchy (§2.1a.4). Fizjologia, która nie
      // rusza, bo GPS milczy, byłaby gorsza od źle policzonej.
      expect(holds(waitingSince: ago(kWaitForFix)), isFalse);
      expect(holds(waitingSince: ago(const Duration(seconds: 5))), isTrue);
    });
  });
}
