/// What stands between a player and a place worth searching (§19.3, §5.6.1).
///
/// §19.3 asks for barriers so that tools mean something outside crafting: a
/// crowbar is not a recipe ingredient, it is the difference between a shop you
/// can enter and one you cannot. The barrier is a property of the place, so it
/// lives in `loot_tables.json` beside the table — a pharmacy is locked, a car
/// park is not, and that is content rather than code.
///
/// **Every barrier has a loud way through and most have a quiet one.** Forcing
/// a door is 150 m of noise (§5.6.1) and takes seconds; picking the lock is
/// quiet and takes a minute. That is the whole decision, and it is the same
/// shape as the one §19.3 builds the search depths around: speed against
/// attention.
///
/// **Nothing here is impassable for want of an item**, except the padlock,
/// which is the one barrier the doc says requires a tool. A player who owns
/// nothing can still get into a building through a window — loudly, and with
/// the glass as the price.
library;

/// A way in.
class BarrierBreach {
  const BarrierBreach({
    required this.seconds,
    required this.noiseM,
    this.toolIds = const [],
    this.needsTool = false,
  });

  final int seconds;

  /// §5.6.1. Read by the enemies of §5.6.2, who walk to where the sound was
  /// rather than to the player.
  final double noiseM;

  /// Items that make this breach available, in order of preference.
  final List<String> toolIds;

  /// True where the breach cannot be attempted empty-handed.
  final bool needsTool;

  bool isAvailableWith(Set<String> carried) =>
      !needsTool || toolIds.any(carried.contains);

  /// Czym gracz naprawdę tędy wejdzie, albo null, jeśli gołymi rękami.
  ///
  /// ⚠️ **Ta sama kolejność, którą zużywa `InventoryController.useTool`.** Panel
  /// pokazujący łom, a zużywający siekierę, byłby gorszy od panelu milczącego:
  /// gracz zapamiętałby cenę, której nie zapłacił.
  String? toolWith(Set<String> carried) =>
      toolIds.where(carried.contains).firstOrNull;
}

/// A barrier on a place, and the ways through it.
enum Barrier {
  /// §19.3: forcing it is 150 m of noise (§5.6.1). Picks open it quietly, and
  /// a crowbar makes the same noise faster than shoulders do.
  door(
    alreadyOpenShare: 0.35,
    // ⚠️ **Półtorej minuty, i to jest zgłoszenie z terenu.** Dwadzieścia sekund
    // ramieniem przy dwunastu łomem znaczyło, że narzędzia są ozdobą: osiem
    // sekund różnicy nikogo nie skłoni do noszenia kilograma sześciuset. Gorzej
    // — gołe ręce były **szybsze** od wytrychów, więc cicha droga nie miała
    // żadnej przewagi poza hałasem.
    //
    // Teraz kolejność jest taka, jaka ma być: łom dwanaście sekund, wytrychy
    // minutę, ramię półtorej minuty i dwieście metrów. Każde narzędzie jest
    // warte noszenia, a wejście bez niczego zostaje możliwe i kosztuje.
    force: BarrierBreach(seconds: 90, noiseM: 200),
    quiet: BarrierBreach(
      seconds: 60,
      noiseM: 20,
      toolIds: ['tool_lockpicks'],
      needsTool: true,
    ),
    pry: BarrierBreach(
      seconds: 12,
      noiseM: 150,
      toolIds: ['melee_crowbar', 'melee_axe'],
      needsTool: true,
    ),
  ),

  /// §19.3 names this one as the barrier that requires a tool. Shoulders do
  /// not open a padlock, and pretending otherwise would make every tool in the
  /// catalogue optional.
  padlock(
    alreadyOpenShare: 0.10,
    quiet: BarrierBreach(
      seconds: 45,
      noiseM: 20,
      toolIds: ['tool_lockpicks'],
      needsTool: true,
    ),
    // ⚠️ Bolt cutters are the tool this barrier was written for, and there
    // were none in the game: a padlock could only be levered at with a crowbar
    // or worried at with a saw. Ten seconds against the lockpicks' forty-five,
    // and sixty metres of noise against twenty — two kilograms of
    // single-purpose steel bought speed and paid in attention, which is the
    // shape every tool decision in §19.3 is supposed to have.
    pry: BarrierBreach(
      seconds: 10,
      noiseM: 60,
      toolIds: ['tool_bolt_cutters'],
      needsTool: true,
    ),
    force: BarrierBreach(
      seconds: 25,
      noiseM: 60,
      toolIds: ['melee_crowbar', 'tool_saw', 'tool_multitool'],
      needsTool: true,
    ),
  ),

  /// The way in that always exists, and always costs the same 150 m.
  window(
    alreadyOpenShare: 0.45,
    // Szyba nie broni się długo — ale pięć sekund to był odruch, nie decyzja.
    // Dziesięć wystarczy, żeby dało się rozmyślić, i dalej jest najszybszą
    // drogą do środka, jaką ma ktoś bez narzędzi.
    force: BarrierBreach(seconds: 10, noiseM: 160),
    quiet: null,
    pry: null,
  );

  const Barrier({
    required this.alreadyOpenShare,
    required this.force,
    required this.quiet,
    required this.pry,
  });

  /// How often somebody already got here first.
  ///
  /// A world where every door is shut is a world nobody else lived in, and it
  /// makes the first hour of the game a lockpicking exercise. Glass goes first
  /// and stays gone, a shop door is often already off its hinges, and a
  /// padlock is the one that usually held — which is what makes a padlock
  /// worth walking to.
  final double alreadyOpenShare;

  /// Shoulders, boots, or a rock. Null where that is not a thing a person can
  /// do to this barrier.
  final BarrierBreach? force;

  /// Slow and nearly silent. Lockpicks, and nothing else.
  final BarrierBreach? quiet;

  /// Fast, loud enough, and needs something to lever or cut with.
  final BarrierBreach? pry;

  static Barrier? fromWire(String? value) => switch (value) {
    'door' => Barrier.door,
    'padlock' => Barrier.padlock,
    'window' => Barrier.window,
    _ => null,
  };

  /// Every way through, in the order they are worth offering: quietest first.
  ///
  /// Quietest first because the loud option is always available and always
  /// obvious, and a player scanning a panel in the dark should meet the
  /// careful choice before the impatient one.
  List<BarrierBreach> get breaches => [?quiet, ?pry, ?force];

  /// The ways through that this inventory actually allows.
  List<BarrierBreach> breachesWith(Set<String> carried) =>
      breaches.where((breach) => breach.isAvailableWith(carried)).toList();

  /// True when nothing carried opens it. Only ever true of a padlock.
  bool blocks(Set<String> carried) => breachesWith(carried).isEmpty;
}
