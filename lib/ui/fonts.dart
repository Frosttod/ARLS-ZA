/// The two faces the game is read in (§3.6, §12).
///
/// Bundled, never fetched. The game is offline-first and is played in fields
/// with no signal; a screen waiting on a webfont is a blank screen.
///
/// IBM Plex, under the SIL Open Font License 1.1 — the licence travels with
/// the files in `assets/fonts/OFL.txt`. Chosen for being a measuring
/// instrument rather than a poster: it was drawn for dashboards, and this is a
/// game read at arm's length, in the rain, while walking.
library;

/// Everything that is words.
///
/// One variable file carries every weight and every width — Condensed
/// included — for less than the two static faces it replaces.
const String kUiFont = 'Plex';

/// Everything that is a figure.
///
/// ⚠️ Worth knowing before changing either of these: **the digits of both
/// faces are exactly 600/1000 em**, measured out of the files rather than
/// assumed. So a number set in one is the same width as the same number set in
/// the other, and mixing them in a fixed-width column cannot break the layout.
/// Only the letters beside a figure — `ml`, `kcal`, `%` — differ at all.
///
/// ⚠️ And the other half of that measurement: IBM Plex Sans carries no `tnum`
/// feature, so [FontFeature.tabularFigures] does nothing in it. It does not
/// have to. Both faces are tabular *by default* — every digit already has the
/// same advance — which is what the dozen calls asking for tabular figures
/// were really asking for. The calls stay because they say what is meant, and
/// because a future face might need them.
const String kDataFont = 'PlexMono';
