/// Drugi etap tworzenia postaci: cztery decyzje, z czym się wychodzi (§4, §12).
///
/// ⚠️ **Sekwencyjnie, po jednym kroku, i dopiero na końcu wszystko naraz.**
/// Cztery listy na jednym ekranie to arkusz do wypełnienia; cztery kroki, z
/// których każdy stawia obok siebie dwie rzeczy robiące co innego, to cztery
/// decyzje. A na końcu podsumowanie, bo dopiero razem widać, czym się to
/// wszystko stało.
///
/// ⚠️ **Statystyki czyta [statsOf], nie ten plik.** Karta wyboru pokazuje te
/// same odczyty, które pokazuje arkusz przedmiotu w grze — bo to jest ten sam
/// przedmiot, i dwa miejsca liczące jego obrażenia osobno rozjechałyby się
/// przy pierwszej zmianie w JSON-ie.
library;

import 'package:flutter/material.dart';

import '../game/controllers/starting_kit_controller.dart';
import '../game/starting_kit.dart';
import '../items/item.dart';
import '../items/item_catalogue.dart';
import '../items/item_names.dart';
import '../items/item_stats.dart';
import '../l10n/app_localizations.dart';
import 'fonts.dart';
import 'item_details_sheet.dart' show statLabel;

/// §4: otwiera drugi etap tworzenia postaci i oddaje cztery wybory.
///
/// Null znaczy, że gracz się cofnął — a wtedy nie ma być zapisany ani wiersz.
Future<Map<KitStep, KitOption>?> pickStartingKit(
  BuildContext context, {
  required ItemCatalogue catalogue,
  required ItemNames names,
}) => Navigator.of(context).push<Map<KitStep, KitOption>>(
  MaterialPageRoute<Map<KitStep, KitOption>>(
    builder: (context) => StartingKitScreen(
      catalogue: catalogue,
      names: names,
      onDone: (chosen) => Navigator.of(context).pop(chosen),
    ),
  ),
);

class StartingKitScreen extends StatefulWidget {
  const StartingKitScreen({
    required this.catalogue,
    required this.names,
    required this.onDone,
    super.key,
  });

  final ItemCatalogue catalogue;

  /// Nazwy i zdania z §4.1 — jeden lookup na oba (§12).
  final ItemNames names;

  /// Cztery wybory, raz, na końcu. ⚠️ Ekran nie zapisuje niczego sam: §11.1
  /// mówi, że zapis albo jest cały, albo go nie ma, a kreator przerwany w
  /// połowie zostawiłby wiersze ekwipunku bez postaci.
  final void Function(Map<KitStep, KitOption> picks) onDone;

  @override
  State<StartingKitScreen> createState() => _StartingKitScreenState();
}

class _StartingKitScreenState extends State<StartingKitScreen> {
  final StartingKitController _wizard = StartingKitController();

  @override
  void dispose() {
    _wizard.dispose();
    super.dispose();
  }

  String _nameOf(ItemDefinition item) {
    final language = Localizations.localeOf(context).languageCode;
    return item.name.resolve(
      language: language,
      lookup: widget.names.forLanguage(language),
    );
  }

  String? _saidOf(ItemDefinition item) => widget.names.lookup(
    'item.${item.id}.desc',
    language: Localizations.localeOf(context).languageCode,
  );

  String _titleOf(L10n l10n, KitStep step) => switch (step) {
    KitStep.tools => l10n.kitStepTools,
    KitStep.medical => l10n.kitStepMedical,
    KitStep.combat => l10n.kitStepCombat,
    KitStep.food => l10n.kitStepFood,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);

    // ⚠️ Jeden `AnimatedBuilder` na cały ekran, nie cztery. Kreator ma jedno
    // źródło stanu i cztery karty, które z niego czytają — subskrypcja na
    // kartę to cztery subskrypcje na jedno dotknięcie palcem (§3.3).
    return AnimatedBuilder(
      animation: _wizard,
      builder: (context, _) {
        final step = _wizard.step;

        return Scaffold(
          appBar: AppBar(
            title: Text(step == null ? l10n.kitSummary : l10n.kitTitle),
            leading: _wizard.picks.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.arrow_back),
                    tooltip: l10n.kitBack,
                    onPressed: _wizard.back,
                  ),
            automaticallyImplyLeading: false,
          ),
          body: step == null ? _summary(l10n) : _choice(l10n, step),
        );
      },
    );
  }

  Widget _choice(L10n l10n, KitStep step) => ListView(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
    children: [
      Text(
        l10n.kitStepOf(_wizard.index + 1, KitStep.values.length),
        style: TextStyle(
          fontSize: 11,
          letterSpacing: 1.1,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        _titleOf(l10n, step),
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 16),
      for (final option in kStartingKit[step]!)
        _OptionCard(
          option: option,
          item: widget.catalogue[option.itemId]!,
          name: _nameOf(widget.catalogue[option.itemId]!),
          said: _saidOf(widget.catalogue[option.itemId]!),
          countLabel: option.count > 1 ? l10n.kitCount(option.count) : null,
          onPick: () => _wizard.pick(step, option),
        ),
    ],
  );

  Widget _summary(L10n l10n) => Column(
    children: [
      Expanded(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          children: [
            Text(
              l10n.kitSummaryHint,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),

            // ⚠️ Obok siebie, nie pod sobą. Cztery karty w rzędzie są jedną
            // odpowiedzią na pytanie „czym to się stało"; cztery pod sobą są
            // listą, którą trzeba przewinąć, żeby ją sobie złożyć w głowie.
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final step in KitStep.values)
                    if (_wizard.picks[step] case final pick?)
                      SizedBox(
                        width: 190,
                        child: _OptionCard(
                          option: pick,
                          item: widget.catalogue[pick.itemId]!,
                          name: _nameOf(widget.catalogue[pick.itemId]!),
                          said: _saidOf(widget.catalogue[pick.itemId]!),
                          countLabel: pick.count > 1
                              ? l10n.kitCount(pick.count)
                              : null,
                          onPick: null,
                        ),
                      ),
                ],
              ),
            ),
          ],
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () => widget.onDone(_wizard.picks),
            child: Text(l10n.kitConfirm),
          ),
        ),
      ),
    ],
  );
}

/// Jedna możliwość: co to jest, co robi, i ile tego jest.
///
/// [onPick] null znaczy, że to jest karta podsumowania — wybór już zapadł.
class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.option,
    required this.item,
    required this.name,
    required this.said,
    required this.countLabel,
    required this.onPick,
  });

  final KitOption option;
  final ItemDefinition item;
  final String name;
  final String? said;
  final String? countLabel;
  final VoidCallback? onPick;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 10, right: 10),
      child: InkWell(
        onTap: onPick,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (countLabel != null)
                    Text(
                      countLabel!,
                      style: TextStyle(
                        fontSize: 14,
                        fontFamily: kDataFont,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),

              // §12: zdanie o tym, czym rzecz jest — to samo, które gracz
              // zobaczy potem na karcie przedmiotu.
              if (said case final sentence?) ...[
                const SizedBox(height: 4),
                Text(
                  sentence,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.35,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],

              const SizedBox(height: 8),

              // ⚠️ Te same odczyty co w grze, tą samą funkcją. Trzy pierwsze:
              // karta wyboru ma pomóc zdecydować, a nie nauczyć wszystkiego.
              for (final stat in statsOf(item).take(3))
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          statLabel(l10n, stat.key),
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      Text(
                        stat.formatted,
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: kDataFont,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
