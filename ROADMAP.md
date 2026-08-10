# ARLS-ZA — roadmap wdrożenia

Dokument wykonawczy do [ARLS-ZA_design_doc_v2.md](ARLS-ZA_design_doc_v2.md). Design doc mówi **co** i **dlaczego**; ten plik mówi **w jakiej kolejności**, **kiedy etap jest skończony** i **co ustaliliśmy przy klawiaturze**.

Każdy zamknięty etap dostaje sekcję **Dziennik wykonania** z decyzjami podjętymi w trakcie, niespodziankami i punktem wejścia dla następnej sesji. Jeśli nie ma czego tam wpisać, etap prawdopodobnie nie został naprawdę skończony.

## Status

| Etap | Zakres | Status | Zamknięty | Commit |
| :---- | :---- | :---- | :---- | :---- |
| 0 | Fundament: trwałość zapisu, zegar, konfiguracja buildu | ✅ zamknięty | 2026-08-10 | `ad55d40` |
| 1 | Tryb deweloperski i symulator GPS | ✅ zamknięty | 2026-08-10 | `HEAD` |
| 2 | Postać i fizjologia | ⬜ następny | — | — |
| 3 | Mapa, GPS, bezpieczeństwo gracza | ⬜ | — | — |
| 4 | Przedmioty, loot, przeszukanie | ⬜ | — | — |
| 5 | Walka, przeciwnicy, hałas | ⬜ | — | — |
| 6 | Ognisko z pełnym cyklem | ⬜ | — | — |
| 7 | Audio pozycyjne i haptyka | ⬜ | — | — |
| 8 | Schron, obóz, pętla dobowa | ⬜ | — | — |
| 9 | Onboarding, dostępność, zgodność | ⬜ | — | — |

**Metryki:** 138 testów · `flutter analyze --fatal-infos` czysty · schemat bazy v1 · release APK 55,1 MB bez devtools

### Zablokowane na użytkowniku

Rzeczy, których nie da się zrobić z poziomu repozytorium.

| Co | Dlaczego blokuje | Od etapu |
| :---- | :---- | :---- |
| Keystore i `android/key.properties` | bez tego `flutter build --release` używa kluczy debug, a takiego artefaktu nie da się opublikować. Instrukcja na górze [PROCEDURA_RELEASE.md](PROCEDURA_RELEASE.md) | 0 |
| GitHub Pages dla `ARLS-ZA-Game` | strona projektu nie jest publicznie widoczna. Settings → Pages → branch `main`, folder `/ (root)` | — |

---

## Zasady prowadzenia prac

1. **Etap kończy się kryterium wyjścia, nie poczuciem gotowości.** Kryterium jest sprawdzalne — testem, pomiarem albo demonstracją na urządzeniu.
2. **Schemat bazy jest addytywny od pierwszego dnia** (§11.1.4). Kolumny się dodaje, nigdy nie usuwa i nie zmienia nazw. Test migracji jest tak samo obowiązkowy jak test logiki.
3. **Symulator GPS wstrzykuje dane tą samą warstwą co prawdziwy GPS** (§11.2), łącznie z błędem pozycji i utratą sygnału. Testowanie na idealnych danych zamaskuje wszystko, co wystąpi w terenie.
4. **Struktury danych przewidują funkcje spoza MVP** — `season_modifiers` (§17), flaga `procedural` w punktach lootu (§10.1), `condition` i `volume_l` w przedmiotach (§4.1). Dodanie ich później to migracja schematu, nie nowa funkcja.
5. **Higiena licencyjna audio od pierwszego pliku** (§14.5): `assets/audio/prototype/` nigdy nie trafia do release'u, każdy plik w `shipped/` ma wpis w `CREDITS.md`, CI to sprawdza.
6. **Etapy 0–1 nie wymagają wychodzenia z domu.** Praca w terenie zaczyna się dopiero na etapie 3.

---

## Etap 0 — Fundament projektu ✅ ZAMKNIĘTY

**Cel:** repozytorium, z którego da się zbudować podpisany release, i baza, która przeżyje aktualizację aplikacji.

