# ARLS-ZA — audyt kodu, 26.08.2025

Stan na commit `4f09495`. Zweryfikowane w kodzie, nie z pamięci: `flutter analyze` czysty, **2389 testów** zielonych, APK debug buduje się. 183 pliki w `lib/`, 159 plików testowych, schemat bazy **v34**.

---

## 1. Summary & Overall Grade

**Ocena: B+ / dobry z wyraźnym długiem w jednym miejscu.**

Ten projekt ma coś, czego nie ma większość kodu, który widuję: **testy pilnują reguł, a nie implementacji**. Warstwy są rozdzielone kontraktem wymuszanym testem (`ui → controllers → {sim, data}`, kontroler importujący `material.dart` wywala suite), migracje bazy są wyłącznie addytywne i weryfikowane przez odtworzenie każdej wydanej wersji schematu, a najczęstszy błąd tego projektu — *parametr z nieszkodliwym domyślnym, którego nikt nie wypełnia* — jest łapany przez testy źródłowe sprawdzające, czy gra faktycznie woła to, co ma napisane. To rzadkie i działa: dzisiejszy audyt znalazł błędy **czytając kod**, a nie po awarii u gracza.

Jednocześnie cały ciężar architektoniczny siedzi w jednym pliku. `lib/main.dart` ma **6462 linie** i jedną klasę stanu, przez którą przechodzi wszystko: jedenaście kontrolerów, pętla gry, GPS, ekwipunek, walka, schron, dziennik. Jest to pilnowane malejącym „ratchetem" (test wywala się, gdy plik urośnie) i systematycznie zmniejszane — 7088 → 6462 przez osiem faz — ale nadal jest to plik, w którym nowa funkcja kosztuje pół godziny szukania linii do wyciągnięcia. To realny podatek od każdej zmiany i widziałem go dziś trzy razy.

Zużycie baterii jest **przemyślane w warstwie GPS i nieprzemyślane w warstwie interfejsu**. Kadencja odbiornika adaptuje się do aktywności (1/5/10/15 s), klasa dokładności nigdy nie schodzi poniżej `high`, usługa pierwszoplanowa startuje tylko przy zgodzie na tło. Ale pętla symulacji tyka **1 Hz bezwarunkowo** i każdy tick woła `setState` w korzeniu drzewa — czyli pełną przebudowę interfejsu raz na sekundę, przez wiele godzin, także wtedy gdy nic się nie zmieniło.

---

## 2. Critical Issues (MUST FIX)

### 2.1. ✅ NAPRAWIONE DZIŚ — pętla gry, która nigdy nie umierała

`lib/main.dart`, `_startOver()`:

```dart
setState(() {
  _character = null;
  _loop = null;          // pole wyzerowane
});
await _loop?.dispose();  // ...więc dispose nie robi nic
```

**Każda śmierć i restart postaci przeciekała cały `GameLoop`**: jego timer 1 Hz nadal się odpalał, subskrypcja fixów GPS zostawała otwarta, stream snapshotów żył dalej — a obok startowała druga pętla. Dwie postacie w sesji = dwie pętle, dwa odbiorniki, dwóch pisarzy do bazy.

*Poprawka:* referencja trzymana w lokalnej zmiennej przed wyzerowaniem pola.

### 2.2. ✅ NAPRAWIONE DZIŚ — listener piszący do martwej pętli

Umiejętność Medycyna była trzymana w zgodzie z pętlą przez domknięcie nad `loop`, dodawane przy **każdym** wejściu do gry i nigdy nieusuwane. Druga postać = dwa listenery, z których pierwszy nadal pisał do pętli po `dispose()`.

*Poprawka:* nazwana metoda, `removeListener` przed `addListener` i ponownie w `dispose()`.

### 2.3. ✅ NAPRAWIONE DZIŚ — sen naliczany raz na stronę książki

Zgłoszone ze zrzutu ekranu: czterdzieści linii „Sen"/„Pobudka" na przemian w ciągu siedmiu minut.

Strona książki jest własną akcją z zegarem (§4.6.1 — to jest to, co nalicza XP w trakcie czytania). `setWorking` wiedziało o warsztacie i o budowie schronu, ale **nie o czytaniu**. Między dwiema stronami nic nie działało, §2.5.1 kładło postać spać w fotelu, a następna strona ją budziła. Dług senny spłacał się po kilka sekund przez cały wieczór.

*Poprawka:* czytanie dołączone do pracy długiej; otwarty egzemplarz ustawiany **przed** awaitowanym zapisem wiersza i trzymany przez granicę strony; dodatkowo dziennik odmawia zapisania nocy krótszej niż dwie minuty.

### 2.4. ⚠️ OTWARTE — ciosy przeciwników przy zamkniętej aplikacji

