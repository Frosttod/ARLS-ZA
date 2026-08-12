/// The first screen of a first run (§1.1, §3.5).
///
/// Language comes before everything, including the safety briefing, for a
/// reason that is not convenience: §3.5 is about traffic and strangers, and a
/// player who cannot read it has not been briefed. Everything after this screen
/// assumes the words on it are understood.
///
/// Both options are written in their own language and neither is preselected.
/// A screen that reads "Choose a language" to somebody who does not read
/// English has already failed, so the labels carry themselves.
library;

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'app_settings.dart';

class LanguagePickerScreen extends StatelessWidget {
  const LanguagePickerScreen({required this.onChosen, super.key});

  final void Function(Locale) onChosen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Wybierz język\nChoose a language',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 32),
                for (final locale in kGameLocales)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: FilledButton(
                      onPressed: () => onChosen(locale),
                      child: Text(_nameOf(locale)),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Each language names itself. Translating a language list defeats it.
  static String _nameOf(Locale locale) => switch (locale.languageCode) {
    'pl' => 'Polski',
    'en' => 'English',
    _ => locale.languageCode.toUpperCase(),
  };
}

/// The reason the language screen exists, restated where a reader will find it:
/// [L10n] is only correct after this screen has run.
const String kLanguageFirstRunNote =
    'The briefing of §3.5 is read after this screen, never before it.';
