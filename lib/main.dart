import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:video_player/video_player.dart';

import 'data/db/save_location.dart';
import 'data/db/snapshot_store.dart';
import 'data/persistence/save_bootstrap.dart';
import 'devtools/dev_mode.dart';
import 'devtools/dev_overlay.dart';
import 'devtools/dev_session.dart';
import 'game/game_loop.dart';
import 'game/game_session.dart';
import 'game/relocation.dart';
import 'l10n/app_localizations.dart';
import 'location/device_position_source.dart';
import 'location/device_power_source.dart';
import 'location/location_access.dart';
import 'location/movement_integrity.dart';
import 'location/position_fix.dart';
import 'map/map_bootstrap.dart';
import 'map/map_source.dart';
import 'map/geometry.dart';
import 'map/pack_manager.dart';
import 'map/pack_store.dart';
import 'map/region_pack.dart';
import 'safety/player_safety.dart';
import 'ui/app_settings.dart';
import 'ui/character_creator.dart';
import 'ui/language_picker.dart';
import 'ui/safety_briefing.dart';
import 'ui/hud.dart';
import 'ui/map_view.dart';
import 'ui/maplibre_surface.dart';
import 'ui/region_picker.dart';
import 'ui/settings_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(const ArlsZaApp());
}

class ArlsZaApp extends StatefulWidget {
  const ArlsZaApp({super.key});

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
      home: IntroScreen(onSettings: _adoptSettings),
    );
  }
}

class IntroScreen extends StatefulWidget {
  const IntroScreen({required this.onSettings, super.key});

  /// Handed up as soon as the database is open, so the whole app can follow the
  /// player's language and theme.
  final void Function(AppSettings) onSettings;

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  late VideoPlayerController _controller;

  /// The save layer boots while the intro plays, so opening the database,
  /// verifying it and running any migration costs the player no extra wait.
  late final Future<SaveSession> _session = _bootSave();

  var _navigated = false;
  AppSettings? _settings;

  Future<SaveSession> _bootSave() async {
    final paths = await resolveSavePaths();
    final bootstrap = SaveBootstrap(paths: paths);
    final session = await bootstrap.boot(now: DateTime.now().toUtc());

    final settings = AppSettings(DatabaseSettingsStore(session.db));
    await settings.load();
    widget.onSettings(settings);
    _settings = settings;

    return session;
  }

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset('assets/INTRO.mp4')
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() {});
        _controller.play();
        _controller.addListener(_onVideoEnd);
      });
  }

  void _onVideoEnd() {
    if (_controller.value.isInitialized &&
        !_controller.value.isPlaying &&
        _controller.value.position >= _controller.value.duration) {
      _goToTitle();
    }
  }

  Future<void> _goToTitle() async {
    if (_navigated || !mounted) return;
    _navigated = true;

    // Never leave the intro before the save layer has reported in — the player
    // has to learn about a recovered or lost save (§11.1.3).
    final session = await _session;
    if (!mounted) return;

    await Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        pageBuilder: (_, animation, _) => FadeTransition(
          opacity: animation,
          child: TitleScreen(session: session, settings: _settings!),
        ),
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  void dispose() {
    _controller.removeListener(_onVideoEnd);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _goToTitle,
        child: SizedBox.expand(
          child: _controller.value.isInitialized
              ? FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _controller.value.size.width,
                    height: _controller.value.size.height,
                    child: VideoPlayer(_controller),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ),
    );
  }
}

/// Title screen. Routes to the creator on a first run, or resumes the active
/// character and puts the HUD on screen.
class TitleScreen extends StatefulWidget {
  const TitleScreen({required this.session, required this.settings, super.key});

  final SaveSession session;
  final AppSettings settings;

  @override
  State<TitleScreen> createState() => _TitleScreenState();
}

class _TitleScreenState extends State<TitleScreen> with WidgetsBindingObserver {
  late final GameSessionFactory _factory = GameSessionFactory(widget.session);

