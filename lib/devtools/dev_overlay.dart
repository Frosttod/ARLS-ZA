/// Diagnostic overlay and control panels (design doc §11.2).
///
/// ⚠️ **Scope note.** §11.2 asks the overlay to break down `MOA_total`, hit
/// chance, noise radius and enemy state machines. None of those systems exist
/// yet — they arrive in stage 5. What is here covers what stage 1 can honestly
/// display: the clock, the position layer and the physiology. The combat rows
/// are marked in `DevOverlay` so the gap is visible rather than forgotten.
///
/// The whole file is reachable only from behind `if (kDevTools)`, so it is
/// removed from release builds along with everything it imports.
library;

import 'package:flutter/material.dart';

import '../core/game_clock.dart';
import '../core/scaled_wall_clock.dart';
import '../location/position_fix.dart';
import '../sim/tick.dart';
import 'dev_console.dart';
import 'dev_mode.dart';
import 'simulated_position_source.dart';

/// Live values the overlay reads from the host each frame.
class DevSnapshot {
  const DevSnapshot({
    required this.state,
    required this.fix,
    required this.signal,
    required this.ticksApplied,
    this.lastFlushAt,
    this.clockRolledBack = false,
  });

  final SimState? state;
  final PositionFix? fix;
  final PositionSignal signal;

  /// Simulated seconds applied since the session started. The 24-second day of
  /// the exit criterion is checked against this.
  final int ticksApplied;

  final DateTime? lastFlushAt;
  final bool clockRolledBack;
}

/// A small always-on readout, plus a button that opens the full panel.
class DevOverlay extends StatelessWidget {
  const DevOverlay({required this.console, required this.snapshot, super.key});

  final DevConsole console;
  final DevSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    if (!kDevTools) return const SizedBox.shrink();

    final state = snapshot.state;
    return Positioned(
      right: 8,
      top: MediaQuery.of(context).padding.top + 8,
      child: Material(
        color: Colors.black.withValues(alpha: 0.72),
        child: InkWell(
          onTap: () => _openPanel(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: DefaultTextStyle(
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                color: Colors.white,
                height: 1.35,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'DEV ${console.timeScale.label}',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: Color(0xFFFFB4A2),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text('sygnał ${_signalLabel(snapshot.signal)}'),
                  if (snapshot.fix case final fix?)
                    Text('±${fix.accuracyM.toStringAsFixed(1)} m'),
                  if (state != null) ...[
                    Text('krew ${state.bloodMl.toStringAsFixed(0)} ml'),
                    Text('woda ${state.waterMl.toStringAsFixed(0)} ml'),
                    Text('kcal ${state.caloriesKcal.toStringAsFixed(0)}'),
                    Text('HR ${state.heartRateBpm.toStringAsFixed(0)}'),
                    Text('strefa ${state.zone.wire}'),
                  ],
                  Text('tick ${snapshot.ticksApplied} s'),
                  // Renders the build marker, which is what gives
                  // tool/check_release_strip.dart something to search for.
                  // Must stay in the widget tree: an unreferenced constant is
                  // tree-shaken even from a devtools build, and the check then
                  // passes for the wrong reason.
                  Text(
                    kDevToolsMarker,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 7,
                      color: Colors.white24,
                    ),
                  ),
                  if (snapshot.clockRolledBack)
                    const Text(
                      'ZEGAR COFNIĘTY',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: Color(0xFFFF6B6B),
                      ),
                    ),
                  if (console.isRecording)
                    Text('REC ${console.recorder!.events.length}'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openPanel(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF14181A),
      builder: (_) => DevPanel(console: console, snapshot: snapshot),
    );
  }

  static String _signalLabel(PositionSignal signal) => switch (signal) {
    PositionSignal.good => 'ok',
    PositionSignal.degraded => 'słaby',
    PositionSignal.lost => 'BRAK',
    PositionSignal.unavailable => 'wył.',
  };
}

/// The full control panel: time, GPS and physiology.
class DevPanel extends StatefulWidget {
  const DevPanel({required this.console, required this.snapshot, super.key});

  final DevConsole console;
  final DevSnapshot snapshot;

  @override
  State<DevPanel> createState() => _DevPanelState();
}

class _DevPanelState extends State<DevPanel> {
  final _latController = TextEditingController();
  final _lonController = TextEditingController();

  @override
  void dispose() {
    _latController.dispose();
    _lonController.dispose();
    super.dispose();
  }

  DevConsole get console => widget.console;

  @override
  Widget build(BuildContext context) {
    if (!kDevTools) return const SizedBox.shrink();

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: DefaultTextStyle(
          style: const TextStyle(color: Colors.white, fontSize: 13),
          child: ListenableBuilder(
            listenable: console,
            builder: (context, _) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const _Heading('Czas'),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final scale in TimeScale.values)
                      ChoiceChip(
                        label: Text(
                          '${scale.label}  ·  doba w '
                          '${_short(scale.dayDuration)}',
                        ),
                        selected: console.timeScale == scale,
                        onSelected: (_) => console.setTimeScale(scale),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final skip in const [
                      Duration(hours: 1),
                      Duration(hours: 6),
                      Duration(days: 1),
                    ])
                      OutlinedButton(
                        onPressed: () => console.skipForward(skip),
                        child: Text('+${_short(skip)}'),
                      ),
                  ],
                ),

                const _Heading('GPS'),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final mode in SimMovementMode.values)
                      ChoiceChip(
                        label: Text(_modeLabel(mode)),
                        selected: console.source.mode == mode,
                        onSelected: (_) => console.setMovementMode(mode),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final preset in SimSpeedPreset.values)
                      ChoiceChip(
                        label: Text(
                          '${preset.label} '
                          '${preset.kmh.toStringAsFixed(1)} km/h',
                        ),
                        selected: console.source.speedMps == preset.mps,
                        onSelected: (_) => console.setSpeed(preset),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    IconButton(
                      onPressed: () => console.steer(-15),
                      icon: const Icon(Icons.turn_left, color: Colors.white),
                      tooltip: 'w lewo 15°',
                    ),
                    Text(
                      '${console.source.headingDeg.toStringAsFixed(0)}°',
                      style: const TextStyle(fontFamily: 'monospace'),
                    ),
                    IconButton(
                      onPressed: () => console.steer(15),
                      icon: const Icon(Icons.turn_right, color: Colors.white),
                      tooltip: 'w prawo 15°',
                    ),
                    const Spacer(),
                    Text(
                      'trasa: ${console.source.track.name} '
                      '(${console.source.track.lengthM.toStringAsFixed(0)} m)',
                      style: const TextStyle(fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final quality in SimSignalQuality.values)
                      ChoiceChip(
                        label: Text(quality.label),
                        selected: console.source.quality == quality,
                        onSelected: (_) => console.setSignalQuality(quality),
                      ),
                  ],
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  value: console.source.noiseEnabled,
                  onChanged: console.setNoiseEnabled,
                  title: const Text(
                    'Szum pozycji',
                    style: TextStyle(color: Colors.white, fontSize: 13),
                  ),
                  subtitle: const Text(
                    'wyłącz, żeby odróżnić błąd logiki od dryfu GPS',
                    style: TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _latController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(labelText: 'lat'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _lonController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(labelText: 'lon'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(onPressed: _jump, child: const Text('Skocz')),
                  ],
                ),

                const _Heading('Fizjologia'),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final preset in DevPreset.values)
                      OutlinedButton(
                        onPressed: () {
                          final state = widget.snapshot.state;
                          if (state != null) {
                            console.applyPreset(preset, state);
                          }
                        },
                        child: Text(preset.label),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final zone in MetabolicZone.values)
                      ChoiceChip(
                        label: Text(
                          '${zone.wire} '
                          '${(zone.calorieFactor * 100).toStringAsFixed(0)}%',
                        ),
                        selected: widget.snapshot.state?.zone == zone,
                        onSelected: (_) => console.setZone(zone),
                      ),
                  ],
                ),

