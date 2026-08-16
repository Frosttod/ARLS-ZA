# ARLS-ZA — lista kontrolna systemów

Stan na dzień **2026-08-16**, commit `d3ababd`. Wygenerowana po przejściu
pełnego zestawu testów: **1263 testy, `flutter analyze` czysty, schemat bazy
v12**.

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
| `combat` | 214 | tabela kalibracyjna §5.1.2 wiersz po wierszu, obrażenia §5.1.5, budżet sprintu, maszyna stanów, hałas, spawn, magazynek, dodatki |
| `ui` | 237 | HUD, ekwipunek, panele, arkusze, geometria dotknięć i pierścieni |
| `sim` | 175 | tick, metabolizm, tętno, wchłanianie, sen, nawyk gry |
| `loot` | 130 | tabele, spawner, przeszukanie, rzeczy na ziemi, przeszkody |
| `map` | 88 | PMTiles, MVT, geometria, namiary, pakiety regionów |
| `inventory` | 80 | dwa limity §18.1a, sloty, porcje, dodatki, trwałość |
| `items` | 71 | katalog jako dane: bilans, nazwy, sloty, użycia |
| `location` | 53 | bramka dokładności, filtr Kalmana, martwa strefa, anty-cheat |
| `db` | 50 | migracje v1→v12, integralność, warstwa gorąca i ciepła |
| `devtools` | 44 | symulator GPS, nakładka, zegar |
| `game` | 43 | pętla gry, nadrabianie przerw, próbkowanie |
| `safety` | 34 | strefy wykluczone §3.5 |
| `core` | 30 | deterministyczny RNG, zegar |
| `notes` | 14 | notatki §19.1, podstawianie nazw miejsc |

**Razem 1263.**

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
- [ ] Ciało zostawia coś do podniesienia
- [ ] **700 m hałasu karabinu w gęstej zabudowie — czy nie za karzące?**
      (§5.6.5 sam oznacza to jako do rozstrzygnięcia w terenie)

### 2.4. Ekwipunek i przedmioty

- [ ] Broń da się założyć w slot W RĘKU i wtedy „Ognia" jest aktywne
- [ ] Dodatki: montaż, zdejmowanie, wolne sloty widoczne w szczegółach
- [ ] Porcje: przerwane picie zostawia połowę butelki
- [ ] Dwa egzemplarze tego samego przedmiotu nie mylą się przy wyrzucaniu
- [ ] Zamiana plecaka na mniejszy nie niszczy starego

### 2.5. Interfejs

- [ ] Komunikaty pod paskami HUD nie zasłaniają menu
- [ ] Dotknięcie statusu otwiera wyjaśnienie
- [ ] Ikony akcji pojawiają się tylko w zasięgu
- [ ] Czytelność w słońcu: ikony 22 px, liczby na stosach

---

## 3. Znane długi

Rzeczy świadomie odłożone, z powodem i miejscem, w którym wrócą.

| Co | Dlaczego odłożone | Wraca w |
| :---- | :---- | :---- |
| Stan magazynka nie jest zapisywany | karabin przeładowujący się przy zamkniętej aplikacji to drobne kłamstwo; uczciwa naprawa to zmiana schematu razem z magazynem schronu | etap 8 |
| Lokalizacja trafienia | strzał zawsze liczy tors; uczciwie to losowanie lokalizacji po obu stronach plus pancerz per lokalizacja | etap 5+ |
| Światło broni nic nie oświetla | §6.2 daje przeciwnikom promień wykrycia bez kierunku; latarka wymaga modelu widzenia | etap 7 |
| Budynki nie blokują ruchu przeciwników | warstwa budynków w paczkach nie niesie typu; woda i strefy §3.5 już blokują | po przebudowie paczek |
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
