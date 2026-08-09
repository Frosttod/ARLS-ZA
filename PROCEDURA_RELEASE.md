# Procedura przygotowania aplikacji do publikacji w Google Play

Wykonaj poniższe kroki dla każdej nowej aplikacji tworzonej na bazie tego template'u.  
Zamień `APPNAME` na faktyczną nazwę aplikacji (małe litery, bez spacji, np. `myapp`).

---

## 1. Zmiana nazwy pakietu (Application ID)

Format docelowy: `com.raidodevelopment.APPNAME`

### 1.1 `android/app/build.gradle.kts`

Zmień dwie wartości:

```kotlin
// PRZED:
namespace = "com.example.flutter_template"
applicationId = "com.example.flutter_template"

// PO:
namespace = "com.raidodevelopment.APPNAME"
applicationId = "com.raidodevelopment.APPNAME"
```

### 1.2 Przenieś plik `MainActivity.kt`

Stara ścieżka:
```
android/app/src/main/kotlin/com/example/flutter_template/MainActivity.kt
```

Nowa ścieżka (utwórz foldery):
```
android/app/src/main/kotlin/com/raidodevelopment/APPNAME/MainActivity.kt
```

Na początku pliku zaktualizuj deklarację pakietu:

```kotlin
// PRZED:
package com.example.flutter_template

// PO:
package com.raidodevelopment.APPNAME
```

Stary folder `com/example/flutter_template/` możesz usunąć.

### 1.3 `pubspec.yaml`

```yaml
# PRZED:
name: flutter_template

# PO:
name: APPNAME
```

---

## 2. Zmiana nazwy wyświetlanej aplikacji

W pliku `android/app/src/main/AndroidManifest.xml` zmień atrybut `android:label`:

```xml
<!-- PRZED: -->
android:label="flutter_template"

<!-- PO: -->
android:label="Twoja Nazwa Aplikacji"
```

---

## 3. Opis dewelopera — sekcja "Prywatność i Dane" (obowiązkowa)

Każda aplikacja RAIDO Development musi zawierać tę sekcję na ekranie Ustawień.  
Jedynym elementem do dostosowania jest opis w `Dane tylko na urządzeniu` — opisz konkretne dane tej aplikacji.

### Wygląd docelowy

```
PRYWATNOŚĆ I DANE
─────────────────────────────────────────
🛡 RAIDO Development          [Privacy by Design]
   Aplikacja projektowana jest z prywatnością
   jako fundamentem — nie jako dodatkiem.
─────────────────────────────────────────
📱 Dane tylko na urządzeniu
   TWOJE_DANE przechowywane są wyłącznie
   lokalnie na Twoim telefonie. Żadne dane
   nie opuszczają urządzenia.
─────────────────────────────────────────
⊘  Zero zbierania danych
   Nie zbieramy, nie analizujemy ani nie
   przesyłamy żadnych danych użytkowników.
   Brak analityki, brak reklam, brak śledzenia.
```

### Kod Flutter — gotowy widget

Wstaw do ekranu Ustawień (`settings_screen.dart` lub odpowiednik):

```dart
Widget _buildPrivacySection() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _SectionHeader('PRYWATNOŚĆ I DANE'),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.shield_outlined, color: Colors.green, size: 20),
                const SizedBox(width: 12),
                const Text(
                  'RAIDO Development',
                  style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.green),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Privacy by Design',
                    style: TextStyle(fontSize: 11, color: Colors.green),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Aplikacja projektowana jest z prywatnością jako fundamentem — nie jako dodatkiem.',
            ),
          ],
        ),
      ),
      const Divider(height: 1),
      ListTile(
        leading: const Icon(Icons.smartphone_outlined, color: Colors.green),
        title: const Text('Dane tylko na urządzeniu', style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: const Text(
          // TODO: Dostosuj — opisz konkretne dane tej aplikacji
          'TWOJE_DANE przechowywane są wyłącznie lokalnie na Twoim telefonie. Żadne dane nie opuszczają urządzenia.',
        ),
      ),
      const Divider(height: 1),
      ListTile(
        leading: const Icon(Icons.block_outlined, color: Colors.green),
        title: const Text('Zero zbierania danych', style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: const Text(
          'Nie zbieramy, nie analizujemy ani nie przesyłamy żadnych danych użytkowników. Brak analityki, brak reklam, brak śledzenia.',
        ),
      ),
    ],
  );
}
```

