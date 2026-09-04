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
import 'survival_rules.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    required this.settings,
    required this.onOpenMaps,
    this.readPermissions,
    this.onFixLocation,
    this.onFixBattery,
    this.simulatorEnabled = false,
    this.onSimulatorChanged,
    super.key,
  });

  final AppSettings settings;
  final VoidCallback onOpenMaps;

  /// Reads what the system currently allows (§3.3, §16.1).
  ///
  /// A function rather than a value, because this screen is a pushed route:
  /// handed a snapshot, it would still be showing the state from the moment it
  /// opened after the player had walked to the system settings, changed
  /// something and come back — which is precisely when they look at it.
  final Future<SystemPermissions> Function()? readPermissions;

  final Future<void> Function()? onFixLocation;
  final Future<void> Function()? onFixBattery;

  /// Only meaningful in a developer build (§11.2).
  final bool simulatorEnabled;
  final void Function(bool)? onSimulatorChanged;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with WidgetsBindingObserver {
  SystemPermissions? _permissions;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_refresh());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Coming back from the system settings is the only moment any of this
  /// changes, and Android tells an app nothing about it.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_refresh());
  }

  Future<void> _refresh() async {
    final read = widget.readPermissions;
    if (read == null) return;

    final permissions = await read();
    if (!mounted) return;
    setState(() => _permissions = permissions);
  }

  Future<void> _fix(Future<void> Function()? action) async {
    if (action == null) return;
    await action();
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final settings = widget.settings;
    final permissions = _permissions;
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
          RadioGroup<ThemeChoice>(
            groupValue: settings.theme,
            onChanged: (choice) {
              if (choice == null) return;
              unawaited(settings.setTheme(choice));
            },
            child: Column(
              children: [
                // §17.2: first and default. The other three are preferences;
                // this one is the sky.
                RadioListTile<ThemeChoice>(
                  value: ThemeChoice.daylight,
                  title: Row(
                    children: [
                      Expanded(child: Text(l10n.themeDaylight)),
                      // §12: co z tego wychodzi *teraz*. Bez tego jedyne
                      // pytanie, jakie ktoś ma przy tej opcji — czy ona w
                      // ogóle działa — nie ma odpowiedzi na ekranie.
                      Text(
                        settings.resolvesDark
                            ? l10n.themeNowDark
                            : l10n.themeNowLight,
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  subtitle: Text(
                    l10n.themeDaylightHint,
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
                RadioListTile<ThemeChoice>(
                  value: ThemeChoice.dark,
                  title: Text(l10n.themeDark),
                ),
                RadioListTile<ThemeChoice>(
                  value: ThemeChoice.light,
                  title: Text(l10n.themeLight),
                ),
                RadioListTile<ThemeChoice>(
                  value: ThemeChoice.system,
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
              status: _locationStatus(l10n, permissions.location),
              good: permissions.location == LocationAccess.granted,
              // Nothing to fix when it is already full. A button offering to
              // repair something that works invites a player to go and break
              // it.
              onFix: permissions.location == LocationAccess.granted
                  ? null
                  : () => unawaited(_fix(widget.onFixLocation)),
            ),
            _PermissionTile(
              title: l10n.permBattery,
              status: switch (permissions.batteryOptimised) {
                true => l10n.permBatteryOn,
                false => l10n.permBatteryOff,
                null => l10n.permBatteryUnknown,
              },
              good: permissions.batteryOptimised == false,
              onFix: permissions.batteryOptimised == true
                  ? () => unawaited(_fix(widget.onFixBattery))
                  : null,
            ),
          ],

          const Divider(),
          ListTile(
            title: Text(l10n.settingsMaps),
            trailing: const Icon(Icons.chevron_right),
            onTap: widget.onOpenMaps,
          ),

          // §15.7: the three rules, findable again on day thirty.
          ListTile(
            title: Text(l10n.rulesTitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const SurvivalRulesScreen(),
              ),
            ),
          ),

          // §16.5: stated rather than configurable, because there is no switch
          // to offer — nothing is collected, so nothing can be opted out of.
          const Divider(),
          _Heading(l10n.settingsPrivacy),
          ListTile(
            title: Text(l10n.settingsTelemetry),
            subtitle: Text(
              l10n.settingsTelemetryBody,
              style: theme.textTheme.bodySmall,
            ),
          ),

          // §11.2: the simulator is opted into, and only where one exists.
          if (kDevTools) ...[
            const Divider(),
            SwitchListTile(
              value: widget.simulatorEnabled,
              onChanged: widget.onSimulatorChanged,
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
