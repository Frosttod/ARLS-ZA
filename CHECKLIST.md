# ARLS-ZA — lista kontrolna systemów

Stan na dzień **2026-08-16**. Wygenerowana po przejściu pełnego zestawu
testów: **1405 testów, `flutter analyze` czysty, schemat bazy v12**.

Dokument ma dwie części, bo są to dwa różne rodzaje pewności:

1. **Co udowadnia maszyna** — testy przechodzą albo nie, i to jest fakt.
2. **Co udowadnia wyłącznie spacer** — czy liczba na ekranie jest tą liczbą,
   której gracz potrzebował, i czy palec trafia w kropkę. Tego żaden test nie
   powie, dlatego etapy 3, 4 i 5 mają w ROADMAP komplet zadań i nadal nie są
   zamknięte.

---

## 1. Co przechodzi automatycznie

| Obszar | Testy | Co jest tam pilnowane |
| :---- | ----: | :---- |
| `combat` | 231 | tabela kalibracyjna §5.1.2 wiersz po wierszu, obrażenia §5.1.5, budżet sprintu, maszyna stanów, hałas, spawn, magazynek, dodatki |
| `ui` | 274 | HUD, ekwipunek, panele, arkusze, geometria dotknięć i pierścieni |
| `sim` | 195 | tick, metabolizm, tętno, wchłanianie, sen, nawyk gry |
| `loot` | 130 | tabele, spawner, przeszukanie, rzeczy na ziemi, przeszkody |
| `map` | 88 | PMTiles, MVT, geometria, namiary, pakiety regionów |
| `inventory` | 82 | dwa limity §18.1a, sloty, porcje, dodatki, trwałość |
| `items` | 71 | katalog jako dane: bilans, nazwy, sloty, użycia |
| `location` | 53 | bramka dokładności, filtr Kalmana, martwa strefa, anty-cheat |
| `db` | 50 | migracje v1→v15, integralność, warstwa gorąca i ciepła |
| `shelter` | 55 | strefy §8.1, czasy budowy §8.3, moduły §8.4, obozy §8.5.2, receptury §18.2 |
| `devtools` | 44 | symulator GPS, nakładka, zegar |
| `game` | 58 | pętla gry, nadrabianie przerw, próbkowanie |
| `safety` | 34 | strefy wykluczone §3.5 |
| `core` | 30 | deterministyczny RNG, zegar |
| `notes` | 14 | notatki §19.1, podstawianie nazw miejsc |

**Razem 1405.**

### Rzeczy, które testy trzymają jako liczby, a nie jako intencje

- **§5.1.2** — siedem sytuacji strzeleckich, każda z szansą trafienia na
  czterech dystansach. Zmiana dowolnej stałej w modelu celności wywala te
  testy, a nie psuje po cichu balansu.
- **§5.1.5** — tabela kalibrów: ~3 naboje 5,45 na Szwędacza, ~7 z 9 mm.
- **§10.3.1–2** — energie wylotowe i utrata krwi na cios.
- **§18.2** — masy materiałów budowlanych odtworzone z tabeli.
- **§6.2** — parametry przeciwników, w tym progi śmierci.
- **§5.6.1** — promienie hałasu i modyfikatory otoczenia.
- **Migracje** — każda wydana wersja schematu daje się otworzyć i podnieść do
  v12, z danymi.

---

## 2. Co sprawdza wyłącznie spacer

Kolejność jest celowa: rzeczy wyżej blokują ocenę tych niżej.

### 2.1. Etap 3 — mapa i GPS

- [ ] Marsz przez 20+ minut bez ostrzeżenia „słaby sygnał"
- [ ] **Telefon na blacie w domu nie nalicza marszu** — tętno, woda i kalorie
      stoją (poprawka: bramka rośnie razem z niepewnością odczytu)
- [ ] Znacznik gracza zostaje na środku przy zoomie i szczypaniu
- [ ] Najszerszy zoom (3 km) nie jest za szeroki do gry
- [ ] Zużycie baterii: ~1%/h w tle, ~4% na 30 min aktywności

### 2.2. Etap 4 — loot i przeszukanie

- [ ] W promieniu 600 m jest 5 miejsc, w 2 km nie więcej niż 15
- [ ] Dłuższe przeszukanie (90 s, 180 s) daje wyraźnie więcej niż 30 s
- [ ] Budżet miejsca działa: 3 × pobieżne albo 2 × dokładne albo 1 × gruntowne
- [ ] Otwarte od startu miejsca zdarzają się — ale nie wszystkie
- [ ] Skrzynki odnawiają się po 4–8 h
- [ ] Kliknięcie w znacznik pokazuje szczegóły z dowolnej odległości
- [ ] Rzeczy na ziemi grupują się w jedną kropkę z liczbą
- [ ] **Znaczniki są widoczne od razu po starcie gry**, bez restartu

