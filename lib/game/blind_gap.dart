/// Przerwa, której nie ma z czego policzyć (§2.5.1, §2.1a.3, §11.1.2).
///
/// ⚠️ **Zgłoszone z terenu: „noc 100% w schronie, a dług senny został".** Gracz
/// wyszedł ze schronu wieczorem, aplikacja zgasła na ulicy, wrócił do domu i
/// przespał noc z telefonem na szafce. Odtworzenie przerwy bierze **ostatnią
/// zapisaną pozycję** — czyli tę ulicę — więc osiem godzin snu wracało jako
/// osiem godzin czuwania na dworze, a dług rósł zamiast maleć.
///
/// Pozycja sprzed ośmiu godzin nie mówi nic o tym, gdzie postać jest teraz.
/// Więc długa przerwa **czeka** na pierwszy świeży odczyt, zamiast być liczona
/// z tego, co akurat zostało na dysku.
///
/// ⚠️ **Czeka krótko i zawsze się doczeka.** Pod dachem odbiornik bywa głuchy
/// (§2.1a.4), a fizjologia, która nie rusza, bo GPS milczy, byłaby gorsza od
/// źle policzonej: po [kWaitForFix] przerwa jest liczona z tego, co jest.
library;

/// Krótsza przerwa nie jest warta czekania — kwadrans to nie noc, a różnica
/// między schronem a ulicą przez kwadrans mieści się w szumie.
const Duration kBlindGapFrom = Duration(minutes: 15);

/// I tyle najwyżej czeka się na odczyt, zanim przerwa zostanie policzona tak,
/// jak się da.
const Duration kWaitForFix = Duration(seconds: 20);

/// Czy tę przerwę trzeba jeszcze potrzymać, zanim się ją policzy.
///
/// Czysta reguła, bo to jest cała decyzja i chce się ją czytać w jednym
/// kawałku: **czekamy tylko wtedy, gdy odpowiedź może się zmienić.** Bez
/// schronu na mapie albo z postacią, która i tak stoi w swoim, nie ma o co
/// pytać — przerwa liczy się natychmiast, dokładnie jak dotąd. Czekanie „na
/// wszelki wypadek" zatrzymywałoby fizjologię po każdym powrocie do gry.
///
/// [fixAt] to znacznik ostatniego zaufanego odczytu; odczyt młodszy od przerwy
/// mówi, gdzie postać jest **teraz**, i to jest jedyna rzecz, na którą się tu
/// czeka. [waitingSince] to moment, od którego czekamy, albo null.
bool holdsBlindGap({
  required DateTime now,
  required DateTime lastUpdate,
  required bool hasShelters,
  required bool inShelter,
  required DateTime? fixAt,
  required DateTime? waitingSince,
}) {
  if (now.difference(lastUpdate) < kBlindGapFrom) return false;
  if (!hasShelters || inShelter) return false;
  if (fixAt != null && fixAt.isAfter(lastUpdate)) return false;

  return now.difference(waitingSince ?? now) < kWaitForFix;
}
