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
import 'inventory/body_slots.dart';
import 'inventory/inventory.dart';
import 'inventory/inventory_store.dart';
import 'inventory/item_use.dart';
import 'items/item_assets.dart';
import 'items/item.dart';
import 'items/item_catalogue.dart';
import 'items/item_names.dart';
import 'combat/aim.dart';
import 'combat/ballistics.dart';
import 'combat/combat_session.dart';
import 'combat/engagement.dart';
import 'combat/magazine.dart';
import 'combat/enemy.dart';
import 'combat/noise.dart';
import 'combat/remains.dart';
import 'combat/attachment.dart';
import 'combat/sanctuary.dart';
import 'combat/shot.dart';
import 'loot/loot_spawner.dart';
import 'loot/loot_store.dart';
import 'loot/loot_table.dart';
import 'loot/dropped_items.dart';
import 'loot/dropped_store.dart';
import 'loot/loot_world.dart';
import 'loot/obstacle.dart';
import 'loot/search.dart';
import 'notes/note.dart';
import 'ui/combat_panel.dart';
import 'ui/ground_sheet.dart';
import 'shelter/recipes.dart';
import 'shelter/shelter.dart';
import 'shelter/shelter_store.dart';
import 'ui/place_sheet.dart';
import 'ui/remains_sheet.dart';
import 'ui/down_screen.dart';
import 'ui/shelter_screen.dart';
import 'ui/item_details_sheet.dart';
import 'ui/note_sheet.dart';
import 'ui/notices.dart';
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
import 'sim/death.dart';
import 'sim/physiology.dart';
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

  /// What the player is carrying.
  ///
  /// ⚠️ A notifier rather than a plain field, and there is a bug behind that.
  ///
  /// The inventory screen is a pushed route: its builder runs once, so a
  /// `setState` here rebuilt the map underneath and left the screen holding
  /// the inventory as it was when it opened. Dropping something therefore
  /// looked like nothing had happened, and the same item could be dropped
  /// again — and again — because the button was reading a stale list.
  ///
  /// One source of truth, and both the screen and this tree listen to it.
  final ValueNotifier<Inventory> _inventory = ValueNotifier(const Inventory());

  /// Item names, read alongside the catalogue (§1.1, §4.1).
  ItemNames? _names;

  /// What people left behind (§19.1), and what the map calls where the player
  /// is standing — the second is what fills the first in.
  NoteSet? _notes;
  PlaceNames _placeNames = PlaceNames.none;

  /// The loot layer (§10). Null until the tables have been read; it does
  /// nothing at all until there is an installed pack to read places out of.
  LootWorld? _world;

  /// What is standing on the map right now. Held here because the map view is
  /// rebuilt constantly and re-reading the tiles for every frame would keep the
  /// phone busy for no gain.
  List<LootBox> _boxes = const [];

  /// The search in progress (§10.2, §19.3), and when it was last advanced.
  ///
  /// ⚠️ Advanced on the wall clock and its own timer, not on the simulation's.
  /// The sim clock refuses to move when the device clock steps backwards
  /// (§2.1.1's rollback guard), and an NTP correction mid-walk therefore froze
  /// the countdown while the player stood there watching it. A search measures
  /// forty-five real seconds of a person standing in a street; that is what it
  /// should count.
  /// A notifier for the same reason the inventory is one: the inventory screen
  /// is a pushed route, and an action started from it has to be visible on it.
  final ValueNotifier<Search?> _search = ValueNotifier(null);
  DateTime? _searchTickedAt;
  Timer? _searchTimer;

  /// The very piece being eaten or drunk (§4.7), so a mouthful comes out of
  /// the bottle in hand rather than out of whichever one the list finds first.
  final ValueNotifier<CarriedItem?> _usingLine = ValueNotifier(null);

  /// §10.3: the bodies, with their pockets still in them.
  List<Remains> _remains = const [];

  /// §8: the shelter and the camps, as the save last had them.
  /// §8: listened to rather than passed by value — the shelter screen is a
  /// pushed route, and a pushed route handed a list keeps showing the list it
  /// opened with. Starting a build then left the counter at zero until
  /// somebody backed out and came in again.
  final ValueNotifier<List<Shelter>> _shelters = ValueNotifier(const []);

  /// §2.1a.3: when the last stretch of work on a site was credited.
  DateTime? _workedAt;

  /// §12: what the game has just said. Under the HUD, never over the menu.
  final ValueNotifier<List<Notice>> _notices = ValueNotifier(const []);

  /// §5.5, §6.1a: everything hostile that is out there, and what it is doing.
  ///
  /// Not persisted. A Walker is not a place — §6.4 makes them afresh whenever
  /// the game runs, so writing them down would only mean loading yesterday's
  /// fight onto a street the player has already left.
  CombatSession _combat = const CombatSession(seed: 0);

  /// When the enemies were last stepped, so a gap in the tick is a gap in
  /// their walk rather than a jump.
  DateTime? _combatAt;

  /// §5.5.1: the one being aimed at. One target for a firearm, and nothing
  /// takes its place when it dies.
  Aim _aim = const Aim();

  /// §6.2: when each of them last swung, so the interval between blows is the
  /// one on the table rather than one a frame.
  final Map<String, DateTime> _lastBlow = {};

  /// §5.4: when the player last swung. A blade has a swing time and swinging
  /// faster than the blade allows is not a thing a person can do.
  DateTime? _lastSwing;

  /// §5.3: what is in the weapon, as opposed to in the pack.
  int _loaded = 0;

  /// §5.5.4: a magazine change in progress, and the thing that can end it.
  Reload? _reload;

  /// What the last reconnaissance revealed, for §10.2.1's ten minutes.
  AreaKnowledge? _knowledge;

  /// What the player has put down and could come back for (§4.8).
  ///
  /// A notifier because the ground list is a pushed route: handed a copy, it
  /// would keep offering things already in the pack.
  final ValueNotifier<List<DroppedItem>> _dropped = ValueNotifier(const []);

  /// Where the player is, for the ground list to measure reach from as they
  /// move about the pile.
  final ValueNotifier<GeoPoint?> _standingAt = ValueNotifier(null);

  /// Procedural places the player has actually looked for (§10.2.3). A
  /// pharmacy is a building and is visible from the street; a wrecked car in a
  /// side road is not, until somebody stops and looks.
  final Set<String> _revealed = {};

  /// Both HUD bars read these. Zero without a catalogue, which only happens if
  /// every bundled data file failed to parse — a broken build, not a state the
  /// player can reach.
  double get _carriedKg =>
      _catalogue == null ? 0 : _inventory.value.massKg(_catalogue!);

  double get _carriedVolumeL =>
      _catalogue == null ? 0 : _inventory.value.volumeL(_catalogue!);

  double _capacityL(BodyProfile body) => _catalogue == null
      ? kPocketCapacityL
      : _inventory.value.limits(body, _catalogue!).capacityL;

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
    // The HUD bars and the search panel read the inventory too, so this tree
    // follows the same notifier the screen does.
    _inventory.addListener(_onInventoryChanged);
    // The map's own panel reads the action from this tree, so it follows the
    // same notifier the inventory screen does.
    _search.addListener(_onInventoryChanged);
    unawaited(_boot());
  }

  void _onInventoryChanged() {
    if (mounted) setState(() {});
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
    _notes = NoteSet.parse(
      await rootBundle.loadString('assets/data/notes.json'),
    );
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
      _inventory.value = loaded.inventory;
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
      // ⚠️ Sticky. A snapshot without a position is the phone having nothing
      // to say, not the player having vanished — and everything that reads
      // this measures *from* it, so a single blank frame put every enemy and
      // every lootbox off the map for as long as it lasted.
      final fix = snapshot.displayFix;
      if (fix != null) {
        _standingAt.value = GeoPoint(fix.latitude, fix.longitude);
      }
      unawaited(_checkRelocation(snapshot));
      unawaited(_settleShelters(snapshot));
      unawaited(_settleDown(snapshot));
      unawaited(_spawnLoot(snapshot));
      _advanceCombat(snapshot);
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

    await _reloadShelters();
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
          onDrop: (line, count) => unawaited(_drop(line, count)),
          onWear: (line) => unawaited(_wear(line)),
          onTakeOff: (line) => unawaited(_takeOff(line)),
          onUse: (line) => unawaited(_use(line)),
          onRead: _readNote,
          onDetails: (line) => unawaited(_showItemDetails(line)),
          action: _search,
          // Which piece, not which item: a half-eaten tin beside three whole
          // ones is one row being used and three that are not.
          usingLine: _usingLine,
          onCancelAction: _cancelSearch,
          onDevFill: kDevTools ? () => unawaited(_devFillPack()) : null,
        ),
      ),
    );
  }

  /// §4.2: one item's readings, and the one it would replace beside them.
  ///
  /// The choice a player actually faces is not "is this vest good" but "is it
  /// better than mine", and that question is unanswerable while the two numbers
  /// live on separate screens.
  Future<void> _showItemDetails(CarriedItem line) async {
    final catalogue = _catalogue;
    final item = catalogue?[line.itemId];
    if (catalogue == null || item == null) return;

    final wearable =
        BodySlot.fromWire(wearSlotOf(item)) != null ||
        item.kind == ItemKind.backpack;
    // This copy, not any copy with that id: the one already on the body is not
    // put on again, but its twin in the pack still can be.
    final worn = _inventory.value.worn.any((other) => identical(other, line));

    await showItemDetails(
      context,
      line: line,
      inventory: _inventory,
      catalogue: catalogue,
      names: _names ?? ItemNames.empty,
      onWear: wearable && !worn ? () => unawaited(_wear(line)) : null,
      wearLabel: L10n.of(context).inventoryWear,
      // The piece the sheet is showing now, not the one it was opened with:
      // each fit rebuilds the line, and the sheet stays open across them.
      onAttach: (current, part) => unawaited(_attach(current, part)),
      onDetach: (current, id) => unawaited(_detach(current, id)),
    );
  }

  /// §5.6.3: bolts something onto this very weapon.
  Future<void> _attach(CarriedItem line, CarriedItem part) async {
    final catalogue = _catalogue;
    if (catalogue == null) return;

    final before = _inventory.value;
    final after = before.attach(line, part, catalogue);

    // A refusal that looks exactly like a working button is the worst thing
    // this screen can do, and it is what the last two reports were about. If
    // nothing moved, say which rule said no.
    if (identical(after, before)) {
      final weapon = catalogue[line.itemId];
      final fitting = catalogue[part.itemId];
      if (!mounted) return;

      _say(
        weapon == null || fitting == null
            ? L10n.of(context).attachmentRefused
            : !fitsWeapon(fitting, weapon)
            ? L10n.of(context).attachmentWrongWeapon
            : line.attachments.contains(fitting.id)
            ? L10n.of(context).attachmentAlreadyOn
            : line.attachments.length >= attachmentSlots(weapon)
            ? L10n.of(context).attachmentNoRail
            : L10n.of(context).attachmentRefused,
      );
      return;
    }

    _inventory.value = after;
    await _saveInventory();
  }

  /// And takes it off again, back into the pack.
  Future<void> _detach(CarriedItem line, String attachmentId) async {
    final catalogue = _catalogue;
    final character = _character;
    if (catalogue == null || character == null) return;

    _inventory.value = _inventory.value.detach(
      line,
      attachmentId,
      catalogue,
      body: character.body,
    );
    await _saveInventory();
  }

  /// Developer builds only. Puts a plausible kit in the pack so the screen can
  /// be looked at on a phone before §10 gives the game a way to find anything.
  Future<void> _devFillPack() async {
    final character = _character;
    final catalogue = _catalogue;
    if (character == null || catalogue == null) return;

    var next = _inventory.value.packId == null
        ? _inventory.value.withPack('pack_daypack')
        : _inventory.value;
    for (final id in const [
      'cloth_winter_jacket',
      'cloth_boots',
      'armor_vest_soft',
    ]) {
      next = next.wear(id, catalogue);
    }
    for (final line in const [
      // Something to fire and something to fire from it: §5 cannot be tried
      // on a phone without both.
      ('weapon_rifle_545', 1),
      ('ammo_545x39', 60),
      ('att_red_dot', 1),
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

    _inventory.value = next;
    await _saveInventory();
  }

  /// §4.8: what leaves the pack lands on the ground and stays for a day.
  ///
  /// Which is the whole reason the two carry limits are a decision. If leaving
  /// something behind destroyed it, "this is too heavy" would always be
  /// answered by throwing it away, and nobody deliberates over that.
  Future<void> _drop(CarriedItem line, int count) async {
    final character = _character;
    final fix = _snapshot?.displayFix;
    // The copy that was pointed at, not any copy with that id: two knives at
    // different conditions are two different things to own.
    final next = _inventory.value.removeLine(line, count: count);
    if (character == null || next == null) return;

    _inventory.value = next;
    await _saveInventory();

    // No position, nowhere to put it. Better than inventing a place: a marker
    // where the player never stood is a walk taken for nothing.
    if (fix == null) return;

    final store = DroppedStore(widget.session.db);
    await store.drop(
      character.profile.id,
      DroppedItem(
        id: 0,
        itemId: line.itemId,
        count: count,
        condition: line.condition,
        pagesTotal: line.pagesTotal,
        pagesRead: line.pagesRead,
        position: GeoPoint(fix.latitude, fix.longitude),
        droppedAt: DateTime.now().toUtc(),
      ),
    );
    await _reloadDropped();
  }

  /// §4.4: puts something on, and what was in that slot comes off.
  ///
  /// A backpack is worn too (§4.5), and swapping one for another is the same
  /// gesture — so it goes through here rather than through a separate control
  /// nobody would look for.
  Future<void> _wear(CarriedItem line) async {
    final catalogue = _catalogue;
    if (catalogue == null) return;

    final definition = catalogue[line.itemId];
    if (definition == null) return;

    // The old pack goes into the new one, which is what actually happens when
    // somebody changes bags in a street — and it goes in whether or not it
    // fits, since the alternative is losing it.
    final next = definition.kind == ItemKind.backpack
        ? _inventory.value.wearPack(line)
        : _inventory.value.removeLine(line)?.wearLine(line, catalogue);
    if (next == null) return;

    _inventory.value = next;
    await _saveInventory();
  }

  /// §4.7: eats, drinks or dresses a wound, for as long as the data says.
  ///
  /// The time is the point. §2.1a calls these actions rather than occupations
  /// because they are short, but a player who wants to drink half a litre
  /// stands still for twenty-five seconds to do it, and that is a decision
  /// when something is walking towards them.
  Future<void> _use(CarriedItem line) async {
    final catalogue = _catalogue;
    final character = _character;
    final loop = _loop;
    if (catalogue == null || character == null || loop == null) return;
    if (_search.value != null) return;

    final definition = catalogue[line.itemId];
    final use = definition == null ? null : useOf(definition);
    if (definition == null || use == null) return;

    // §2.6: a dressing with nothing open to close is a dressing spent for
    // nothing, and there is no getting it back. Refused, and told why — the
    // way out of a low blood volume with nothing bleeding is food, water and
    // time, not another bandage.
    if (use.stopsBleedingTo != null && use.kcal == 0 && use.waterMl == 0) {
      if (loop.bleeding == BleedTier.none) {
        _say(L10n.of(context).inventoryNoWound);
        return;
      }
      // §2.6: down to the grade it can handle, not to nothing. A pressure
      // dressing on an arterial bleed is not a tourniquet.
      if (use.stopsBleedingTo!.index >= loop.bleeding.index) {
        _say(L10n.of(context).inventoryWrongDressing);
        return;
      }
    }

    final fix = _snapshot?.displayFix;
    // Half a bottle takes half as long to finish, which is what makes putting
    // it down and coming back to it a real option rather than a punishment.
    final seconds = (use.duration.inSeconds * line.portion).round();

    _usingLine.value = line;
    setState(() {
      _search.value = Search.using(
        at: fix == null
            ? const GeoPoint(0, 0)
            : GeoPoint(fix.latitude, fix.longitude),
        now: DateTime.now().toUtc(),
        itemId: line.itemId,
        duration: Duration(seconds: seconds < 1 ? 1 : seconds),
        label: use.action.label,
      );
    });
    _startSearchTimer();
  }

  /// The action finished: the item is gone and the body has it.
  Future<void> _finishUse(Search action) async {
    final catalogue = _catalogue;
    final loop = _loop;
    final itemId = action.usingItemId;
    if (catalogue == null || loop == null || itemId == null) return;

    final definition = catalogue[itemId];
    final use = definition == null ? null : useOf(definition);
    if (definition == null || use == null) return;

    // What was left of the piece, which is all that is left to swallow.
    final line = _usingLine.value;
    final portion = line?.portion ?? 1;
    _usingLine.value = null;

    if (use.consumesItem) {
      // The very piece that was in hand: a half bottle beside a full one is
      // two different things to own.
      final next = line == null
          ? _inventory.value.remove(itemId, count: 1)
          : _inventory.value.removeLine(line);
      if (next != null) {
        _inventory.value = next;
        await _saveInventory();
      }
    }

    loop.applyUse(kcal: use.kcal * portion, waterMl: use.waterMl * portion);

    // §2.6: what the dressing was for. After the item is gone, so an
    // interrupted one neither heals nor is consumed.
    final treats = use.stopsBleedingTo;
    if (treats != null) loop.treatBleeding(treats);

    if (!mounted) return;

    final language = Localizations.localeOf(context).languageCode;
    _say(
      L10n.of(context).inventoryUsed(
        definition.name.resolve(
          language: language,
          lookup: (_names ?? ItemNames.empty).forLanguage(language),
        ),
      ),
    );
  }

  /// §4.4: a worn piece comes off into the pack, never onto the ground.
  ///
  /// Taking a coat off and throwing it away are different decisions, and only
  /// one of them should be one tap away from a screen read in the dark.
  Future<void> _takeOff(CarriedItem line) async {
    _inventory.value = _inventory.value.takeOff(line.itemId);
    await _saveInventory();
  }

  Future<void> _reloadDropped() async {
    final character = _character;
    if (character == null) return;

    final items = await DroppedStore(
      widget.session.db,
    ).load(character.profile.id, DateTime.now().toUtc());
    if (!mounted) return;

    setState(() => _dropped.value = items);
  }

  /// Opens a note the player is carrying (§19.1).
  void _readNote(CarriedItem line) {
    final note = line.noteId == null ? null : _notes?[line.noteId!];
    if (note == null) return;

    unawaited(showNote(context, note: note, names: _placeNames));
  }

  /// What the panel says is underfoot: the nearest pile, and how much else
  /// there is behind it.
  String? _groundLabel() {
    final piles = _pilesInReach();
    if (piles.isEmpty) return null;

    final nearest = _labelFor(piles.first);
    return piles.length == 1 ? nearest : '$nearest  +${piles.length - 1}';
  }

  String? _labelFor(GroundPile pile) {
    final catalogue = _catalogue;
    if (catalogue == null || !mounted) return null;

    final definition = catalogue[pile.itemId];
    if (definition == null) return pile.itemId;

    final language = Localizations.localeOf(context).languageCode;
    final name = definition.name.resolve(
      language: language,
      lookup: (_names ?? ItemNames.empty).forLanguage(language),
    );
    return pile.count > 1 ? '$name ×${pile.count}' : name;
  }

  /// A tap on the map (§3.6): what the player wants to know about that dot.
  ///
  /// A yellow dot that says only "something is here" makes every dot worth the
  /// same walk, which makes none of them a decision.
  void _showMarker(MapMarker? marker) {
    final catalogue = _catalogue;
    final fix = _snapshot?.displayFix;
    if (catalogue == null || fix == null) return;
    final at = GeoPoint(fix.latitude, fix.longitude);

    // §5.5.1: a tap on empty street lets the target go. Aiming is where the
    // player's attention is, and pointing somewhere else is how a person says
    // they have stopped looking at something.
    if (marker == null) {
      if (_aim.hasTarget) setState(() => _aim = _aim.released);
      return;
    }

    if (marker.kind == MarkerKind.loot) {
      final box = _boxes.where((b) => b.poiId == marker.id).firstOrNull;
      if (box == null) return;

      unawaited(
        showPlaceDetails(
          context,
          box: box,
          table: _world?.tables[box.tableId],
          distanceM: box.position.distanceTo(at),
          catalogue: catalogue,
          now: _snapshot?.state.lastUpdate ?? DateTime.now().toUtc(),
        ),
      );
      return;
    }

    if (marker.kind == MarkerKind.enemy) {
      // §5.5.1: one tap, one target, and it costs the sight picture. The rest
      // of them carry on running — aiming is where attention goes, not a
      // pause button.
      setState(() {
        _aim = _aim.at(
          marker.id,
          now: DateTime.now(),
          settle: settleTime(
            heartRate: _snapshot?.state.heartRateBpm ?? 70,
            rest: _character?.constants.restingHeartRate ?? 70,
            max: _character?.constants.maxHeartRate ?? 190,
          ),
        );
      });
      return;
    }

    if (marker.kind == MarkerKind.remains) {
      final id = marker.id.substring('remains.'.length);
      final body = _remains.where((b) => b.id == id).firstOrNull;
      if (body == null) return;

      unawaited(
        showRemains(
          context,
          kindName: enemyKindName(L10n.of(context), body.kind),
          distanceM: body.position.distanceTo(at),
          searched: body.searched,
          onSearch: body.searched || body.position.distanceTo(at) > kStillnessM
              ? null
              : () => unawaited(_searchRemains(body)),
        ),
      );
      return;
    }

    if (marker.kind == MarkerKind.dropped) {
      final id = int.tryParse(marker.id.split('.').last);
      final item = _dropped.value.where((i) => i.id == id).firstOrNull;
      if (item == null) return;

      unawaited(
        showItemDetails(
          context,
          line: CarriedItem(
            itemId: item.itemId,
            count: item.count,
            condition: item.condition,
            pagesTotal: item.pagesTotal,
            pagesRead: item.pagesRead,
          ),
          inventory: _inventory,
          catalogue: catalogue,
          names: _names ?? ItemNames.empty,
        ),
      );
    }
  }

  /// Everything at the player's feet, gathered into piles (§4.8).
  List<GroundPile> _pilesInReach() {
    final at = _standingAt.value;
    if (at == null) return const [];
    return pilesWithin(_dropped.value, at, reachM: kStillnessM);
  }

  /// Opens the heap at the player's feet.
  ///
  /// Always the list, even for one pile. The panel no longer names what is
  /// down there — a glyph and the map are worth more than a line of text — so
  /// taking it on the strength of the icon alone would be picking something up
  /// without being told what it is.
  void _openGround() {
    if (_pilesInReach().isEmpty) return;

    unawaited(
      showGroundItems(
        context,
        dropped: _dropped,
        at: _standingAt,
        reachM: kStillnessM,
        catalogue: _catalogue!,
        names: _names ?? ItemNames.empty,
        onTake: (pile) => unawaited(_takePile(pile)),
        onDetails: (pile) => unawaited(
          showItemDetails(
            context,
            line: CarriedItem(
              itemId: pile.itemId,
              count: pile.count,
              condition: pile.condition,
              pagesTotal: pile.pagesTotal,
              pagesRead: pile.pagesRead,
            ),
            inventory: _inventory,
            catalogue: _catalogue!,
            names: _names ?? ItemNames.empty,
          ),
        ),
      ),
    );
  }

  /// Picks up a whole pile, nearest row first.
  ///
  /// It stops at the first row that will not fit rather than skipping past it
  /// to something smaller: a player who is out of room should be told, not
  /// quietly given the lighter half of what they asked for.
  Future<void> _takePile(GroundPile pile) async {
    for (final part in pile.parts) {
      final before = _inventory.value;
      await _takeDropped(part);
      if (identical(_inventory.value, before)) return;
    }
  }

  /// Picks a pile back up, if it fits (§18.1a).
  Future<void> _takeDropped(DroppedItem item) async {
    final character = _character;
    final catalogue = _catalogue;
    if (character == null || catalogue == null) return;

    final result = _inventory.value.add(
      item.itemId,
      catalogue,
      body: character.body,
      count: item.count,
      condition: item.condition,
      pagesTotal: item.pagesTotal,
    );
    if (!result.isAccepted && (result.acceptedCount ?? 0) == 0) {
      if (mounted) _say(L10n.of(context).droppedNoRoom);
      return;
    }

    _inventory.value = result.inventory;
    await _saveInventory();

    // Removed only once it is in the pack, and only as much of it as went in.
    // Deleting first and finding it did not fit — or deleting the whole pile
    // when two of five pieces fitted — would be the game destroying something
    // on the player's behalf.
    final taken = result.acceptedCount ?? item.count;
    await DroppedStore(
      widget.session.db,
    ).takeSome(item.id, left: item.count - taken);
    if (taken < item.count && mounted) _say(L10n.of(context).droppedNoRoom);
    await _reloadDropped();
  }

  Future<void> _saveInventory() async {
    final character = _character;
    if (character == null) return;
    await InventoryStore(
      widget.session.db,
    ).save(character.profile.id, _inventory.value);
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
    await _reloadDropped();
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

    setState(() {
      _boxes = plan.boxes;
      _placeNames = plan.names;
    });
  }

  /// §6.1a: one step of the fight, driven by the same tick as everything else.
  ///
  /// §11 already decides how much time has passed and hands it over; a fight
  /// with a timer of its own would keep running with the app closed, which is
  /// exactly what §2.1a says an occupation must not do.
  void _advanceCombat(GameSnapshot snapshot) {
    final character = _character;
    final fix = snapshot.displayFix;
    if (character == null || fix == null) return;

    final now = snapshot.state.lastUpdate;
    final since = _combatAt;
    _combatAt = now;

    final elapsed = since == null ? Duration.zero : now.difference(since);

    // ⚠️ No time passed is not the same as a gap. Found on a phone: the
    // enemies kept vanishing, because a snapshot can be published without the
    // simulation clock having moved — a position update does it — and the two
    // cases were treated alike. Emptying the street on those wiped everything
    // out from under the player every few seconds.
    if (elapsed <= Duration.zero) {
      if (since != null) return;

      // A first tick: nothing to walk through, but the street is whatever it
      // already was rather than nothing.
      setState(() {
        _combat = CombatSession(
          seed: character.profile.rngSeed,
          enemies: _combat.enemies,
          open: _combat.open,
        );
      });
      return;
    }

    // One after the app was away. §11.1.2 replays a gap for the body, because
    // a body keeps burning calories in a pocket; a street does not. What a
    // Walker did during eight hours of sleep is not knowable, so the street is
    // emptied and made again rather than guessed at.
    if (elapsed > kCombatGapForgotten) {
      setState(() {
        _combat = CombatSession(seed: character.profile.rngSeed);
        _aim = const Aim();
      });
      return;
    }

    // §9.2: they took you for dead. Nothing swings at somebody on the ground,
    // and nothing swings for ten minutes after they get up — which is the
    // valve against waking inside a hotspot and going straight back down.
    if ((_loop?.down ?? DownState.none) == DownState.none) {
      _takeBlows(GeoPoint(fix.latitude, fix.longitude), now);
    }
    _advanceReload(GeoPoint(fix.latitude, fix.longitude));

    setState(() {
      // §10.3: bodies nobody came back for stop being worth drawing.
      _remains = sweepRemains(_remains, now);
      _combat = _combat.advance(
        playerAt: GeoPoint(fix.latitude, fix.longitude),
        elapsed: elapsed,
        now: now,
        // §10.3: whatever bled out on the way leaves a body, exactly as one
        // that went down under the sights does.
        onDeath: _remember,
        obstacles: _world?.obstacles ?? const [],
        // §8.1: they wait at the edge of what the player built.
        sanctuaries: _sanctuaries,
        shelterAt: _shelters.value
            .where((s) => s.kind == ShelterKind.main)
            .firstOrNull
            ?.position,
        // §5.6.1: walls that swallow a shot swallow a silhouette too.
        denseUrban: _world?.denseUrban ?? false,
      );
    });
  }

  /// §5.5.1: the thing currently aimed at, if it is still out there.
  Enemy? get _target {
    final id = _aim.targetId;
    if (id == null) return null;

    for (final enemy in _combat.enemies) {
      if (enemy.id == id && !enemy.isDead) return enemy;
    }
    return null;
  }

  /// What is in the hand, if it is something that fires (§5.5.1).
  ItemDefinition? get _weapon {
    final catalogue = _catalogue;
    if (catalogue == null) return null;

    for (final line in _inventory.value.worn) {
      final item = catalogue[line.itemId];
      if (item != null && item.kind == ItemKind.firearm) return item;
    }
    return null;
  }

  /// §5.6.3: what is carried that fits the weapon in hand.
  ///
  /// ⚠️ Fitted because it fits. Which attachment is actually on which weapon
  /// is per-weapon state, and that is the schema change the magazine is
  /// already waiting for in stage 8.
  List<ItemDefinition> _attachmentsFor(ItemDefinition weapon) {
    final catalogue = _catalogue;
    if (catalogue == null) return const [];

    // What is on this weapon, not what is in the pack. Two rifles in one bag
    // are two rifles: the one with the suppressor is the one worth carrying
    // into a town (§5.6.3).
    final line = _wieldedLine;
    if (line == null) return const [];

    return [
      for (final id in line.attachments)
        if (catalogue[id] != null) catalogue[id]!,
    ];
  }

  /// The very piece in the hand, rather than its definition.
  CarriedItem? get _wieldedLine {
    final catalogue = _catalogue;
    if (catalogue == null) return null;

    for (final line in _inventory.value.worn) {
      if (catalogue[line.itemId]?.kind == ItemKind.firearm) return line;
    }
    return null;
  }

  /// A round that fits it, out of the pack (§10.3.3: the calibre string is the
  /// whole reason ammunition is a resource rather than a number).
  CarriedItem? _roundFor(ItemDefinition weapon) {
    final catalogue = _catalogue;
    final calibre = weapon.props['caliber'];
    if (catalogue == null || calibre == null) return null;

    for (final line in _inventory.value.carried) {
      final item = catalogue[line.itemId];
      if (item?.kind == ItemKind.ammo && item?.props['caliber'] == calibre) {
        return line;
      }
    }
    return null;
  }

  /// Which round is in the weapon, for §5.1.5's wound channel.
  ///
  /// Whatever of that calibre is nearest to hand. A player carrying buckshot
  /// and slugs is carrying one kind of shotgun ammunition as far as this is
  /// concerned, which is a simplification worth revisiting when there is a
  /// reason to choose.
  ItemDefinition? _loadedRound(ItemDefinition weapon) {
    final catalogue = _catalogue;
    final line = _roundFor(weapon);
    if (catalogue == null || line == null) return null;

    return catalogue[line.itemId];
  }

  /// §5.1.4: the odds, worked out exactly once and shown before they are used.
  ShotError? _aimError(Enemy target) {
    final character = _character;
    final weapon = _weapon;
    final snapshot = _snapshot;
    if (character == null || weapon == null || snapshot == null) return null;

    return aimError(
      weapon: weapon,
      attachments: _attachmentsFor(weapon),
      // §7's Marksmanship does not exist yet, so everybody is a novice — which
      // is §5.1.2's first row and the one the balance is built on.
      skill: 0,
      heartRate: snapshot.state.heartRateBpm,
      restingHr: character.constants.restingHeartRate,
      maxHr: character.constants.maxHeartRate,
      playerSpeedKmh: (snapshot.fix?.speedMps ?? 0) * 3.6,
      targetSpeedKmh: target.speedKmh,
      spreadMultiplier: _aim.spreadMultiplierAt(DateTime.now()),
    );
  }

  /// One round, one roll, and everything it costs (§5.1, §5.1.5, §5.6).
  Future<void> _fire() async {
    final character = _character;
    final catalogue = _catalogue;
    final target = _target;
    final weapon = _weapon;
    final fix = _snapshot?.displayFix;
    if (character == null ||
        catalogue == null ||
        target == null ||
        weapon == null ||
        fix == null) {
      return;
    }

    final error = _aimError(target);
    if (_loaded <= 0 || error == null) return;

    final at = GeoPoint(fix.latitude, fix.longitude);
    final outcome = fireAt(
      weapon: weapon,
      ammo: _loadedRound(weapon),
      attachments: _attachmentsFor(weapon),
      target: target,
      distanceM: target.position.distanceTo(at),
      error: error,
      random: Random(),
      // §5.6.1: a built-up street in daylight takes a third off what is heard.
      denseUrban: _world?.denseUrban ?? false,
      night: false,
    );

    // The round is gone whatever happened to the shot.
    setState(() => _loaded -= 1);
    if (!mounted) return;

    final l10n = L10n.of(context);
    setState(() {
      var session = _combat;
      if (outcome.hit) {
        session = session.wound(
          target.id,
          outcome.bloodLossMl,
          bleeding: outcome.bleedMlPerSecond,
        );
      }

      // §10.3: a body, not a heap. What it was carrying stays in its pockets
      // until somebody walks over and puts a hand in them — dropping it on
      // the ground would answer, from two hundred metres off, the one
      // question worth walking over to answer.
      final down = session.enemies.where((e) => e.id == target.id).firstOrNull;
      if (down != null && down.isDead) _remember(down);

      // §5.6: heard whether or not it hit, from where it was fired.
      session = session.heard(
        NoiseEvent(
          at: at,
          radiusM: outcome.noiseM,
          startedAt: DateTime.now().toUtc(),
        ),
        playerAt: at,
      );
      _combat = session;

      // §5.5.1: nothing takes the place of a target that has gone down.
      final still = session.enemies.where((e) => e.id == target.id).firstOrNull;
      if (still == null || still.isDead) _aim = _aim.released;
    });

    // §2.6: where it landed and what it opened. A head shot that ends it is
    // worth saying as an execution; a leg that keeps bleeding is worth saying
    // because it changes whether to run or to stay.
    final down = _combat.enemies.where((e) => e.id == target.id).firstOrNull;
    _say(
      !outcome.hit
          ? l10n.combatMiss
          : down == null || down.isDead
          ? (outcome.location == HitLocation.head
                ? l10n.combatExecution
                : l10n.combatDown)
          : l10n.combatHitAt(
              hitLocationName(l10n, outcome.location!),
              outcome.bloodLossMl.round(),
            ),
    );
  }

  /// §5.2, §5.5.3: everything in reach swings, and being surrounded hurts.
  ///
  /// Below twenty metres §5.2 stops pretending GPS knows where anybody is
  /// standing and settles it abstractly, which is what this is: no positions,
  /// no facing, just how many of them are on you and how often each can swing.
  void _takeBlows(GeoPoint at, DateTime now) {
    final loop = _loop;
    final catalogue = _catalogue;
    if (loop == null || catalogue == null) return;

    final inReach = [
      for (final enemy in _combat.enemies)
        if (!enemy.isDead && enemy.position.distanceTo(at) <= kMeleeM) enemy,
    ];
    if (inReach.isEmpty) {
      _lastBlow.clear();
      return;
    }

    // §5.5.3: the player answers one of them and the rest swing freely, which
    // is why letting a group close is very nearly a sentence.
    final crowding = flankingMultiplier(inReach.length);
    var taken = 0.0;
    HitLocation? worst;

    for (final enemy in inReach) {
      final last = _lastBlow[enemy.id];
      if (last != null && now.difference(last) < enemy.kind.attackInterval) {
        continue;
      }
      _lastBlow[enemy.id] = now;

      // §2.6: teeth and hands land where they land. A bite to the arm the
      // player put up is not the bite that takes them down, and the log is
      // where the difference gets said.
      final where = rollHitLocation(Random().nextDouble());
      if (worst == null || where.multiplier > worst.multiplier) worst = where;

      // §4.4: armour reduces a blow only where it covers, and a bite is blunt.
      final protection = _inventory.value.protectionAgainst(
        catalogue: catalogue,
        slot: 'torso_armor',
        hitRoll: Random().nextDouble(),
        blunt: true,
      );

      taken +=
          enemy.kind.damageMl *
          crowding *
          where.multiplier *
          (1 - protection.clamp(0, 1) / 5);
    }

    if (taken <= 0 || worst == null) return;

    // §2.6: teeth and nails leave something open. A moderate bleed is what a
    // pressure dressing answers — which is the whole reason to carry one, and
    // the reason walking away from a clinch is not the end of the fight.
    loop.applyWound(
      taken,
      bleeding: worst == HitLocation.head || worst == HitLocation.torso
          ? BleedTier.moderate
          : BleedTier.superficial,
    );
    _say(
      L10n.of(
        context,
      ).combatHurtAt(hitLocationName(L10n.of(context), worst), taken.round()),
    );
  }

  /// §5.5.4: the magazine goes in, unless something gets to the player first.
  void _advanceReload(GeoPoint at) {
    final reload = _reload;
    final weapon = _weapon;
    final catalogue = _catalogue;
    if (reload == null || weapon == null || catalogue == null) return;

    // ⚠️ Whatever it is doing. Hands stop when a body is that close, and the
    // game is not going to argue about intent.
    final tooClose = reloadBrokenBy([
      for (final enemy in _combat.enemies)
        if (!enemy.isDead) enemy.position.distanceTo(at),
    ]);

    if (tooClose) {
      setState(() => _reload = null);
      _say(L10n.of(context).combatReloadBroken);
      return;
    }

    if (!reload.isDoneAt(DateTime.now())) return;

    final rounds = roundsToLoad(
      weapon: weapon,
      attachments: _attachmentsFor(weapon),
      loaded: _loaded,
      carried: _roundsCarried(weapon),
    );
    if (rounds <= 0) {
      setState(() => _reload = null);
      return;
    }

    // The rounds leave the pack as they go into the weapon, so a magazine is
    // never both in the rifle and in the bag.
    var inventory = _inventory.value;
    for (var i = 0; i < rounds; i++) {
      final line = _roundFor(weapon);
      if (line == null) break;
      inventory = inventory.removeLine(line) ?? inventory;
    }

    setState(() {
      _inventory.value = inventory;
      _loaded += rounds;
      _reload = null;
    });
    unawaited(_saveInventory());
  }

  /// Starts a magazine change (§5.3).
  void _startReload() {
    final weapon = _weapon;
    if (weapon == null || _reload != null) return;
    if (_roundsCarried(weapon) <= 0) return;

    setState(() {
      _reload = Reload(
        weaponId: weapon.id,
        readyAt: DateTime.now().add(
          reloadTime(weapon, attachments: _attachmentsFor(weapon)),
        ),
      );
    });
  }

  /// How many rounds of the right calibre are in the pack (§10.3.3).
  int _roundsCarried(ItemDefinition weapon) {
    final catalogue = _catalogue;
    final calibre = weapon.props['caliber'];
    if (catalogue == null || calibre == null) return 0;

    var rounds = 0;
    for (final line in _inventory.value.carried) {
      final item = catalogue[line.itemId];
      if (item?.kind == ItemKind.ammo && item?.props['caliber'] == calibre) {
        rounds += line.count;
      }
    }
    return rounds;
  }

  /// §5.4: hands, or whatever is in them.
  ///
  /// Computational rather than a test of thumbs (§5.4's own recommendation for
  /// the MVP): the decision was made when the player let something get within
  /// twenty metres, not in the tap that follows.
  Future<void> _strike() async {
    final character = _character;
    final catalogue = _catalogue;
    final target = _target;
    final fix = _snapshot?.displayFix;
    if (character == null ||
        catalogue == null ||
        target == null ||
        fix == null) {
      return;
    }

    final blade = _meleeInHand;
    final swing = Duration(
      milliseconds:
          (((blade?.props['swing_seconds'] as num?)?.toDouble() ?? 1.4) * 1000)
              .round(),
    );

    final now = DateTime.now();
    final last = _lastSwing;
    if (last != null && now.difference(last) < swing) return;
    _lastSwing = now;

    final limits = _inventory.value.limits(character.body, catalogue);
    final chance = meleeHitChance(
      // §7's Melee skill does not exist yet, so everybody swings like a
      // novice — which is §5.4's own baseline.
      skill: 0,
      carriedKg: _carriedKg,
      maxCarryKg: limits.maxKg,
      fatigue:
          character.constants.maxHeartRate <=
              character.constants.restingHeartRate
          ? 0
          : ((_snapshot?.state.heartRateBpm ?? 70) -
                    character.constants.restingHeartRate) /
                (character.constants.maxHeartRate -
                    character.constants.restingHeartRate),
    );

    final landed = Random().nextDouble() < chance;
    final where = rollHitLocation(Random().nextDouble());
    final damage =
        ((blade?.props['blood_ml_per_hit'] as num?)?.toDouble() ?? 40) *
        where.multiplier;

    setState(() {
      // §2.6: a blade opens what it lands in, and a throat opened is a fight
      // that finishes itself.
      if (landed) {
        _combat = _combat.wound(
          target.id,
          damage,
          bleeding: switch (where) {
            HitLocation.head => 5,
            HitLocation.torso => 3,
            _ => 1,
          },
        );
      }

      // §5.6.1: hands and a blade are twenty-five metres of noise, which is
      // the whole reason to use them.
      _combat = _combat.heard(
        NoiseEvent(
          at: GeoPoint(fix.latitude, fix.longitude),
          radiusM: NoiseKind.melee.baseM,
          startedAt: DateTime.now().toUtc(),
        ),
        playerAt: GeoPoint(fix.latitude, fix.longitude),
      );

      final still = _combat.enemies.where((e) => e.id == target.id).firstOrNull;
      if (still == null || still.isDead) {
        if (still != null) _remember(still);
        _aim = _aim.released;
      }
    });

    if (!mounted) return;
    final left = _combat.enemies.where((e) => e.id == target.id).firstOrNull;
    _say(
      !landed
          ? L10n.of(context).combatMiss
          : left == null || left.isDead
          ? (where == HitLocation.head
                ? L10n.of(context).combatExecution
                : L10n.of(context).combatDown)
          : L10n.of(context).combatHitAt(
              hitLocationName(L10n.of(context), where),
              damage.round(),
            ),
    );
  }

  /// What is in the hand, if it is something to swing (§5.4).
  ItemDefinition? get _meleeInHand {
    final catalogue = _catalogue;
    if (catalogue == null) return null;

    for (final line in _inventory.value.worn) {
      final item = catalogue[line.itemId];
      if (item != null && item.kind == ItemKind.melee) return item;
    }
    return null;
  }

  /// §10.3: marks where something went down.
  /// Everything the player can do standing exactly here (§10.2, §19.3, §4.8).
  ///
  /// Built in one place because it is drawn in two: on its own when nothing is
  /// in the sights, and stacked over the combat panel when something is.
  Widget _actionPanel(BuildContext context) {
    final box = _boxInReach();

    return SearchPanel(
      search: _search.value,
      targetName: box?.name,
      canSearchHere: box != null,
      // §10.3.5: how much of this place is left to turn over, so the panel can
      // grey out a pass there is no longer room for.
      searchUnitsLeft: box?.searchUnitsLeft ?? 0,
      barrier: _barrierOn(box),
      carried: _carriedIds(),
      onSearchArea: _startAreaSearch,
      onSearchHere: _startObjectSearch,
      onBreach: _startBreach,
      droppedLabel: _groundLabel(),
      // Only with something actually underfoot. Found on a walk: the glyph
      // stayed on the panel from anywhere, so "can I pick that up from here"
      // was answered by pressing it and finding out.
      onTakeDropped: _catalogue == null || _pilesInReach().isEmpty
          ? null
          : _openGround,
      onCancel: _cancelSearch,
    );
  }

  // --------------------------------------------------------------- death ---

  /// §9: everything that happens once, at the moment the body gives out.
  ///
  /// The loop decides *when* — it is the only thing that knows whether the
  /// phone is asleep or has lost the sky, and §9.1 makes both of those reasons
  /// a character may not die. This is the rest of it: what the character
  /// leaves behind, and what the save has to remember.
  Future<void> _settleDown(GameSnapshot snapshot) async {
    final loop = _loop;
    final character = _character;
    if (loop == null || character == null) return;

    if (loop.takeWentDown()) {
      // §5.5.1: nothing is aimed at any more, and nothing is being searched.
      setState(() {
        _aim = _aim.released;
        _search.value = null;
        _usingLine.value = null;
      });

      if (loop.down == DownState.dead) {
        await _factory.recordDeath(
          character: character,
          cause: (loop.deathCause ?? DeathCause.bloodLoss).wire,
          now: snapshot.state.lastUpdate,
        );
      } else {
        await _scatterKit(snapshot);
      }
    }

    if (loop.takeJustWoke()) {
      await _saveInventory();
      if (mounted) _say(L10n.of(context).downCaches);
    }
  }

  /// §9.2: the weapon in the hands is gone, and half of the rest is on the
  /// ground where the character fell.
  ///
  /// Caches rather than a wipe, and they stay where the body fell rather than
  /// following the player: §9.2.1 makes that the whole balance of the mode —
  /// the penalty grows with how far the player has moved since, and no rule
  /// had to be written to make it do that.
  Future<void> _scatterKit(GameSnapshot snapshot) async {
    final character = _character;
    final catalogue = _catalogue;
    final fix = snapshot.displayFix;
    if (character == null || catalogue == null || fix == null) return;

    final at = GeoPoint(fix.latitude, fix.longitude);
    final random = Random(
      character.profile.rngSeed ^ snapshot.state.lastUpdate.hashCode,
    );
    final store = DroppedStore(widget.session.db);

    var pack = _inventory.value;

    // Whatever was in the hands is simply gone. §9.2 is explicit, and it is
    // what stops a deliberate death being a cheap way home.
    for (final line in [...pack.worn]) {
      final item = catalogue[line.itemId];
      if (item == null) continue;
      if (item.kind == ItemKind.firearm || item.kind == ItemKind.melee) {
        pack = pack.removeLine(line, count: line.count) ?? pack;
      }
    }

    // Half of the rest, by the piece rather than by the count: losing three of
    // five bandages and keeping two is what §9.2 describes.
    for (final line in [...pack.carried]) {
      if (random.nextDouble() >= kWakeLossFraction) continue;

      pack = pack.removeLine(line, count: line.count) ?? pack;
      await store.drop(
        character.profile.id,
        DroppedItem(
          id: 0,
          itemId: line.itemId,
          count: line.count,
          condition: line.condition,
          // Two or three caches in thirty to a hundred metres, so getting it
          // back is a walk rather than a button.
          position: at.offsetBy(
            metres: 30 + random.nextDouble() * 70,
            bearingDeg: random.nextDouble() * 360,
          ),
          droppedAt: DateTime.now().toUtc(),
        ),
      );
    }

    _inventory.value = pack;
    await _saveInventory();
    await _reloadDropped();
  }

  /// §9.1: a new character in the same body.
  Future<void> _startOver(ActiveCharacter dead) async {
    // The creator keeps height, weight, age and sex — it is still the player's
    // own body, and sitting through the measurements again would be theatre.
    setState(() {
      _character = null;
      _loop = null;
    });
    await _loop?.dispose();
    if (mounted) await _boot();
  }

  // ------------------------------------------------------------- shelter ---

  /// §8.1: the circles the fight does not happen inside.
  List<Sanctuary> get _sanctuaries => [
    for (final place in _shelters.value)
      if (place.isReadyAt(DateTime.now().toUtc()))
        Sanctuary(at: place.position, radiusM: place.kind.safeRadiusM),
  ];

  /// §8: what has been built, from the save.
  Future<void> _reloadShelters() async {
    final character = _character;
    if (character == null) return;

    final places = await ShelterStore(
      widget.session.db,
    ).load(character.profile.id, DateTime.now().toUtc());
    if (!mounted) return;

    setState(() => _shelters.value = [...places]);
    _loop?.setShelters(places);
  }

  /// Re-reads them when something they depend on has moved on.
  ///
  /// Cheap and rare: only when a building finished, or when the player has
  /// walked into one — §8.5.2's clock on a camp restarts on a visit, and a
  /// visit is not an event the loop can raise on its own.
  Future<void> _settleShelters(GameSnapshot snapshot) async {
    if (_shelters.value.isEmpty) return;

    final now = snapshot.state.lastUpdate;
    final fix = snapshot.displayFix;
    final at = fix == null ? null : GeoPoint(fix.latitude, fix.longitude);

    // §2.1a.3: work only happens on the site. A stretch of standing there is
    // spent on whatever is going up; a stretch anywhere else buys nothing, so
    // a player cannot start a nine-hour workshop and walk to the next town.
    final since = _workedAt;
    _workedAt = now;
    if (at != null && since != null && now.isAfter(since)) {
      final spent = now.difference(since);
      var wrote = false;

      final places = [..._shelters.value];
      for (var i = 0; i < places.length; i++) {
        final place = places[i];
        if (!place.atSite(at)) continue;
        if (place.buildLeft == null && place.buildingLeft == null) continue;
        if (place.buildLeft == Duration.zero &&
            (place.buildingLeft ?? Duration.zero) == Duration.zero) {
          continue;
        }

        final worked = place.worked(spent);
        places[i] = worked;
        _shelters.value = [...places];
        await ShelterStore(widget.session.db).saveWork(worked);
        wrote = true;
      }
      if (wrote) await _reloadShelters();
    }

    final finished = _shelters.value.any(
      (place) =>
          place.building != null &&
          (place.buildingLeft ?? Duration.zero) <= Duration.zero,
    );

    final inside = at == null
        ? null
        : shelterAt(at, _shelters.value, now: now);
    final stale =
        inside != null &&
        (inside.visitedAt == null ||
            now.difference(inside.visitedAt!) > const Duration(hours: 1));

    if (!finished && !stale) return;

    if (stale) {
      await ShelterStore(widget.session.db).visited(inside.id, now);
    }
    await _reloadShelters();
  }

  Future<void> _openShelter() async {
    final character = _character;
    final catalogue = _catalogue;
    if (character == null || catalogue == null) return;

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ShelterScreen(
            shelters: _shelters,
            standingAt: _standingAt,
            carried: _carriedCounts(),
            itemNameOf: (id) {
              final definition = catalogue[id];
              if (definition == null) return id;

              final language = Localizations.localeOf(context).languageCode;
              return definition.name.resolve(
                language: language,
                lookup: (_names ?? ItemNames.empty).forLanguage(language),
              );
            },
            hasTools: _carries('tool_hammer') || _carries('tool_axe'),
            hasHammer: _carries('tool_hammer'),
            hasMultitool: _carries('tool_multitool'),
            onBuild: (kind) => unawaited(_buildShelter(kind)),
            onBuildModule: (module) => unawaited(_buildModule(module)),
          ),
      ),
    );
    await _reloadShelters();
  }

  /// §8.3: starts the work where the player is standing.
  ///
  /// ⚠️ That is, in practice, their home address (§8.2). It goes in the local
  /// save and nowhere else — `allowBackup` is off for the whole database.
  Future<void> _buildShelter(ShelterKind kind) async {
    final character = _character;
    final at = _standingAt.value;
    if (character == null || at == null) return;

    if (kind == ShelterKind.camp) {
      final refusal = campRefusalAt(at, existing: _shelters.value);
      if (refusal != null) return;
      if (missingFor(kCampMaterials, _carriedCounts()).isNotEmpty) return;

      await _spendMaterials(kCampMaterials);
    }

    await ShelterStore(widget.session.db).begin(
      character.profile.id,
      kind: kind,
      at: at,
      now: DateTime.now().toUtc(),
      buildTime: buildTimeFor(
        kind,
        hasTools: _carries('tool_hammer') || _carries('tool_axe'),
      ),
    );

    await _reloadShelters();
    if (!mounted) return;
    _say(L10n.of(context).shelterBuildStarted);
  }

  /// §8.4, §18.2: one level onto one module, against the clock.
  Future<void> _buildModule(ShelterModule module) async {
    final shelter = _shelters.value
        .where((place) => place.kind == ShelterKind.main)
        .firstOrNull;
    if (shelter == null || shelter.building != null) return;

    final recipe = nextLevelOf(module, have: shelter.levelOf(module));
    if (recipe == null) return;

    final hammer = _carries('tool_hammer');
    final multitool = _carries('tool_multitool');
    if (!toolsAllow(recipe, hasHammer: hammer, hasMultitool: multitool)) return;
    if (missingFor(recipe.materials, _carriedCounts()).isNotEmpty) return;

    // §2.1a.3: you have to be standing in it to build onto it.
    final at = _standingAt.value;
    if (at == null || !shelter.atSite(at)) {
      _say(L10n.of(context).shelterNotHere);
      return;
    }

    final work = moduleWork(
      recipe,
      hasHammer: hammer,
      hasMultitool: multitool,
      workshopLevel: shelter.levelOf(ShelterModule.workshop),
    );

    await _spendMaterials(recipe.materials);
    await ShelterStore(widget.session.db).beginModule(
      shelter.id,
      module: module,
      level: recipe.level,
      readyAt: DateTime.now().toUtc().add(work),
      work: work,
    );

    await _reloadShelters();
    if (!mounted) return;
    _say(L10n.of(context).shelterBuildStarted);
  }

  /// Takes what a build costs out of the pack (§18.2).
  Future<void> _spendMaterials(Map<String, int> materials) async {
    var pack = _inventory.value;

    for (final entry in materials.entries) {
      var left = entry.value;
      while (left > 0) {
        final line = pack.carried
            .where((piece) => piece.itemId == entry.key)
            .firstOrNull;
        if (line == null) break;

        final taken = line.count < left ? line.count : left;
        pack = pack.removeLine(line, count: taken) ?? pack;
        left -= taken;
      }
    }

    _inventory.value = pack;
    await _saveInventory();
  }

  /// How many of each thing is in the pack, which is what §18.2 counts in.
  Map<String, int> _carriedCounts() {
    final counts = <String, int>{};
    for (final line in _inventory.value.carried) {
      counts[line.itemId] = (counts[line.itemId] ?? 0) + line.count;
    }
    return counts;
  }

  bool _carries(String itemId) => _carriedIds().contains(itemId);

  /// An item's name in the player's language.
  String _nameOfItem(ItemDefinition item) {
    final language = Localizations.localeOf(context).languageCode;
    return item.name.resolve(
      language: language,
      lookup: (_names ?? ItemNames.empty).forLanguage(language),
    );
  }

  /// §10.3: marks where something went down, for as long as it is worth
  /// coming back to.
  void _remember(Enemy enemy) {
    _remains = addRemains(
      _remains,
      Remains(
        id: enemy.id,
        kind: enemy.kind,
        position: enemy.position,
        diedAt: DateTime.now().toUtc(),
      ),
    );
  }

  /// §10.3: turns out the pockets of the body in reach.
  ///
  /// Only from arm's length, and only once. What comes out lands on the ground
  /// where it fell, which is the same pile machinery §4.8 already has — the
  /// difference is that nobody could see it from across the street.
  Future<void> _searchRemains(Remains body) async {
    final at = _standingAt.value;
    if (at == null || body.searched) return;
    if (body.position.distanceTo(at) > kStillnessM) return;

    setState(() {
      _remains = [
        for (final other in _remains)
          other.id == body.id ? other.emptied : other,
      ];
    });

    await _leaveRemainsOf(body);
    if (!mounted) return;
    _say(L10n.of(context).remainsSearched);
  }

  /// §4.8, §10.3: what is left where something went down.
  ///
  /// Not a loot table of its own: a Walker was a person with pockets, so it is
  /// the scraps §18.2 already knows about plus, rarely, whatever it was
  /// carrying. Seeded from the enemy, so the same body always held the same
  /// thing however many times the app is restarted over it.
  Future<void> _leaveRemainsOf(Remains body) async {
    final character = _character;
    if (character == null) return;

    final random = Random(character.profile.rngSeed ^ body.id.hashCode);
    final drops = <String>[
      if (random.nextDouble() < 0.55) 'mat_fabric',
      if (random.nextDouble() < 0.30) 'mat_metal',
      if (random.nextDouble() < 0.18) 'med_bandage',
      // §10.3.3: ammunition on a body is a windfall, not an income.
      if (body.kind != EnemyKind.walker && random.nextDouble() < 0.12)
        'ammo_9x19',
    ];
    if (drops.isEmpty) return;

    final store = DroppedStore(widget.session.db);
    for (final itemId in drops) {
      await store.drop(
        character.profile.id,
        DroppedItem(
          id: 0,
          itemId: itemId,
          count: itemId == 'ammo_9x19' ? 3 + random.nextInt(8) : 1,
          position: body.position,
          droppedAt: DateTime.now().toUtc(),
        ),
      );
    }

    await _reloadDropped();
  }

  /// §5.5.2: what the HUD says about a fight, or null when there is none.
  ///
  /// Engaged rather than nearby: something wandering its own patch two hundred
  /// metres off is not a fight, and a warning that never goes out is a warning
  /// nobody reads.
  ThreatReading? _threat(GameSnapshot snapshot) {
    final fix = snapshot.displayFix;
    if (fix == null) return null;

    final at = GeoPoint(fix.latitude, fix.longitude);
    final engaged = [
      for (final enemy in _combat.near(at))
        if (enemy.state != EnemyState.idle &&
            enemy.state != EnemyState.returning)
          enemy,
    ];
    if (engaged.isEmpty) return null;

    var nearest = double.infinity;
    var sprinting = false;
    for (final enemy in engaged) {
      final distance = enemy.position.distanceTo(at);
      if (distance < nearest) nearest = distance;
      if (enemy.budget > Duration.zero) sprinting = true;
    }

    return ThreatReading(
      count: engaged.length,
      nearestM: nearest,
      anySprinting: sprinting,
    );
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
            // §10.2: how close is close enough to search it. Judging
            // twenty-five metres by eye on a map that zooms is guesswork.
            reachM: kSearchReachM,
          ),

      // §3.6: red, and only what is near enough to be part of the fight
      // (§5.5.6). Seeing every Walker in the district would answer the one
      // question §7's Reconnaissance is there to ask.
      // ⚠️ The last place the player was, never a default of nought — an
      // island off Africa is further than the forget radius from everything,
      // so a single fix without a position wiped every enemy off the map.
      for (final enemy in _combat.near(_standingAt.value ?? GeoPoint(0, 0)))
        MapMarker(
          id: enemy.id,
          kind: MarkerKind.enemy,
          at: enemy.position,
          // §3.6: which way it is walking. Not a field of view — §6.2 gives
          // them a radius and nothing directional — but knowing that one of
          // them has turned towards you is the whole of the warning.
          headingDeg: enemy.headingDeg,
          alert: switch (enemy.state) {
            EnemyState.chase || EnemyState.spent => MarkerAlert.hunting,
            EnemyState.alert => MarkerAlert.searching,
            EnemyState.idle || EnemyState.returning => MarkerAlert.calm,
          },
        ),

      // §3.6: blue, and there is only ever one of them plus the camps.
      for (final place in _shelters.value)
        MapMarker(
          id: 'shelter.${place.id}',
          kind: MarkerKind.shelter,
          at: place.position,
          reachM: place.kind.safeRadiusM,
        ),

      // §10.3: bone white, with a skull on it. Stays until it is not worth
      // walking back to.
      for (final body in _remains)
        MapMarker(
          id: 'remains.${body.id}',
          kind: MarkerKind.remains,
          at: body.position,
          reachM: kStillnessM,
        ),

      // §4.8: grey, and gone after a day.
      for (final item in _dropped.value)
        MapMarker(
          id: 'dropped.${item.id}',
          kind: MarkerKind.dropped,
          at: item.position,
          // §4.8: a pile is picked up from arm's reach, which is a much
          // tighter ring than a building's.
          reachM: kStillnessM,
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
    // The smoothed position, as the search itself uses: whether a place is
    // within reach should not flicker with the scatter between two buildings.
    final fix = _snapshot?.displayFix;
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

  /// Advances whatever search is running, once a second.
  ///
  /// Its own timer rather than the snapshot stream: snapshots stop arriving
  /// with anything new to say when the player is standing still, which is
  /// precisely the whole duration of a search.
  Future<void> _advanceSearch() async {
    final search = _search.value;
    if (search == null || !search.isRunning) return;

    final now = DateTime.now().toUtc();
    final since = _searchTickedAt ?? now;
    final delta = now.difference(since);
    if (delta <= Duration.zero) return;
    _searchTickedAt = now;

    final snapshot = _snapshot;
    // The smoothed position, not the raw one: the raw fix jumps around by
    // metres between buildings and the player has not moved (§3.2).
    final fix = snapshot?.displayFix;

    final next = search.advance(
      delta,
      at: fix == null ? null : GeoPoint(fix.latitude, fix.longitude),
      // §2.1a: a search counts only while the game can still see where the
      // player is. A position it has stopped trusting cannot answer the one
      // question a search asks — did they stand still?
      present:
          snapshot != null && snapshot.signal != PositionSignal.unavailable,
    );

    if (next.isRunning) {
      _search.value = next;
      return;
    }

    _stopSearchTimer();
    _search.value = null;

    if (next.state == SearchState.done) {
      final at = snapshot?.state.lastUpdate ?? now;
      await switch (next) {
        final s when s.isUse => _finishUse(s),
        final s when s.isBreach => _finishBreach(s, at),
        final s when s.isArea => _finishAreaSearch(s, at),
        final s => _finishObjectSearch(s, at),
      };
    } else {
      await _interruptUse(next);
      if (mounted) {
        _say(
          next.state == SearchState.cancelledByMovement
              ? L10n.of(context).searchMoved
              : L10n.of(context).searchLostSignal,
        );
      }
    }
  }

  void _startSearchTimer() {
    _searchTickedAt = DateTime.now().toUtc();
    _searchTimer?.cancel();
    _searchTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => unawaited(_advanceSearch()),
    );
  }

  void _stopSearchTimer() {
    _searchTimer?.cancel();
    _searchTimer = null;
    _searchTickedAt = null;
  }

  void _startAreaSearch() {
    final fix = _snapshot?.displayFix;
    if (fix == null || _search.value != null) return;

    setState(() {
      _search.value = Search.area(
        at: GeoPoint(fix.latitude, fix.longitude),
        now: DateTime.now().toUtc(),
      );
    });
    _startSearchTimer();
  }

  void _startObjectSearch(SearchDepth depth) {
    final fix = _snapshot?.displayFix;
    final box = _boxInReach();
    if (fix == null || box == null || _search.value != null) return;

    setState(() {
      _search.value = Search.object(
        at: GeoPoint(fix.latitude, fix.longitude),
        now: DateTime.now().toUtc(),
        poiId: box.poiId,
        depth: depth,
      );
    });
    _startSearchTimer();
  }

  /// §19.3: what still shuts the place in reach, if anything.
  ///
  /// A box that has been opened once stays open — a forced door does not
  /// repair itself while the player walks home.
  Barrier? _barrierOn(LootBox? box) {
    if (box == null || box.isOpen) return null;
    return _world?.tables[box.tableId]?.barrier;
  }

  /// Item ids the player is carrying or wearing. What decides the ways in.
  Set<String> _carriedIds() => {
    for (final line in _inventory.value.carried) line.itemId,
    for (final line in _inventory.value.worn) line.itemId,
  };

  void _startBreach(BarrierBreach breach) {
    final fix = _snapshot?.displayFix;
    final box = _boxInReach();
    if (fix == null || box == null || _search.value != null) return;

    setState(() {
      _search.value = Search.breach(
        at: GeoPoint(fix.latitude, fix.longitude),
        now: DateTime.now().toUtc(),
        poiId: box.poiId,
        breach: breach,
      );
    });
    _startSearchTimer();
  }

  /// §19.3: the way in is made, and it stays made.
  Future<void> _finishBreach(Search search, DateTime now) async {
    final character = _character;
    final poiId = search.targetPoiId;
    if (character == null || poiId == null) return;

    final box = _boxes.where((b) => b.poiId == poiId).firstOrNull;
    if (box == null) return;

    final opened = box.openedAtTime(now);
    setState(() {
      _boxes = [
        for (final b in _boxes)
          if (b.poiId == poiId) opened else b,
      ];
    });

    await LootStore(widget.session.db).saveOne(character.profile.id, opened);
    if (mounted) _say(L10n.of(context).breachDone);
  }

  void _cancelSearch() {
    final running = _search.value;
    if (running == null) return;

    _stopSearchTimer();
    _search.value = null;
    unawaited(_interruptUse(running));
  }

  /// §4.7: half a bottle drunk is half a bottle gone, and half a bottle left.
  ///
  /// Anything else makes the choice a trap. Losing the whole bottle for
  /// stopping would teach a player never to start one near a corner they
  /// might have to run round; getting it all back for free would make the
  /// time it takes meaningless.
  Future<void> _interruptUse(Search action) async {
    final line = _usingLine.value;
    final loop = _loop;
    final catalogue = _catalogue;
    _usingLine.value = null;

    if (line == null || loop == null || catalogue == null || !action.isUse) {
      return;
    }

    final definition = catalogue[line.itemId];
    final use = definition == null ? null : useOf(definition);
    // Only what is swallowed comes in mouthfuls. A tourniquet half tied is not
    // half a tourniquet — it is a tourniquet still in the pack.
    if (use == null || !use.consumesItem) return;
    if (use.kcal == 0 && use.waterMl == 0) return;

    final swallowed = action.progress.clamp(0.0, 1.0) * line.portion;
    if (swallowed <= 0) return;

    loop.applyUse(kcal: use.kcal * swallowed, waterMl: use.waterMl * swallowed);
    _inventory.value = _inventory.value.consumePortion(
      line,
      action.progress.clamp(0.0, 1.0),
    );
    await _saveInventory();
  }

  /// §10.2.3: reconnaissance reveals the places that cannot be seen from the
  /// street, and the state of the ones that can.
  Future<void> _finishAreaSearch(Search search, DateTime now) async {
    final previous = _knowledge;
    final radius = searchRadiusM(
      // Reconnaissance is §7 and does not exist yet; binoculars do.
      binoculars:
          _inventory.value.countOf('tool_binoculars') > 0 ||
          _inventory.value.worn.any((line) => line.itemId == 'tool_binoculars'),
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
    if (!box.canSearchAt(depth)) return;

    // Seeded from the place, the character and how far into this place the
    // player already is, so the same search of the same shop gives the same
    // result however many times the app is restarted mid-search (§11) — and a
    // second pass over the same shelves is a different draw rather than the
    // first one again.
    final random = Random(
      character.profile.rngSeed ^
          poiId.hashCode ^
          (box.searchUnits * 2654435761),
    );
    final drop = table.roll(random, depth: depth, catalogue: catalogue);

    var inventory = _inventory.value;
    final taken = <String, int>{};
    var refused = false;

    for (final entry in drop.entries) {
      // §19.1: a note is not a generic item. Which one it is depends on where
      // it was found, and it is the same one every time — a message that
      // changed between readings would stop being somebody's message.
      final note = entry.key == 'lit_note'
          ? _notes?.forPlace(
              selectors: [table.match.isEmpty ? table.id : table.match.first],
              names: _placeNames,
              seed: character.profile.rngSeed ^ poiId.hashCode,
            )
          : null;

      final result = inventory.add(
        entry.key,
        catalogue,
        body: character.body,
        count: entry.value,
        noteId: note?.id,
      );
      inventory = result.inventory;

      final accepted = result.acceptedCount ?? entry.value;
      if (accepted > 0) taken[entry.key] = accepted;
      if (accepted < entry.value) refused = true;
    }

    // What the pass took out of the place, whether or not everything fitted.
    // §19.3 spends the time on searching it, not on carrying the result — and
    // shelves that stayed full because a pack was full would be a way to farm
    // one shop.
    final searched = box.searchedAt(depth, now, random);

    setState(() {
      _inventory.value = inventory;
      _boxes = [
        for (final b in _boxes)
          if (b.poiId == poiId) searched else b,
      ];
    });

    await LootStore(widget.session.db).saveOne(character.profile.id, searched);
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

    _say(
      '${l10n.searchFound(listed)}${refused ? ' · ${l10n.searchNoRoom}' : ''}',
    );
  }

  /// One line, at the bottom, gone in a few seconds. The player is walking.
  /// §12: the game says something, under the HUD rather than over the menu.
  void _say(String message) {
    if (!mounted) return;

    final notice = Notice(message, DateTime.now());
    _notices.value = [notice, ..._notices.value];

    Timer(kNoticeLifetime, () {
      if (!mounted) return;
      _notices.value = _notices.value
          .where((other) => !identical(other, notice))
          .toList();
    });
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
    _searchTimer?.cancel();
    _inventory.dispose();
    _search.dispose();
    _dropped.dispose();
    _standingAt.dispose();
    _usingLine.dispose();
    _shelters.dispose();
    _notices.dispose();
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
    // §9: nothing else is drawn while the character is not on their feet. The
    // bug this exists to close: a character with no blood left went on looting
    // shops while something chewed on them, because nothing had ever asked.
    final down = _loop?.down ?? DownState.none;
    if (character != null &&
        (down == DownState.dead || down == DownState.unconscious)) {
      return DownScreen(
        state: down,
        cause: _loop?.deathCause,
        until: _loop?.downUntil,
        now: snapshot?.state.lastUpdate ?? DateTime.now().toUtc(),
        onNewCharacter: down == DownState.dead
            ? () => unawaited(_startOver(character))
            : null,
      );
    }

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
                  onMarkerTap,
                  noise,
                }) => MapLibreSurface(
                  source: source,
                  centre: centre,
                  markers: markers,
                  economy: economy,
                  onMarkerTap: onMarkerTap,
                  noise: noise,
                  fallbackCentre: _packCentre,
                ),
            fix: snapshot?.displayFix,
            // §4.8: a pack emptied on a corner is fourteen rows in one place,
            // and fourteen overlapping circles is a smear rather than a map.
            markers: clusterMarkers(_lootMarkers()),
            onMarkerTap: _showMarker,
            // §5.6.5: what the last shot woke up, drawn at the radius it
            // actually carried.
            noise: _combat.open == null
                ? null
                : NoiseWave(
                    at: _combat.open!.at,
                    radiusM: _combat.open!.radiusM,
                    startedAt: _combat.open!.startedAt.toLocal(),
                  ),
            // §4.6, §10.2, §8.3: the bar for whatever is running, at the top.
            // Eating and building are the same thing from the player's side —
            // something they are waiting on — so they share the one slot.
            progress: _search.value != null && _search.value!.isRunning
                ? ActionProgress(
                    search: _search.value!,
                    onCancel: _cancelSearch,
                  )
                : BuildProgress.of(
                    _shelters.value,
                    _standingAt.value,
                    DateTime.now().toUtc(),
                  ),
            searchPanel: snapshot == null
                ? null
                : Builder(
                    builder: (context) {
                      // §5.1.4: while something is being aimed at, the panel
                      // is the odds and the trigger. Searching a shop with a
                      // Walker in the sights is not a thing to offer.
                      // ⚠️ Whenever something is aimed at, weapon or no
                      // weapon. Found on a phone: tapping an enemy with
                      // nothing in hand looked like the tap had missed,
                      // because the panel only appeared when a shot could be
                      // worked out — so the one case where a player most
                      // needs to be told what they are looking at showed them
                      // nothing at all.
                      final target = _target;
                      final error = target == null ? null : _aimError(target);
                      if (target != null) {
                        // §5.5.1 and §10.2 at once: what can be done standing
                        // here sits *above* the fight, not behind it. Found on
                        // a phone: taking a target buried the search and
                        // pick-up glyphs under the combat panel, so a body at
                        // the player's feet could not be gone through until
                        // the fight was over.
                        final weapon = _weapon;
                        final round = weapon == null ? null : _roundFor(weapon);

                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _actionPanel(context),
                            CombatPanel(
                              targetName: enemyKindName(
                                L10n.of(context),
                                target.kind,
                              ),
                              state: target.state,
                          weaponName: weapon == null
                              ? null
                              : _nameOfItem(weapon),
                              distanceM: target.position.distanceTo(
                                GeoPoint(
                                  snapshot.displayFix?.latitude ?? 0,
                                  snapshot.displayFix?.longitude ?? 0,
                                ),
                              ),
                              chance: error == null
                                  ? null
                                  : hitChance(
                                      moa: error.total,
                                      distanceM: target.position.distanceTo(
                                        GeoPoint(
                                          snapshot.displayFix?.latitude ?? 0,
                                          snapshot.displayFix?.longitude ?? 0,
                                        ),
                                      ),
                                    ),
                              dominant: error?.dominant,
                              settling:
                                  _aim.spreadMultiplierAt(DateTime.now()) >
                                  1.02,
                              condition: target.condition,
                              sprintLeft: target.sprintLeftFraction,
                              bloodLeft: target.bloodLeft,
                              bleeding: target.isBleeding,
                              loaded: _loaded,
                              magazine: weapon == null
                                  ? 0
                                  : magazineSize(
                                      weapon,
                                      attachments: _attachmentsFor(weapon),
                                    ),
                              reloading: _reload != null,
                              refusal: weapon == null
                                  ? L10n.of(context).combatNoWeapon
                                  : _loaded <= 0 && round == null
                                  ? L10n.of(context).combatNoAmmo
                                  : null,
                              onReload:
                                  weapon == null ||
                                      round == null ||
                                      _reload != null
                                  ? null
                                  : _startReload,
                              onFire:
                                  weapon == null ||
                                      _loaded <= 0 ||
                                      _reload != null
                                  ? null
                                  : () => unawaited(_fire()),
                              // §5.2: below twenty metres the receiver has nothing
                              // useful to say about anybody's position, so the
                              // fight stops being about distance and becomes about
                              // what is in your hands.
                              onStrike:
                                  target.position.distanceTo(
                                        GeoPoint(
                                          snapshot.displayFix?.latitude ?? 0,
                                          snapshot.displayFix?.longitude ?? 0,
                                        ),
                                      ) <=
                                      kMeleeM
                                  ? () => unawaited(_strike())
                                  : null,
                            ),
                          ],
                        );
                      }

                      return _actionPanel(context);
                    },
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
                    bleeding: _loop?.bleeding ?? BleedTier.none,
                    carryComfortKg: character.body.carryComfortKg,
                    carryMaxKg: character.body.carryMaxKg,
                    carriedKg: _carriedKg,
                    carriedVolumeL: _carriedVolumeL,
                    capacityL: _capacityL(character.body),
                    threat: _threat(snapshot),
                  ),
            notices: NoticeStack(notices: _notices),
            onMenu: (entry) {
              // Profile and shelter arrive with the systems behind them
              // (§7, §8). The two that have something to show are wired.
              switch (entry) {
                case MapMenuEntry.settings:
                  unawaited(_openSettings());
                case MapMenuEntry.inventory:
                  unawaited(_openInventory());
                case MapMenuEntry.shelter:
                  unawaited(_openShelter());
                case MapMenuEntry.profile:
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
      // Not a warning. The receiver is doing what a receiver does, and saying
      // so is what stops the player reading a cold start as a fault.
      PositionSignal.acquiring => l10n.hudAcquiring,
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