### Przykłady opisu "Dane tylko na urządzeniu"

| Typ aplikacji | Opis |
|---------------|------|
| Tracker jazdy | `Pojazdy, trasy i statystyki przechowywane są wyłącznie lokalnie na Twoim telefonie. Żadne dane nie opuszczają urządzenia.` |
| Notatnik | `Notatki i pliki przechowywane są wyłącznie lokalnie na Twoim telefonie. Żadne dane nie opuszczają urządzenia.` |
| Dziennik nawyków | `Nawyki, wpisy i statystyki przechowywane są wyłącznie lokalnie na Twoim telefonie. Żadne dane nie opuszczają urządzenia.` |
| Budżet domowy | `Transakcje i budżety przechowywane są wyłącznie lokalnie na Twoim telefonie. Żadne dane nie opuszczają urządzenia.` |

---

## 4. Generowanie klucza podpisywania (Keystore)

> Klucz generujesz **raz na konto Google Play** — jeden klucz podpisuje wszystkie Twoje aplikacje.  
> Zachowaj plik `.jks` i hasła w bezpiecznym miejscu (np. password manager). Bez nich nie możesz aktualizować aplikacji.

### 4.1 Wygeneruj keystore

Uruchom w terminalu (Windows CMD / PowerShell):

```
keytool -genkey -v -keystore android/app-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Zostaniesz poproszony o podanie:
- **storePassword** — hasło do pliku keystore
- **keyPassword** — hasło do klucza (może być takie samo jak storePassword)
- Dane organizacji: imię/nazwisko → `Przemyslaw Rolnik`, organizacja → `RAIDO Development`, miasto → `Poznan`, kraj → `PL`

> `keytool` jest częścią Java JDK. Jeśli komenda nie jest dostępna, użyj pełnej ścieżki:
> `"C:\Program Files\Java\jdk-XX\bin\keytool.exe"`

### 4.2 Utwórz plik `android/key.properties`

Utwórz nowy plik `android/key.properties` (nie commituj go do git!):

```properties
storePassword=TWOJE_HASLO_STORE
keyPassword=TWOJE_HASLO_KLUCZA
keyAlias=upload
storeFile=../app-key.jks
```

### 4.3 Zaktualizuj `android/.gitignore`

Upewnij się, że zawiera:

```
key.properties
**/*.keystore
**/*.jks
```

---

## 5. Konfiguracja podpisywania w Gradle

Zastąp całą zawartość `android/app/build.gradle.kts` poniższą wersją:

```kotlin
import java.util.Properties
import java.io.FileInputStream

val keyPropertiesFile = rootProject.file("key.properties")
val keyProperties = Properties().apply {
    if (keyPropertiesFile.exists()) load(FileInputStream(keyPropertiesFile))
}

plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.raidodevelopment.APPNAME"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    signingConfigs {
        create("release") {
            if (keyPropertiesFile.exists()) {
                keyAlias = keyProperties["keyAlias"] as String
                keyPassword = keyProperties["keyPassword"] as String
                storeFile = file(keyProperties["storeFile"] as String)
                storePassword = keyProperties["storePassword"] as String
            }
        }
    }

    defaultConfig {
        applicationId = "com.raidodevelopment.APPNAME"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = if (keyPropertiesFile.exists())
                signingConfigs.getByName("release")
            else
                signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
```

---

## 6. SHA-256 — kiedy jest potrzebny

SHA-256 z keystore potrzebny jest do integracji z usługami Google:

| Usługa | Gdzie wpisać |
|--------|-------------|
| Google Play Console | Setup → App Signing → App signing key certificate |
| Firebase Authentication | Project Settings → Your apps → SHA certificate fingerprints |
| Google Maps API | Google Cloud Console → ograniczenie klucza API do aplikacji |
| Google Sign-In | Google Cloud Console → OAuth 2.0 credentials |

### Odczyt SHA-256 z keystore

```bash
keytool -list -v -keystore android/app-key.jks -alias upload -storepass TWOJE_HASLO
```

Szukaj linii: `SHA256: XX:XX:XX:...`

### SHA-256 debug keystore (dla testów / Firebase dev)

```bash
# Windows
keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android

# macOS / Linux
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

---

## 7. Budowanie App Bundle do Google Play

### Zwiększ numer wersji przed każdym uploadem

W `pubspec.yaml` — `versionCode` (liczba po `+`) musi rosnąć przy każdym uploadzie:

```yaml
version: 1.0.0+1
#        ^^^^^  ^
#        nazwa  versionCode (musi rosnąć)
```

### Zbuduj App Bundle

```bash
# App Bundle (wymagany przez Google Play):
flutter build appbundle --release

# Alternatywnie APK (do testów poza Play Store):
flutter build apk --release
```

Wynikowe pliki:
- `build/app/outputs/bundle/release/app-release.aab`
- `build/app/outputs/flutter-apk/app-release.apk`

### Weryfikacja podpisania

```bash
# Weryfikacja AAB
keytool -printcert -jarfile build/app/outputs/bundle/release/app-release.aab

# Weryfikacja APK (metoda 1)
apksigner verify --print-certs build/app/outputs/flutter-apk/app-release.apk

# Weryfikacja APK (metoda 2)
keytool -printcert -jarfile build/app/outputs/flutter-apk/app-release.apk
```

---

## 8. Pierwsze przesłanie do Google Play Console

1. Wejdź na [play.google.com/console](https://play.google.com/console)
2. Utwórz aplikację → wpisz `com.raidodevelopment.APPNAME` jako Package name
3. Przejdź do **Production** lub **Internal testing** → **Create new release**
4. Włącz **Google Play App Signing** (zalecane — Google przechowuje klucz produkcyjny, Twój `app-key.jks` służy tylko do weryfikacji tożsamości przy uploadzie)
5. Prześlij `app-release.aab`
6. Po włączeniu App Signing SHA-256 znajdziesz w: Play Console → Setup → App Signing → **App signing key certificate**

---

## 9. Checklist przed pierwszym wgraniem

- [ ] `applicationId` zmieniony na `com.raidodevelopment.APPNAME`
- [ ] `android:label` ustawiony na właściwą nazwę wyświetlaną
- [ ] `MainActivity.kt` przeniesiony do nowego folderu pakietu
- [ ] Sekcja "Prywatność i Dane" dodana do ekranu Ustawień (opis `Dane tylko na urządzeniu` dostosowany do aplikacji)
- [ ] `key.properties` istnieje i wskazuje na właściwy plik `.jks`
- [ ] `key.properties` oraz `*.jks` są w `.gitignore`
- [ ] Plik `app-key.jks` jest zbackupowany poza projektem
- [ ] `versionCode` w `pubspec.yaml` jest poprawny
- [ ] App Bundle zbudowany bez błędów i podpisany właściwym kluczem

---

## Szybka ściągawka — polecenia

| Cel | Polecenie |
|-----|-----------|
| Generuj keystore | `keytool -genkey -v -keystore android/app-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload` |
| SHA-256 z keystore | `keytool -list -v -keystore android/app-key.jks -alias upload` |
| SHA-256 debug | `keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android` |
| Build AAB release | `flutter build appbundle --release` |
| Build APK release | `flutter build apk --release` |
| Build APK debug | `flutter build apk --debug` |
| Weryfikacja APK | `apksigner verify --print-certs app-release.apk` |
| Weryfikacja AAB | `keytool -printcert -jarfile app-release.aab` |

---

## Przykład dla aplikacji "MyApp"

| Pole | Wartość |
|------|---------|
| applicationId | `com.raidodevelopment.myapp` |
| android:label | `MyApp` |
| pubspec name | `myapp` |
| keystore file | `android/app-key.jks` |
| keystore alias | `upload` |
| package Kotlin | `com.raidodevelopment.myapp` |
