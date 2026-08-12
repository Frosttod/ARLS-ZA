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

import 'package:flutter/material.dart';

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

/// Reads and writes the two settings, and tells the app when they change.
class AppSettings extends ChangeNotifier {
  AppSettings(this._store);

  final SettingsStore _store;

  Locale? _locale;
  ThemeMode _themeMode = ThemeMode.dark;

  /// Null until the player has chosen. The app then follows the system, and
  /// the first-run screen is shown.
  Locale? get locale => _locale;

  ThemeMode get themeMode => _themeMode;

  /// Whether the language has ever been chosen. A first run stops here.
  bool get languageChosen => _locale != null;

  Future<void> load() async {
    final language = await _store.read(kLocaleSettingKey);
    final theme = await _store.read(kThemeSettingKey);

    _locale = _localeFrom(language);
    _themeMode = _themeFrom(theme);
    notifyListeners();
  }

  Future<void> setLocale(Locale value) async {
    _locale = value;
    notifyListeners();
    await _store.write(kLocaleSettingKey, value.languageCode);
  }

  Future<void> setThemeMode(ThemeMode value) async {
    _themeMode = value;
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

ThemeMode _themeFrom(String? name) => switch (name) {
  'light' => ThemeMode.light,
  'system' => ThemeMode.system,
  // Dark is the default and the fallback: the game is designed to be read at
  // night, and §3.6's map is drawn for it.
  _ => ThemeMode.dark,
};

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
  useMaterial3: true,
);