| # | Zadanie | Odniesienie | Gdzie |
| :---- | :---- | :---- | :---- |
| 0.1 | Rebranding: `applicationId` i `namespace` → `com.raidodevelopment.arlsza`, `android:label` → `ARLS-ZA Game`, ścieżka `MainActivity.kt`, `name` w `pubspec.yaml` | — | `android/app/build.gradle.kts` |
| 0.2 | Release signing config (keystore poza repozytorium, `key.properties` w `.gitignore`) | — | `android/app/build.gradle.kts` |
| 0.3 | `git init`, konwencja commitów, CI: `flutter analyze` + `flutter test` | — | `.github/workflows/ci.yml` |
| 0.4 | Drift/SQLite: schemat v1, tryb WAL, transakcje, wersja schematu w bazie | §11.1.1–11.1.2 | `lib/data/db/` |
| 0.5 | Podział stanu na warstwy: gorąca (60 s), ciepła (przy zmianie), zimna (przy zdarzeniu) | §11.1.1 | `lib/data/persistence/save_writer.dart` |
| 0.6 | Migawki rotacyjne: 3 sztuki, sumy kontrolne, weryfikacja bazy przy starcie, odtwarzanie z komunikatem | §11.1.3 | `lib/data/db/snapshot_store.dart` |
| 0.7 | Test migracji w CI: ścieżka v1→v2→v3 na wygenerowanych danych | §11.1.4 | `test/db/schema_test.dart`, `drift_schemas/` |
| 0.8 | Eksport/import profilu do JSON | §11.3 | `lib/data/persistence/profile_transfer.dart` |
| 0.9 | Deterministyczny RNG z seedem zapisanym w profilu | §11 | `lib/core/deterministic_rng.dart` |
| 0.10 | Silnik tickowy 1 Hz w izolacie, ticki idempotentne od `last_update`, catch-up po wznowieniu | §11, §2.1.1 | `lib/sim/` |
| 0.11 | Anti-cheat zegara: `last_update` jako licznik monotoniczny, cofnięcie czasu = tick 0 s | §2.1.1 | `lib/core/game_clock.dart` |
| 0.12 | Lokalizacja: `flutter_localizations` + ARB, PL i EN, klucze zamiast tekstów w plikach danych | §1.1 | `lib/l10n/` |

**Kryterium wyjścia:** aplikacja z podpisanym buildem release, pusty tick 1 Hz działa w izolacie, przeżywa kill procesu i wraca z catch-upem bez dziury w symulacji, test migracji przechodzi w CI.

**Stan:** spełnione. Kryterium zapisane wykonywalnie w `test/db/save_bootstrap_test.dart` — sesja gubi niezapisane sekundy warstwy gorącej, wraca z catch-upem bez dziury, a powtórzenie tego samego catch-upu daje ten sam stan.

### Dziennik wykonania — etap 0

#### Decyzje podjęte w trakcie

Rozstrzygnięcia, których nie było w dokumencie projektowym, a bez których nie dało się napisać kodu.

- ⚠️ **`DateTime` zapisywany jako tekst ISO-8601 UTC**, nie jako sekundy uniksowe (`build.yaml`, `store_date_time_values_as_text`). Wiążące na całe życie schematu — zmiana po wydaniu to migracja danych, nie przełącznik. Powód niżej, w niespodziankach.
- **Warstwa bazy jest wolna od Fluttera.** `path_provider` wciągał `dart:ui` do `database.dart`, przez co testy nie ładowały się pod `dart test`, a izolat silnika tickowego miałby ten sam problem. Rozwiązywanie katalogu zapisu stoi osobno w `lib/data/db/save_location.dart`.
- **Klucze obce przez `customConstraints`, nie przez `.references()`.** Drift w tej wersji cicho gubi `.references(Profiles, #id)` — wypisuje ostrzeżenie i generuje kolumnę bez ograniczenia. Test czyta `sqlite_master` i sprawdza, że `FOREIGN KEY` naprawdę jest w `CREATE TABLE`; sama deklaracja niczego nie gwarantuje.
- **`schemaVersion` musi być literałem**, nie odwołaniem do stałej — `drift_dev schema dump` czyta go statycznie i nie pójdzie za referencją. Spójności z `kSchemaVersion` pilnuje test.
- ⚠️ **Build release bez keystore kończy się kluczami debug i ostrzeżeniem, nie błędem.** Twardy błąd włącza `-Prequire-signing=true`, którego używa potok wydawniczy. Wariant „zawsze twardy błąd" psułby `flutter build --release` każdemu, kto sklonuje repozytorium.
- **Import profilu zawsze wstawia nową postać**, nigdy nie nadpisuje istniejącej. Pomyłkowe przywrócenie kopii nie może skasować żywej passy.
- **Migracja odpala się dopiero po migawce przedmigracyjnej**, która nie podlega rotacji okresowej. To jedyna rzecz stojąca między złą migracją a zapisami wszystkich graczy.

#### Niespodzianki

- **Drift oddaje `DateTime` w czasie lokalnym.** Znacznik zapisany jako `12:00 UTC` wracał z bazy jako `14:00` bez flagi UTC. Trafiłoby to prosto w porównanie w anti-cheacie zegara z §2.1.1 — dwie godziny darmowego czasu przy każdym odczycie na CEST. Złapał to test bootstrapu, nie przegląd kodu. **Wniosek na przyszłość: każdy typ przechodzący przez granicę bazy wymaga testu round-tripu**, nawet jeśli wygląda na trywialny.
- **`flutter test` i `dart test` to różne środowiska.** Testy czystej logiki pod `dart test` są znacznie szybsze, ale wywalają się na każdym imporcie ciągnącym Flutter. To wymusiło rozdzielenie warstw — z korzyścią dla architektury.
- Gradle wsypywał `android/build/reports/` do commita; `.gitignore` template'u pokrywał tylko `/build` w katalogu głównym.

