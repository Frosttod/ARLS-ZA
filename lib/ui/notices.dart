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

import 'dart:async';

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';

import '../combat/blows_away.dart';
import '../l10n/app_localizations.dart';
import 'units.dart';

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

/// What the game has said lately, and when each line stops being news.
///
/// ⚠️ **Lived in `main.dart` as a notifier plus a timer.** The pair is one
/// idea — a line lasts [kNoticeLifetime] and then it is gone — and half of it
/// sitting in the entry point meant every caller had to be trusted to start
/// the timer. Here it cannot be forgotten: [say] is the only way in.
class NoticeBoard {
  final ValueNotifier<List<Notice>> lines = ValueNotifier(const []);

  var _open = true;

  /// One line, gone in a few seconds. The player is walking.
  void say(String message, {DateTime? at}) {
    if (!_open) return;

    final notice = Notice(message, at ?? DateTime.now());
    lines.value = [notice, ...lines.value];

    Timer(kNoticeLifetime, () {
      if (!_open) return;
      lines.value = lines.value
          .where((other) => !identical(other, notice))
          .toList();
    });
  }

  /// ⚠️ The flag is not tidiness. A timer outlives the screen that started it,
  /// and writing to a disposed notifier throws — which is exactly what a
  /// message arriving as the player leaves the game would do.
  void dispose() {
    _open = false;
    lines.dispose();
  }
}

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

/// §5.5.3, §12: co się stało przy zgaszonym ekranie.
///
/// ⚠️ **Okno, nie pasek na dole.** Zgłoszone z terenu: gracz wrócił do gry ze
/// wstrząsem i krwawieniem i **nie wiedział dlaczego**. Komunikat gasnący po
/// trzech sekundach w trakcie wstawania aplikacji to komunikat, którego nikt
/// nie przeczytał — a to jest jedyna rzecz, która wydarzyła się bez niego.
Future<void> showAwayFight(BuildContext context, BlowsAway hurt) {
  final l10n = L10n.of(context);

  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.awayTitle),
      content: Text(l10n.awayAttackedBody(hurt.blows, hurt.bloodMl.round())),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.commonOk),
        ),
      ],
    ),
  );
}

/// §6.5.3, §6.10: strefa urosła, kiedy nikt nie patrzył.
///
/// ⚠️ **Okno, nie pasek na trzy sekundy.** Awans jest jedyną rzeczą, którą świat
/// robi za plecami gracza — także przez noc z telefonem w szufladzie — więc
/// komunikat, który sam znika, byłby informacją wysłaną w pustkę. Ta sama
/// decyzja, którą wymusił raport z walki poza aplikacją ([showAwayFight]).
Future<void> showZoneGrew(
  BuildContext context, {
  required int level,
  required double radiusM,
  required int enemies,
  required double? distanceM,
}) {
  final l10n = L10n.of(context);

  // §12: kierunku nie mamy czym nazwać — paczki PMTiles nie niosą warstwy z
  // nazwami ulic — więc mówimy to, co wiemy na pewno: jak daleko.
  final where = distanceM == null
      ? l10n.zoneGrewNear
      : l10n.zoneGrewAway(metres(distanceM));

  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.zoneGrewTitle),
      content: Text(l10n.zoneGrewBody(where, level, radiusM.round(), enemies)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.commonOk),
        ),
      ],
    ),
  );
}
