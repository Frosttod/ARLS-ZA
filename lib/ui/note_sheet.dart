/// Reading somebody else's note (§19.1).
///
/// A sheet rather than a screen, and deliberately plain: the note is the only
/// thing on it. §19.1.2 asks for the concrete over the grand, and framing a
/// shopping list in an interface would work against the writing.
library;

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../notes/note.dart';
import 'hud.dart' show HudColors;

Future<void> showNote(
  BuildContext context, {
  required Note note,
  required PlaceNames names,
}) {
  final language = Localizations.localeOf(context).languageCode;

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      final colours = HudColors.of(context);
      final l10n = L10n.of(context);

      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                note.titleIn(language),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colours.text,
                ),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: SingleChildScrollView(
                  child: Text(
                    note.textIn(language, names),
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: colours.text,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.noteClose),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