### 2.3. Etap 5 — walka

- [ ] **Przeciwnicy krążą po swoim terenie, gdy cię nie widzą** (poprawka:
      spawn tłowy ma własny dom, nie pozycję gracza)
- [ ] Stożki kierunku i znaki `?` / `!` siedzą na kropkach
- [ ] Dotknięcie przeciwnika otwiera panel także bez broni w ręku
- [ ] Dotknięcie pustej mapy zwalnia cel
- [ ] „Celowanie…" przechodzi w „Namierzony" po ~2 s (4 s przy wysokim tętnie)
- [ ] Grupa 4 Szwędaczy kosztuje nowicjusza **~30 naboi** (§10.3.3)
- [ ] Zwarcie: dwóch przeciwników przy mnożniku 1,3 boli wyraźnie
- [ ] Przeładowanie przerywane przy zbliżeniu <5 m
- [ ] Fala hałasu po strzale jest widoczna i odpowiada promieniowi
- [ ] Ciało zostawia czaszkę na mapie, a łup dopiero po przeszukaniu z bliska
- [ ] **Czaszka pojawia się także, gdy wróg wykrwawi się w biegu**, nie tylko pod celownikiem
- [ ] Ikony przeciwników nie znikają przy chwilowym braku pozycji
- [ ] Panel walki pokazuje nazwę broni w rękach, nie stan wroga
- [ ] Log trafień nazywa miejsce (głowa — egzekucja, tors, ręce, nogi)
- [ ] Ranny przeciwnik wykrwawia się w biegu — pasek krwi na panelu spada
- [ ] Paski jedzenia/picia są na górze i nie chowają się pod panelem walki
- [ ] Ikony szukania i podnoszenia są nad panelem zaznaczonego wroga
- [ ] **700 m hałasu karabinu w gęstej zabudowie — czy nie za karzące?**
      (§5.6.5 sam oznacza to jako do rozstrzygnięcia w terenie)

### 2.4. Ekwipunek i przedmioty

- [ ] Broń da się założyć w slot W RĘKU i wtedy „Ognia" jest aktywne
- [ ] Dodatki: montaż i zdejmowanie **na broni trzymanej w ręku**, nie tylko w plecaku
- [ ] Odmowa montażu mówi, która reguła zabroniła (brak slotu, nie pasuje, już jest)
- [ ] Wolne sloty widoczne w szczegółach i maleją po montażu
- [ ] Wiersz broni w ekwipunku pokazuje dodatki i to, co dały (−MOA, +szt.)
- [ ] Porównanie wyłącznie z tym, co na ciele — nigdy dwa z plecaka
- [ ] Porcje: przerwane picie zostawia połowę butelki
- [ ] Dwa egzemplarze tego samego przedmiotu nie mylą się przy wyrzucaniu
- [ ] Zamiana plecaka na mniejszy nie niszczy starego

### 2.5. Schron (etap 8)

- [ ] Schron staje tam, gdzie stoisz, i po ~2 h (z młotkiem) zaczyna działać
- [ ] W strefie 50 m przeciwnicy zatrzymują się na granicy i nie wchodzą
- [ ] Ze strefy nie da się strzelać — „Ognia" jest wyszarzone z powodem
- [ ] **Noc w schronie spłaca dług senny bez klikania czegokolwiek** (§2.5.1)
- [ ] Moduł buduje się przy zamkniętej aplikacji i jest gotowy po powrocie
- [ ] Obóz bliżej niż 800 m od schronu jest odmówiony z podaniem powodu
- [ ] Znacznik schronu (niebieski) siedzi na właściwym miejscu
- [ ] **Praca stoi, gdy odejdziesz** — pasek nie rusza poza strefą
- [ ] Rozbudowa modułu jest odmówiona spoza schronu, z podaniem powodu
- [ ] **Licznik budowy rusza od razu** po jej rozpoczęciu, bez wychodzenia z ekranu
- [ ] Pasek budowy jest pod paskiem statystyk, gdy stoisz na placu
- [ ] **Schron postawiony wieczorem jest gotowy rano** — przy zamkniętej aplikacji
- [ ] Postęp budowy przeżywa ubicie procesu (traci najwyżej 15 s)
- [ ] Budowa da się przerwać, a okno mówi wprost, że nie da się tego cofnąć
- [ ] Licznik budowy tyka co sekundę, nie skacze co 15 s
- [ ] **Budowa rusza po wejściu do gry w budynku**, bez czekania na GPS
- [ ] 10 minut bezczynności w schronie przechodzi w sen (także w dzień)