`CombatController` istnieje (147 linii) i jest wołany w ośmiu miejscach, ale **rozliczenie obrażeń po zamknięciu aplikacji nie jest zaimplementowane**. Gracz otoczony przez przeciwników może zamknąć aplikację i wrócić bez szwanku. Decyzja projektowa już zapadła (rozliczać, limit ~5 min, może doprowadzić do utraty przytomności, **nigdy nie zabija**) — brakuje kodu.

**Ryzyko:** to jest exploit, nie niedogodność. Cała ekonomia ryzyka §5–§6 opiera się na tym, że z walki trzeba wyjść.

### 2.5. ⚠️ OTWARTE — dokumentacja stanu testów kłamie

`CHECKLIST.md` deklaruje „2121 testów, schemat v29". Faktycznie **2389 testów, schemat v34**. Plik jest wskazywany jako źródło prawdy o pokryciu — a nie jest.

---

## 3. Optimization & Performance Debt

### 3.1. Pełna przebudowa drzewa 1 Hz — największy dług wydajnościowy

`lib/main.dart:1222`:

```dart
loop.snapshots.listen((snapshot) {
  setState(() => _position.accept(snapshot));
  ...
});
```

Pętla tyka co sekundę (`cadence = Duration(seconds: 1)`, `game_loop.dart:168`) **niezależnie od trybu oszczędnego** — tryb oszczędny zmienia kadencję *GPS*, nie kadencję symulacji. Każdy tick wywołuje `setState` w `_TitleScreenState`, czyli w korzeniu, co przebudowuje całą gałąź interfejsu.

Łagodzące, i to porządnie zrobione:
- `_markerCache` i `_benchCache` — wyniki cache'owane po tożsamości wejść, więc kosztowne rzeczy nie liczą się ponownie
- mixin `Ticking` zatrzymuje własne timery widżetów, gdy aplikacja idzie w tło
- para świt/zmierzch cache'owana godzinowo zamiast liczona przy każdym publish

Ale sama przebudowa zostaje. **To jest faza 9 migracji (scoped rebuilds)** i powinna być następnym krokiem architektonicznym po tym, jak `main.dart` zejdzie poniżej ~5000 linii.

*Rekomendacja:* zamiast `setState` w korzeniu — `ValueNotifier<GameSnapshot>` i `ValueListenableBuilder` wokół tych trzech rzeczy, które faktycznie zmieniają się co sekundę (HUD, pasek akcji, znaczniki). Reszta drzewa nie ma powodu wiedzieć o ticku.

### 3.2. GPS — ocena: dobrze, z jednym świadomym kompromisem

Zweryfikowane:

| Aspekt | Stan |
| :---- | :---- |
| Kadencja adaptacyjna | ✅ walka 1 s / marsz 5 s / postój 10 s / schron 15 s |
| Klasa dokładności | ✅ nigdy poniżej `high` — `medium` w geolocatorze to WiFi/cell (20–100 m), nie GPS |
| Usługa pierwszoplanowa | ✅ tylko przy `LocationAccess.granted` (zgoda na tło) |
| Zamykanie subskrypcji | ✅ `_sub?.cancel()` w `setCadence`, `stop()`, `dispose()` |
| Histereza | ✅ minuta przed zwolnieniem kadencji, **zero** przed przyspieszeniem |

**Kompromis:** schron to 15 s zamiast wyłączenia odbiornika, którego wprost żąda §2.1a.4. Powód jest udokumentowany i był błędem znalezionym w terenie: strefa jest wyliczana *z pozycji*, więc wyłączony odbiornik = zakleszczenie, z którego nie da się wyjść (nikt nie może zaobserwować, że gracz wyszedł). 15 s to jedna trzecia kosztu stania na ulicy.

*Możliwa dalsza oszczędność:* wewnątrz schronu, po pierwszych dwóch minutach bez ruchu, zejść do 30–60 s. Wyjście za próg byłoby zauważone do minuty zamiast do 15 s — akceptowalne, bo w schronie nie ma przeciwników (§8.1).

### 3.3. Rozmiary plików

| Plik | Linie | Uwaga |
| :---- | :---- | :---- |
| `lib/main.dart` | 6462 | ratchet, malejący; wciąż jedna klasa stanu na wszystko |
| `lib/ui/inventory_screen.dart` | 1679 | następny kandydat, brak ratchetu |
| `lib/game/game_loop.dart` | 1256 | spójny, ale rośnie |

W `main.dart` największe pozostałe bloki: `_enter` (204), `_advanceCombat` (157), `_finishObjectSearch` (123), `_strike` (123), `_use` (122). **`_advanceCombat` ma gotowy dom** — `CombatController` istnieje i jest w dużej mierze pusty.

### 3.4. Zapisy do bazy

Sprawdzone i w porządku: zapisy są dławione tam, gdzie trzeba (postęp budowy w kawałkach zamiast co tick, ogniska tylko gdy integralność ruszyła o ≥1 punkt lub furia wygasła, dziennik ograniczony do 400 wpisów z przycinaniem). Snapshoty rotacyjne co 30 minut plus obowiązkowo przy pauzie.

---

## 4. Recommendations for Improvement

