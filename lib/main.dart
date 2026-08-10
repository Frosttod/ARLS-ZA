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
import 'l10n/app_localizations.dart';
import 'location/position_fix.dart';
import 'sim/tick.dart';

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

/// Reference character from §15.4, until the creator arrives in stage 2.
const _placeholderConstants = SimConstants(
  bloodMaxMl: 5319,
  waterDailyMl: 2800,
  caloriesDailyKcal: 2450,
  restingHeartRate: 70,
  maxHeartRate: 187,
);

/// Placeholder title screen. The character creator and the map arrive in
/// stages 2 and 3; what stages 0 and 1 owe is proof the save layer booted and
/// that developer mode can drive the position source.
class TitleScreen extends StatefulWidget {
  const TitleScreen({required this.session, super.key});

  final SaveSession session;

  @override
  State<TitleScreen> createState() => _TitleScreenState();
}

class _TitleScreenState extends State<TitleScreen> {
  /// Null in a release build — `DevSession.attach` short-circuits on the const
  /// gate, so nothing here survives tree shaking (§11.2).
  DevSession? _dev;

  PositionFix? _fix;
  PositionSignal _signal = PositionSignal.unavailable;

  @override
  void initState() {
    super.initState();
    if (kDevTools) {
      final dev = DevSession.attach(constants: _placeholderConstants);
      _dev = dev;
      if (dev != null) {
        dev.source.fixes.listen((fix) {
          if (mounted) setState(() => _fix = fix);
        });
        dev.source.signal.listen((signal) {
          if (mounted) setState(() => _signal = signal);
        });
        unawaited(dev.start());
      }
    }
  }

  @override
  void dispose() {
    unawaited(_dev?.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final recovery = widget.session.recovery;
    final dev = _dev;

    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset('assets/icon.png', width: 120),
                    const SizedBox(height: 24),
                    Text(
                      l10n.appTitle,
                      style: Theme.of(context).textTheme.headlineMedium,
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
                  ],
                ),
              ),
            ),
          ),
          if (dev != null)
            DevOverlay(
              console: dev.console,
              snapshot: DevSnapshot(
                state: null,
                fix: _fix,
                signal: _signal,
                ticksApplied: 0,
              ),
            ),
        ],
      ),
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
