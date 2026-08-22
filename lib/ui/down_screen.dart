/// The screen for a character who is not on their feet (§9).
///
/// It covers the map completely and on purpose. The bug it exists to fix was
/// a character with no blood left walking around looting shops while a Walker
/// chewed on them — everything still worked, because nothing had ever asked
/// whether the player was alive. A state the game does not draw is a state the
/// game does not have.
library;

import 'fonts.dart';
import 'ticking.dart';
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../sim/death.dart';
import 'hud.dart' show HudColors;

class DownScreen extends StatefulWidget {
  const DownScreen({
    required this.state,
    required this.cause,
    required this.until,
    this.log = const [],
    this.onNewCharacter,
    super.key,
  });

  final DownState state;
  final DeathCause? cause;

  /// §9.2: when the hour is up. Null for the end of a hardcore character.
  final DateTime? until;

  /// §5.5: the last of the fight, oldest first.
  ///
  /// ⚠️ The one thing a player actually asks at this screen is "how did I
  /// die". Every line of it was on screen at the time and every line of it was
  /// gone by the time it mattered.
  final List<String> log;

  /// §9.1: the same body, a new name. Null in softcore, where there is nothing
  /// to start over.
  final VoidCallback? onNewCharacter;

  @override
  State<DownScreen> createState() => _DownScreenState();
}

class _DownScreenState extends State<DownScreen>
    with WidgetsBindingObserver, Ticking<DownScreen> {
  /// The hour runs on the wall clock (§9.2), so the screen has to as well —
  /// a countdown that only moves when a tick happens reads as a stopped one.
  /// §9.1's countdown is the one thing on screen, so it always ticks — but
  /// not in a pocket, where nobody is reading it.
  @override
  bool get ticking => true;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final colours = HudColors.of(context);
    final state = widget.state;
    final until = widget.until;
    final dead = state == DownState.dead;
    final left = until == null
        ? Duration.zero
        : until.difference(DateTime.now().toUtc());

    return Scaffold(
      backgroundColor: const Color(0xFF07090A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                dead ? l10n.deathTitle : l10n.downTitle,
                style: TextStyle(
                  fontSize: 22,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.bold,
                  color: colours.alert,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                causeName(l10n, widget.cause),
                style: TextStyle(fontSize: 14, color: colours.muted),
              ),
              const SizedBox(height: 20),
              Text(
                dead ? l10n.deathWhat : l10n.downWhat,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: colours.text,
                ),
              ),

              if (!dead) ...[
                const SizedBox(height: 24),
                Text(
                  l10n.downLeft(_short(left.isNegative ? Duration.zero : left)),
                  style: TextStyle(
                    fontSize: 28,
                    color: colours.data,
                    fontFamily: kDataFont,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  // §9.2: the clock runs whether or not anybody is looking.
                  l10n.downClosedApp,
                  style: TextStyle(fontSize: 12, color: colours.muted),
                ),
              ],

              // §5.5: the last of the fight. The one question anybody asks at
              // this screen is "how did I die", and every line of the answer
              // was on screen at the time and gone by the time it mattered.
              if (widget.log.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text(
                  l10n.downLog.toUpperCase(),
                  style: TextStyle(
                    fontSize: 9,
                    letterSpacing: 1.5,
                    color: colours.muted,
                  ),
                ),
                const SizedBox(height: 6),
                Flexible(
                  child: SingleChildScrollView(
                    reverse: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final line in widget.log)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: Text(
                              line,
                              style: TextStyle(
                                fontSize: 12,
                                height: 1.35,
                                color: colours.text,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],

              if (widget.onNewCharacter != null) ...[
                const SizedBox(height: 28),
                FilledButton(
                  onPressed: widget.onNewCharacter,
                  child: Text(l10n.deathNewCharacter),
                ),
                const SizedBox(height: 8),
                Text(
                  // §9.1: the same body. It is still the player's height and
                  // weight, so there is no creator to sit through again.
                  l10n.deathSameBody,
                  style: TextStyle(fontSize: 12, color: colours.muted),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

String causeName(L10n l10n, DeathCause? cause) => switch (cause) {
  null => '',
  DeathCause.bloodLoss => l10n.causeBloodLoss,
  DeathCause.thirst => l10n.causeThirst,
  DeathCause.starvation => l10n.causeStarvation,
};

String _short(Duration time) {
  final minutes = time.inMinutes;
  final seconds = time.inSeconds % 60;

  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}
