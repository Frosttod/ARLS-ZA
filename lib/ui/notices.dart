/// What the game just told the player (§12, §3.6).
///
/// These used to be snack bars. On a phone that puts them across the bottom of
/// the screen, which is where the menu and the searching controls live — so
/// the one place the game speaks was also the one place it covered up, and a
/// message about a full pack sat on top of the button for doing something
/// about it.
///
/// They belong under the HUD instead: the top right is already where the game
/// states things about the body, and nothing there is a control. Stacked
/// newest first, three at most, because a fourth line of history is not news.
library;

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';

import 'hud.dart' show HudColors;

/// One thing said, and when.
class Notice {
  const Notice(this.text, this.at);

  final String text;
  final DateTime at;
}

/// §12: how long a line stays before it stops being news.
const Duration kNoticeLifetime = Duration(seconds: 4);

/// At most this many at once. Older ones are dropped rather than queued: a
/// player who searched three places wants the last answer, not the first.
const int kNoticesShown = 3;

class NoticeStack extends StatelessWidget {
  const NoticeStack({required this.notices, super.key});

  final ValueListenable<List<Notice>> notices;

  @override
  Widget build(BuildContext context) {
    final colours = HudColors.of(context);

    return ValueListenableBuilder<List<Notice>>(
      valueListenable: notices,
      builder: (context, lines, _) {
        if (lines.isEmpty) return const SizedBox.shrink();

        return
        // Never in the way of a finger: the map underneath is tappable and a
        // message is not a control.
        IgnorePointer(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(48, 6, 8, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final notice in lines.take(kNoticesShown))
                  Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: colours.panel.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: colours.muted.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      notice.text,
                      textAlign: TextAlign.right,
                      style: TextStyle(fontSize: 12, color: colours.text),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
