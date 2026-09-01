/// Co woda, jedzenie i sen robią z ciałem — zanim to zrobią (§2.3, §2.5.4, §12).
///
/// ⚠️ **Gra karała i nigdzie nie mówiła jak.** Profil pokazywał karę dopiero
/// wtedy, gdy już bolała, więc „zostało mi pół butelki" było liczbą bez ceny.
/// §12 chce odwrotnie: cena ma być widoczna **przed** decyzją, bo to ona jest
/// decyzją. Trzy wiersze stanu ciała otwierają teraz drabinkę z §2.3 i §2.5.4,
/// z zaznaczonym szczeblem, na którym gracz stoi.
///
/// Szczeble przychodzą z [PenaltyLadder], czyli są **generowane z tych samych
/// funkcji, które karzą** — ekran nie zna żadnego progu na pamięć.
library;

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../sim/penalty_ladder.dart';
import 'effects.dart';
import 'hud.dart' show HudColors;

/// Którą witalność pokazuje arkusz.
enum VitalKind { water, food, sleep }

Future<void> showVitalSheet(
  BuildContext context, {
  required VitalKind kind,
  required PenaltyLadder ladder,
  required String now,
}) => showModalBottomSheet<void>(
  context: context,
  showDragHandle: true,
  builder: (context) => VitalSheet(kind: kind, ladder: ladder, now: now),
);

class VitalSheet extends StatelessWidget {
  const VitalSheet({
    required this.kind,
    required this.ladder,
    required this.now,
    super.key,
  });

  final VitalKind kind;
  final PenaltyLadder ladder;

  /// Stan w słowach gracza: „1 627 ml z 2 905 ml".
  final String now;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final colours = HudColors.of(context);
    final standing = ladder.current;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _title(l10n, kind),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colours.text,
              ),
            ),
            const SizedBox(height: 2),
            Text(now, style: TextStyle(fontSize: 13, color: colours.data)),
            const SizedBox(height: 16),

            // §12: najpierw to, co obowiązuje **teraz**. Drabinka pod spodem
            // jest po to, żeby wiedzieć, co będzie dalej — ale pytanie, które
            // gracz ma na ekranie, brzmi „co mnie kosztuje ta butelka".
            Text(
              standing == null
                  ? l10n.vitalNoPenaltyYet
                  : effects(_effectsOf(l10n, standing)),
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: standing == null ? colours.muted : colours.alert,
              ),
            ),
            const SizedBox(height: 16),

            Text(
              l10n.vitalLadder,
              style: TextStyle(fontSize: 11, color: colours.muted),
            ),
            const SizedBox(height: 6),
            for (final rung in ladder.rungs)
              _RungRow(
                label: _threshold(l10n, kind, rung.at),
                effects: effects(_effectsOf(l10n, rung)),
                reached: ladder.reached(rung),
                colours: colours,
              ),
          ],
        ),
      ),
    );
  }
}

/// Jeden szczebel: od kiedy, i co wtedy.
class _RungRow extends StatelessWidget {
  const _RungRow({
    required this.label,
    required this.effects,
    required this.reached,
    required this.colours,
  });

  final String label;
  final String effects;

  /// Czy gracz już tam jest. Osiągnięty szczebel jest wyróżniony, a nie
  /// przekreślony: to nie jest lista zadań, tylko skala.
  final bool reached;

  final HudColors colours;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 84,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: reached ? FontWeight.bold : FontWeight.normal,
              color: reached ? colours.alert : colours.muted,
            ),
          ),
        ),
        Expanded(
          child: Text(
            effects,
            style: TextStyle(
              fontSize: 12,
              height: 1.35,
              color: reached ? colours.text : colours.muted,
            ),
          ),
        ),
      ],
    ),
  );
}

String _title(L10n l10n, VitalKind kind) => switch (kind) {
  VitalKind.water => l10n.vitalWater,
  VitalKind.food => l10n.vitalFood,
  VitalKind.sleep => l10n.vitalSleep,
};

/// Próg w jednostce, którą ta witalność mierzy (§2.3, §2.5.4).
String _threshold(L10n l10n, VitalKind kind, double at) => switch (kind) {
  VitalKind.water => l10n.vitalOfBodyMass((at * 100).round()),
  VitalKind.food => l10n.vitalBelowDaily((100 - at * 100).round()),
  VitalKind.sleep => l10n.vitalFromHours(at.round()),
};

/// Co ten szczebel robi, w liczbach, którymi gra naprawdę liczy.
///
/// ⚠️ Tylko to, co się zmienia. Wiersz „celność ×1,00" jest wierszem, który
/// każe czytać zero.
List<String> _effectsOf(L10n l10n, Rung rung) => [
  if (rung.accuracy < 1)
    l10n.vitalAccuracy(((1 - rung.accuracy) * 100).round()),
  if (rung.actionTime > 1)
    l10n.vitalSlower(((rung.actionTime - 1) * 100).round()),
  if (rung.extraMoa > 0) l10n.vitalMoa(rung.extraMoa.toStringAsFixed(0)),
  if (rung.learning < 1)
    l10n.vitalLearning(((1 - rung.learning) * 100).round()),
];