                const _Heading('Powtórka'),
                Row(
                  children: [
                    FilledButton.tonal(
                      onPressed: console.isRecording
                          ? () => console.stopRecording()
                          : null,
                      child: Text(
                        console.isRecording
                            ? 'Zatrzymaj (${console.recorder!.events.length})'
                            : 'Nagrywanie wyłączone',
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: console.isRecording
                          ? () => console.mark('marker')
                          : null,
                      child: const Text('Znacznik'),
                    ),
                  ],
                ),

                const _Heading('Brakuje — etap 5'),
                const Text(
                  'Rozbicie MOA_total, szansa trafienia, promień hałasu i stany '
                  'maszyny przeciwników (§11.2). Te systemy jeszcze nie '
                  'istnieją; nakładka pokazuje wyłącznie to, co da się zmierzyć '
                  'dzisiaj.',
                  style: TextStyle(color: Colors.white60, fontSize: 11),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _jump() {
    final lat = double.tryParse(_latController.text.trim());
    final lon = double.tryParse(_lonController.text.trim());
    if (lat == null || lon == null) return;
    if (lat < -90 || lat > 90 || lon < -180 || lon > 180) return;
    console.jumpTo(lat, lon);
  }

  static String _modeLabel(SimMovementMode mode) => switch (mode) {
    SimMovementMode.stationary => 'postój',
    SimMovementMode.route => 'trasa',
    SimMovementMode.manual => 'ręcznie',
  };
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 16, bottom: 6),
    child: Text(
      text.toUpperCase(),
      style: const TextStyle(
        color: Color(0xFFFFB4A2),
        fontSize: 11,
        letterSpacing: 2,
        fontFamily: 'monospace',
      ),
    ),
  );
}

String _short(Duration d) {
  if (d.inDays >= 1) return '${d.inDays} d';
  if (d.inHours >= 1) return '${d.inHours} h';
  if (d.inMinutes >= 1) return '${d.inMinutes} min';
  return '${d.inSeconds} s';
}

/// One-line build description for the panel header.
String describeDevTools(GameClock clock) =>
    'devtools · mark=${clock.highWaterMark}';
