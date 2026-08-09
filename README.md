# ARLS-ZA — Almost Real Life Survival: Zombie Apocalypse

Hiper-realistyczny survival GPS na Androida. Ciało gracza jest kontrolerem: objętość krwi liczona wzorem Nadlera, wydatek energetyczny z MET wyprowadzonego z prędkości GPS, rozrzut broni w minutach kątowych. Nie ma pasków zasobów — są konsekwencje fizjologiczne realnego wysiłku.

**Strona projektu:** [English](https://frosttod.github.io/ARLS-ZA-Game/) · [polski](https://frosttod.github.io/ARLS-ZA-Game/pl/) — opis wszystkich systemów gry. Źródło strony: [Frosttod/ARLS-ZA-Game](https://github.com/Frosttod/ARLS-ZA-Game)

| | |
| :---- | :---- |
| Platforma | Android · Flutter |
| Pakiet | `com.raidodevelopment.arlsza` |
| Nazwa w sklepie | ARLS-ZA Game |
| Model sieciowy | offline-first, brak własnych serwerów gry |
| Status | dokumentacja kompletna, implementacja na etapie 0 |

## Dokumentacja

| Plik | Zawartość |
| :---- | :---- |
| [ARLS-ZA_design_doc_v2.md](ARLS-ZA_design_doc_v2.md) | dokument projektowy — wszystkie systemy, wzory, tabele balansu, otwarte decyzje |
| [ROADMAP.md](ROADMAP.md) | dziesięć etapów wdrożenia z kryteriami wyjścia, zakres MVP, rejestr ryzyk |
| [PROCEDURA_RELEASE.md](PROCEDURA_RELEASE.md) | procedura wydania |
| [CHANGELOG.md](CHANGELOG.md) | historia zmian w kodzie |
| `ARLS-ZA_design_doc_v2.original.md` | archiwum: historia wersji dokumentu i odrzucone warianty projektowe |

## Uruchomienie

```bash
flutter pub get
flutter run
```

Wymagany Flutter z Dart SDK w wersji ^3.12.0.

## Strona projektu

Statyczny HTML, dwie wersje językowe (angielska domyślna), bez zależności zewnętrznych i bez procesu budowania. Mieszka w osobnym repozytorium [Frosttod/ARLS-ZA-Game](https://github.com/Frosttod/ARLS-ZA-Game) i jest publikowana przez GitHub Pages.

## Zasady projektowe, których nie otwieramy ponownie

- **Brak zakupów wewnętrznych** — bez Google Play Billing, bez waluty premium, bez skrótów za pieniądze
- **Brak danych zdrowotnych** — żadnej integracji z Health Connect ani czujnikami; parametry ciała nie opuszczają telefonu
- **Brak serwerów gry** — jedynym zewnętrznym API jest Open-Meteo, z cache i łagodną degradacją
- **Awaria techniczna nigdy nie może zabić postaci** w trybie Hardcore

## Bezpieczeństwo gracza

Gra wysyła ludzi na ulicę, często po zmroku. Strefy wykluczone ze spawnu (drogi, tory, wody, tereny prywatne, szpitale, szkoły, cmentarze, miejsca kultu), blokada walki powyżej 15 km/h i jednorazowy ekran akceptacji zasad są wymagane przed pierwszym testem zewnętrznym — nie są opcjonalne. Szczegóły w §3.5 dokumentu projektowego.

---

Raido Development