### 4.1. Zarządzania stanem **nie zmieniać** na Provider/Riverpod/BLoC

Pytałeś o to wprost, więc odpowiadam wprost: **nie**. Projekt nie używa żadnego z nich (jedyne trafienie w `pubspec.yaml` to `path_provider`, co jest czymś innym). Stan to `ChangeNotifier`/`ValueNotifier` plus jedenaście własnych kontrolerów i własna `GameLoop`.

Powody, żeby zostawić:
- reguła zależności jest **wymuszona testem** — kontroler nie może dotknąć widżetu; Riverpod tego nie daje, tylko przenosi problem
- symulacja fizjologii (`lib/sim`) nie zna Fluttera w ogóle i przez to testuje się w czystym Darcie bez bindingu — to jest cenniejsze niż jakikolwiek framework DI
- kontrolery już mają dyscyplinę „żaden nie zna sąsiada"; to jest to, co Riverpod sprzedaje

Migracja kosztowałaby tygodnie i **nie naprawiłaby jedynego realnego problemu**, którym jest `setState` w korzeniu (punkt 3.1). To da się naprawić w obecnej architekturze w jeden wieczór.

### 4.2. Kolejność prac (moja rekomendacja)

1. **Faza 9 — scoped rebuilds.** Punkt 3.1. Największy zwrot na baterii i płynności, wykonalny bez zmiany architektury.
2. **`_advanceCombat` → `CombatController`.** 157 linii do gotowego domu; przy okazji odblokowuje 2.4.
3. **Rozliczanie ciosów po zamknięciu aplikacji** (2.4). To jest dziura w regułach, nie w kodzie.
4. **Ratchet dla `inventory_screen.dart`.** 1679 linii bez żadnego hamulca to `main.dart` za rok.

### 4.3. Nazewnictwo — do posprzątania przy okazji

Realna niespójność, znaleziona przy audycie:

| Pole | Typ | Problem |
| :---- | :---- | :---- |
| `_bench2` | `CraftController` | **cyfra w nazwie** — pozostałość po migracji, w której `_bench()` (metoda) już istniało |
| `_pack` vs `_inventory` | kontroler vs notifier | dwie nazwy na jedną rzecz |
| `_shelf` vs `_stash` | kontroler vs notifier | to samo |
| `_read` vs `_reading`/`_readBook` | kontroler vs akcja | `_read.open` czyta się jak czasownik |

Żadne z tego nie jest błędem. Wszystkie razem sprawiają, że nowa osoba przy tym kodzie musi zgadywać, czy `_pack` to kontroler, czy dane.

### 4.4. Podwójny zapis tych samych zdarzeń

`PlayerStats` (liczniki §13.1) i `Journal` (§3.6.1) zapisują te same zdarzenia z dwóch miejsc — przeszukanie zwiększa licznik **i** pisze wpis, zabicie tak samo. Dziś idą przez dwa lejki (`_note` i `_diary`), co działa, ale jest to jedno zdarzenie z dwoma niezależnymi ścieżkami zapisu i dwoma sposobami na rozjechanie się.

*Sugestia:* jeden lejek zdarzeń, który karmi oba. Nie pilne — oba są przetestowane — ale to naturalne miejsce na trzeci błąd tej klasy.

### 4.5. Co jest zrobione dobrze i czego nie ruszać

- **Testy jako specyfikacja.** Nazwy testów są zdaniami po polsku opisującymi regułę, a komentarze `⚠️` przy nich opisują *błąd, którego test pilnuje*. To jest dokumentacja, która nie może się zdezaktualizować.
- **Ratchet na `main.dart`.** Irytujący i skuteczny. Nie podnosić go nigdy — to jedyny powód, dla którego plik maleje.
- **Migracje addytywne z weryfikacją.** Każda wydana wersja schematu jest otwierana na wygenerowanych danych i migrowana do bieżącej. 34 wersje, wszystkie przechodzą.
- **Modele bez Fluttera.** `lib/sim`, `lib/combat`, `lib/skills` — testowalne w milisekundach.
- **Testy „czy gra to woła".** Źródłowe asercje, że model jest faktycznie podpięty. Trzy razy dziś złapały martwy kod, w tym mój własny.

---

## 5. Załącznik: co naprawiono w trakcie tego audytu

| # | Rzecz | Commit |
| :---- | :---- | :---- |
| 2.1 | Przeciek `GameLoop` przy restarcie postaci | `4f09495` |
| 2.2 | Kumulujące się listenery piszące do martwej pętli | `4f09495` |
| 2.3 | Sen/pobudka raz na stronę książki | `06c3f6f` |
| — | Czytanie jednym ciągiem, pasek pokazuje „strona 3/160" | `06c3f6f` |

Przy okazji, żeby zmieścić się w ratchecie, zlikwidowane dwie realne duplikacje: `_running()` pisał swoją kolumnę dwa razy, `_actionPanel` miał blok tam, gdzie wystarczy wyrażenie.
