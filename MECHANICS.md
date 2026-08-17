# ARLS-ZA — mechaniki, stan faktyczny

**Co robi gra dzisiaj**, z liczbami wziętymi z kodu, a nie z zamiarów.

Ten plik istnieje, bo trzy dokumenty nie odpowiadały na to pytanie:

| Dokument | Odpowiada na |
| :---- | :---- |
| `ARLS-ZA_design_doc_v2.md` | **co** chcemy zbudować i **dlaczego** |
| `ROADMAP.md` | **w jakiej kolejności** i **kiedy etap jest skończony** |
| `CHECKLIST.md` | **co jest przetestowane** i **jakie mamy długi** |
| **`MECHANICS.md`** | **co gra faktycznie robi**, z liczbami |

Różnica jest istotna, bo w kilkunastu miejscach **świadomie odeszliśmy od dokumentu projektowego** — czasem dlatego, że jego liczby były wewnętrznie sprzeczne, czasem dlatego, że spacer pokazał coś innego. Te decyzje żyły dotąd wyłącznie w komentarzach w kodzie. [Sekcja 13](#13-odejścia-od-dokumentu-projektowego) zbiera je w jednym miejscu.

⚠️ **Reguła utrzymania tego pliku:** liczba zmieniona w kodzie i nieprzeniesiona tutaj czyni ten dokument gorszym niż jego brak. Przy każdej zmianie stałej — aktualizuj sekcję.

**Stan:** 1460 testów · schemat bazy v18 · etapy 0–2 zamknięte, 3–5 i 8 przed testem w terenie.

---

## Spis sekcji

1. [Fundamenty — czas, zapis, determinizm](#1-fundamenty)
2. [Ciało — parametry postaci](#2-ciało)
3. [Metabolizm — kalorie, woda, tętno](#3-metabolizm)
4. [Krew, rany i wstrząs](#4-krew-rany-i-wstrząs)
5. [Sen](#5-sen)
6. [GPS, ruch i bezpieczeństwo gracza](#6-gps-ruch-i-bezpieczeństwo)
7. [Mapa i znaczniki](#7-mapa-i-znaczniki)
8. [Przedmioty i ekwipunek](#8-przedmioty-i-ekwipunek)
9. [Loot — gdzie, ile, jak szukać](#9-loot)
10. [Walka — celność, obrażenia, hałas](#10-walka)
11. [Przeciwnicy](#11-przeciwnicy)
12. [Schron i obóz](#12-schron-i-obóz)
13. [Śmierć i utrata przytomności](#13-śmierć)
14. [Odejścia od dokumentu projektowego](#14-odejścia-od-dokumentu-projektowego)
15. [Czego jeszcze nie ma](#15-czego-jeszcze-nie-ma)

---

## 1. Fundamenty

### 1.1. Czas

Gra liczy czas **zegarem ściennym**, nie czasem spędzonym przy ekranie. Wszystko, co trwa — trawienie, budowa, nieprzytomność, odnowa lootu — mija tak samo przy zamkniętej aplikacji.

| Reguła | Wartość | Gdzie |
| :---- | :---- | :---- |
| Krok symulacji | 1 s | `GameLoop.cadence` |
| Przerwa uznana za „niemierzone" | **> 5 min** | `kUnmeasuredGap` |
| Nadrabianie przerwy | w kawałkach po 1 h | `advanceInChunks` |
| Podłoga offline | 10% zapasu | `SimConstants.offlineFloor` |

**Zawór offline (§2.1.1).** Przerwa dłuższa niż 5 minut jest odtwarzana, ale zasoby nie mogą spaść poniżej 10% — telefon w kieszeni nie zabija postaci głodem.

**Ochrona przed cofnięciem zegara.** Najwyższy zaakceptowany czas zapisany w bazie; ustawienie zegara wstecz nie daje darmowej regeneracji.

### 1.2. Zapis

- Drift/SQLite w trybie WAL, każdy zapis w transakcji.
- **Migracje wyłącznie addytywne** — kolumna nigdy nie jest usuwana ani zmieniana. Aktualny schemat **v18**, wszystkie wersje od v1 mają test migracji na wygenerowanych danych.
- Warstwa gorąca (`vitals`) zapisywana co **60 s** i przy każdym `onPause`.
- Rotujące migawki, `PRAGMA wal_checkpoint(TRUNCATE)` przy wyjściu w tło.
- ⚠️ `allowBackup="false"` — baza zawiera adres domowy gracza (schron).

### 1.3. Determinizm

Każda postać ma jedno ziarno RNG (`rngSeed`), nadane raz przy tworzeniu. Z niego wynikają: rozmieszczenie lootu, zawartość skrzyń, punkty generowane proceduralnie, zawartość zwłok. **Ta sama wioska wygląda tak samo między sesjami.**

---

## 2. Ciało

Postać powstaje z czterech danych podanych przez gracza: **płeć, wiek, wzrost, waga**. Wszystko inne jest z nich wyliczone.

| Parametr | Wzór | Zakres wejścia |
| :---- | :---- | :---- |
| Objętość krwi | Nadler | wiek 16–80 |
| Zapotrzebowanie energetyczne | Mifflin–St Jeor × 1,375 | wzrost 120–220 cm |
| Woda dobowa | 35 ml × masa ciała | waga 35–200 kg |
| Tętno spoczynkowe | szacowane lub podane | 35–110 bpm |
| Tętno maksymalne | 220 − wiek | — |
| BMI | walidacja | 12–60 |

### 2.1. Dwa limity udźwigu (§18.1a)

| Limit | Wartość | Skutek przekroczenia |
| :---- | :---- | :---- |
| **Komfortowy** | 30% masy ciała | dodatkowe kalorie, wolniejszy marsz |
| **Twardy** | **45% masy ciała** | nie da się podnieść |
| **Objętość** | pojemność plecaka | druga, niezależna ściana |

⚠️ Objętość jest **osobnym** limitem. Plecak metalu kończy się na masie, plecak plastiku na objętości, i żadna z tych liczb nie przewiduje drugiej. Kieszenie bez plecaka: **12 l**.

**Udźwig gender-neutralny** — świadoma decyzja, nie przeoczenie.

---

## 3. Metabolizm

### 3.1. Strefy (§2.1)

Zużycie skaluje się od tego, gdzie postać jest. To jest powód, dla którego zamknięcie aplikacji pod dachem jest tańsze niż w terenie.

| Strefa | Kalorie | Woda |
| :---- | ----: | ----: |
| Otwarty teren | 100% | 100% |
| Obóz | 50% | 55% |
| Schron | 35% | 40% |
| Sen | **20%** | **30%** |

### 3.2. Wchłanianie (§2.2, §2.3)

Zjedzone **nie jest** natychmiast we krwi. Trafia do żołądka i przechodzi dalej ze stałą prędkością:

| | Tempo | Przykład |
| :---- | :---- | :---- |
| Woda | **25 ml/min** | pół litra = **20 minut** |
| Kalorie | **8 kcal/min** | puszka 500 kcal = **~62 minuty** |

Na pasku HUD widać to jako znacznik `+` przed wypełnieniem. To jest cała mechanika: jedzenie jest czymś, co się nosi i bierze **zanim** będzie potrzebne, a nie przyciskiem wciskanym, gdy pasek czerwienieje.

⚠️ Zapas jest **capowany dobowym zapotrzebowaniem**. Nadmiar nie jest bankowany.

### 3.3. Progi odwodnienia

Liczone jako **deficyt względem masy ciała**, nie względem paska:

| Deficyt | Skutek |
| :---- | :---- |
| ≥ 2% masy ciała | celność ×0,85 |
| ≥ 5% | poważne osłabienie |
| ≥ 10% | stan krytyczny |
| > 48 h bez wody przy wysiłku | śmiertelne |

⚠️ Woda może zejść **poniżej zera**. Zapas to dobowe zapotrzebowanie (2 800 ml dla 80 kg), a progi to procenty masy ciała (2% = 1 600 ml, 10% = 8 000 ml) — clampowanie na zerze uczyniłoby dwa z trzech progów nieosiągalnymi.

### 3.4. Głód

| Zapas | Skutek |
| :---- | :---- |
| < 50% | precyzja ×0,90 |
| < 20% | wszystkie czynności ×1,20 czasu |
| 0 przez > 24 h | utrata przytomności |

### 3.5. Tętno (§2.4)

Dąży do celu wyznaczonego przez MET, stałą czasową **90 s**. Sen: −14 bpm, podłoga 35 bpm. MET maksymalne 14.

Tętno jest jednocześnie wskaźnikiem wytrzymałości, której gra nie ma osobno — i **największym pojedynczym źródłem rozrzutu strzału** (sekcja 10).

---

## 4. Krew, rany i wstrząs

**Krew jest paskiem zdrowia, którego ta gra nie ma.** Wszystko, co rani, wyrażone jest w mililitrach.

### 4.1. Klasy wstrząsu (ATLS, §2.6)

| Utrata | Klasa | Stan |
| :---- | :---- | :---- |
| < 15% | I | brak objawów |
| 15–30% | **II** | +2 MOA, −10% udźwigu |
| 30–40% | **III** | +5 MOA, przyciemniony obraz, brak biegu bez zawrotów |
| > 40% | **IV** | utrata przytomności → śmierć |

### 4.2. Krwawienie (tiery)

| Typ | Ubytek | Czym zatrzymać |
| :---- | ----: | :---- |
| Powierzchowne | 3 ml/min | samo po 3–5 min |
| Umiarkowane | 25 ml/min | opatrunek uciskowy |
| Silne | 90 ml/min | opatrunek + unieruchomienie |
| Tętnicze | **350 ml/min** | wyłącznie staza |

**Modyfikator wysiłku:** `ubytek × (tętno / tętno_spoczynkowe)`. Bieg przy krwawieniu przyspiesza utratę — przy 160 bpm wobec 70 jest to **2,3×**.

Krwawienie **przeżywa wygaszenie ekranu** (kolumna w bazie). Opatrunek schodzi do stopnia, który obsłuży, i nie niżej — opatrunek na tętnicze nie zadziała.

### 4.3. Regeneracja krwi

⚠️ **Tego nie ma w dokumencie projektowym.** Bez tego przeżycie ciężkiej walki było dożywociem w klasie IV.

| | |
| :---- | :---- |
| Tempo | **60 ml/h** |
| Warunek | najedzenie **i** nawodnienie (gorsze z dwóch) |
| Podczas krwawienia | **zero** |

Ubytek 2 l wraca w ~1,5 doby, jeśli gracz je i pije. Nie da się napełnić wiadra z dziurą — zatrzymanie krwawienia jest pierwszą robotą, nie opcjonalną.

---

## 5. Sen

**Sen jest stanem, nie akcją.** Gracz nic nie klika. Zero uprawnień, zero Health Connect, zero danych zdrowotnych — wiążąca decyzja architektoniczna.

### 5.1. Warunki

Postać śpi, gdy **jednocześnie**:

1. jest w strefie schronu (50 m) lub obozu (20 m),
2. **nie wykonuje żadnego zajęcia ani czynności**,
3. **i** jest noc **albo** minęło **10 minut** spokoju.

| | |
| :---- | :---- |
| Zapotrzebowanie dobowe | **8 h** |
| Próg „usadowienia się" | **10 min** |
| Jakość — schron | 100% |
| Jakość — obóz | **70%** |
| Moduł Salon | +15% na poziom (maks. +45%) |

Noc wyliczana offline ze wschodu i zachodu słońca dla szerokości geograficznej i daty. **Naturalna sezonowość bez żadnego modyfikatora**: 21 czerwca w Poznaniu noc trwa 7,4 h (dług narasta mimo schronu), 21 grudnia 16,6 h.

**Wybudza:** rozpoczęcie czegokolwiek (budowa, crafting, lektura, jedzenie, opatrunek, przeszukanie) albo wyjście ze strefy.

### 5.2. Skutki długu

| Dług | Skutek |
| :---- | :---- |
| 0–4 h | brak |
| 4–12 h | +20% czasu lektury, **+1 MOA** |
| 12–24 h | +50% czasu wszystkich czynności, **+3 MOA**, −20% nauki |
| > 24 h | **mikrosny** — 5–15 s zablokowania interfejsu |

---

## 6. GPS, ruch i bezpieczeństwo

### 6.1. Filtrowanie pozycji (§3.2)

| Reguła | Wartość |
| :---- | :---- |
| Bramka dokładności | odrzuca `accuracy > 25 m` |
| Martwa strefa | **8 m** netto w oknie |
| Filtr | Kalman na strumieniu |
| Utrata sygnału | > 60 s → pauza symulacji ruchu |

⚠️ **Dwie różne pozycje.** `fix` przeszedł bramkę i decyduje, co liczy się jako **ruch**. `displayFix` to najlepsza pozycja jakiejkolwiek szerokości i decyduje, gdzie **narysować** gracza. W budynku każdy odczyt ma 30–60 m i żaden nie jest marszem — ale gracz gdzieś stoi.

**Pozycja jest „lepka"**: snapshot bez pozycji to telefon, który nie ma nic do powiedzenia, a nie gracz, który zniknął. Na starcie zasiewana z zapisu.

### 6.2. Anti-cheat (§3.4)

- Wykrywanie mock location.
- **> 40 km/h przez > 30 s** = pojazd → zawieszenie rozgrywki (nie kara).

### 6.3. Bezpieczeństwo gracza (§3.5)

**Strefy wykluczone ze spawnu:** drogi główne (15 m od jezdni), tory czynne, woda, cmentarze, teren wojskowy, tereny religijne, szkoły i przedszkola.

**Blokada walki:** prędkość > **15 km/h** albo zawieszony run. To nie balans — to ktoś na rowerze albo przechodzący przez jezdnię bez patrzenia.

### 6.4. Bateria (§3.3)

| Aktywność | Częstotliwość GPS |
| :---- | :---- |
| Walka | 1 Hz |
| Marsz | 0,2 Hz |
| Postój | 0,05 Hz |

Ostrzeżenie przy **20%**, tryb ekonomiczny: brak animacji, kamera skacze zamiast płynąć.

---

## 7. Mapa i znaczniki

### 7.1. Renderowanie

⚠️ **MapLibre rysuje wyłącznie kafelki.** Wszystkie znaczniki, pierścienie, stożki, glify i fale hałasu maluje Flutter w jednym `paint()` na klatkę.

Powód nie jest estetyczny: adnotacje MapLibre kosztują przelot przez platform channel każda, do 65 sztuk, przepisywane przy każdym ruchu. Ta jedna decyzja stała za trzema błędami — utratą płynności przy szczypaniu, pustą mapą po zimnym starcie i glifami odklejającymi się od kropek.

Dziś kropka i palec, który w nią trafia, liczone są **z tej samej arytmetyki**.

### 7.2. Zasięgi rysowane wokół gracza

Zasięg jest symetryczny, więc jeden okrąg wokół gracza mówi to samo, co 65 kółek wokół rzeczy.

| Promień | Znaczy |
| ----: | :---- |
| **25 m** | tak blisko trzeba być, żeby przeszukać miejsce |
| **15 m** | zasięg ręki — podniesienie czegoś z ziemi |

⚠️ **Strefa schronu (50 m) nie jest zasięgiem.** To kawałek ziemi i rysowana jest wokół schronu, nie wokół gracza.

### 7.3. Ikony typów miejsc

Dziewięć kształtów, czytanych z **tabeli lootu** (bo to ona decyduje, co jest w środku), nie z tagu OSM:

| Ikona | Miejsca |
| :---- | :---- |
| ✚ krzyż | apteka, szpital, karetka |
| 🛡 tarcza | wojsko, radiowóz |
| 🍴 sztućce | spożywcze |
| 🔧 klucz | warsztat, przemysł, magazyn, garaż |
| ◎ celownik | broń, sport, ambona |
| 📖 książka | biblioteka, szkoła |
| 🏠 dom | mieszkanie, stodoła, schron |
| 🚗 auto | porzucony samochód |
| 🗑 kosz | śmietniki, pobocza |

**Dziewięć i ani jednego więcej** — jest test, który pęknie, jeśli legenda urośnie.

### 7.4. Zoom i grupowanie

| | |
| :---- | :---- |
| Zoom startowy | 17,5 |
| Najbliżej | 19 |
| Najszerzej | **3 km** przez ekran |
| Grupowanie znaczników | **25 m** |

⚠️ MapLibre serwuje kafelki **512 px** — `metresPerPixel = 156543,03392/2 × cos(lat) / 2^zoom`. Pomylenie tego z konwencją 256 px czyniło każdą odległość dwa razy węższą.

Mapy **nie da się przeciągnąć**. Gracz jest zawsze na środku.

---

## 8. Przedmioty i ekwipunek

### 8.1. Sloty na ciele

Głowa, tors (odzież), tors (pancerz), nogi, stopy, dłonie, **ręce** (broń), plecy (plecak).

**Broń w ręku jest `worn`**, nie w plecaku — to częste źródło pomyłek przy zmianach w kodzie.

### 8.2. Stan pojedynczej sztuki

Każda sztuka niesie własny stan i **nigdy nie jest utożsamiana z innymi o tym samym id**:

| Pole | Znaczenie |
| :---- | :---- |
| `condition` | zużycie, 0–100% |
| `portion` | ile zostało z otwartej porcji (0–1) |
| `pagesTotal` / `pagesRead` | postęp lektury |
| `noteId` | która to notatka |
| `attachments` | co jest przykręcone |

⚠️ **Id przedmiotu to nie tożsamość.** Dwie konserwy, jedna napoczęta — to dwa różne przedmioty. Ta pomyłka wracała pięciokrotnie.

### 8.3. Dodatki do broni (§5.6.3)

Siedzą **na konkretnej sztuce broni**, nie na graczu. Dwa karabiny w plecaku to dwa karabiny — ten z tłumikiem jest tym, który warto wziąć do miasta.

| Dodatek | Efekt |
| :---- | :---- |
| Kolimator | −1,2 MOA, celowanie ×0,85 |
| Chwyt przedni | −0,5 MOA, celowanie ×0,8 |
| Laser | celowanie ×0,6, widoczny dla przeciwników |
| Latarka | 20 m światła, widoczna dla przeciwników |
| Magazynek przedłużony | +10 naboi, +0,5 s przeładowania |
| Tłumik | hałas **×0,29**, +0,3 MOA |

Liczba slotów zależy od broni (rewolwer 1, karabin 3). **Masa dodatków wlicza się do udźwigu.** Dodatki przeżywają wyrzucenie broni na ziemię.

---

## 9. Loot

### 9.1. Gęstość

| | Wartość |
| :---- | ----: |
| Maks. aktywnych miejsc | **15** |
| Promień spawnu | **1 200 m** ⚠️ beta |
| Promień przy cienkiej mapie | 1 800 m |
| Gwarantowany bliski ring | **5 miejsc w 600 m** |
| Zapominanie | 4 000 m |
| Odnowa skrzyni | **4–8 h** |

⚠️ **1 200 m to figura beta**, poniżej dwóch kilometrów z §10. Powód: 25 minut marszu w jedną stronę po jeden sklep to nie jest zadanie, to szum na mapie — a znacznik, do którego nikt nie pójdzie, uczy gracza, żeby przestał czytać znaczniki. Wraca do 2 km, gdy ogniska (§6.5) dadzą dalekim punktom powód istnienia.

### 9.2. Skąd biorą się miejsca

| Źródło | Jak |
| :---- | :---- |
| **OSM** | apteki, szpitale, sklepy, warsztaty, biblioteki… (11 tabel) |
| **Proceduralne** | wymyślone tam, gdzie mapa jest pusta (11 tabel) |

**§10.1 istnieje, bo bez niego gra działa tylko w dużych miastach.** Zmierzone na tych samych 12 km: centrum Poznania — 74 455 miejsc, wiejska Wielkopolska — 263.

Punkty generowane stoją **przy drogach, nigdy na nich** (20 m od jezdni), co 250 m, minimum 300 m od siebie.

**Mieszanka według terenu** — udziały tych samych punktów, nie punkty dodatkowe:

| Teren | Co powstaje |
| :---- | :---- |
| Zabudowa mieszkalna | dom 60% · śmietnik 25% · auto 15% |
| Pola | stodoła 85% · auto 15% |
| Las | ambona 100% |
| Pobocze | pobocze 55% · auto 30% · śmietnik 15% |

Miasto dostaje **4 wymyślone punkty niezależnie od gęstości** — inaczej auta i śmietniki nie istniałyby dla nikogo mieszkającego w mieście.

**Karetka i radiowóz** stoją 25 m od szpitala/komisariatu, po jednym, tylko gdy budynek jest na mapie. Oba **zamknięte**.

### 9.3. Widoczność

| Widoczne od razu | Dopiero po rozpoznaniu |
| :---- | :---- |
| wszystko z OSM, auto, kosz, pobocze, karetka, radiowóz, warsztat, punkt wody | opuszczony dom, stodoła, ambona |

Reguła: **czy trzeba tego szukać**, a nie czy zostało wymyślone. Samochód na ulicy widać z chodnika; dom, który może być opuszczony, to dokładnie to, po co jest rozpoznanie.

### 9.4. Przeszukiwanie (§10.3.5)

Każde miejsce ma **budżet 6 jednostek**:

| Głębokość | Czas bazowy | Koszt | Losowań | Rzadkość |
| :---- | ----: | ----: | :---- | :---- |
| Pobieżne | 30 s | 2 | 1–2 | tylko pospolite |
| Dokładne | 90 s | 3 | 2–4 | + niepospolite |
| Gruntowne | **180 s** | **6** | 3–5 | wszystko |

⚠️ **Czas skaluje się rozmiarem miejsca.** Trzy minuty nad śmietnikiem to te
same trzy minuty co nad supermarketem, i czyta się dokładnie tak.

| Rozmiar | Mnożnik | Pobieżne / dokładne / gruntowne | Co |
| :---- | ----: | :---- | :---- |
| **tiny** | ×0,2 | 6 / 18 / 36 s | śmietnik, pobocze, punkt wody |
| **small** | ×0,5 | 15 / 45 / **90 s** | samochód, karetka, radiowóz, ambona, wiata |
| **normal** | ×1,0 | 30 / 90 / 180 s | sklepy, mieszkania, warsztaty, magazyny |

Mnożnik działa **wyłącznie na czas**, nigdy na zawartość. Śmietnik przeszukany
gruntownie to nadal śmietnik przeszukany gruntownie — po prostu kończy się
szybciej. Minimum 5 s: poniżej przestaje być czynnością, a staje się
przyciskiem z mignięciem.

Czyli: **3× pobieżne**, albo **2× dokładne**, albo **1× gruntowne**. Zaczęcie od gruntownego zamyka resztę.

### 9.5. Bariery (§19.3)

| Bariera | Otwarte od startu | Siłą | Cicho | Narzędziem |
| :---- | ----: | :---- | :---- | :---- |
| **Drzwi** | 35% | 20 s / 150 m | wytrychy 60 s / 20 m | łom, siekiera 12 s / 150 m |
| **Kłódka** | 10% | — | wytrychy 45 s / 20 m | **nożyce 10 s / 60 m**, łom/piła/multitool 25 s / 60 m |
| **Okno** | 45% | 5 s / 150 m | — | — |

⚠️ **Kłódki nie da się otworzyć bez narzędzia.** §19.3 nazywa ją barierą
wymagającą narzędzia, a złagodzenie tego uczyniłoby każde narzędzie w grze
opcjonalnym.

**Nożyce do kłódek** (`tool_bolt_cutters`, 1,9 kg) to głośna i szybka
odpowiedź; **wytrychy** (`tool_lockpicks`, 0,1 kg) to cicha i wolna. Dwa
kilogramy jednozadaniowej stali kupują 35 sekund i płacą 40 metrami hałasu —
i to jest cała decyzja.

| | |
| :---- | :---- |
| Rozpoznanie terenu | 45 s, promień 100 m, pamięć 10 min |
| Hałas przeszukania | **80 m** |
| Zasięg przeszukania | 25 m |
| Ruch przerywa | 2 odczyty poza 15 m |

⚠️ **Użycie przedmiotu (jedzenie, picie, opatrunek) nie wymaga GPS ani stania w miejscu.** To rzeczy, które robi ciało, a nie rzeczy, których świadkiem jest GPS.

### 9.6. Rzeczy na ziemi

| | |
| :---- | :---- |
| Czas życia | **24 h** |
| Maks. sztuk | 50 |
| Grupowanie w kropkę | 25 m |
| Podniesienie | zasięg ręki (15 m) |

Kliknięcie w kropkę pokazuje **listę wszystkiego**, co pod nią leży. Karabin z tłumikiem i goły to dwie osobne kupki.

---

## 10. Walka

### 10.1. Celność (§5.1)

⚠️ **MOA to średnica grupy, nigdy promień.** Pomylenie tego przesuwa szansę trafienia o czynnik ~3.

Błędy składają się jako **pierwiastek sumy kwadratów** — pięć źródeł po jednej minucie kątowej to nie pięć minut.

| Źródło | Wzór |
| :---- | :---- |
| Broń | z danych przedmiotu (`moa`) |
| Wprawa | `25 − 21 × umiejętność` (25 MOA nowicjusz, 4 mistrz) |
| **Tętno** | `60 × ((HR−spocz)/(maks−spocz))²` |
| **Ruch** | `8 × v^1,2` (marsz 55 MOA, bieg 165) |
| Cel | `0,6 × v` |
| Stan | dług snu + utrata krwi |

Szansa trafienia: `P = [2Φ(W/2σ) − 1] × [2Φ(H/2σ) − 1]`, gdzie `σ = D/4`.

Panel walki pokazuje **największe pojedyncze źródło** obok procentu — żeby chybienie dało się naprawić, a nie tylko przeżyć.

**Celowanie (§5.3):** przełączenie celu daje rozrzut ×2,5, opadający przez **2 s** (4 s przy wysokim tętnie).

### 10.2. Obrażenia (§5.1.5)

`ubytek [ml] = 5,1 × energia[J]^0,6 × współczynnik_rany × lokalizacja × (1 − pancerz)`

⚠️ Wykładnik 0,6 jest sednem. Model liniowy zawsze karałby małe kalibry — cała hierarchia broni wynika z tych sześciu dziesiątych.

**Kalibracja:** ~3,2 naboje 5,45 na Szwędacza, ~7,2 z 9 mm.

### 10.3. Lokalizacja trafienia

| Lokalizacja | Szansa | Mnożnik | Krwawienie |
| :---- | ----: | ----: | ----: |
| Głowa | 12% | **×4,0** | 6 ml/s |
| Tors | 45% | ×1,0 | 4 ml/s |
| Ręce | 18% | ×0,6 | 1,2 ml/s |
| Nogi | 25% | ×0,7 | 1,2 ml/s |

Losowane **w obie strony** — ugryzienie też ma lokalizację. Trafiony przeciwnik może **wykrwawić się, zanim dobiegnie**, co czyni wycofanie się taktyką.

### 10.4. Dystanse (§5.2)

| | |
| :---- | :---- |
| Wykrycie minimalne | 150 m |
| Strzał — zakres | 50–250 m |
| **Zwarcie** | **≤ 20 m** |
| Przeładowanie przerywa | przeciwnik bliżej niż **5 m** |

Poniżej 20 m GPS nie ma nic sensownego do powiedzenia o niczyjej pozycji — walka przestaje być o dystansie i staje się o tym, co masz w rękach.

**Oskrzydlenie (§5.5.3):** gracz odpowiada jednemu, reszta bije bezkarnie. Mnożnik rośnie z liczbą — wpuszczenie grupy w zwarcie to prawie wyrok.

### 10.5. Hałas (§5.6)

| Źródło | Zasięg |
| :---- | ----: |
| Strzelba | 900 m |
| **Karabin** | **700 m** |
| Pistolet | 450 m |
| Tłumiony karabin | 200 m |
| Wyważanie | 150 m |
| Tłumiony pistolet | 120 m |
| Młotek (budowa) | 100 m |
| Przeszukanie | 80 m |
| Bieg gracza | 40 m |
| **Nóż** | **25 m** |
| Kroki | 15 m |

**Modyfikatory:** noc ×1,3 · gęsta zabudowa ×0,7 (tylko w dzień) · otwarty teren ×1,2 · zła pogoda ×0,75.

⚠️ Noc jest **głośniejsza**, nie cichsza — mniej tła i inwersja temperaturowa niosą dźwięk dalej.

### 10.6. Reakcja na hałas (§5.6.2)

**Idą do miejsca, w którym powstał dźwięk — nie do gracza.** To zostawia miejsce na taktykę: strzał, przemieszczenie, obserwacja.

| Odległość od źródła | Reakcja |
| :---- | :---- |
| < ⅓ promienia | **POŚCIG** — lokalizują gracza |
| ⅓ – 1 promienia | **CZUJNOŚĆ** — do punktu hałasu, 60 s przeszukiwania |
| > promienia | brak |

| | |
| :---- | :---- |
| Maks. reagujących | **6**, od najbliższego |
| Okno kumulacji | 30 s |
| Seria ciągła | jedno zdarzenie ×1,15, nie pięć |

⚠️ **Dźwięk niosący ≥ 200 m jest „płoszący" — pokonują dystans biegiem.** Dokument mówi „marsz" dla wszystkiego jednakowo; chybiony strzał ściągający ich spacerkiem czytał się jak świat, który go nie usłyszał. Nóż i kroki nadal ściągają marszem.

⚠️ **Kolejny strzał przekierowuje także tych, którzy już idą do poprzedniego.** Nie przekierowuje tego, kto już widzi gracza — inaczej grupę dałoby się odciągnąć rzuconą puszką.

Efekt: **każdy nabój ściąga ulicę tam, gdzie stoisz teraz.** Broń palna jest do kończenia walk, nie do ich podtrzymywania.

---

## 11. Przeciwnicy

### 11.1. Rodzaje (§6.2)

| | Skakun | **Szwędacz** | Brutal |
| :---- | :---- | :---- | :---- |
| Marsz | 5–7 km/h | 3–4 km/h | 2–4 km/h |
| Bieg | **27–32 km/h** | 15–18 km/h | 12–17 km/h |
| Budżet sprintu | 25 s | 90 s | 45 s |
| Regeneracja | 60 s | 45 s | 120 s |
| Krew | 2 400–2 800 | 3 200–3 600 | **6 000–8 000** |
| Obrażenia | 120 ml | 180 ml | **400 ml** |
| Co ile bije | 1,2 s | 2 s | 3 s |
| Wykrycie | 120 m | 80 m | 60 m |
| Śmierć przy utracie | 45% | 45% | 50% |
| Grupa | 1 | **2–4** | 1 |

W MVP występuje wyłącznie **Szwędacz**. Grupa 2–4 czyni walkę z grupą stanem domyślnym gry.

### 11.2. Stany (§6.1a)

| Stan | Zachowanie | Prędkość |
| :---- | :---- | :---- |
| **SPOCZYNEK** | krąży po swoim terenie (40 m) | marsz |
| **CZUJNOŚĆ** | idzie do punktu hałasu | marsz (**bieg**, gdy hałas ≥ 200 m) |
| **POŚCIG** | biegnie za graczem | bieg, zużywa budżet |
| **WYCZERPANIE** | budżet pusty | **40%** biegu |
| **POWRÓT** | utrata kontaktu lub smycz | marsz do domu |

| | |
| :---- | :---- |
| Smycz | 400 m od domu |
| Utrata kontaktu | 45 s |
| Dystans kontaktu | 150 m |
| Czas przeszukiwania | 60 s |
| Maks. skręt — marsz | 12°/s |
| Maks. skręt — pościg | 60°/s |

⚠️ **Nic nie obraca się w miejscu.** Wcześniejszy błąd: przeciwnik, który stracił kontakt, obracał się o 118° w sekundę, co czytało się jak usterka, a nie jak ciało.

**Omijają przeszkody** — woda i strefy §3.5 blokują ruch. Budynki jeszcze nie (warstwa w paczkach nie niesie typu).

**W gęstej zabudowie zasięg wykrycia ×0,7** — ściany, które połykają strzał, połykają też sylwetkę.

### 11.3. Spawn (§6.4)

| | Wartość |
| :---- | ----: |
| Minimalny dystans od gracza | **150 m** |
| Zasięg symulacji | 600 m |
| **Rysowani na mapie** | **300 m** (histereza do 375 m) |
| Limit aktywnych | 8 (horda 12) |
| Gęstość tłowa | **2 / km²** |
| Od schronu | 200 m |

**Nie ma opóźnienia czasowego** — spawner biegnie w każdym ticku i tworzy przeciwnika, gdy tylko jest legalne miejsce i limit na to pozwala.

⚠️ **Histereza:** znacznik już narysowany zostaje widoczny do 375 m. Bez niej ten sam Szwędacz migotał, przechodząc granicę 300 m tam i z powrotem.

⚠️ Przy 600 m i gęstości 2/km² maksymalna liczba przeciwników tłowych to **2**. Prawdziwa populacja ma pochodzić z ognisk (§6.5), których jeszcze nie ma.

### 11.4. Trwałość

**Przeciwnicy nie są zapisywani.** §6.4 odtwarza populację przy każdym uruchomieniu — Szwędacz to nie miejsce.

**Ale walka jest zapisywana:**

| | |
| :---- | :---- |
| Ważność | **15 min** |
| Zasięg | **500 m** |
| Wraca | ~60% zaangażowanych, maks. **4** |
| Gdzie | 150–270 m od gracza, szukają |

Bez tego zamknięcie aplikacji było doskonałą ucieczką. Ucieczka nadal istnieje — jest spacerem, nie menedżerem zadań.

**Ciała są zapisywane** — 6 h, ze znacznikiem „przeszukane". Łup pojawia się dopiero po przeszukaniu z bliska.

---

## 12. Schron i obóz

### 12.1. Strefy (§8.1)

⚠️ **Promień bezpieczeństwa i promień zakazu strzału to ta sama liczba.** Dwie różne wartości tworzą pierścień, w którym przeciwnik dosięga gracza, a gracz nie może odpowiedzieć.

| | Schron | Obóz |
| :---- | ----: | ----: |
| Strefa | **50 m** | **20 m** |
| Metabolizm | 35% / 40% | 50% / 55% |
| Sen | 100% | 70% |
| Magazyn | 25 kg + moduł | 30 kg |
| Moduły | 4 × 3 poziomy | brak |
| Czas budowy | **3 h** | **40 min** |

Przeciwnicy zatrzymują się na granicy. Gracz musi wyjść, żeby walczyć — ale nie jest bezbronny.

### 12.2. Budowa (§8.3)

| | |
| :---- | :---- |
| Bazowo | 3 h |
| Z narzędziami (młotek + siekiera) | **−35%** → 1 h 57 min |
| Inżynieria 100% | dodatkowe −30% |
| Minimum osiągalne | **~1 h 22 min** |

⚠️ **Praca liczy się wyłącznie na placu.** Odejście zatrzymuje pasek. Postęp zapisywany co 15 s, znacznik czasu w bazie — noc z zamkniętą aplikacją liczy się w całości.

**Przerwanie** jest możliwe i nieodwracalne: materiały zostają w ścianach, praca zaczyna się od zera. Okno mówi to wprost.

### 12.3. Moduły (§8.4)

| Moduł | Efekt / poziom | Maks. |
| :---- | :---- | :---- |
| **Magazyn** | +50 kg | 175 kg |
| **Warsztat** | naprawa do 60% / 85% / 100% | + receptury złożone |
| **Salon** | +15% tempa snu | +45% |
| **Laboratorium** | +3% z posiłków | +9% |

⚠️ Warsztat przebudowany względem dokumentu: **dostęp do możliwości**, nie procent oszczędności czasu. Wersja z 3% na poziom to coś, za co nikt nigdy nie zapłaciłby trzech poziomów.

**Koszt pełnej rozbudowy: 731 kg** — około 30 kursów z pełnym plecakiem. To ma być cel na tygodnie.

Wymagania narzędziowe: młotek do wszystkiego, multitool ×1,6 czasu, Warsztat L2+ wymaga obu bez alternatywy.

### 12.4. Obozy (§8.5.2)

| | |
| :---- | ----: |
| Maksymalnie | **2** |
| Od schronu | 800 m |
| Między sobą | 800 m |
| Od centrum ogniska | 400 m |
| Rozpad | **14 dni** |
| Zniknięcie | **21 dni** |

Schron główny **nigdy się nie rozpada** — to miejsce, gdzie gracz mieszka.

### 12.5. Prywatność (§8.2)

⚠️ Współrzędne schronu to w praktyce **adres domowy gracza**. Zapisane lokalnie, nigdy nie wysyłane, `allowBackup="false"` dla całej bazy.

---

## 13. Śmierć

Tryb wybierany raz przy tworzeniu postaci. **Nieodwracalnie.**

### 13.1. Zabezpieczenia (§9.1)

⚠️ **Nie do negocjacji.** Permadeath z powodu awarii technicznej to gwarantowana jedna gwiazdka w sklepie.

- Śmierć **nie może** nastąpić we śnie.
- Śmierć **nie może** nastąpić przy utraconym sygnale GPS.

### 13.2. Hardcore

Koniec postaci. Wpis do Kroniki z pełnym stanem. Nowa postać zachowuje parametry fizjologiczne — to nadal to samo ciało gracza, zmienia się tylko imię.

### 13.3. Softcore

| | |
| :---- | ----: |
| Nieprzytomność | **60 min** czasu zegarowego |
| Krew po przebudzeniu | **65%** (klasa III) |
| Woda i kalorie | 15% |
| Broń w rękach | **zawsze przepada** |
| Reszta noszonego i plecak | **50% losowo** |
| Skrytki | 30–100 m od miejsca upadku |
| Okno łaski | **10 min** |

Budzi się **tam, gdzie fizycznie jest gracz** — rozjazd między pozycją postaci a pozycją gracza jest niedopuszczalny w żadnym stanie gry.

**Przebudzenie w pojeździe** (> 15 km/h lub zły GPS) jest **odroczone**, nie karane.

Ekran śmierci pokazuje **log ostatnich chwil walki** — 30 linii, około dwóch minut złej walki.

---

## 14. Odejścia od dokumentu projektowego

Miejsca, w których kod **świadomie** robi coś innego niż `ARLS-ZA_design_doc_v2.md`. Każde ma powód.

| Co | Dokument | Kod | Dlaczego |
| :---- | :---- | :---- | :---- |
| **Krew po przebudzeniu** | „25% maksymalnej (klasa III)" | **65%** | Te dwie połowy są sprzeczne: 25% pozostałej to 75% utraty = klasa **IV** = śmierć. Dosłownie wdrożone → budzisz się i natychmiast padasz z powrotem, w pętli. Wygrała klasa, nie liczba. |
| **Reakcja na hałas** | marsz do punktu hałasu | **bieg**, gdy hałas ≥ 200 m | Chybiony strzał ściągający ich spacerkiem z 400 m czytał się jak świat, który go nie usłyszał. Bez tego cena broni palnej jest notatką w logu, a nie kosztem. |
| **Przekierowanie na drugi strzał** | reagują tylko SPOCZYNEK/POWRÓT | także **CZUJNOŚĆ** | Idący do pierwszego strzału ignorowali każdy następny — można było strzelać i odchodzić bez konsekwencji. |
| **Promień spawnu lootu** | 2 km | **1,2 km** (beta) | 25 minut marszu po jeden sklep to szum na mapie. Wraca przy ogniskach. |
| **Sen w dzień** | tylko noc (§2.5.3) | **także 10 min spokoju** | Prośba z testów. Nie da się farmić — dług zatrzymuje się na zerze. |
| **Warsztat** | 3% na poziom | dostęp do napraw | Dokument sam oznacza swoją wersję jako niezbalansowaną. |
| **Regeneracja krwi** | brak | **60 ml/h** | Bez tego przeżycie ciężkiej walki to dożywocie w klasie IV. |
| **Widoczność miejsc** | proceduralne = ukryte | ukryte tylko to, czego trzeba szukać | Samochód na ulicy widać z chodnika. |
| **Czas przeszukania** | jeden dla wszystkiego | **skalowany rozmiarem** ×0,2 / ×0,5 / ×1 | Trzy minuty nad śmietnikiem to te same trzy minuty co nad supermarketem. |
| **Czas budowy schronu** | §8.3: −35% z narzędziami · §18.3: ×2,5 bez | wdrożono **§8.3** | Dokument sam sobie przeczy. **Do rozstrzygnięcia.** |
| **Skrytki po utracie przytomności** | 48 h | **24 h** | Leżą jako zwykłe rzeczy na ziemi (§4.8), a te mają dobę. Dług. |
| **Okno łaski** | warunkowe (przeciwnicy w 300 m) | zawsze 10 min | Dług. |
| **Udźwig** | — | gender-neutralny | Świadoma decyzja gracza. |

---

## 15. Czego jeszcze nie ma

| Mechanika | Stan | Blokuje |
| :---- | :---- | :---- |
| **Ogniska (§6.5)** | ⬜ etap 6 | prawdziwą populację przeciwników; dziś świat ma maks. 2 tłowych |
| **Umiejętności (§7)** | ⬜ | wszyscy strzelają jak nowicjusz (25 MOA) |
| **Magazynki jako przedmioty** | ⬜ | stan magazynka nie jest zapisywany |
| **Zawartość magazynu schronu** | ⬜ | pojemność policzona, nie ma gdzie odłożyć |
| **Dźwięki i haptyka** | ⬜ etap 7 | ~55 plików, licencje |
| **Pancerz per lokalizacja** | ⬜ | trafienia mają lokalizacje, pancerz liczy jeden próg torsa |
| **Budynki jako przeszkody** | ⬜ | warstwa w paczkach nie niesie typu |
| **Światło broni** | ⬜ | §6.2 daje wykrywanie bez kierunku |
| **Crafting, moduły, recykling** | ⬜ P3 | — |
| **Pogoda i sezonowość** | ⬜ P4 | wymaga craftingu |
| **Onboarding, dostępność** | ⬜ etap 9 | publikację |

---

## Jak utrzymać ten plik

```
flutter test          # liczby w sekcjach są pilnowane testami
flutter analyze
```

Większość stałych z tego dokumentu ma test, który pęknie przy zmianie. Jeśli zmieniasz liczbę:

1. zmień stałą w kodzie,
2. popraw test, który ją trzyma,
3. **popraw sekcję tutaj**,
4. jeśli to odejście od dokumentu projektowego — dopisz wiersz do [sekcji 14](#14-odejścia-od-dokumentu-projektowego) z powodem.

Punkt 4 jest najważniejszy. Powód zapomniany po trzech miesiącach wraca jako „dziwna liczba, pewnie błąd".
