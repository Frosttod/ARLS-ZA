# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

### Stage 2 — Character and physiology

The first system that can be balanced. A character sheet now turns into a body
that spends calories, water, sleep and blood in real time, and the game says so
on screen.

#### Added

- **Character sheet and derived body** (`lib/sim/body.dart`) — name, sex, age,
  height and weight, validated on range and on a BMI of 12–60 so no formula is
  fed nonsense (§1.2). From those four figures come blood volume (Nadler),
  basal metabolic rate (Mifflin–St Jeor), maximum heart rate (Tanaka), daily
  water at 35 ml/kg, resting heart rate and the carry limits. Carry weight is
  the same for both sexes, which is a deliberate choice and has a test saying
  so.
- **Metabolism** (`lib/sim/metabolism.dart`) — MET from ground speed, a load
  surcharge after Pandolf, and energy spent as the excess over resting rather
  than as the full MET cost, because the daily baseline already comes from
  Mifflin–St Jeor. Heart rate chases its target and relaxes back on an
  exponential with τ ≈ 90 s.
- **Hunger, thirst, sleep and blood** (`lib/sim/physiology.dart`) — the
  threshold tables of §2.3–§2.6, ATLS shock classes, bleed tiers scaled by
  exertion, and sweat split into an environmental part that heat and clothing
  charge for at any activity and an activity part on top.
- **Daylight without a network** (`lib/sim/daylight.dart`) — solar declination
  and hour angle give sunrise and sunset anywhere offline, including polar day
  and polar night (§17.2). Automatic sleep depends on it.
- **One occupation at a time** (`lib/sim/occupation.dart`) — the rule of §2.1a,
  with occupations, actions and background processes kept apart. Stored as
  JSON, so the shelter systems of §8 and §18 can add fields without a migration
  each.
- **Full tick model** (`lib/sim/tick.dart`) — pure, idempotent and linear in
  elapsed time, so fourteen days of catch-up gives the same state as fourteen
  days of playing. Metabolic zones scale the drain: field 100%, camp 50%,
  shelter 35%, sleep 20%.
- **Game loop** (`lib/game/game_loop.dart`) — joins position to speed to MET to
  the tick to the save writer, and flushes at the cadences of §11.1.1. Speed is
  computed from consecutive fixes rather than read off the fix, because a real
  chip does not always supply it. Losing signal zeroes movement instead of
  freezing the last known speed, so GPS drift is not charged to the player.
- **Session composition** (`lib/game/game_session.dart`) — creates a character
  and its opening vitals in one transaction, reads the active one back, and
  starts the loop. Kept out of the widgets so the sequence is testable without
  pumping a UI.
- **Character creator and HUD** (`lib/ui/`) — the creator shows every derived
  figure as the player types and leaves the irreversible death mode unselected.
  The HUD reports blood in millilitres as well as per cent, water, calories,
  heart rate and carry load, and names every status in words rather than
  leaning on icons and colour alone (§12).
- **Schema v2** — four columns added to the existing tables under an additive
  migration, with the pre-migration snapshot taken first.

#### Fixed

- **Blood volume for the reference character.** Nadler gives **5319 ml** for
  180 cm / 80 kg, not the 5290 ml stated in the design document. The figure had
  already spread to the §15.4 mockup, both language versions of the project
  site and every test fixture; corrected in all of them.

### Stage 1 — Developer mode

Nothing player-facing. This stage exists so the metabolic model can be balanced
without walking several kilometres for every build (design doc §11.2).

#### Added

- **Position abstraction** (`lib/location/`) — `PositionSource` is the single
  entry point for coordinates. The real GPS (stage 3) and the simulator both
  implement it, so nothing downstream can tell them apart. The dropout watchdog
  of §3.2 lives in the shared base class rather than being written twice.
- **GPS simulator** — walks a GPX track at a chosen ground speed, or is steered
  by hand, or teleports to a coordinate. Speed presets match the MET bands of
  §2.2. A minimal GPX reader is included; routes loop, so a simulated walk can
  run indefinitely.
- **GPS error model** — accuracy drawn from a quality band (open sky, urban,
  street canyon, indoors) and the position scattered uniformly inside that
  circle. A stationary character still drifts, which is what makes the dead-zone
  filter of §3.2 testable. The canyon preset deliberately breaches the 25 m
  accuracy gate; the indoor preset stops fixes entirely.
- **Time acceleration** (`ScaledWallClock`) — ×1, ×60, ×3600, plus forward-only
  skips. It multiplies elapsed time underneath `GameClock`, so the tick engine
  receives an ordinary `Duration` and never learns time was scaled. Switching
  scale re-anchors rather than recomputing, so virtual time never jumps
  backwards into the rollback guard of §2.1.1.
- **Session recording and replay** — a seed plus an event stream, stored as
  JSON Lines. Replays are deterministic and go through the same `advance()` the
  game uses. Events carry simulation time, so a recording made at ×3600 replays
  identically at ×1. A truncated last line costs one event, not the file.
- **Developer console and overlay** — time controls, movement and signal
  controls, coordinate jump, physiology overrides and one-tap fixtures. Every
  override is recorded, because a balance figure taken from a session where
  someone quietly refilled the blood is worthless.
- **Release stripping** (`tool/check_release_strip.dart`) — developer mode is
  gated on a `const bool`, which lets the AOT compiler remove the branch and
  everything only it reaches. The tool searches the built artifact for a marker
  reachable only from devtools code. CI runs it twice: once on a normal release
  (must pass) and once on a build with devtools forced on (must fail), so a
  check that stopped finding anything cannot masquerade as a pass.
- 54 further tests, 138 in total.

#### Known gaps

- The diagnostic overlay does not yet break down `MOA_total`, hit chance, noise
  radius or enemy state machines (§11.2). Those systems arrive in stage 5; the
  gap is stated in the panel itself rather than left implicit.
- The §3.2 filters — Kalman, the 25 m accuracy gate, the 8 m/10 s dead zone —
  belong to stage 3. The simulator already produces the data that will exercise
  them.

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