  /// Null in a release build — `DevSession.attach` short-circuits on the const
  /// gate, so nothing here survives tree shaking (§11.2).
  DevSession? _dev;

  ActiveCharacter? _character;
  GameLoop? _loop;
  GameSnapshot? _snapshot;
  bool _loading = true;

  /// The real GPS, when that is what is driving the game. Held so the location
  /// gate can send the player to the right settings page and ask again.
  DevicePositionSource? _device;

  /// True until a language has been chosen. Nothing at all runs first.
  bool _needsLanguage = false;

  /// True until §3.5 has been read and accepted.
  bool _needsBriefing = false;

  /// The map layer. Built once, on the first boot after the briefing.
  PackManager? _packs;

  /// Watches downloads for as long as the game runs, not for as long as the
  /// region screen is open (§16.6). A pack that finishes while the player is
  /// back on the map has to put itself on the map.
  StreamSubscription<DownloadState>? _downloadWatch;

  /// Where the tiles are read from, or null while there is no map at all — the
  /// region screen is then what the player sees (§16.6).
  MapSource? _mapSource;

  /// So the region screen opens itself on a first run and never again.
  bool _askedForMap = false;

  /// Where the previous session ended, read once at boot. What the first
  /// trusted fix is compared against (§16.6).
  GeoPoint? _lastKnown;

  /// Told once per session, not once per fix.
  bool _relocationTold = false;

  /// True only in a developer build where the simulator has been switched on
  /// (§11.2). Everything else walks on real ground.
  bool _useSimulator = false;

  /// The region the player chose to stream rather than download (§16.6).
  ///
  /// Held separately from [_mapSource] because resolving the map again — after
  /// the region screen closes, say — asks what is *installed*, and would
  /// otherwise throw the choice away and leave the player on a blank screen.
  RegionPack? _streamedChoice;

  /// Set when the operating system will not give us a position (§16.1). The
  /// game stops at the gate rather than running a simulation on movement that
  /// will never arrive.
  LocationAccess? _blocked;

