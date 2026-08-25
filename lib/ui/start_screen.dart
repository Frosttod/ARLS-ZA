/// What is on screen before the map is (§3.6, §11.1.5, §16.1).
///
/// ⚠️ **Three different "not yet" states, and they are not the same.** A run
/// with a character but no map fix is a *running simulation* waiting on the
/// receiver — putting a logo over it would read as something having gone
/// wrong. A run with no character at all is the title screen. A run refused
/// the location permission is neither: it is a wall with a way through it, and
/// §16.1 says the way through has to be offered rather than described.
///
/// All three used to be assembled in the largest build method in the codebase,
/// where the difference between them was three nested conditions nobody could
/// see the shape of.
library;

import 'package:flutter/material.dart';

import '../data/db/snapshot_store.dart';
import '../l10n/app_localizations.dart';
import '../location/location_access.dart';
import 'location_gate.dart';

/// The simulation is running and the map is not resolved yet.
///
/// The panel stays, because everything on it is still true — a character does
/// not stop being thirsty because the receiver has not answered.
class WaitingForMapScreen extends StatelessWidget {
  const WaitingForMapScreen({required this.hud, super.key});

  final Widget? hud;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Stack(
      children: [
        const Center(child: CircularProgressIndicator()),
        if (hud case final panel?)
          Positioned(top: 0, left: 0, right: 0, child: SafeArea(child: panel)),
      ],
    ),
  );
}

/// The title, and whatever is standing between the player and a run.
class StartScreen extends StatelessWidget {
  const StartScreen({
    required this.loading,
    required this.playerName,
    required this.recovery,
    required this.blocked,
    required this.onRetry,
    required this.onNewCharacter,
    this.hud,
    this.overlay,
    super.key,
  });

  final bool loading;

  /// The character's name once there is one, and the game's until then.
  final String? playerName;

  /// §11.1.5: what the save layer had to do to open this run, if anything.
  final SaveRecovery recovery;

  /// §16.1: why the location was refused, or null.
  final LocationAccess? blocked;

  final Future<void> Function() onRetry;
  final VoidCallback onNewCharacter;

  /// Shown when a character exists — the vitals do not stop being true because
  /// the map is not up.
  final Widget? hud;

  /// §15.3's developer panel, when it is running.
  final Widget? overlay;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);

    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              ?hud,
              Expanded(
                child: SafeArea(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: loading
                          ? const CircularProgressIndicator()
                          : Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Image.asset('assets/icon.png', width: 120),
                                const SizedBox(height: 24),
                                Text(
                                  playerName ?? l10n.appTitle,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.headlineMedium,
                                ),
                                Text(
                                  l10n.appTagline,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                const SizedBox(height: 32),

                                // §11.1.5: said plainly. A save that came back
                                // short is a thing the player has lost time to,
                                // and finding out by noticing it is worse than
                                // being told.
                                if (recovery.health == SaveHealth.restored)
                                  BlockedPanel(
                                    title: l10n.saveRestoredTitle,
                                    body: l10n.saveRestoredBody(
                                      recovery.timeLost?.inMinutes ?? 0,
                                    ),
                                  ),
                                if (recovery.health == SaveHealth.lost)
                                  BlockedPanel(
                                    title: l10n.saveLostTitle,
                                    body: l10n.saveLostBody,
                                  ),

                                if (blocked case final access?)
                                  LocationGate(
                                    access: access,
                                    onRetry: onRetry,
                                  ),
                                if (playerName == null)
                                  FilledButton(
                                    onPressed: onNewCharacter,
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
          ?overlay,
        ],
      ),
    );
  }
}