#### Punkt wejścia dla następnej sesji

Fundament jest gotowy, ale **nie jest jeszcze przez nic używany**. `main.dart` woła `SaveBootstrap.boot()` i pokazuje wynik odzyskiwania — na tym koniec. Brakuje spięcia:

- pętli, która pobiera stan z `TickEngine` i podaje go do `SaveWriter.stageHot()`
- reakcji na cykl życia aplikacji: `AppLifecycleState.paused` → `writer.quiesce()` plus `persistClockMark()`
- wywołań `SnapshotStore.isDue()` w rytmie gry

To jest zamierzone — bez postaci nie ma czego tickować. Spięcie należy do etapu 2, kiedy pojawi się prawdziwy stan do zapisania.

⚠️ Cała weryfikacja etapu 0 szła lokalnie na Windowsie. CI odpaliło się po raz pierwszy przy commicie `ad55d40` — **sprawdzić, czy przechodzi na Ubuntu**.

---

## Etap 1 — Tryb deweloperski ✅ ZAMKNIĘTY

**Cel:** możliwość iterowania nad balansem bez wychodzenia z domu. Bez tego etapu każda kolejna zmiana wymaga kilometrów spaceru.

| # | Zadanie | Odniesienie | Gdzie |
| :---- | :---- | :---- | :---- |
| 1.1 | Warstwa abstrakcji pozycji — jedno wejście dla prawdziwego GPS i symulatora | §11.2 | `lib/location/` |
| 1.2 | Symulator GPS: odtwarzanie tras GPX z regulowaną prędkością, sterowanie strzałkami, skok do współrzędnych | §11.2 | `lib/devtools/simulated_position_source.dart`, `gpx.dart` |
| 1.3 | Symulacja błędu pozycji i utraty sygnału w symulatorze | §11.2, §3.2 | `SimSignalQuality` |
| 1.4 | Przyspieszenie czasu ×1 / ×60 / ×3600 | §11.2 | `lib/core/scaled_wall_clock.dart` |
| 1.5 | Panel fizjologii: wymuszanie tętna, krwi, wody, kalorii, długu snu | §11.2 | `lib/devtools/dev_console.dart` |
| 1.6 | Nakładka diagnostyczna: `MOA_total` z rozbiciem, szansa trafienia, promień hałasu, stany przeciwników | §11.2 | `lib/devtools/dev_overlay.dart` — **częściowo, patrz niżej** |
| 1.7 | Powtórki: zapis sesji (seed + strumień zdarzeń) i deterministyczne odtworzenie | §11.2 | `lib/devtools/session_recorder.dart` |
| 1.8 | Wycięcie całości z release'u flagą kompilacji | §11.2 | `lib/devtools/dev_mode.dart`, `tool/check_release_strip.dart` |

**Kryterium wyjścia:** doba gry przechodzi w 24 sekundy na trasie GPX, a build release nie zawiera ani jednej linii kodu deweloperskiego (zweryfikowane rozmiarem i analizą artefaktu).

**Stan:** spełnione, zweryfikowane pomiarem.

| Sprawdzenie | Wynik |
| :---- | :---- |
| Doba gry przy ×3600 | 24 s, test w `scaled_wall_clock_test.dart` |
| Release APK | **55,1 MB**, marker nieobecny, `check_release_strip.dart` przechodzi |
| Release z `--dart-define=arls.devtools=true` | **57,4 MB**, marker obecny, check zawodzi |
| Różnica | **2,3 MB** wyciętego kodu |

