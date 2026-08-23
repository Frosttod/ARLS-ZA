/// What to say when the operating system will not give us a position (§16.1).
///
/// ⚠️ Each state gets its own words and its own button. "Location refused"
/// with a button that opens the wrong settings page is worse than saying
/// nothing at all — the player is standing outside wondering why the map is
/// empty, and a wrong instruction sends them somewhere that cannot help.
///
/// Out of `main.dart` because it is what it looks like: a paragraph and a
/// button. Nothing here knows anything about the game, which is exactly why it
/// did not belong in the file that knows everything about it.
library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../location/location_access.dart';

/// A bordered paragraph: a title, and what it means.
///
/// ⚠️ Not [Notice], which is a different thing with a similar name — that one
/// is the line the game says under the HUD and takes itself away after four
/// seconds (§12). This one is a wall: it stays until the reason for it does.
class BlockedPanel extends StatelessWidget {
  const BlockedPanel({required this.title, required this.body, super.key});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: Theme.of(context).colorScheme.error,
            width: 2,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 4),
          Text(body, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

/// §16.1: the wall, with the one button that can take it down.
class LocationGate extends StatelessWidget {
  const LocationGate({required this.access, required this.onRetry, super.key});

  final LocationAccess access;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);

    final (title, body) = switch (access) {
      LocationAccess.serviceDisabled => (
        l10n.locationServiceOffTitle,
        l10n.locationServiceOffBody,
      ),
      LocationAccess.deniedForever => (
        l10n.locationDeniedTitle,
        l10n.locationDeniedBody,
      ),
      // Not yet asked, or asked and dismissed. Explain what it is for before
      // asking again, rather than firing the system prompt a second time with
      // no context (§16.1).
      _ => (l10n.locationTitle, l10n.locationBody),
    };

    return Column(
      children: [
        BlockedPanel(title: title, body: body),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: () => unawaited(onRetry()),
          child: Text(
            access.needsSystemSettings
                ? l10n.locationSettings
                : l10n.locationGrant,
          ),
        ),
      ],
    );
  }
}
