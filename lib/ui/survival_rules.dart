/// The three rules, kept where a player can find them again (§15.7).
///
/// ⚠️ **Onboarding is the one screen nobody re-reads, and these three lines are
/// the ones worth re-reading.** §15.7 asks for them at the end of the first
/// session *and* in the menu afterwards, because the lesson they carry —
/// standing still is worth more than any weapon in the game — is one a player
/// only believes after it has cost them something.
///
/// Deliberately not a tutorial: no progress, no dismissal, nothing to complete.
/// A page you can walk out of, and come back to on day thirty.
library;

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

class SurvivalRulesScreen extends StatelessWidget {
  const SurvivalRulesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final theme = Theme.of(context);

    final rules = <(String, String)>[
      (l10n.rulesStandTitle, l10n.rulesStandBody),
      (l10n.rulesRunTitle, l10n.rulesRunBody),
      (l10n.rulesBodyTitle, l10n.rulesBodyBody),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.rulesTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(l10n.rulesIntro, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 24),
            for (final (title, body) in rules)
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(body, style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
