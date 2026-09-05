# Play Console — co wpisać, i skąd to wiadomo (§16.7, §16.1)

Etap 9 dzieli się na dwie części. Kod jest w repozytorium; **formularze wypełnia
człowiek zalogowany do Play Console** i tego nie da się zrobić stąd. Ten plik
jest odpowiedzią na każde pole tych formularzy, wyprowadzoną z tego, co
aplikacja faktycznie robi — nie z pamięci.

⚠️ **Jeśli aplikacja się zmieni, ten plik jest nieaktualny.** Źródłem prawdy są:
`android/app/src/main/AndroidManifest.xml` (uprawnienia), `pubspec.yaml`
(zależności, czyli co w ogóle mogłoby wysłać cokolwiek) oraz
`tool/build_privacy_pages.dart` (polityka prywatności, generowana na stronę).

---

## Polityka prywatności (9.8) — URL

| Co | Gdzie |
| :---- | :---- |
| Wersja EN | `https://frosttod.github.io/ARLS-ZA-Game/privacy.html` |
| Wersja PL | `https://frosttod.github.io/ARLS-ZA-Game/pl/privacy.html` |
| Źródło | `tool/build_privacy_pages.dart` w tym repozytorium |

⚠️ **Adres zacznie działać dopiero po włączeniu GitHub Pages** dla repozytorium
`ARLS-ZA-Game` (Settings → Pages → branch `main`, folder `/ (root)`). Do tego
czasu Play Console odrzuci formularz, bo sprawdza, czy URL odpowiada.

⚠️ **Kontakt.** Polityka odsyła do zgłoszeń w repozytorium. Play Console wymaga
osobno **adresu e-mail** na stronie aplikacji w sklepie — to jest decyzja, czyj
adres tam trafia, i dlatego nie ma go w kodzie.

---

## Data Safety (9.8) — odpowiedzi

Formularz pyta o *zbieranie* (wysyłanie poza urządzenie) i o *udostępnianie*.
Aplikacja nie robi ani jednego, ani drugiego.

| Pytanie | Odpowiedź | Dlaczego tak, a nie „na wszelki wypadek" |
| :---- | :---- | :---- |
| Czy aplikacja zbiera lub udostępnia dane użytkownika? | **Nie** | Brak kont, brak serwera, brak SDK analitycznego i reklamowego, brak raportowania awarii. Nie ma kodu, który mógłby wysłać dane |
| Lokalizacja — zbierana? | **Nie** | Czytana i przechowywana wyłącznie na urządzeniu (`allowBackup=false`), nigdy nie opuszcza telefonu |
| Dane osobowe (wzrost, waga, wiek, płeć) — zbierane? | **Nie** | Ta sama zasada: baza w prywatnej pamięci aplikacji |
| Czy dane są szyfrowane w tranzycie? | **Nie dotyczy** | Nie ma tranzytu danych użytkownika |
| Czy użytkownik może zażądać usunięcia danych? | **Tak — odinstalowanie** | Nie ma kopii poza urządzeniem, więc nie ma czego kasować zdalnie |

**Jedyne żądanie sieciowe** aplikacji to pobranie pakietu mapy offline
(`http` w `pubspec.yaml`, §16.6). Serwer wydający plik widzi adres IP
urządzenia — jak przy każdym pobraniu pliku — i nic poza tym. To nie jest
zbieranie danych użytkownika w rozumieniu formularza, ale **jest** opisane w
polityce prywatności, żeby nie było niespodzianki.

---

## Uzasadnienie `ACCESS_BACKGROUND_LOCATION` (9.9)

Play wymaga osobnej deklaracji i **wideo demonstracyjnego**. Tekst poniżej jest
gotowy do wklejenia; wideo trzeba nagrać (ekran telefonu: start gry, wygaszenie
ekranu, spacer, powrót do aplikacji z doliczonym dystansem).

> ARLS-ZA to gra survivalowa, w której postacią porusza realny ruch gracza
> mierzony GPS-em. Dostęp do lokalizacji w tle jest potrzebny, żeby gra liczyła
> przebyty dystans przy wygaszonym ekranie — bez tego postać przestawałaby się
> poruszać w chwili schowania telefonu do kieszeni, co jest normalnym sposobem
> grania w grę wymagającą chodzenia. Lokalizacja jest używana i przechowywana
> wyłącznie na urządzeniu, nie jest przesyłana na żaden serwer ani udostępniana
> stronom trzecim. Gra działa w pełni po odmowie tego uprawnienia — dolicza
> spacer przy następnym otwarciu aplikacji.

⚠️ **Ostatnie zdanie musi zostać prawdą.** Tryb tylko-pierwszoplanowy jest
pełnoprawnym wariantem gry (§16.1) i jest kryterium wyjścia etapu 9.

---

## IARC (klasyfikacja wiekowa)

Kwestionariusz wypełnia się w Play Console. Fakty do zaznaczenia:

- przemoc wobec **fantastycznych** postaci (zombie), bez krwi w warstwie
  graficznej — gra pokazuje liczby, nie obrazy ran
- brak treści seksualnych, hazardu, wulgaryzmów
- brak interakcji między użytkownikami (gra jest w pełni offline, bez czatu)
- brak zakupów w aplikacji
- **gra zachęca do aktywności w prawdziwym świecie** — to jest pole, które
  trzeba zaznaczyć uczciwie, bo z niego wynika ostrzeżenie o bezpieczeństwie

---

## Czego tu jeszcze nie ma

| Zadanie | Stan |
| :---- | :---- |
| 9.4 — skryptowana pierwsza walka (§15.6) | niezrobione, siedem kroków podpowiedzi plus przeciwnik, który nie może zabić |
| 9.11 — ikona, zrzuty, opis ASO | ikona jest (`assets/icon.png`), reszta to materiały do sklepu |
