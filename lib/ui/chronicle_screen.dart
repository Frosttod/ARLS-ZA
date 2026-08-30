/// Passy, które się skończyły (§13.1, §9.3, §12).
///
/// ⚠️ **Wiersze były zapisywane od pierwszego dnia i nikt ich nigdy nie
/// czytał.** Baza wypełnia `chronicle_entries` przy każdej śmierci, a
/// `chronicleFor` nie miał w grze ani jednego wołającego. §13.1 mówi wprost, po
/// co hardcore istnieje: passa, która padła, ma zostać na czymś zapisana.
/// Licznik dni, którego po śmierci nie da się już zobaczyć, jest licznikiem
/// donikąd.
///
/// Najdłuższa passa stoi na górze, osobno. To jest ta jedna liczba, o którą
/// chodzi w całej grze, i szukanie jej wzrokiem po liście byłoby zadaniem.
library;

import 'package:flutter/material.dart';

import '../journal/chronicle.dart';
import '../l10n/app_localizations.dart';
import '../sim/death.dart';
import 'down_screen.dart' show causeName;
import 'effects.dart';
import 'hud.dart' show HudColors;

Future<void> showChronicle(
  BuildContext context, {
  required List<PastRun> runs,
}) => Navigator.of(
  context,
).push(MaterialPageRoute<void>(builder: (_) => ChronicleScreen(runs: runs)));

class ChronicleScreen extends StatelessWidget {
  const ChronicleScreen({required this.runs, super.key});

  /// Najświeższa pierwsza — tak, jak podaje je `ChronicleStore`.
  final List<PastRun> runs;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final colours = HudColors.of(context);

    // ⚠️ Rekord liczony tutaj, nie zapisany obok. Jedna liczba wyliczana z
    // listy nie może się z tą listą rozjechać, a zapisana — może, i to jest
    // dokładnie ten rodzaj rozjazdu, którego nikt nigdy nie zauważa.
    final best = runs.isEmpty
        ? 0
        : runs.map((run) => run.days).reduce((a, b) => a > b ? a : b);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.chronicleTitle)),
      body: runs.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  l10n.chronicleEmpty,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: colours.muted),
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                Text(
                  l10n.chronicleBest(best),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colours.text,
                  ),
                ),
                const SizedBox(height: 16),
                for (final run in runs)
                  _Run(run: run, colours: colours, l10n: l10n),
              ],
            ),
    );
  }
}

/// Jedna passa: ile dni, co ją skończyło, i kiedy to było.
class _Run extends StatelessWidget {
  const _Run({required this.run, required this.colours, required this.l10n});

  final PastRun run;
  final HudColors colours;
  final L10n l10n;

  @override
  Widget build(BuildContext context) {
    final ended = run.endedAt.toLocal();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.chronicleRunDays(run.days),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: colours.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  // §9.1: co ją skończyło, tymi samymi słowami, którymi
                  // powiedział to ekran śmierci — dwa różne opisy jednego
                  // zgonu czytają się jak dwie różne śmierci.
                  effects([
                    causeName(
                      l10n,
                      DeathCause.values
                          .where((cause) => cause.wire == run.cause)
                          .firstOrNull,
                    ),
                    run.hardcore
                        ? l10n.chronicleHardcore
                        : l10n.chronicleSoftcore,
                  ]),
                  style: TextStyle(fontSize: 12, color: colours.muted),
                ),
              ],
            ),
          ),
          Text(
            '${ended.year}-${_two(ended.month)}-${_two(ended.day)}',
            style: TextStyle(fontSize: 12, color: colours.muted),
          ),
        ],
      ),
    );
  }
}

String _two(int value) => value.toString().padLeft(2, '0');
