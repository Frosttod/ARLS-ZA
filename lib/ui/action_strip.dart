/// Everything the player is currently waiting on, in one place (§2.1a, §12).
///
/// ⚠️ **Every action with a clock belongs here, and every one of them can be
/// stopped from here.** The player is walking with the phone. An action whose
/// only sign lives on a pushed screen — the bench, the shelter, the pack — is
/// an action they cannot see while playing and cannot get out of when
/// something comes round the corner.
///
/// This has already cost three separate "it does not work" reports for things
/// that were in fact running: a reload with no bar, a night's sleep with no
/// readable debt, and a search cooldown with no spoken refusal. The strip sits
/// directly under the stats, which is where somebody looks to find out what
/// their character is doing.
library;

import 'dart:async';

import 'package:flutter/material.dart';

import 'fonts.dart';
import 'hud.dart' show HudColors;

/// One thing under way.
class RunningAction {
  const RunningAction({
    required this.icon,
    required this.label,
    required this.startedAt,
    required this.readyAt,
    this.onStop,
    this.note,
  });

  final IconData icon;

  /// What it is, in the player's words. "Changing magazine", not "reload".
  final String label;

  final DateTime startedAt;
  final DateTime readyAt;

  /// How to get out of it. Null only for something that genuinely cannot be
  /// stopped — which, so far, is nothing.
  final VoidCallback? onStop;

  /// One line under the bar for whatever the player needs to know while it
  /// runs: that this is heard from eighty metres, that stopping keeps the work.
  final String? note;

  double progressAt(DateTime now) {
    final total = readyAt.difference(startedAt).inMilliseconds;
    if (total <= 0) return 1;

    return (now.difference(startedAt).inMilliseconds / total).clamp(0.0, 1.0);
  }

  Duration remainingAt(DateTime now) {
    final left = readyAt.difference(now);
    return left.isNegative ? Duration.zero : left;
  }
}

/// The strip itself.
///
/// Its own clock, because most of what it draws is a deadline in a database
/// rather than a ticking notifier — a bar drawn straight from those would sit
/// perfectly still for a quarter of an hour and read as broken.
class ActionStrip extends StatefulWidget {
  const ActionStrip({required this.actions, super.key});

  final List<RunningAction> actions;

  @override
  State<ActionStrip> createState() => _ActionStripState();
}

class _ActionStripState extends State<ActionStrip> {
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.actions.isEmpty) return const SizedBox.shrink();

    final colours = HudColors.of(context);
    final now = DateTime.now().toUtc();

    return Material(
      color: colours.panel.withValues(alpha: 0.92),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 6, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final action in widget.actions)
              _ActionLine(action: action, now: now, colours: colours),
          ],
        ),
      ),
    );
  }
}

class _ActionLine extends StatelessWidget {
  const _ActionLine({
    required this.action,
    required this.now,
    required this.colours,
  });

  final RunningAction action;
  final DateTime now;
  final HudColors colours;

  @override
  Widget build(BuildContext context) {
    final left = action.remainingAt(now);

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(action.icon, size: 14, color: colours.data),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  action.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, color: colours.text),
                ),
              ),
              Text(
                _said(left),
                style: TextStyle(
                  fontSize: 13,
                  color: colours.data,
                  fontFamily: kDataFont,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              if (action.onStop != null)
                IconButton(
                  onPressed: action.onStop,
                  icon: const Icon(Icons.stop_circle_outlined, size: 18),
                  tooltip: MaterialLocalizations.of(context).cancelButtonLabel,
                  color: colours.muted,
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.only(left: 8),
                )
              else
                const SizedBox(width: 8),
            ],
          ),
          const SizedBox(height: 3),
          LinearProgressIndicator(
            value: action.progressAt(now),
            minHeight: 3,
            backgroundColor: colours.muted.withValues(alpha: 0.25),
            color: colours.data,
          ),
          if (action.note != null) ...[
            const SizedBox(height: 2),
            Text(
              action.note!,
              style: TextStyle(fontSize: 11, color: colours.muted),
            ),
          ],
        ],
      ),
    );
  }

  /// Hours where there are hours, and seconds where the difference matters.
  static String _said(Duration left) {
    if (left.inHours >= 1) return '${left.inHours} h ${left.inMinutes % 60}′';
    if (left.inMinutes >= 1) {
      return '${left.inMinutes}′ ${(left.inSeconds % 60).toString().padLeft(2, '0')}';
    }
    return '${left.inSeconds} s';
  }
}
