/// Starting the app, and the net under it (§16.1).
///
/// ⚠️ **Everything inside the zone, including the binding.**
///
/// This game is tested by walking round a city with it. Until [CrashLog]
/// existed a thrown exception went to the console of a machine that was not
/// there — there was no `FlutterError.onError`, no `PlatformDispatcher.onError`
/// and no zone — so a field report could say "crash" and nothing more.
///
/// Nearly every handler in the game is `unawaited(_something())`, so the zone
/// is the mechanism that matters: that is where those errors surface.
///
/// ⚠️ **This file knows nothing about the game.** It knows there is a first
/// screen and that the first screen will hand it the player's settings. What
/// the first screen is arrives as an argument — which is what stops this from
/// becoming the second place that imports everything.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../l10n/app_localizations.dart';
import '../ui/app_settings.dart';
import '../ui/crash_banner.dart';

import 'crash_log.dart';

/// Puts [app] on screen with the net installed under it.
void runGuarded(Widget app) {
  CrashLog.guard(() {
    WidgetsFlutterBinding.ensureInitialized();
    CrashLog.install();

    // ⚠️ **Before anything writes a step of its own.** A hang leaves no
    // exception — the field reported SIGQUIT and a tombstone, which is
    // Android's way of saying the main thread stopped answering. What it does
    // leave is the last step that reached the disk, and this is the only
    // moment that can be read.
    unawaited(CrashLog.readLastRun());

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    runApp(app);
  });
}

class ArlsZaApp extends StatefulWidget {
  const ArlsZaApp({required this.home, super.key});

  /// The first screen, given a way to hand its settings back up.
  ///
  /// A function rather than a widget because the settings arrive *from* it —
  /// the database opens behind the intro film, and the player's language and
  /// theme are inside the database.
  final Widget Function(void Function(AppSettings) onSettings) home;

  @override
  State<ArlsZaApp> createState() => _ArlsZaAppState();
}

class _ArlsZaAppState extends State<ArlsZaApp> {
  /// Set once the save layer is open. Until then the app follows the system,
  /// which is the best guess available before anything has been read.
  AppSettings? _settings;

  void _adoptSettings(AppSettings settings) {
    if (_settings == settings) return;
    setState(() => _settings = settings);
    settings.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    final settings = _settings;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (context) => L10n.of(context).appTitle,
      localizationsDelegates: const [
        L10n.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: L10n.supportedLocales,
      locale: settings?.locale,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: settings?.themeMode ?? ThemeMode.dark,
      // §16.1: over the whole app rather than on one screen — half the time
      // the screen the player was on is the thing that broke.
      builder: (context, child) =>
          CrashBanner(child: child ?? const SizedBox.shrink()),
      home: widget.home(_adoptSettings),
    );
  }
}
