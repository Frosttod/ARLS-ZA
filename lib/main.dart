import 'dart:async';
import 'dart:math';

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
import 'inventory/inventory.dart';
import 'inventory/inventory_store.dart';
import 'items/item_assets.dart';
import 'items/item_catalogue.dart';
import 'items/item_names.dart';
import 'loot/loot_spawner.dart';
import 'loot/loot_store.dart';
import 'loot/loot_table.dart';
import 'loot/loot_world.dart';
import 'loot/search.dart';
import 'ui/search_panel.dart';
import 'game/game_session.dart';
import 'game/relocation.dart';
import 'l10n/app_localizations.dart';
import 'location/device_position_source.dart';
import 'location/device_power_source.dart';
import 'location/location_access.dart';
import 'location/movement_integrity.dart';
import 'location/position_fix.dart';
import 'location/system_permissions.dart';
import 'map/map_bootstrap.dart';
import 'map/map_source.dart';
import 'map/geometry.dart';
import 'map/pack_manager.dart';
import 'map/pack_store.dart';
import 'map/region_pack.dart';
import 'safety/player_safety.dart';
import 'sim/body.dart';
import 'ui/app_settings.dart';
import 'ui/character_creator.dart';
import 'ui/language_picker.dart';
import 'ui/safety_briefing.dart';
import 'ui/hud.dart';
import 'ui/inventory_screen.dart';
import 'ui/map_markers.dart';
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

  /// Everything the game knows about items (§4.1), read once at boot from the
  /// bundled files and any content pack the player has.
  ItemCatalogue? _catalogue;

  /// What the player is carrying. Empty until there is something to pick up —
  /// the two HUD bars still read off it, so they show the real limits from the
  /// first frame rather than appearing when the first item does.
  Inventory _inventory = const Inventory();

  /// Item names, read alongside the catalogue (§1.1, §4.1).
  ItemNames? _names;

  /// The loot layer (§10). Null until the tables have been read; it does
  /// nothing at all until there is an installed pack to read places out of.
  LootWorld? _world;

  /// What is standing on the map right now. Held here because the map view is
  /// rebuilt constantly and re-reading the tiles for every frame would keep the
  /// phone busy for no gain.
  List<LootBox> _boxes = const [];

  /// The search in progress (§10.2, §19.3), and when it was last advanced.
  Search? _search;
  DateTime? _searchTickedAt;

  /// What the last reconnaissance revealed, for §10.2.1's ten minutes.
  AreaKnowledge? _knowledge;

  /// Procedural places the player has actually looked for (§10.2.3). A
  /// pharmacy is a building and is visible from the street; a wrecked car in a
  /// side road is not, until somebody stops and looks.
  final Set<String> _revealed = {};

  /// Both HUD bars read these. Zero without a catalogue, which only happens if
  /// every bundled data file failed to parse — a broken build, not a state the
  /// player can reach.
  double get _carriedKg =>
      _catalogue == null ? 0 : _inventory.massKg(_catalogue!);

  double get _carriedVolumeL =>
      _catalogue == null ? 0 : _inventory.volumeL(_catalogue!);

  double _capacityL(BodyProfile body) => _catalogue == null
      ? kPocketCapacityL
      : _inventory.limits(body, _catalogue!).capacityL;

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

  /// The middle of the installed pack, from its own header. Where the camera
  /// points until the first fix arrives (§16.6).
  GeoPoint? _packCentre;

  /// Where the previous session ended, read once at boot. What the first
  /// trusted fix is compared against (§16.6).
  GeoPoint? _lastKnown;

  /// Told once per session, not once per fix.
  bool _relocationTold = false;

  /// What the system allows (§3.3, §16.1). Re-read whenever the app comes back,
  /// because the player may have just changed it.
  SystemPermissions? _permissions;

  /// The startup prompt is offered once a session and never nags.
  bool _permissionsOffered = false;

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

    // Read once. A problem here is a shipped data file being wrong, which the
    // build should already have caught — so it is logged for the developer
    // overlay and the game runs on whatever parsed (§4.1).
    _catalogue = await loadItemCatalogue();
    _names = await loadItemNames();
    final tables = LootTableSet.parse(
      await rootBundle.loadString('assets/data/loot_tables.json'),
    );
    _world = LootWorld(tables: tables);
    if (!mounted) return;

    await _readPermissions();
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

  /// Asks the system what it currently allows.
  ///
  /// Cheap and worth repeating: the player can change any of the three from
  /// outside the app, and the game has no way to be told.
  Future<void> _readPermissions() async {
    if (_useSimulator) return;

    final permissions = await _currentPermissions();
    if (!mounted) return;
    setState(() => _permissions = permissions);
  }

  /// Asks the system, without touching any state.
  ///
  /// Handed to the settings screen so it can re-read for itself: a pushed
  /// route given a value keeps showing the value it was built with, which is
  /// stale exactly when the player is looking at it — right after they walked
  /// to the system settings and changed something.
  Future<SystemPermissions> _currentPermissions() async => SystemPermissions(
    // checkPermission only; asking here would fire a prompt every time the
    // settings screen is opened.
    location: await currentLocationAccess(),
    batteryOptimised: await const SystemSettings().isBatteryOptimised(),
  );

  /// Offered once, after the map is up, and dismissible.
  ///
  /// Not a gate: §16.1 says foreground-only is a supported way to play, so this
  /// explains what is missing and what it costs rather than demanding it. The
  /// battery half is the part no system dialog ever mentions.
  Future<void> _offerPermissions() async {
    if (_permissionsOffered || _useSimulator) return;
    final permissions = _permissions;
    if (permissions == null || permissions.backgroundWorks) return;

    _permissionsOffered = true;
    final l10n = L10n.of(context);
    final fix = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.permStartupTitle),
        content: Text(l10n.permStartupBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.permStartupLater),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.permStartupFix),
          ),
        ],
      ),
    );

    if (fix == true && mounted) await _openSettings();
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

    // What the character was carrying when the app last closed. Rows naming an
    // item nothing defines are dropped rather than guessed at (§4.1) — that
    // happens when a content pack is uninstalled, and the pack going away is
    // what took the item with it.
    final catalogue = _catalogue;
    if (catalogue != null) {
      final loaded = await InventoryStore(
        widget.session.db,
      ).load(character.profile.id, catalogue);
      if (!mounted) return;
      _inventory = loaded.inventory;
    }

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
      unawaited(_spawnLoot(snapshot));
      unawaited(_advanceSearch(snapshot));
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
    if (mounted) await _offerPermissions();
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

    final header = active?.header;
    final centre = header == null
        ? null
        : GeoPoint(header.centre.latitude, header.centre.longitude);

    if (!mounted) return;
    setState(() {
      _mapSource = source;
      _packCentre = centre;
    });

    // The loot layer reads the same file the renderer draws (§10). A streamed
    // pack gives it nothing: it is read over the network, and a POI query
    // across it would be hundreds of range requests every time somebody walks.
    await _world?.useSource(source);
    await _loadLootBoxes();

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
          readPermissions: _currentPermissions,
          onFixLocation: _fixLocation,
          onFixBattery: const SystemSettings().openBatterySettings,
          simulatorEnabled: _useSimulator,
          onSimulatorChanged: (value) => unawaited(_setSimulator(value)),
        ),
      ),
    );
  }

  Future<void> _openInventory() async {
    final character = _character;
    final catalogue = _catalogue;
    if (character == null || catalogue == null) return;

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => InventoryScreen(
          inventory: _inventory,
          catalogue: catalogue,
          names: _names ?? ItemNames.empty,
          body: character.body,
          onDrop: (line) => unawaited(_drop(line)),
          onDevFill: kDevTools ? () => unawaited(_devFillPack()) : null,
        ),
      ),
    );
  }

  /// Developer builds only. Puts a plausible kit in the pack so the screen can
  /// be looked at on a phone before §10 gives the game a way to find anything.
  Future<void> _devFillPack() async {
    final character = _character;
    final catalogue = _catalogue;
    if (character == null || catalogue == null) return;

    var next = _inventory.packId == null
        ? _inventory.withPack('pack_daypack')
        : _inventory;
    for (final id in const [
      'cloth_winter_jacket',
      'cloth_boots',
      'armor_vest_soft',
    ]) {
      next = next.wear(id, catalogue);
    }
    for (final line in const [
      ('food_canned_meat', 2),
      ('drink_water_bottle_500', 2),
      ('med_bandage', 3),
      ('melee_knife', 1),
      ('mat_wood', 4),
      ('tool_flashlight', 1),
    ]) {
      next = next
          .add(line.$1, catalogue, body: character.body, count: line.$2)
          .inventory;
    }
    next = next
        .add(
          'lit_guide_survival',
          catalogue,
          body: character.body,
          pagesTotal: 160,
        )
        .inventory;

    setState(() => _inventory = next);
    await _saveInventory();

    if (mounted) Navigator.of(context).pop();
  }

  /// §4.8 will put a dropped item on the map for 24 hours. Until the loot layer
  /// exists there is nowhere for it to land, so it simply leaves the pack.
  Future<void> _drop(CarriedItem line) async {
    final next = _inventory.remove(line.itemId, count: line.count);
    if (next == null) return;

    setState(() => _inventory = next);
    await _saveInventory();
  }

  Future<void> _saveInventory() async {
    final character = _character;
    if (character == null) return;
    await InventoryStore(
      widget.session.db,
    ).save(character.profile.id, _inventory);
  }

  /// What was on the map when the app last closed.
  ///
  /// Read before anything is spawned, so a player who walked towards a marker
  /// and closed the app finds the same marker in the same place.
  Future<void> _loadLootBoxes() async {
    final character = _character;
    if (character == null) return;

    final boxes = await LootStore(widget.session.db).load(character.profile.id);
    if (!mounted) return;

    setState(() => _boxes = boxes);
  }

  /// Puts loot on the map around wherever the player now is (§10).
  ///
  /// Driven off the fix rather than a timer: the thing that makes new loot
  /// worth spawning is the player having walked somewhere, and nothing else.
  Future<void> _spawnLoot(GameSnapshot snapshot) async {
    final world = _world;
    final character = _character;
    final fix = snapshot.fix;
    if (world == null || character == null || fix == null) return;
    if (!world.isReady) return;

    final at = GeoPoint(fix.latitude, fix.longitude);
    if (!world.shouldReplan(at)) return;

    final plan = await world.plan(
      centre: at,
      existing: _boxes,
      now: snapshot.state.lastUpdate,
      seed: character.profile.rngSeed,
    );
    if (plan == null || !mounted) return;

    await LootStore(widget.session.db).save(character.profile.id, plan);
    if (!mounted) return;

    setState(() => _boxes = plan.boxes);
  }

  /// §3.6: loot is yellow. An emptied box is not drawn at all — a marker that
  /// stays after there is nothing behind it is a walk taken for nothing.
  ///
  /// §10.2.3 decides what is on the map before anybody looks: a pharmacy is a
  /// building and is visible from the street, so its marker is always there. A
  /// wrecked car in a side road is not, and appears only once the player has
  /// stopped and searched the area.
  List<MapMarker> _lootMarkers() {
    final now = _snapshot?.state.lastUpdate ?? DateTime.now().toUtc();

    return [
      for (final box in _boxes)
        if (box.isActiveAt(now) && _isVisible(box))
          MapMarker(
            id: box.poiId,
            kind: MarkerKind.loot,
            at: box.position,
            label: box.name,
          ),
    ];
  }

  bool _isVisible(LootBox box) {
    final table = _world?.tables[box.tableId];
    if (table == null || table.source == LootSource.osm) return true;
    return _revealed.contains(box.poiId);
  }

  /// The box the player is standing at, if any (§19.3).
  LootBox? _boxInReach() {
    final fix = _snapshot?.fix;
    if (fix == null) return null;

    final at = GeoPoint(fix.latitude, fix.longitude);
    final now = _snapshot?.state.lastUpdate ?? DateTime.now().toUtc();

    LootBox? best;
    var bestDistance = kSearchReachM;
    for (final box in _boxes) {
      if (!box.isActiveAt(now) || !_isVisible(box)) continue;
      final distance = box.position.distanceTo(at);
      if (distance > bestDistance) continue;
      best = box;
      bestDistance = distance;
    }
    return best;
  }

  /// Advances whatever search is running, one snapshot at a time.
  ///
  /// The loop's own clock rather than a timer of its own: a search has to tick
  /// at the same rate as the body it belongs to, and stop for the same reasons.
  Future<void> _advanceSearch(GameSnapshot snapshot) async {
    final search = _search;
    if (search == null || !search.isRunning) return;

    final now = snapshot.state.lastUpdate;
    final since = _searchTickedAt ?? search.startedAt;
    final delta = now.difference(since);
    if (delta <= Duration.zero) return;
    _searchTickedAt = now;

    final fix = snapshot.fix;
    final next = search.advance(
      delta,
      at: fix == null ? null : GeoPoint(fix.latitude, fix.longitude),
      // §2.1a and §10.2: a search counts only while the game is actually
      // watching the player move. A degraded or lost signal is exactly the
      // case where "did they stand still" cannot be answered.
      present: snapshot.signal == PositionSignal.good,
    );

    if (next.isRunning) {
      setState(() => _search = next);
      return;
    }

    setState(() => _search = null);
    _searchTickedAt = null;

    if (next.state == SearchState.done) {
      await (next.isArea ? _finishAreaSearch(next, now) : _finishObjectSearch(next, now));
    } else if (mounted) {
      _say(
        next.state == SearchState.cancelledByMovement
            ? L10n.of(context).searchMoved
            : L10n.of(context).searchLostSignal,
      );
    }
  }

  void _startAreaSearch() {
    final fix = _snapshot?.fix;
    if (fix == null || _search != null) return;

    setState(() {
      _search = Search.area(
        at: GeoPoint(fix.latitude, fix.longitude),
        now: _snapshot!.state.lastUpdate,
      );
      _searchTickedAt = _snapshot!.state.lastUpdate;
    });
  }

  void _startObjectSearch(SearchDepth depth) {
    final fix = _snapshot?.fix;
    final box = _boxInReach();
    if (fix == null || box == null || _search != null) return;

    setState(() {
      _search = Search.object(
        at: GeoPoint(fix.latitude, fix.longitude),
        now: _snapshot!.state.lastUpdate,
        poiId: box.poiId,
        depth: depth,
      );
      _searchTickedAt = _snapshot!.state.lastUpdate;
    });
  }

  void _cancelSearch() {
    if (_search == null) return;
    setState(() {
      _search = null;
      _searchTickedAt = null;
    });
  }

  /// §10.2.3: reconnaissance reveals the places that cannot be seen from the
  /// street, and the state of the ones that can.
  Future<void> _finishAreaSearch(Search search, DateTime now) async {
    final previous = _knowledge;
    final radius = searchRadiusM(
      // Reconnaissance is §7 and does not exist yet; binoculars do.
      binoculars: _inventory.countOf('tool_binoculars') > 0 ||
          _inventory.worn.any((line) => line.itemId == 'tool_binoculars'),
    );

    final found = <String>{
      for (final box in _boxes)
        if (box.position.distanceTo(search.anchor) <= radius) box.poiId,
    };
    final fresh = found.difference(_revealed);

    setState(() {
      _revealed.addAll(found);
      _knowledge = AreaKnowledge(
        at: search.anchor,
        radiusM: radius,
        completedAt: now,
        revealedPoiIds: found,
      );
    });

    if (!mounted) return;
    final l10n = L10n.of(context);
    // §10.2.1: looking again at ground already searched is allowed and adds
    // nothing for ten minutes. Saying so plainly beats letting the player read
    // an empty result as a failed search.
    final knownAlready = previous?.covers(search.anchor, now) ?? false;
    _say(
      fresh.isNotEmpty && !knownAlready
          ? l10n.searchRevealed(fresh.length)
          : l10n.searchNothingNew,
    );
  }

  /// §19.3: the table is rolled, what fits goes in the pack, and the box is
  /// empty until it refills (§10).
  Future<void> _finishObjectSearch(Search search, DateTime now) async {
    final character = _character;
    final catalogue = _catalogue;
    final world = _world;
    final poiId = search.targetPoiId;
    final depth = search.depth;
    if (character == null ||
        catalogue == null ||
        world == null ||
        poiId == null ||
        depth == null) {
      return;
    }

    final box = _boxes.where((b) => b.poiId == poiId).firstOrNull;
    final table = box == null ? null : world.tables[box.tableId];
    if (box == null || table == null) return;

    // Seeded from the place and the character, so the same search of the same
    // shop gives the same result however many times the app is restarted
    // mid-search (§11).
    final random = Random(character.profile.rngSeed ^ poiId.hashCode);
    final drop = table.roll(random, depth: depth, catalogue: catalogue);

    var inventory = _inventory;
    final taken = <String, int>{};
    var refused = false;

    for (final entry in drop.entries) {
      final result = inventory.add(
        entry.key,
        catalogue,
        body: character.body,
        count: entry.value,
      );
      inventory = result.inventory;

      final accepted = result.acceptedCount ?? entry.value;
      if (accepted > 0) taken[entry.key] = accepted;
      if (accepted < entry.value) refused = true;
    }

    // The box is emptied whether or not everything fitted. §19.3 spends the
    // time on searching it, not on carrying the result — and a box that stayed
    // full because a pack was full would be a way to farm one shop.
    final emptied = box.lootedAtTime(now, random);

    setState(() {
      _inventory = inventory;
      _boxes = [
        for (final b in _boxes) if (b.poiId == poiId) emptied else b,
      ];
    });

    await LootStore(widget.session.db).saveOne(character.profile.id, emptied);
    await _saveInventory();
    if (!mounted) return;

    final l10n = L10n.of(context);
    if (taken.isEmpty) {
      _say(l10n.searchFoundNothing);
      return;
    }

    final language = Localizations.localeOf(context).languageCode;
    final names = _names ?? ItemNames.empty;
    final listed = taken.entries
        .map((entry) {
          final item = catalogue[entry.key];
          final name = item == null
              ? entry.key
              : item.name.resolve(
                  language: language,
                  lookup: names.forLanguage(language),
                );
          return entry.value > 1 ? '$name ×${entry.value}' : name;
        })
        .join(', ');

    _say('${l10n.searchFound(listed)}${refused ? ' · ${l10n.searchNoRoom}' : ''}');
  }

  /// One line, at the bottom, gone in a few seconds. The player is walking.
  void _say(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 4)),
    );
  }

  /// Sends the player wherever the current refusal can actually be changed.
  Future<void> _fixLocation() async {
    final access = _permissions?.location ?? LocationAccess.denied;
    if (access.isAskable) {
      await requestLocationAccess();
    } else {
      // Background location cannot be granted from a prompt on modern
      // Android: it is a trip to the app's own settings page, every time.
      await const SystemSettings().openAppSettings();
    }
    await _readPermissions();
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
        unawaited(_readPermissions());
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
    unawaited(_world?.dispose());
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
                  fallbackCentre: _packCentre,
                ),
            fix: snapshot?.displayFix,
            markers: _lootMarkers(),
            searchPanel: snapshot == null
                ? null
                : SearchPanel(
                    search: _search,
                    targetName: _boxInReach()?.name,
                    canSearchHere: _boxInReach() != null,
                    onSearchArea: _startAreaSearch,
                    onSearchHere: _startObjectSearch,
                    onCancel: _cancelSearch,
                  ),
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
                    carryMaxKg: character.body.carryMaxKg,
                    carriedKg: _carriedKg,
                    carriedVolumeL: _carriedVolumeL,
                    capacityL: _capacityL(character.body),
                  ),
            onMenu: (entry) {
              // Profile and shelter arrive with the systems behind them
              // (§7, §8). The two that have something to show are wired.
              switch (entry) {
                case MapMenuEntry.settings:
                  unawaited(_openSettings());
                case MapMenuEntry.inventory:
                  unawaited(_openInventory());
                case MapMenuEntry.profile:
                case MapMenuEntry.shelter:
                  break;
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

    if (character != null && blocked == null) {
      // A character exists, so the game is running; the map is simply not
      // resolved yet. Showing the title screen here would put a logo over a
      // live simulation and read as something having gone wrong.
      return Scaffold(
        body: Stack(
          children: [
            const Center(child: CircularProgressIndicator()),
            if (snapshot != null)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Hud(
                    state: snapshot.state,
                    status: snapshot.status,
                    constants: character.constants,
                    warnings: _warnings(l10n, snapshot),
                    carryComfortKg: character.body.carryComfortKg,
                    carryMaxKg: character.body.carryMaxKg,
                    carriedKg: _carriedKg,
                    carriedVolumeL: _carriedVolumeL,
                    capacityL: _capacityL(character.body),
                  ),
                ),
              ),
          ],
        ),
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
                  carryMaxKg: character.body.carryMaxKg,
                  carriedKg: _carriedKg,
                  carriedVolumeL: _carriedVolumeL,
                  capacityL: _capacityL(character.body),
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
  List<String> _warnings(L10n l10n, GameSnapshot snapshot) => [
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
    if (_permissions?.location == LocationAccess.foregroundOnly)
      l10n.permLocationForeground,
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