  /// Where the simulated clock stood when the loop started, so the developer
  /// overlay can report how much game time this session has consumed.
  DateTime? _sessionStart;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_boot());
  }

  Future<void> _boot() async {
    // Language before the rules. §3.5 is about traffic and strangers, and a
    // player who cannot read it has not been briefed.
    if (!widget.settings.languageChosen) {
      setState(() {
        _needsLanguage = true;
        _loading = false;
      });
      return;
    }

    // §3.5 is read before anything happens, including before a character
    // exists. The rules are about the person holding the phone, not the one in
    // the game.
    final accepted = briefingAccepted(
      await widget.session.db.readSetting(kSafetyBriefingKey),
    );
    if (!mounted) return;

    if (!accepted) {
      setState(() {
        _needsBriefing = true;
        _loading = false;
      });
      return;
    }

    _useSimulator = simulatorEnabled(
      await widget.session.db.readSetting(kSimulatorSettingKey),
    );
    if (!mounted) return;

    // The position is not a feature of this game, it is the input (§3). Asking
    // before a character exists means a player who will not grant it finds out
    // in one screen rather than after filling in a character sheet.
    //
    // Skipped only when the simulator is actually driving: it needs no
    // permission, and a prompt nothing will use is noise (§11.2).
    if (!_useSimulator) {
      final access = await requestLocationAccess();
      if (!mounted) return;

      if (!access.canPlay) {
        setState(() {
          _blocked = access;
          _loading = false;
        });
        return;
      }
    }

    final existing = await _factory.loadActive();
    if (!mounted) return;

    if (existing == null) {
      setState(() => _loading = false);
      return;
    }
    await _enter(existing);
  }

  Future<void> _chooseLanguage(Locale locale) async {
    await widget.settings.setLocale(locale);
    if (!mounted) return;

    setState(() {
      _needsLanguage = false;
      _loading = true;
    });
    await _boot();
  }

  Future<void> _acceptBriefing() async {
    await widget.session.db.writeSetting(
      kSafetyBriefingKey,
      '$kSafetyBriefingVersion',
    );
    if (!mounted) return;

    setState(() {
      _needsBriefing = false;
      _loading = true;
    });
    await _boot();
  }

  /// Starts the simulation for [character] and shows the HUD.
  Future<void> _enter(ActiveCharacter character) async {
    // Read before the loop starts writing over it: this is the only moment the
    // *previous* session's position is still on disk (§16.6).
    final previous = await _factory.lastKnownPosition(character.profile.id);
    _lastKnown = previous == null
        ? null
        : GeoPoint(previous.latitude, previous.longitude);
    if (!mounted) return;

    if (kDevTools && _useSimulator) {
      _dev = DevSession.attach(constants: character.constants);
    }

    final l10n = L10n.of(context);
    final source = buildPositionSource(
      notice: ForegroundNotice(
        title: l10n.locationNotificationTitle,
        body: l10n.locationNotificationBody,
      ),
      dev: _dev,
      useSimulator: _useSimulator,
    );

    if (source is DevicePositionSource) {
      _device = source;

      // Ask before the loop starts. Starting a loop that will never receive a
      // fix leaves the player watching a HUD that never changes, with nothing
      // saying why.
      final access = await source.requestAccess();
      if (!mounted) {
        await source.dispose();
        return;
      }
      if (!access.canPlay) {
        setState(() {
          _character = character;
          _blocked = access;
          _loading = false;
        });
        return;
      }
    }

    final loop = await _factory.startLoop(
      character: character,
      source: source,
      clock: _dev?.gameClock,
      power: DevicePowerSource(),
    );
    loop.snapshots.listen((snapshot) {
      if (!mounted) return;
      setState(() {
        _sessionStart ??= snapshot.state.lastUpdate;
        _snapshot = snapshot;
      });
      unawaited(_checkRelocation(snapshot));
    });

    if (!mounted) {
      await loop.dispose();
      return;
    }
    setState(() {
      _character = character;
      _loop = loop;
      _blocked = null;
      _loading = false;
    });

    await _resolveMap();
  }

  /// Finds a map for where the player is standing (§16.6).
  ///
  /// Runs after the loop has started, so the first fix — if there is one — can
  /// pick the right region. With no fix yet it falls back to whatever is
  /// installed, which on a second run is the right answer anyway.
  Future<void> _resolveMap() async {
    final packs = _packs ??= await bootMapPacks();
    _downloadWatch ??= packs.downloads.listen((state) {
      if (state.outcome == InstallOutcome.installed) {
        unawaited(_resolveMap());
      }
    });
    final near = await _bestKnownPosition();

    final active = await packs.activePack(
      nearLatitude: near?.latitude,
      nearLongitude: near?.longitude,
    );

    // An installed pack always wins; a chosen stream is the fallback, and only
    // then is there genuinely no map.
    final streamed = _streamedChoice;
    final source =
        packs.sourceFor(active) ??
        (streamed == null ? null : StreamedPack(streamed.url));

    if (!mounted) return;
    setState(() => _mapSource = source);

    // §16.6 calls this the first-run screen, and it is: with no map there is
    // nothing to draw, nowhere to put a marker and no §10 to run. Opening it
    // unasked is right exactly once, which is what [_askedForMap] guards.
    if (source == null && !_askedForMap) {
      _askedForMap = true;
      await _openRegionPicker();
    }
  }

  /// The live fix if there is one, otherwise the last position on disk.
  ///
  /// A GPS lock takes seconds and the region screen is the first thing a player
  /// sees. Falling back to the save is what makes "near you" mean anything on
  /// the second run, and on the first it is honestly unknown.
  Future<({double latitude, double longitude})?> _bestKnownPosition() async {
    final fix = _snapshot?.fix;
    if (fix != null) {
      return (latitude: fix.latitude, longitude: fix.longitude);
    }

    final character = _character;
    if (character == null) return null;
    return _factory.lastKnownPosition(character.profile.id);
  }

  /// Did this session open somewhere else? (§16.6)
  ///
  /// Only the first trusted fix is asked. A fix that failed the accuracy gate
  /// or came from a mock provider is not a journey, and the filter has already
  /// dropped those — what reaches a snapshot has passed both (§3.2, §3.4).
  Future<void> _checkRelocation(GameSnapshot snapshot) async {
    if (_relocationTold) return;

    final fix = snapshot.fix;
    if (fix == null || snapshot.signal != PositionSignal.good) return;

    _relocationTold = true;
    final here = GeoPoint(fix.latitude, fix.longitude);

    final covered =
        _mapSource != null &&
        (await _packs?.activePack(
              nearLatitude: here.latitude,
              nearLongitude: here.longitude,
            )) !=
            null;

    final moved = detectRelocation(
      lastKnown: _lastKnown,
      trusted: here,
      mapCoversHere: covered,
    );
    if (!moved.happened || !mounted) return;

    final l10n = L10n.of(context);
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.relocationTitle),
        content: Text(
          moved.verdict == RelocationVerdict.covered
              ? l10n.relocationBody(moved.kilometres)
              : l10n.relocationNoMapBody(moved.kilometres),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.relocationDismiss),
          ),
        ],
      ),
    );

    // Nothing to draw and nowhere for §10 to put anything: the region screen
    // is the only useful next step.
    if (moved.verdict == RelocationVerdict.uncovered && mounted) {
      await _openRegionPicker();
    }
  }

  /// The player chose the network map rather than waiting for a download.
  void _playStreamed(RegionPack pack) {
    setState(() {
      _streamedChoice = pack;
      _mapSource = StreamedPack(pack.url);
    });
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> _openSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SettingsScreen(
          settings: widget.settings,
          onOpenMaps: () => unawaited(_openRegionPicker()),
          simulatorEnabled: _useSimulator,
          onSimulatorChanged: (value) => unawaited(_setSimulator(value)),
        ),
      ),
    );
  }

  /// Switching the source is a restart of the session, not a live swap: the
  /// filter, the loop and the map are all built around one of them (§11.2).
  Future<void> _setSimulator(bool value) async {
    await widget.session.db.writeSetting(
      kSimulatorSettingKey,
      value ? 'true' : 'false',
    );
    if (!mounted) return;

    setState(() => _useSimulator = value);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(L10n.of(context).settingsRestartNeeded)),
      );
    }
  }

  Future<void> _openRegionPicker() async {
    final packs = _packs ??= await bootMapPacks();
    if (!mounted) return;

    final near = await _bestKnownPosition();
    if (!mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RegionPickerScreen(
          manager: packs,
          nearLatitude: near?.latitude,
          nearLongitude: near?.longitude,
          onPlayStreamed: _playStreamed,

          // A finished download is the whole reason the screen was open.
          // Leaving it up and making the player find the back gesture reads
          // as the download not having worked.
          onDone: () => Navigator.of(context).popUntil((r) => r.isFirst),
        ),
      ),
    );
    if (mounted) await _resolveMap();
  }

  Future<void> _createCharacter(CharacterDraft draft) async {
    final created = await _factory.create(
      name: draft.name,
      spec: draft.spec,
      deathMode: draft.deathMode,
      now: DateTime.now().toUtc(),
    );
    if (!mounted) return;

    Navigator.of(context).pop();
    setState(() => _loading = true);
    await _enter(created);
  }

  /// The two moments the process is most likely to be killed (§11.1.5).
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final loop = _loop;
    if (loop == null) return;

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        unawaited(loop.onPaused(DateTime.now().toUtc()));
      case AppLifecycleState.resumed:
        unawaited(loop.onResumed());
      case AppLifecycleState.inactive:
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_downloadWatch?.cancel());
    unawaited(_loop?.dispose());
    unawaited(_dev?.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_needsLanguage) {
      return LanguagePickerScreen(
        onChosen: (locale) => unawaited(_chooseLanguage(locale)),
      );
    }

    if (_needsBriefing) {
      return SafetyBriefingScreen(onAccept: () => unawaited(_acceptBriefing()));
    }

    final l10n = L10n.of(context);
    final recovery = widget.session.recovery;
    final dev = _dev;
    final snapshot = _snapshot;
    final character = _character;
    final blocked = _blocked;

    final source = _mapSource;
    // Deliberately not waiting for a snapshot. The first one arrives with the
    // first fix, and a lock takes seconds — showing the region in the meantime
    // beats a title screen the player has already left.
    if (source != null && character != null) {
      return Stack(
        children: [
          MapScreen(
            tileBuilder:
                (
                  context, {
                  required centre,
                  required markers,
                  required economy,
                }) => MapLibreSurface(
                  source: source,
                  centre: centre,
                  markers: markers,
                  economy: economy,
                ),
            fix: snapshot?.fix,
            headingDeg: snapshot?.fix?.headingDeg,
            economy: snapshot?.economy ?? false,
            // There is always a map here — this branch only runs with a
            // source. Whether the player has walked off its *edge* is the
            // coverage question of §16.6, and it arrives with 3.12.
            hasPack: true,
            hud: snapshot == null
                ? null
                : Hud(
                    state: snapshot.state,
                    status: snapshot.status,
                    constants: character.constants,
                    warnings: _warnings(l10n, snapshot),
                    carryComfortKg: character.body.carryComfortKg,
                  ),
            onMenu: (entry) {
              // Only the map is built; the rest of §3.6 arrives with the
              // systems behind it. Settings is the one that already has
              // something to do.
              if (entry == MapMenuEntry.settings) {
                unawaited(_openSettings());
              }
            },
          ),
          if (dev != null)
            DevOverlay(
              console: dev.console,
              snapshot: DevSnapshot(
                state: snapshot?.state,
                fix: snapshot?.fix,
                signal: snapshot?.signal ?? PositionSignal.unavailable,
                ticksApplied: _simulatedSeconds(snapshot),
                lastFlushAt: snapshot?.lastFlushAt,
                clockRolledBack: snapshot?.clockRolledBack ?? false,
              ),
            ),
        ],
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              if (snapshot != null && character != null)
                Hud(
                  state: snapshot.state,
                  status: snapshot.status,
                  constants: character.constants,
                  warnings: _warnings(l10n, snapshot),
                  carryComfortKg: character.body.carryComfortKg,
                ),
              Expanded(
                child: SafeArea(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: _loading
                          ? const CircularProgressIndicator()
                          : Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Image.asset('assets/icon.png', width: 120),
                                const SizedBox(height: 24),
                                Text(
                                  character?.profile.name ?? l10n.appTitle,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.headlineMedium,
                                ),
                                Text(
                                  l10n.appTagline,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                const SizedBox(height: 32),
                                if (recovery.health == SaveHealth.restored)
                                  _Notice(
                                    title: l10n.saveRestoredTitle,
                                    body: l10n.saveRestoredBody(
                                      recovery.timeLost?.inMinutes ?? 0,
                                    ),
                                  ),
                                if (recovery.health == SaveHealth.lost)
                                  _Notice(
                                    title: l10n.saveLostTitle,
                                    body: l10n.saveLostBody,
                                  ),
                                if (blocked != null)
                                  _LocationGate(
                                    access: blocked,
                                    onRetry: _retryAccess,
                                  ),
                                if (blocked == null &&
                                    _device?.access ==
                                        LocationAccess.foregroundOnly)
                                  _Notice(
                                    title: l10n.locationForegroundOnlyTitle,
                                    body: l10n.locationForegroundOnlyBody,
                                  ),
                                if (character == null)
                                  FilledButton(
                                    onPressed: _openCreator,
                                    child: Text(l10n.newCharacter),
                                  ),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (dev != null)
            DevOverlay(
              console: dev.console,
              snapshot: DevSnapshot(
                state: snapshot?.state,
                fix: snapshot?.fix,
                signal: snapshot?.signal ?? PositionSignal.unavailable,
                ticksApplied: _simulatedSeconds(snapshot),
                lastFlushAt: snapshot?.lastFlushAt,
                clockRolledBack: snapshot?.clockRolledBack ?? false,
              ),
            ),
        ],
      ),
    );
  }

  /// The player has been to the settings, or wants to be asked again.
  Future<void> _retryAccess() async {
    final device = _device;
    final character = _character;

    // The gate can fire before there is a character at all — the permission is
    // now asked for during boot. Then the way back is simply to ask again.
    if (device == null || character == null) {
      final blocked = _blocked;
      if (blocked != null && blocked.needsSystemSettings) {
        await openSettingsFor(blocked);
        return;
      }

      final access = await requestLocationAccess();
      if (!mounted) return;

      if (access.canPlay) {
        setState(() {
          _blocked = null;
          _loading = true;
        });
        await _boot();
      } else {
        setState(() => _blocked = access);
      }
      return;
    }

    if (device.access.needsSystemSettings) {
      await device.openRelevantSettings();
      // Android gives us nothing to await here: the player may come back
      // having changed the setting, or not at all. The button stays, so the
      // next tap re-asks.
      return;
    }

    setState(() => _loading = true);
    await device.dispose();
    _device = null;
    await _enter(character);
  }

  void _openCreator() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CharacterCreatorScreen(onCreate: _createCharacter),
      ),
    );
  }

  /// Game seconds this session has consumed. In furious time scale a minute of
  /// wall clock is more than two days of it, which is exactly what the overlay
  /// exists to make visible.
  int _simulatedSeconds(GameSnapshot? snapshot) {
    final start = _sessionStart;
    if (snapshot == null || start == null) return 0;
    return snapshot.state.lastUpdate.difference(start).inSeconds;
  }

  /// Everything the systems layer wants said in words, in the order it matters.
  ///
  /// A suspended run comes first: while it holds, nothing else the HUD says is
  /// being applied anyway (§3.4).
  static List<String> _warnings(L10n l10n, GameSnapshot snapshot) => [
    ?switch (snapshot.integrityReason) {
      IntegrityReason.mockProvider => l10n.integritySuspendedMock,
      IntegrityReason.vehicleSpeed
          when snapshot.integrity == IntegrityState.suspended =>
        l10n.integritySuspendedVehicle,
      _ => null,
    },
    ?switch (snapshot.signal) {
      PositionSignal.lost || PositionSignal.unavailable => l10n.hudNoSignal,
      PositionSignal.degraded => l10n.hudWeakSignal,
      PositionSignal.good => null,
    },
    if (snapshot.economy) l10n.hudLowBattery,
    if (snapshot.combatBlocked == CombatBlock.movingTooFast)
      l10n.safetyNoCombatMoving,
  ];
}

/// What to say when the operating system will not give us a position (§16.1).
///
/// Each state gets its own words and its own button. "Location refused" with a
/// button that opens the wrong settings page is worse than saying nothing.
class _LocationGate extends StatelessWidget {
  const _LocationGate({required this.access, required this.onRetry});

  final LocationAccess access;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);

    final (title, body) = switch (access) {
      LocationAccess.serviceDisabled => (
        l10n.locationServiceOffTitle,
        l10n.locationServiceOffBody,
      ),
      LocationAccess.deniedForever => (
        l10n.locationDeniedTitle,
        l10n.locationDeniedBody,
      ),
      // Not yet asked, or asked and dismissed. Explain what it is for before
      // asking again, rather than firing the system prompt a second time with
      // no context (§16.1).
      _ => (l10n.locationTitle, l10n.locationBody),
    };

    return Column(
      children: [
        _Notice(title: title, body: body),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: () => unawaited(onRetry()),
          child: Text(
            access.needsSystemSettings
                ? l10n.locationSettings
                : l10n.locationGrant,
          ),
        ),
      ],
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: Theme.of(context).colorScheme.error,
            width: 2,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 4),
          Text(body, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
