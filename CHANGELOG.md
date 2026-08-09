# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

### Stage 0 — Foundation

Persistence, simulation clock and build configuration. No gameplay yet: the
point of this stage is a save that survives a crash and an update.

#### Added

- **Save database** (`lib/data/db/`) — Drift/SQLite in WAL mode, schema v1 split
  by write frequency into hot, warm and cold layers (design doc §11.1.1).
  Foreign keys cascade from `profiles`, so vitals cannot outlive the character.
- **Write policy** (`SaveWriter`) — hot state buffered and flushed every 60 s and
  on every transition to the background; warm and cold writes go through
  immediately in a transaction and drag the hot layer with them. Worst-case loss
  is 60 seconds of physiology (§11.1.1).
- **Rotating snapshots** (`SnapshotStore`) — three periodic snapshots plus a
  mandatory pre-migration one, each with a SHA-256 checksum. The database is
  verified at startup and a corrupt file is replaced by the newest snapshot that
  opens cleanly; the corrupt file is quarantined rather than deleted, and the
  player is told how much time was lost (§11.1.3).
- **Monotonic clock** (`GameClock`) — elapsed time is derived from `last_update`
  with a high-water mark persisted across restarts. Winding the device clock
  back yields a zero-length tick, never a negative one, and winding it forward
  again cannot be cashed in twice (§2.1.1).
- **Tick engine** (`lib/sim/`) — pure, idempotent `advance()` running in an
  isolate at 1 Hz, with chunked catch-up after an absence. Offline consumption
  is floored at 10% of every resource and can never kill (§2.1.1).
- **Deterministic RNG** — splittable counter-based generator with independent
  streams per domain, so loot rolls cannot be shifted by firing extra shots.
  Seed is stored in the profile and the cursor is persisted, which is what makes
  developer-mode replays reproducible (§11, §11.2).
- **Profile export/import** — a single checksummed, versioned JSON bundle the
  player owns. Import always inserts a new character, so a mistaken restore
  cannot destroy a live streak (§11.3).
- **Startup sequence** (`SaveBootstrap`) — verify, snapshot before migrating,
  open, restore the clock, hand back a session.
- **Localisation** — `flutter_localizations` with ARB files for English and
  Polish; all player-facing strings are keys (§1.1).
- **CI** (`.github/workflows/ci.yml`) — format check, `flutter analyze
  --fatal-infos`, tests, a guard that generated code is current, a guard that
  every schema version has a committed dump, and a debug Android build.
- 84 tests covering the clock rollback guard, tick idempotency, the 60-second
  loss bound, snapshot rotation and recovery, migration harness and the export
  bundle.

#### Changed

- Application id and namespace are now `com.raidodevelopment.arlsza`, the store
  label is `ARLS-ZA Game`, and the Dart package is `arls_za`.
- Release builds use a keystore referenced from `android/key.properties`, which
  is not in the repository. Without it the build falls back to debug keys and
  says so; `-Prequire-signing=true` turns that into a hard failure.
- `minSdk` raised to 26, required for vibration amplitude control (§14.2).
- Android auto-backup and device transfer disabled. The save holds the shelter
  location and the body parameters entered at character creation, and neither
  may leave the device (§1.2, §8.2, §11.1.3).
- `DateTime` values are stored as ISO-8601 UTC text rather than unix seconds.
  The default returns local times, which silently breaks the clock rollback
  guard — a timestamp written as 12:00 UTC came back as 14:00 local and the
  difference was free time for the player.

## [0.1.0] - 2026-06-09

### Added
- Animated intro screen playing `assets/INTRO.mp4` on app launch (full-screen, immersive mode)
- Tap-to-skip on the intro screen
- Fade transition from intro to home screen
- App icon (`assets/icon.png`) displayed on home screen
- `video_player ^2.9.2` dependency
