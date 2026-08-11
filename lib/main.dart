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
import 'l10n/app_localizations.dart';
import 'location/position_fix.dart';
import 'ui/character_creator.dart';
import 'ui/hud.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(const ArlsZaApp());
}

class ArlsZaApp extends StatelessWidget {
  const ArlsZaApp({super.key});

  @override
  Widget build(BuildContext context) {
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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFA82D17),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: Colors.black,
        useMaterial3: true,
      ),
      home: const IntroScreen(),
    );
  }
}

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  late VideoPlayerController _controller;

  /// The save layer boots while the intro plays, so opening the database,
  /// verifying it and running any migration costs the player no extra wait.
  late final Future<SaveSession> _session = _bootSave();

  var _navigated = false;

  Future<SaveSession> _bootSave() async {
    final paths = await resolveSavePaths();
    final bootstrap = SaveBootstrap(paths: paths);
    return bootstrap.boot(now: DateTime.now().toUtc());
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
          child: TitleScreen(session: session),
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
  const TitleScreen({required this.session, super.key});

  final SaveSession session;

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
    final existing = await _factory.loadActive();
    if (!mounted) return;

    if (existing == null) {
      setState(() => _loading = false);
      return;
    }
    await _enter(existing);
  }

  /// Starts the simulation for [character] and shows the HUD.
  Future<void> _enter(ActiveCharacter character) async {
    if (kDevTools) {
      _dev = DevSession.attach(constants: character.constants);
    }

    final source = buildPositionSource(_dev);
    if (source == null) {
      // Nothing can drive the position yet. Say so rather than running a
      // simulation on movement that will never arrive — the real GPS is
      // stage 3.
      if (mounted) {
        setState(() {
          _character = character;
          _loading = false;
        });
      }
      return;
    }

    final loop = await _factory.startLoop(
      character: character,
      source: source,
      clock: _dev?.gameClock,
    );
    loop.snapshots.listen((snapshot) {
      if (!mounted) return;
      setState(() {
        _sessionStart ??= snapshot.state.lastUpdate;
        _snapshot = snapshot;
      });
    });

    if (!mounted) {
      await loop.dispose();
      return;
    }
    setState(() {
      _character = character;
      _loop = loop;
      _loading = false;
    });
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
    unawaited(_loop?.dispose());
    unawaited(_dev?.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final recovery = widget.session.recovery;
    final dev = _dev;
    final snapshot = _snapshot;
    final character = _character;

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
                  signalWarning: _signalWarning(l10n, snapshot.signal),
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

  static String? _signalWarning(L10n l10n, PositionSignal signal) =>
      switch (signal) {
        PositionSignal.lost || PositionSignal.unavailable => l10n.hudNoSignal,
        PositionSignal.degraded => l10n.hudWeakSignal,
        PositionSignal.good => null,
      };
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
