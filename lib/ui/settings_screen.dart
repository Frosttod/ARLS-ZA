/// USTAWIENIA, the fourth entry of §3.6's bottom menu.
///
/// Everything here is a choice about the app rather than about the character:
/// the language the rules were read in, whether the screen is legible in
/// daylight, and which map is on the device. The developer switch is at the
/// bottom and only exists in a build that carries developer mode at all —
/// there is nothing to toggle in a release.
library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../devtools/dev_mode.dart';
import '../l10n/app_localizations.dart';
import 'app_settings.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    required this.settings,
    required this.onOpenMaps,
    this.simulatorEnabled = false,
    this.onSimulatorChanged,
    super.key,
  });

  final AppSettings settings;
  final VoidCallback onOpenMaps;

  /// Only meaningful in a developer build (§11.2).
  final bool simulatorEnabled;
  final void Function(bool)? onSimulatorChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        children: [
          _Heading(l10n.settingsLanguage),
          RadioGroup<String>(
            groupValue: settings.locale?.languageCode,
            onChanged: (code) {
              if (code == null) return;
              unawaited(settings.setLocale(Locale(code)));
            },
            child: Column(
              children: [
                for (final locale in kGameLocales)
                  RadioListTile<String>(
                    value: locale.languageCode,
                    title: Text(_languageName(locale)),
                  ),
              ],
            ),
          ),

          const Divider(),
          _Heading(l10n.themeTitle),
          RadioGroup<ThemeMode>(
            groupValue: settings.themeMode,
            onChanged: (mode) {
              if (mode == null) return;
              unawaited(settings.setThemeMode(mode));
            },
            child: Column(
              children: [
                RadioListTile<ThemeMode>(
                  value: ThemeMode.dark,
                  title: Text(l10n.themeDark),
                ),
                RadioListTile<ThemeMode>(
                  value: ThemeMode.light,
                  title: Text(l10n.themeLight),
                ),
                RadioListTile<ThemeMode>(
                  value: ThemeMode.system,
                  title: Text(l10n.themeSystem),
                ),
              ],
            ),
          ),

          const Divider(),
          ListTile(
            title: Text(l10n.settingsMaps),
            trailing: const Icon(Icons.chevron_right),
            onTap: onOpenMaps,
          ),

          // §11.2: the simulator is opted into, and only where one exists.
          if (kDevTools) ...[
            const Divider(),
            SwitchListTile(
              value: simulatorEnabled,
              onChanged: onSimulatorChanged,
              title: Text(l10n.settingsSimulator),
              subtitle: Text(
                l10n.settingsSimulatorBody,
                style: theme.textTheme.bodySmall,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Each language names itself; translating a language list defeats it.
  static String _languageName(Locale locale) => switch (locale.languageCode) {
    'pl' => 'Polski',
    'en' => 'English',
    _ => locale.languageCode.toUpperCase(),
  };
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
    child: Text(
      text,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: Theme.of(context).colorScheme.primary,
      ),
    ),
  );
}
