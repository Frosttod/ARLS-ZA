/// The film, and the save layer opening behind it (§11.1, §16.1).
///
/// ⚠️ **The boot rides on the intro on purpose.** Opening the database,
/// verifying its checksums and running any migration is the slowest thing the
/// app does, and it happens while the player is watching something. Skipping
/// the film does not skip the wait — it waits for the save and then goes, so
/// that a recovered or lost save is never announced to somebody who has
/// already walked past the message (§11.1.3).
library;

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../data/db/save_location.dart';
import '../data/persistence/save_bootstrap.dart';
import 'app_settings.dart';

class IntroScreen extends StatefulWidget {
  const IntroScreen({required this.onSettings, required this.next, super.key});

  /// Handed up as soon as the database is open, so the whole app can follow
  /// the player's language and theme.
  final void Function(AppSettings) onSettings;

  /// What comes after the film.
  ///
  /// ⚠️ Injected rather than imported, and that is the whole reason this
  /// screen could leave `main.dart` at all. The title screen still lives
  /// there; importing it from here would make a cycle out of what is really a
  /// one-way street — the film knows there is a *next thing*, not which one.
  final Widget Function(SaveSession session, AppSettings settings) next;

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
          child: widget.next(session, _settings!),
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