⚠️ **Zadanie 1.6 jest domknięte tylko częściowo, świadomie.** Nakładka pokazuje zegar, warstwę pozycji i fizjologię. Rozbicie `MOA_total`, szansa trafienia, promień hałasu i stany maszyny przeciwników **nie istnieją jeszcze jako systemy** — powstają na etapie 5. Brak jest wypisany wprost w panelu (sekcja „Brakuje — etap 5"), żeby nie zniknął z pola widzenia.

### Dziennik wykonania — etap 1

#### Decyzje podjęte w trakcie

- **Bramka to `const bool`, nie flaga runtime'owa.** `const bool kDevTools` pozwala kompilatorowi AOT uznać `if (kDevTools) { ... }` za martwy kod i usunąć gałąź razem ze wszystkim, do czego tylko ona sięga. Zwykły `bool` zostawiłby cały drzewiec devtools w binarce.
- **Domyślnie włączone poza release, przełączalne w obie strony** przez `--dart-define=arls.devtools=true|false`. Wymuszenie w release potrzebne do testu, że sam test nie jest pusty.
- **Przyspieszenie czasu siedzi w zegarze, nie w silniku tickowym.** `ScaledWallClock` mnoży upływ czasu pod `GameClock`, więc `advance()` dostaje zwykły `Duration` i nigdy nie dowiaduje się o mnożniku. Dzięki temu przebieg przyspieszony jest porównywalny ze zwykłym, a funkcja pozostaje czysta.
- **Zmiana skali re-kotwiczy zamiast przeliczać historię.** Przełączenie ×1 → ×3600 → ×1 nigdy nie cofa czasu wirtualnego, co inaczej wywołałoby fałszywy alarm anti-cheatu z §2.1.1. Osobny test tego pilnuje.
- **`skipForward` działa wyłącznie do przodu.** Skok wstecz byłby najprostszym sposobem obejścia zabezpieczenia, które reszta kodu traktuje jako pewnik.
- **Symulator rozprasza pozycję wewnątrz okręgu dokładności**, z `sqrt` na promieniu, żeby rozkład był równomierny po powierzchni. Bez tego dryf kupiłby się wokół prawdziwej pozycji, a filtr martwej strefy z §3.2 nie miałby czego filtrować.
- **Prawdziwa pozycja nie jest nigdzie eksponowana poza panelem.** Gra widzi wyłącznie zaszumiony odczyt — dokładnie jak w terenie.
- **Parser GPX napisany ręcznie**, bez pakietu XML. Zależność używana tylko przez devtools i tak siedziałaby w `pubspec.yaml` release'u.
- **Powtórki w formacie JSON Lines**, dopisywanym liniami. Nagranie przeżywa crash, który miało zarejestrować: urwana ostatnia linia kosztuje jedno zdarzenie, nie plik.
- **Zdarzenia niosą czas symulacji, nie zegarowy.** Dlatego zmiana skali czasu w trakcie nagrania nie wpływa na odtworzenie — mnożnik jest już wpieczony w znaczniki.

#### Niespodzianki

- 🔴 **Test wycinania był pusty i przechodził z błędnego powodu.** Marker był w stałej, do której nie sięgało żadne żywe wywołanie, więc kompilator wyrzucał go **także z buildu z włączonymi devtools** — check pokazywał „czysto" niezależnie od stanu bramki. Wykryte dopiero przez zbudowanie release'u z `--dart-define=arls.devtools=true` i sprawdzenie, czy check **zawodzi**. Naprawione przez wstawienie markera w faktycznie renderowany widget. **Wniosek: każdy test negatywny wymaga dowodu, że potrafi zawieść.** CI ma teraz osobny krok, który to sprawdza.
- **`kReleaseMode` z `package:flutter/foundation.dart` wciągał `dart:ui`** do symulatora pozycji i nagrywarki, przez co nie ładowały się pod `dart test`. To ta sama pułapka co `path_provider` w etapie 0. Zastąpione bezpośrednim `bool.fromEnvironment('dart.vm.product')` — tym samym define, z którego korzysta sam Flutter.

#### Punkt wejścia dla następnej sesji

Symulator działa i emituje pozycje, ale **nic ich jeszcze nie konsumuje** — `TitleScreen` tylko je wyświetla w nakładce. Etap 2 musi spiąć trzy rzeczy, które teraz istnieją osobno:

- `SimulatedPositionSource` → prędkość → MET → `TickEngine`
- `TickEngine` → `SaveWriter.stageHot()` w rytmie 60 s
- `DevConsole.takePendingOverride()` → wstrzyknięcie wymuszonych wartości do stanu symulacji

⚠️ Filtry z §3.2 (Kalman, odrzucanie `accuracy > 25 m`, martwa strefa 8 m/10 s) **celowo nie powstały** — należą do etapu 3. Symulator już potrafi produkować dane, które ich wymagają: preset „wąwóz miejski" przebija próg 25 m, a dryf na postoju daje fałszywy ruch. To materiał testowy czekający na filtr.

---

## Etap 2 — Postać i fizjologia

**Cel:** działający model ciała — pierwszy system, który da się zbalansować.

| # | Zadanie | Odniesienie |
| :---- | :---- | :---- |
| 2.1 | Kreator postaci: nazwa, płeć, wiek, wzrost, waga, walidacja zakresów i BMI 12–60 | §1.2 |
| 2.2 | Parametry wyliczane: Nadler, Mifflin–St Jeor, Tanaka, woda 35 ml/kg, HR spoczynkowe, udźwig 0,30/0,45 | §1.3 |
| 2.3 | Wybór trybu Hardcore/Softcore, nieodwracalny, z osobnym potwierdzeniem | §9, §15.4 |
| 2.4 | MET z prędkości, `MET_efektywne` z obciążeniem, kcal/min | §2.2 |
| 2.5 | Strefy metaboliczne: teren 100% / obóz 50% / schron 35% / sen 20% | §2.1 |
| 2.6 | Głód, pragnienie, straty z potem, progi kar | §2.3 |
| 2.7 | Tętno: model, powrót wykładniczy τ ≈ 90 s, tabela kar | §2.4 |
| 2.8 | Sen automatyczny z pory doby i strefy, dług senny, efekty deprywacji | §2.5 |
| 2.9 | Długość dnia liczona offline (deklinacja słoneczna) — warunek działania snu | §17.2 |
| 2.10 | Model obrażeń i krwawienia: klasy ATLS, tiery krwawienia, modyfikator wysiłku | §2.6 |
| 2.11 | Reguła zajęć: jedno naraz, kategorie ZAJĘCIE / CZYNNOŚĆ / PROCES TŁOWY | §2.1a |
| 2.12 | Zawór offline: żaden zasób nie spada poniżej 10%, brak śmierci w stanie uśpionym | §2.1.1, §9.1 |
| 2.13 | HUD: krew, statusy, woda, kalorie, udźwig (masa i objętość) | §3.6, §18.1a |

**Kryterium wyjścia:** przy ×3600 doba symulacji daje liczby zgodne z tabelami §2 w granicach błędu zaokrągleń; postać z zamkniętą aplikacją przez 14 dni budzi się osłabiona, ale żywa.

---

## Etap 3 — Mapa i GPS

**Cel:** pierwszy raz gra działa w prawdziwym mieście.

| # | Zadanie | Odniesienie |
| :---- | :---- | :---- |
| 3.1 | MapLibre GL Native + PMTiles, pakiet kafelków na region | §3.1 |
| 3.2 | Ekran pierwszego uruchomienia: wybór regionu, obsługa braku miejsca, wyjazd poza pakiet | §16.6 |
| 3.3 | `geolocator` + foreground service z powiadomieniem trwałym | §3.3 |
| 3.4 | Filtr Kalmana, odrzucanie `accuracy > 25 m`, martwa strefa 8 m/10 s, pauza po 60 s utraty sygnału | §3.2 |
| 3.5 | Adaptacyjne próbkowanie 1 / 0,2 / 0,05 Hz, tryb oszczędny, ostrzeżenie przy <20% baterii | §3.3 |
| 3.6 | Tryb tylko-foreground jako pełnoprawny wariant gry przy odmowie zgody na lokalizację w tle | §16.1 |
| 3.7 | Anti-cheat: mock provider, >40 km/h przez >30 s → zawieszenie rozgrywki | §3.4 |
| 3.8 | Strefy wykluczone ze spawnu po tagach OSM (drogi, tory, wody, tereny prywatne, szpitale, szkoły, cmentarze, obiekty kultu, komisariaty, obiekty wojskowe) | §3.5 |
| 3.9 | Blokada walki przy >15 km/h | §3.5 |
| 3.10 | Widok mapy: gracz, stożek kierunku, znaczniki, dolne menu | §3.6 |
| 3.11 | Zapis pozycji do warstwy gorącej przy każdym `onPause`, checkpoint WAL | §11.1.2, §11.1.5 |

⚠️ **Etap 3 to pierwszy moment, w którym §3.5 przestaje być teorią.** Strefy wykluczone i blokada walki w ruchu muszą działać, zanim ktokolwiek poza deweloperem uruchomi grę w terenie.

**Kryterium wyjścia:** godzinny spacer po mieście daje spójny ślad bez fałszywego ruchu na postoju, zużycie baterii mieści się w założeniach §3.3, a proces przeżywa agresywne oszczędzanie energii (test na urządzeniu Xiaomi/Samsung).

---

## Etap 4 — Przedmioty i loot

**Cel:** świat ma zawartość, a plecak ma cenę.

| # | Zadanie | Odniesienie |
| :---- | :---- | :---- |
| 4.1 | Wspólny schemat przedmiotu + walidacja JSON przy buildzie | §4.1 |
| 4.2 | `items.json` — pełne 89 pozycji, `loot_tables.json` — 20 tabel | §10.3, Załącznik |
| 4.3 | Ekwipunek z dwoma limitami: masa i objętość, oba paski w HUD | §18.1a |
| 4.4 | Plecaki (udźwig + pojemność), odzież i pancerz (dwie osie ochrony) | §4.4, §4.5 |
| 4.5 | Loot z POI OSM, respawn 4–8 h, max 15 aktywnych w promieniu 2 km | §10 |
| 4.6 | Zapasowa warstwa proceduralna przy gęstości POI < 8, flaga `procedural` | §10.1 |
| 4.7 | Przeszukanie terenu (rozpoznanie): 45 s bezruchu, promień, co odsłania | §10.2 |
| 4.8 | Przeszukanie obiektu jako czynność czasowa: 30 / 90 / 180 s, hałas, przerwanie | §19.3, §10.3.5 |
| 4.9 | Przeszkody: wyważenie drzwi, kłódka, szyba — wymagania narzędziowe i hałas | §19.3 |
| 4.10 | Porzucone przedmioty na mapie, 24 h, limit 50 znaczników | §4.8 |
| 4.11 | `notes.json` — notatki fabularne, podstawianie `{street}`/`{district}`/`{city}` z OSM | §19.1 |

⚠️ **Pułapka fleksyjna (polski):** zdania z placeholderem muszą być konstruowane tak, by nazwa stała w mianowniku („ulica {street}", nigdy „z {street}") — §19.1.1.

**Kryterium wyjścia:** w promieniu 2 km od punktu testowego gra znajduje sensowne POI, a w miejscowości bez POI warstwa proceduralna wyzwala się automatycznie i daje grywalną gęstość punktów.

---

## Etap 5 — Walka i przeciwnicy

**Cel:** starcie, które jest decyzją, a nie klikaniem.

| # | Zadanie | Odniesienie |
| :---- | :---- | :---- |
| 5.1 | Model celności: składanie MOA przez pierwiastek sumy kwadratów, `P(trafienie)` z dystrybuanty | §5.1 |
| 5.2 | Rekalibracja składników: tętno kwadratowo, ruch gracza `8 × v^1.2` | §5.1.1 |
| 5.3 | Jawna szansa trafienia w HUD wraz z największym składnikiem błędu | §5.1.4 |
| 5.4 | Model obrażeń: `5,1 × J^0,6 × wound_factor × mnożnik_lokalizacji × (1 − ochrona)` | §5.1.5 |
| 5.5 | Szwędacz: parametry, maszyna stanów, budżet sprintu, smycz 400 m, utrata kontaktu 45 s | §6.1, §6.1a, §6.2 |
| 5.6 | Ruch przeciwników po linii prostej (routing OSM poza MVP) | §6.3 |
| 5.7 | Namierzanie jednego celu, koszt przełączenia 1,2 s, brak automatyki po śmierci celu | §5.5.1 |
| 5.8 | HUD walki grupowej ze wskaźnikiem budżetu sprintu każdego przeciwnika | §5.5.2 |
| 5.9 | Przerwanie przeładowania przy zbliżeniu <5 m | §5.5.4 |
| 5.10 | Limit 8 aktywnych przeciwników w promieniu 300 m | §5.5.6 |
| 5.11 | **System hałasu:** promienie, modyfikatory otoczenia, reakcja przeciwników, limit 6 reagujących, kumulacja 30 s | §5.6 |
| 5.12 | Wizualizacja fali hałasu na mapie | §5.6.5 |
| 5.13 | Dystanse zaangażowania: wykrycie od 150 m, walka 50–250 m, poniżej 20 m tryb wręcz | §5.2 |
| 5.14 | Zasady spawnu: nigdy bliżej niż 150 m, nigdy w strefach wykluczonych, nigdy w 200 m od schronu | §6.4 |

⚠️ **System hałasu wchodzi razem z walką, nie po niej.** Bez niego strzelanie nie ma kosztu innego niż amunicja i znika główna decyzja taktyczna gry (§0.1).

**Kryterium wyjścia:** wartości z tabeli kalibracyjnej §5.1.2 odtwarzają się w nakładce diagnostycznej; grupa 4 Szwędaczy kosztuje nowicjusza ~24 naboje zgodnie z §10.3.3.

---

## Etap 6 — Ognisko

**Cel:** presja, która rośnie sama. Bez tego nie ma czego przetrwać.

| # | Zadanie | Odniesienie |
| :---- | :---- | :---- |
| 6.1 | Rozmieszczenie: 500–2000 m od schronu, min. 450 m między centrami, promień do 200 m | §6.5.1 |
| 6.2 | Poziomy 1–10: promień, limit wrogów, respawn, skład | §6.5.2 |
| 6.3 | Wzrost: `max(2h, 8h − 0.25h × dzień) × random(0.6, 1.4)`, 25% czasu uśpionego | §6.5.3 |
| 6.4 | Powiadomienie push przy awansie z nazwą ulicy z OSM | §6.5.3 |
| 6.5 | Integralność, punkty za eliminacje, 50% poza promieniem, regeneracja +5%/h | §6.5.4 |
| 6.6 | Wzburzenie po zbiciu poziomu: 10 min, ×3 respawn, +50% limitu, skład o szczebel wyżej | §6.5.4 |
| 6.7 | Zawór bezpieczeństwa: wzburzenie nie odnawia się przy oddaleniu >400 m | §6.5.4, decyzja otwarta §13/3 |
| 6.8 | Likwidacja: skład z lootem ×3, slot pusty 24–48 h, nowe ognisko na poziomie 1 | §6.5.4 |
| 6.9 | Wizualizacja: okrąg, kolor wg poziomu, panel po tapnięciu | §6.5.6 |
| 6.10 | Licznik passy przetrwania + ekran Kronika | §13.1, §9.3 |

**Kryterium wyjścia:** przy ×3600 ognisko przechodzi pełną ścieżkę 1 → 10 → zbicie → likwidacja bez rozjazdu stanu po restarcie aplikacji; symulacja odpowiada na pytanie z §16.4 (czy gracz z 1 h dziennie nadąża).

---

## Etap 7 — Audio i haptyka

**Cel:** jedyny interfejs, który działa przy telefonie w kieszeni.

| # | Zadanie | Odniesienie |
| :---- | :---- | :---- |
| 7.1 | `flutter_soloud`, budżet 16 kanałów, OGG dla efektów, Opus dla ambientu | §14.2, §14.9 |
| 7.2 | Dźwięk pozycyjny `play3d()`, mapowanie współrzędnych na wektor, orientacja słuchacza z magnetometru | §14.2 |
| 7.3 | Bicie serca w tempie `HR_aktualne`, głośność rosnąca z tętnem | §14.7 |
| 7.4 | Mapowania stanów: odwodnienie, krwawienie, klasa III wstrząsu, dług snu | §14.7 |
| 7.5 | Przytłumienie miksu po strzale na 2–3 s | §5.6.4 |
| 7.6 | ~55 plików wg tabeli, `CREDITS.md` prowadzony od pierwszego pliku, skrypt CI | §14.5, §14.6 |
| 7.7 | Haptyka: wzorce rozróżnialne przez kieszeń, duplikat każdego sygnału krytycznego | §14.8, §14.1 |
| 7.8 | Tryb bez ambientu przy wygaszonym ekranie | §14.9 |

⚠️ **Gra nigdy nie może wymagać słuchawek** (§14.1). Pełna informacja musi docierać także przez wibracje i ekran.

**Kryterium wyjścia:** z telefonem w kieszeni i wygaszonym ekranem gracz rozpoznaje kierunek zbliżającego się przeciwnika oraz odróżnia wszystkie wzorce haptyczne; assety audio mieszczą się w 25 MB, a `shipped/` przechodzi kontrolę CI.

---

## Etap 8 — Schron i pętla dobowa

**Cel:** miejsce, do którego się wraca, i powód, żeby wracać.

| # | Zadanie | Odniesienie |
| :---- | :---- | :---- |
| 8.1 | Budowa schronu podstawowego, ~3 h, postęp w tle z powiadomieniem | §8.3 |
| 8.2 | Strefy: 50 m dla bezpieczeństwa i blokady ataku — oba promienie równe | §8.1 |
| 8.3 | Prywatność lokalizacji schronu: `allowBackup=false` dla rekordu lub szyfrowanie | §8.2, §11.1.3 |
| 8.4 | Obóz: 20 m, ~40 min budowy, prosta skrzynia +30 kg, max 2, wygasanie po 14/21 dniach | §8.5 |
| 8.5 | Magazyn bazowy 25 kg z limitem objętości 3 l/kg | §18.2, §18.1a |
| 8.6 | Zajęcia schronowe tykające przy zamkniętej aplikacji, anulowane przy zmianie strefy | §2.1a.3–2.1a.4 |
| 8.7 | Śmierć: Hardcore z zabezpieczeniami, Softcore z utratą przytomności i skrytkami | §9.1, §9.2 |
| 8.8 | Przemieszczenie gracza w czasie nieprzytomności, okno łaski 10 min | §9.2.1 |
| 8.9 | Ekran powrotu po przerwie: co urosło, co stracone, czy była horda | §16.3 |

**Kryterium wyjścia:** pełna doba rozgrywki — wyjście, loot, walka, powrót, nocne zajęcie — przechodzi bez utraty stanu przy wymuszonym killu procesu w każdym z tych momentów.

---

## Etap 9 — Onboarding i zgodność

**Cel:** gra, którą można wypuścić.

| # | Zadanie | Odniesienie |
| :---- | :---- | :---- |
| 9.1 | Etap 0 onboardingu — bezpieczeństwo, aktywne potwierdzenie checkboxem | §15.3 |
| 9.2 | Kreator z kontekstem + ekran wyliczonych parametrów | §15.4 |
| 9.3 | Podpowiedzi kontekstowe wyzwalane zdarzeniami | §15.5 |
| 9.4 | Pierwsza walka — jedyny scenariusz skryptowany, przeciwnik nie może zabić | §15.6 |
| 9.5 | Ekran „Zasady przetrwania" dostępny z menu | §15.7 |
| 9.6 | Przypomnienie o widoczności po zachodzie słońca | §3.5 |
| 9.7 | Dostępność: czytniki ekranu w menu, wysoki kontrast, skalowanie czcionek, wibracje zamiast dźwięku | §12 |
| 9.8 | Polityka prywatności (publiczny URL), formularz Data Safety, RODO, regulamin, IARC | §16.7 |
| 9.9 | Uzasadnienie `ACCESS_BACKGROUND_LOCATION` + wideo demonstracyjne | §16.1 |
| 9.10 | Telemetria: wyłącznie zagregowana, bez lokalizacji, domyślnie wyłączona, z jawną zgodą | §16.5 |
| 9.11 | Ikona, nazwa w sklepie, zrzuty ekranu, opis ASO, obsługa proporcji ekranu | §16.8 |

**Kryterium wyjścia:** build przechodzi wewnętrzne testy w Play Console, onboarding zamyka się w 5 minutach, a gra działa w pełni po odmowie zgody na lokalizację w tle.

---

## MVP — definicja gotowości

Zakres z §0.1, czyli etapy 0–9 z ograniczeniami:

- 1 typ przeciwnika (Szwędacz), 3 bronie, ~20 przedmiotów w rotacji, 1 ognisko
- schron bez modułów, bez craftingu, bez literatury i nauki umiejętności
- PL + EN
- ślady po ludziach (§19.1) i przeszukanie jako czynność (§19.3) — w zakresie, bo są tanie i najsilniej zmieniają odczucie z gry

**Test akceptacyjny MVP:** trzydziestodniowa passa przetrwania rozegrana w terenie przez osobę spoza zespołu, bez utraty zapisu i bez sytuacji, w której gra popycha gracza w niebezpieczne miejsce.

---

## Po MVP

| Fala | Zawartość | Odniesienie |
| :---- | :---- | :---- |
| **P1 — głębia przeżyciowa** | wydarzenia losowe, warstwa historii osobistej na mapie, tropy, modyfikatory osobnicze przeciwników, kamienie milowe | §19.2, §19.4–19.7 |
| **P2 — progresja** | literatura i umiejętności, wprawa czytelnicza, Archiwum, warstwa fabularna `story.json` | §4.6, §7, §20 |
| **P3 — wytwarzanie** | surowce, receptury, moduły schronu, wymagania narzędziowe, recykling, elaboracja amunicji, łuski | §18 |
| **P4 — środowisko** | sezonowość (wskaźniki C i D), pogoda krótkoterminowa z Open-Meteo, temperatura | §17 |
| **P5 — rozszerzenie walki** | Skakun i Brutal, walka wręcz, tłumiki, hordy, oskrzydlenie | §5.4, §5.5.3, §6.5.5 |
| **P6 — zasięg** | DE/ES/FR, ogniska polowe, routing przeciwników po grafie OSM, tryb dostępności | §1.1, §6.3, §6.5.7, §12 |

⚠️ **P4 wymaga P3.** Sezonowość stoi na założeniu, że zimą jest co robić w schronie przez cztery miesiące — bez craftingu i rozbudowy modułów zima jest pusta (§17.6).

---

## Ryzyka prowadzące do przerwania prac

| Ryzyko | Objaw | Odpowiedź |
| :---- | :---- | :---- |
| **Gra złożona z samych kosztów** | w typowej godzinie przeważa zarządzanie ograniczeniami nad odkrywaniem | policzyć proporcję przed testami terenowymi; §19.1 i §19.3 są w MVP właśnie dlatego (§19.8) |
| **Tempo ognisk nie pasuje do 1 h gry dziennie** | wszyscy gracze dochodzą do trzech ognisk poziomu 10 w tym samym momencie | symulacja przed etapem 6, korekta wzoru z §6.5.3 (§16.4) |
| **Spirala niemocy w Softcore** | gracz mdleje, budzi się z 25% krwi, mdleje ponownie | zaprojektować dno przed publikacją: minimalny loot gwarantowany albo reset ognisk (§16.2) |
| **Odmowa zgody na lokalizację w tle** | Google odrzuca formularz albo użytkownik odmawia | tryb tylko-foreground jako pełnoprawny wariant gry, gotowy na etapie 3 (§16.1) |
| **Ubijanie foreground service** | dziura w symulacji na urządzeniach Xiaomi/Huawei/Samsung | zapis przy `onPause` + catch-up + podpowiedź o wyłączeniu optymalizacji baterii (§11.1.5) |
| **Zdarzenie w terenie z udziałem gracza** | wypadek, wejście na teren prywatny | §3.5 wdrożone w całości przed pierwszym testem zewnętrznym, regulamin przed publikacją |
