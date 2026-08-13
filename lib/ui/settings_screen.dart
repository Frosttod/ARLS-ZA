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
import '../location/location_access.dart';
import '../location/system_permissions.dart';
import 'app_settings.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    required this.settings,
    required this.onOpenMaps,
    this.permissions,
    this.onFixLocation,
    this.onFixBattery,
    this.simulatorEnabled = false,
    this.onSimulatorChanged,
    super.key,
  });

  final AppSettings settings;
  final VoidCallback onOpenMaps;

  /// What the system currently allows (§3.3, §16.1). Null while it is being
  /// read — the section is then simply absent rather than showing a guess.
  final SystemPermissions? permissions;

  final VoidCallback? onFixLocation;
  final VoidCallback? onFixBattery;

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

          if (permissions != null) ...[
            const Divider(),
            _Heading(l10n.permTitle),
            _PermissionTile(
              title: l10n.permLocation,
              status: _locationStatus(l10n, permissions!.location),
              good: permissions!.location == LocationAccess.granted,
              onFix: onFixLocation,
            ),
            _PermissionTile(
              title: l10n.permBattery,
              status: switch (permissions!.batteryOptimised) {
                true => l10n.permBatteryOn,
                false => l10n.permBatteryOff,
                null => l10n.permBatteryUnknown,
              },
              good: permissions!.batteryOptimised == false,
              onFix: permissions!.batteryOptimised == true
                  ? onFixBattery
                  : null,
            ),
          ],

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

  static String _locationStatus(L10n l10n, LocationAccess access) =>
      switch (access) {
        LocationAccess.granted => l10n.permLocationGranted,
        LocationAccess.foregroundOnly => l10n.permLocationForeground,
        LocationAccess.serviceDisabled => l10n.permLocationOff,
        LocationAccess.denied ||
        LocationAccess.deniedForever => l10n.permLocationDenied,
      };

  /// Each language names itself; translating a language list defeats it.
  static String _languageName(Locale locale) => switch (locale.languageCode) {
    'pl' => 'Polski',
    'en' => 'English',
    _ => locale.languageCode.toUpperCase(),
  };
}

/// One system switch, its state in words, and a way to change it.
///
/// The state is a sentence rather than a tick: "on" tells a player nothing
/// about whether that is the state they want, and for battery optimisation the
/// wanted state is off.
class _PermissionTile extends StatelessWidget {
  const _PermissionTile({
    required this.title,
    required this.status,
    required this.good,
    this.onFix,
  });

  final String title;
  final String status;
  final bool good;
  final VoidCallback? onFix;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      leading: Icon(
        good ? Icons.check_circle_outline : Icons.error_outline,
        color: good ? theme.colorScheme.primary : theme.colorScheme.error,
      ),
      title: Text(title),
      subtitle: Text(status, style: theme.textTheme.bodySmall),
      trailing: onFix == null
          ? null
          : TextButton(onPressed: onFix, child: Text(L10n.of(context).permFix)),
    );
  }
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
