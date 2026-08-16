/// What is left where something went down (§10.3, §12).
///
/// The sheet exists because the map deliberately does not say what is in the
/// pockets. A skull two hundred metres off is a fact — something died there —
/// and the contents are a reason to walk over, not a thing to read from here.
/// So this says what it was, how far it is, and whether anybody has been
/// through it already, and it offers the one action at arm's length.
library;

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'hud.dart' show HudColors;

Future<void> showRemains(
  BuildContext context, {
  required String kindName,
  required double distanceM,
  required bool searched,
  required VoidCallback? onSearch,
}) => showModalBottomSheet<void>(
  context: context,
  builder: (context) => RemainsSheet(
    kindName: kindName,
    distanceM: distanceM,
    searched: searched,
    onSearch: onSearch,
  ),
);

class RemainsSheet extends StatelessWidget {
  const RemainsSheet({
    required this.kindName,
    required this.distanceM,
    required this.searched,
    required this.onSearch,
    super.key,
  });

  final String kindName;
  final double distanceM;
  final bool searched;

  /// Null when it has already been turned out, or when it is out of reach —
  /// §4.8's arm's length, the same one a pile on the ground uses.
  final VoidCallback? onSearch;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final colours = HudColors.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('☠', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${l10n.remainsTitle} · $kindName',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: colours.text,
                    ),
                  ),
                ),
                Text(
                  '${distanceM.round()} m',
                  style: TextStyle(fontSize: 13, color: colours.data),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              searched ? l10n.remainsEmptied : l10n.remainsUnsearched,
              style: TextStyle(fontSize: 13, height: 1.4, color: colours.muted),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(l10n.commonOk),
                  ),
                  const SizedBox(width: 4),
                  FilledButton.icon(
                    onPressed: onSearch == null
                        ? null
                        : () {
                            Navigator.of(context).pop();
                            onSearch!();
                          },
                    icon: const Icon(Icons.search, size: 18),
                    label: Text(l10n.remainsSearch),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