### 2.6. Śmierć (§9)

- [ ] Utrata przytomności zasłania mapę — żadna akcja nie działa
- [ ] Godzina leci przy zamkniętej aplikacji
- [ ] Po przebudzeniu: 25% krwi, 15% wody i kalorii, broń z rąk przepadła
- [ ] Skrytki leżą tam, gdzie padłeś, 30–100 m od miejsca upadku
- [ ] Przez 10 minut po przebudzeniu nikt nie atakuje i Ty też nie możesz
- [ ] Sen i brak GPS nie mogą zabić (§9.1)

### 2.7. Interfejs

- [ ] Komunikaty pod paskami HUD nie zasłaniają menu
- [ ] Pasek trwającej czynności jest na górze, pod udźwigiem — także na mapie
- [ ] Ugryzienie zaczyna krwawienie, bandaż je zatrzymuje
- [ ] Po opatrzeniu krew wraca (najedzony i napojony), ~60 ml/h
- [ ] Krwawienie przeżywa wygaszenie ekranu
- [ ] Pasek snu jest pod wodą i kaloriami i spada w ciągu dnia
- [ ] Dotknięcie statusu otwiera wyjaśnienie
- [ ] Ikony akcji pojawiają się tylko w zasięgu
- [ ] Czytelność w słońcu: ikony 22 px, liczby na stosach

---

## 3. Znane długi

Rzeczy świadomie odłożone, z powodem i miejscem, w którym wrócą.

| Co | Dlaczego odłożone | Wraca w |
| :---- | :---- | :---- |
| Stan magazynka nie jest zapisywany | karabin przeładowujący się przy zamkniętej aplikacji to drobne kłamstwo; uczciwa naprawa to zmiana schematu razem z magazynem schronu | etap 8 |
| Pancerz per lokalizacja | lokalizacja trafienia losowana po obu stronach, ale pancerz nadal liczy się jednym progiem torsa | etap 5+ |
| Ciała nie są zapisywane | jak cała sesja walki (§6.4 odtwarza populację przy każdym uruchomieniu); ciało żyje 6 h w obrębie sesji | razem z zapisem sesji walki |
| Światło broni nic nie oświetla | §6.2 daje przeciwnikom promień wykrycia bez kierunku; latarka wymaga modelu widzenia | etap 7 |
| Budynki nie blokują ruchu przeciwników | warstwa budynków w paczkach nie niesie typu; woda i strefy §3.5 już blokują | po przebudowie paczek |
| Zawartość magazynu schronu | pojemność (25 kg + moduł, 3 l/kg) jest policzona, ale nie ma gdzie odłożyć rzeczy — to własna tabela i własny ekran | etap 8 (8.5) |
| Brak powiadomienia po ukończeniu budowy | §8.3 prosi o powiadomienie; kanał powiadomień to osobna praca razem z §16.3 | etap 9 |
| Konflikt §8.3 vs §18.3 | §8.3: 3 h gołymi rękami, z narzędziami −35%. §18.3: bez narzędzi ×2,5. Wdrożono §8.3 — do rozstrzygnięcia | do decyzji |
| Skrytki §9.2 znikają po 24 h, nie po 48 | leżą jako zwykłe rzeczy na ziemi (§4.8), a te mają dobę | razem z §4.8 |
| Okno łaski nie sprawdza, czy w ogóle ktoś jest w pobliżu | §9.2 chce warunkowego okna (przeciwnicy w 300 m); dziś zawsze 10 minut | etap 8 |
| Regeneracja krwi nie jest liniowa w czasie | tempo zależy od stanu żołądka na początku kroku, jak wchłanianie; luki >1 h idą przez `advanceInChunks`, więc rozjazd to najwyżej godzina | świadome |
| Pomiar dobowego czasu gry nie jest zapisywany | model tempa gotowy, zapis to zmiana schematu razem ze składem ognisk | etap 6 |
| `{street}` w notatkach | paczki PMTiles bez warstwy `transportation_name` | przebudowa 17 paczek |
| Dźwięki | ~55 plików, licencje od pierwszego pliku | etap 7 |

---

## 4. Zablokowane na użytkowniku

- [ ] GitHub Pages dla `ARLS-ZA-Game` (Settings → Pages → `main`, `/`)
- [ ] Pakiet miejski Poznania na Pages
- [ ] Wideo uzasadniające lokalizację w tle dla Google Play

---

## Jak odświeżyć tę listę

```
flutter analyze
flutter test
dart run tool/build_item_pages.dart   # katalog przedmiotów na stronie
```

Liczby w części 1 pochodzą z `flutter test test/<obszar>`. Część 2 zmienia się
tylko po spacerze — i to jest jej sens.
