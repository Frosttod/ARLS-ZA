/// The safety briefing, shown once before the first step (§3.5).
///
/// §3.5 is the section marked mandatory, and this screen is the part of it the
/// player actually reads. Two decisions worth stating:
///
/// * **The button is at the bottom of the rules, not beside them.** The reader
///   has to travel past every line to reach it. This is not a dark pattern in
///   reverse — it is the difference between a briefing and a dialog.
/// * **It is accepted, not dismissed.** There is no close button, no back
///   gesture out of it and no "later". The alternative is a player walking into
///   traffic having agreed to nothing.
/// * **A tick, not a tap.** §15.3 asks for a checkbox rather than a bare
///   "Next", and the difference is not decoration: a button at the end of a
///   list is pressed by a thumb travelling downwards, while a box has to be
///   aimed at. The button stays dead until it is ticked.
library;

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

class SafetyBriefingScreen extends StatefulWidget {
  const SafetyBriefingScreen({required this.onAccept, super.key});

  final VoidCallback onAccept;

  @override
  State<SafetyBriefingScreen> createState() => _SafetyBriefingScreenState();
}

class _SafetyBriefingScreenState extends State<SafetyBriefingScreen> {
  var _taken = false;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final theme = Theme.of(context);

    final rules = [
      l10n.safetyRuleTraffic,
      l10n.safetyRuleNoDriving,
      l10n.safetyRuleNoTrespass,
      l10n.safetyRuleRespect,
      l10n.safetyRuleNight,
      l10n.safetyRuleStop,
    ];

    return PopScope(
      // There is no way out of this screen except through it.
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                l10n.safetyBriefingTitle,
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              Text(l10n.safetyBriefingIntro, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 24),
              for (final rule in rules)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 7, right: 12),
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.error,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Expanded(
                        child: Text(rule, style: theme.textTheme.bodyMedium),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
              CheckboxListTile(
                value: _taken,
                onChanged: (value) => setState(() => _taken = value ?? false),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(
                  l10n.safetyBriefingAccept,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: 8),
              FilledButton(
                // ⚠️ Null, not a button that scolds. A disabled control says
                // "not yet" without taking a tap to say it.
                onPressed: _taken ? widget.onAccept : null,
                child: Text(l10n.safetyBriefingGo),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
