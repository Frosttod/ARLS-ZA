/// Settings the player chooses about the app rather than the character (§12).
///
/// Two of them so far, and both have to be settled before anything else
/// happens:
///
/// * **Language.** §3.5's briefing is about traffic and strangers, and a player
///   who cannot read it has not been briefed. So the language is asked first,
///   before the rules, and before a character exists.
/// * **Theme.** The game is designed for a dark screen at night, but it is also
///   played in daylight, where a black map in bright sun is unreadable (§12).
///
/// Stored in the settings table, which survives a reinstall of nothing and an
/// update of everything: it lives in the same database as the save.
library;

import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';

import 'fonts.dart';

import '../data/db/database.dart';

const String kLocaleSettingKey = 'app.locale';
const String kThemeSettingKey = 'app.theme';

/// Languages the game is written in (§1.1). Not a list of locales Flutter
/// supports — a list of languages somebody has actually translated.
const List<Locale> kGameLocales = [Locale('pl'), Locale('en')];

/// Where the two settings are kept.
///
/// An interface rather than the database directly, so a widget test can drive
/// the screen without one. That is not only tidiness: a real write inside a
/// pump loop never completes under the test binding's clock, and the test hangs
/// rather than failing — which is a much worse way to learn about a mistake.
abstract class SettingsStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
}

/// The real one, over the save database.
class DatabaseSettingsStore implements SettingsStore {
  const DatabaseSettingsStore(this.db);

  final SaveDatabase db;

  @override
  Future<String?> read(String key) => db.readSetting(key);

  @override
  Future<void> write(String key, String value) => db.writeSetting(key, value);
}

/// Keeps settings in memory. For tests, and for a screen shown before the save
/// layer is open.
class MemorySettingsStore implements SettingsStore {
  MemorySettingsStore([Map<String, String>? initial]) : _values = {...?initial};

  final Map<String, String> _values;

  @override
  Future<String?> read(String key) async => _values[key];

  @override
  Future<void> write(String key, String value) async => _values[key] = value;
}

/// §12, §17.2: which palette the game shows, and what decides it.
///
/// ⚠️ [daylight] is the one that is not a preference. The other three answer
/// "what do I like"; this one answers "what is it like outside", from the
/// player's own position — light between dawn and dusk, dark between dusk and
/// dawn. It is the default because this game is played by walking around, and
/// a black map under a June noon is not legible at arm's length (§12) while a
/// white one at midnight ruins the night vision the player is using to watch
/// where their feet go.
/// §12, §17.2: how dark it has to be before the map turns dark.
///
/// ⚠️ Half way through civil twilight — the sun three degrees under — rather
/// than at the first hint of it. Dusk takes a good half hour at this latitude,
/// and a palette that flipped at the first degree would turn the map black
/// while the street outside was still perfectly bright.
const double kDarkPaletteAt = 0.5;

enum ThemeChoice {
  daylight,
  dark,
  light,
  system;

  static ThemeChoice fromWire(String? name) {
    for (final choice in values) {
      if (choice.name == name) return choice;
    }
    // ⚠️ Not `dark`. An unknown value is a downgrade or a hand-edited row, and
    // the honest answer for both is the default the game ships with.
    return ThemeChoice.daylight;
  }
}

/// Reads and writes the two settings, and tells the app when they change.
class AppSettings extends ChangeNotifier {
  AppSettings(this._store);

  final SettingsStore _store;

  Locale? _locale;
  ThemeChoice _theme = ThemeChoice.daylight;

  /// §17.2: whether it is dark where the player is standing.
  ///
  /// ⚠️ Told, never worked out here. The sun's altitude needs a position and a
  /// clock, and this class has neither — it holds settings. The game loop
  /// already computes it for §10.2.2 and §17.4 and hands the same figure over,
  /// so the map and the search radius can never disagree about whether it is
  /// night.
  bool _darkOutside = true;

  /// Null until the player has chosen. The app then follows the system, and
  /// the first-run screen is shown.
  Locale? get locale => _locale;

  ThemeChoice get theme => _theme;

  /// §17.2, §12: czy *w tej chwili* wychodzi ciemny motyw.
  ///
  /// ⚠️ Do pokazania w ustawieniach. „Dzień i noc" rozstrzyga się z pozycji i
  /// zegara, więc ekran, który mówi tylko którą opcję wybrano, nie odpowiada
  /// na jedyne pytanie, jakie ktoś ma przy tej opcji: *czy ona w ogóle działa*.
  /// Zgłoszone z terenu jako „mamy dzień, a styl ciemny".
  bool get resolvesDark =>
      themeMode == ThemeMode.dark ||
      (themeMode == ThemeMode.system &&
          PlatformDispatcher.instance.platformBrightness == Brightness.dark);

  ThemeMode get themeMode => switch (_theme) {
    ThemeChoice.daylight => _darkOutside ? ThemeMode.dark : ThemeMode.light,
    ThemeChoice.dark => ThemeMode.dark,
    ThemeChoice.light => ThemeMode.light,
    ThemeChoice.system => ThemeMode.system,
  };

  /// Whether the language has ever been chosen. A first run stops here.
  bool get languageChosen => _locale != null;

  Future<void> load() async {
    final language = await _store.read(kLocaleSettingKey);
    final theme = await _store.read(kThemeSettingKey);

    _locale = _localeFrom(language);
    _theme = ThemeChoice.fromWire(theme);
    notifyListeners();
  }

  /// §17.2: the game reporting the sky. Silent unless it actually changed and
  /// unless anybody is looking at it — a notification per tick would rebuild
  /// the whole application once a second.
  void setDarkOutside(bool dark) {
    if (dark == _darkOutside) return;

    _darkOutside = dark;
    if (_theme == ThemeChoice.daylight) notifyListeners();
  }

  Future<void> setLocale(Locale value) async {
    _locale = value;
    notifyListeners();
    await _store.write(kLocaleSettingKey, value.languageCode);
  }

  Future<void> setTheme(ThemeChoice value) async {
    _theme = value;
    notifyListeners();
    await _store.write(kThemeSettingKey, value.name);
  }
}

/// Turns a stored language code into a locale the game actually has.
///
/// An unknown code — a downgrade, a hand-edited row — reads as "never chosen"
/// rather than as English, because guessing wrong here means a briefing in a
/// language the player does not read.
Locale? _localeFrom(String? code) {
  if (code == null) return null;
  for (final locale in kGameLocales) {
    if (locale.languageCode == code) return locale;
  }
  return null;
}

/// The two palettes.
///
/// Dark is the one the game is designed around. Light exists because the same
/// screen is read at noon in June, when a black map under a bright sky is not
/// legible at arm's length (§12).
ThemeData buildTheme(Brightness brightness) => ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFFA82D17),
    brightness: brightness,
  ),
  scaffoldBackgroundColor: brightness == Brightness.dark
      ? Colors.black
      : const Color(0xFFF6F4F2),

  // §12: one face for everything that is words.
  //
  // Set on the theme rather than on each style, because nearly every
  // [TextStyle] in this app gives a size and a colour and nothing else — so
  // they inherit, and the face can be changed in one place instead of four
  // hundred.
  fontFamily: kUiFont,
  useMaterial3: true,
);
