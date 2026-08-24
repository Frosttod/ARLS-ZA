import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'data/db/snapshot_store.dart';
import 'data/persistence/save_bootstrap.dart';
import 'devtools/dev_mode.dart';
import 'devtools/dev_overlay.dart';
import 'devtools/dev_session.dart';
import 'game/controllers/action_controller.dart';
import 'game/controllers/combat_controller.dart';
import 'game/controllers/skill_controller.dart';
import 'game/controllers/craft_controller.dart';
import 'game/controllers/inventory_controller.dart';
import 'game/controllers/loot_controller.dart';
import 'game/controllers/shelter_controller.dart';
import 'game/controllers/stash_controller.dart';
import 'game/game_loop.dart';
import 'inventory/body_slots.dart';
import 'inventory/inventory.dart';
import 'inventory/item_use.dart';
import 'items/item_assets.dart';
import 'items/item.dart';
import 'items/item_catalogue.dart';
import 'items/item_names.dart';
import 'combat/aim.dart';
import 'combat/ballistics.dart';
import 'combat/combat_session.dart';
import 'combat/engagement.dart';
import 'combat/magazine.dart';
import 'craft/craft_job.dart';
import 'craft/salvage_batch.dart';
import 'craft/item_recipe.dart';
import 'ui/action_strip.dart';
import 'app/bootstrap.dart';
import 'app/game_controllers.dart';
import 'app/game_scope.dart';
import 'app/crash_log.dart';
import 'ui/craft_screen.dart';
import 'ui/intro_screen.dart';
import 'ui/location_gate.dart';
import 'ui/disassemble_screen.dart';
import 'combat/magazine_item.dart';
import 'combat/weapon_load.dart';
import 'combat/enemy.dart';
import 'combat/noise.dart';
import 'combat/enemy_spawner.dart';
import 'combat/pursuit.dart';
import 'combat/remains.dart';
import 'combat/remains_store.dart';
import 'combat/attachment.dart';
import 'combat/sanctuary.dart';
import 'combat/shot.dart';
import 'loot/loot_spawner.dart';
import 'loot/loot_store.dart';
import 'loot/loot_table.dart';
import 'loot/dropped_items.dart';
import 'loot/dropped_store.dart';
import 'loot/loot_world.dart';
import 'loot/procedural_points.dart' show kCarSelector, kWasteSelector;
import 'safety/spawn_exclusion.dart';
import 'loot/obstacle.dart';
import 'loot/search.dart';
import 'notes/note.dart';
import 'ui/combat_panel.dart';
import 'ui/ground_sheet.dart';
import 'shelter/recipes.dart';
import 'shelter/shelter.dart';
import 'shelter/shelter_store.dart';
import 'ui/place_sheet.dart';
import 'ui/remains_sheet.dart';
import 'ui/down_screen.dart';
import 'ui/shelter_screen.dart';
import 'ui/stash_screen.dart';
import 'shelter/stash.dart';
import 'ui/item_details_sheet.dart';
import 'ui/note_sheet.dart';
import 'ui/notices.dart';
import 'ui/refresh_rate.dart';
import 'ui/search_panel.dart';
import 'game/game_session.dart';
import 'actions/action_runner.dart';
import 'game/position_controller.dart';
import 'sim/timed_action.dart';
import 'game/relocation.dart';
import 'l10n/app_localizations.dart';
import 'location/device_position_source.dart';
import 'location/device_power_source.dart';
import 'location/location_access.dart';
import 'location/position_fix.dart';
import 'location/system_permissions.dart';
import 'map/map_bootstrap.dart';
import 'map/map_source.dart';
import 'map/geometry.dart';
import 'map/pack_manager.dart';
import 'map/pack_store.dart';
import 'map/region_pack.dart';
import 'safety/player_safety.dart';
import 'sim/body.dart';
import 'sim/death.dart';
import 'sim/physiology.dart';
import 'sim/occupation.dart';
import 'sim/player_stats.dart';
import 'sim/player_stats_store.dart';
import 'ui/profile_screen.dart';
import 'ui/app_settings.dart';
import 'ui/character_creator.dart';
import 'ui/language_picker.dart';
import 'ui/safety_briefing.dart';
import 'ui/effects.dart';
import 'ui/hud.dart';
import 'ui/status_notes.dart';
import 'ui/inventory_screen.dart';
import 'ui/map_markers.dart';
import 'ui/map_view.dart';
import 'ui/maplibre_surface.dart';
import 'ui/region_picker.dart';
import 'ui/settings_screen.dart';

/// ⚠️ **What is left here is the door, not the house.**
///
/// This file was seven thousand lines and one class that owned the pack, the
/// shelves, the shelters, the loot, the fight, five clocks and the screen they
/// were drawn on. Crediting a meal could reach the game loop, come back
/// through a snapshot listener and credit the meal again — three hops between
/// layers that were, in the file, one class. That is what the field reported
/// as the game hanging on food.
///
/// It is being taken apart one owner at a time. The order and the guarantees
/// are the migration plan; what this comment is for is the direction: things
/// leave, nothing arrives.
void main() => runGuarded(
  ArlsZaApp(
    home: (onSettings) => IntroScreen(
      onSettings: onSettings,
      // ⚠️ Wired here rather than imported by the film. The title screen still
      // lives in this file, and a screen in `lib/ui` reaching back into
      // `main.dart` would make a cycle out of a one-way street.
      next: (session, settings) =>
          TitleScreen(session: session, settings: settings),
    ),
  ),
);

/// Title screen. Routes to the creator on a first run, or resumes the active
/// character and puts the HUD on screen.
class TitleScreen extends StatefulWidget {
  const TitleScreen({
    required this.session,
    required this.settings,
    this.probe = const DeviceSystemProbe(),
    super.key,
  });

  final SaveSession session;
  final AppSettings settings;

  /// ⚠️ What the system will say about permissions, behind a seam.
  ///
  /// [_boot] awaits this, and on a device it is two platform channels. In a
  /// test they never answer, so the whole screen stayed blank and the
  /// orchestration in this file had no test at all — which was a missing seam
  /// rather than a missing test. The default is the real device; nothing in
  /// the game passes anything else.
  final SystemProbe probe;

  @override
  State<TitleScreen> createState() => _TitleScreenState();
}

class _TitleScreenState extends State<TitleScreen> with WidgetsBindingObserver {
  late final GameSessionFactory _factory = GameSessionFactory(widget.session);

  /// Null in a release build — `DevSession.attach` short-circuits on the const
  /// gate, so nothing here survives tree shaking (§11.2).
  DevSession? _dev;

  ActiveCharacter? _character;

  /// §13.1: what this character has done, counted. Loaded with them.
  PlayerStats _stats = PlayerStats.empty;

  /// §3.3, §3.6: smooth while the battery can afford it.
  final _refresh = ScreenRefresh();

  /// §10.2.3: when looking around may next turn something up.
  ///
  /// Separate from [_knowledge], which is about what has been *seen*: the ten
  /// minutes there stop a second look repeating the first, and this stops the
  /// finding from becoming a tap somebody stands on.
  DateTime? get _scoutedAt => _loot.scoutedAt;

  /// §10.2.3: and where that was, so the next one has to be somewhere else.
  GeoPoint? get _scoutedFrom => _loot.scoutedFrom;

  /// §12: how the pack is sorted. Outlives the screen it belongs to.
  ValueNotifier<PackOrder> get _packOrder => _pack.order;

  /// §18.2: what is on the shelves of the place currently open.
  ///
  /// ⚠️ A notifier, and the shelter screen is a pushed route — which is the
  /// bug class this codebase has found five times. Passing a plain value would
  /// leave the list on screen showing what the shelves held when it opened.
  ValueNotifier<Stash> get _stash => _shelf.stash;

  /// Which shelter [_stash] belongs to, so a save goes to the right shelves.
  Shelter? get _openShelves => _shelf.openAt;

  GameLoop? _loop;
  bool _loading = true;

  /// Everything the game knows about items (§4.1), read once at boot from the
  /// bundled files and any content pack the player has.
  ItemCatalogue? _catalogue;

  /// What the player is carrying.
  ///
  /// ⚠️ A notifier rather than a plain field, and there is a bug behind that.
  ///
  /// The inventory screen is a pushed route: its builder runs once, so a
  /// `setState` here rebuilt the map underneath and left the screen holding
  /// the inventory as it was when it opened. Dropping something therefore
  /// looked like nothing had happened, and the same item could be dropped
  /// again — and again — because the button was reading a stale list.
  ///
  /// One source of truth, and both the screen and this tree listen to it.
  ValueNotifier<Inventory> get _inventory => _pack.inventory;

  /// Item names, read alongside the catalogue (§1.1, §4.1).
  ItemNames? _names;

  /// What people left behind (§19.1), and what the map calls where the player
  /// is standing — the second is what fills the first in.
  NoteSet? _notes;
  PlaceNames get _placeNames => _loot.placeNames;

  /// The loot layer (§10). Null until the tables have been read; it does
  /// nothing at all until there is an installed pack to read places out of.
  LootWorld? _world;

  /// What is standing on the map right now. Held here because the map view is
  /// rebuilt constantly and re-reading the tiles for every frame would keep the
  /// phone busy for no gain.
  List<LootBox> get _boxes => _loot.boxes.value;

  /// The search in progress (§10.2, §19.3), and when it was last advanced.
  ///
  /// ⚠️ Advanced on the wall clock and its own timer, not on the simulation's.
  /// The sim clock refuses to move when the device clock steps backwards
  /// (§2.1.1's rollback guard), and an NTP correction mid-walk therefore froze
  /// the countdown while the player stood there watching it. A search measures
  /// forty-five real seconds of a person standing in a street; that is what it
  /// should count.
  /// A notifier for the same reason the inventory is one: the inventory screen
  /// is a pushed route, and an action started from it has to be visible on it.
  ValueNotifier<Search?> get _search => _clock.search;
  DateTime? get _searchTickedAt => _clock.tickedAt;

  /// ⚠️ §2.1a.3: the bench needs a clock of its own.
  ///
  /// Reported from a shelter: a dismantling reached 00:00 and stopped there,
  /// and only pressing stop and starting again finished it. Nothing was
  /// polling the deadline. The job is a row in a database with a time on it,
  /// and the only things that ever looked at it were opening the app and
  /// opening the bench — neither of which a player does while watching a bar
  /// run out in front of them.

  /// The very piece being eaten or drunk (§4.7), so a mouthful comes out of
  /// the bottle in hand rather than out of whichever one the list finds first.
  ValueNotifier<CarriedItem?> get _usingLine => _clock.usingLine;

  /// §10.3: the bodies, with their pockets still in them.
  List<Remains> get _remains => _loot.remains.value;

  /// §5.5: the last of the fight, in the order it happened.
  ///
  /// ⚠️ Kept because of one sentence after a walk: "I do not know how I died".
  /// Every line of it was on screen at the time and every line of it was gone
  /// by the time it mattered — a notice lasts seconds and a death is exactly
  /// the moment somebody wants the last minute back. Thirty lines is about two
  /// minutes of a bad fight.
  List<String> get _combatLog => _fight.log;

  void _logCombat(String line) => _fight.say(line);

  /// §8: the shelter and the camps, as the save last had them.
  /// §8: listened to rather than passed by value — the shelter screen is a
  /// pushed route, and a pushed route handed a list keeps showing the list it
  /// opened with. Starting a build then left the counter at zero until
  /// somebody backed out and came in again.
  ValueNotifier<List<Shelter>> get _shelters => _places.shelters;

  /// §12: what the game has just said. Under the HUD, never over the menu.
  final ValueNotifier<List<Notice>> _notices = ValueNotifier(const []);

  /// §5.5, §6.1a: everything hostile that is out there, and what it is doing.
  ///
  /// Not persisted. A Walker is not a place — §6.4 makes them afresh whenever
  /// the game runs, so writing them down would only mean loading yesterday's
  /// fight onto a street the player has already left.
  CombatSession get _combat => _fight.session;

  set _combat(CombatSession next) => _fight.session = next;

  /// When the enemies were last stepped, so a gap in the tick is a gap in
  /// their walk rather than a jump.
  DateTime? get _combatAt => _fight.steppedAt;

  set _combatAt(DateTime? next) => _fight.steppedAt = next;

  /// §5.5.1: the one being aimed at. One target for a firearm, and nothing
  /// takes its place when it dies.
  Aim _aim = const Aim();

  /// §6.2: when each of them last swung, so the interval between blows is the
  /// one on the table rather than one a frame.
  final Map<String, DateTime> _lastBlow = {};

  /// §5.4: when the player last swung. A blade has a swing time and swinging
  /// faster than the blade allows is not a thing a person can do.
  DateTime? _lastSwing;

  /// §5.6.3: what is on the weapon, one line per place.
  ///
  /// Sorted by place rather than by the order things were fitted, so the list
  /// does not reshuffle when a player swaps a magazine — the rifle's lines sit
  /// where they sat.
  List<WeaponFitting> _weaponFittings() {
    final line = _weaponLine;
    final catalogue = _catalogue;
    if (line == null || catalogue == null) return const [];

    final l10n = L10n.of(context);
    final fitted = <(AttachmentSlot, WeaponFitting)>[];

    for (final id in line.attachments) {
      final part = catalogue[id];
      if (part == null) continue;

      final place = slotOf(part) ?? AttachmentSlot.rail;
      final magazine = Magazine.of(part);

      fitted.add((
        place,
        WeaponFitting(
          place: _placeName(l10n, place),
          name: _nameOfItem(part),
          // §5.3: the magazine says what is in it, because that is the one
          // number worth a glance before walking round a corner.
          effect: attachmentEffect(
            part,
            rounds: magazine == null ? null : (line.rounds ?? 0),
            capacity: magazine?.capacity,
          ),
        ),
      ));
    }

    fitted.sort((a, b) => a.$1.index.compareTo(b.$1.index));
    return [for (final entry in fitted) entry.$2];
  }

  String _placeName(L10n l10n, AttachmentSlot place) => switch (place) {
    AttachmentSlot.magazine => l10n.slotMagazine,
    AttachmentSlot.optic => l10n.slotOptic,
    AttachmentSlot.barrel => l10n.slotBarrel,
    AttachmentSlot.grip => l10n.slotGrip,
    AttachmentSlot.rail => l10n.slotRail,
  };

  /// §5.5.4's seconds, as something to watch.
  ReloadProgress? _reloadProgress() {
    final running = _reload;
    final weapon = _weapon;
    if (running == null || weapon == null) return null;

    final l10n = L10n.of(context);

    // Three different things wearing the same three and a half seconds. A
    // player who pressed a button deserves to read which one they started.
    final label = Feed.of(weapon) != Feed.magazine
        ? l10n.reloadFeeding
        : _weaponCapacity == null
        ? l10n.reloadFitting
        : l10n.reloadSwapping;

    return ReloadProgress(
      label: label,
      value: running.progress(DateTime.now()),
    );
  }

  /// §5.3: what the weapon in hand would hold, or null with no magazine in it.
  int? get _weaponCapacity {
    final line = _weaponLine;
    final catalogue = _catalogue;
    if (line == null || catalogue == null) return null;

    final load = WeaponLoad.of(line, catalogue);
    if (load == null) return null;

    // ⚠️ Null rather than nought for a magazine-fed weapon with no magazine.
    // "No magazine" and "no rounds" are different sentences, and the first is
    // the one that tells a player what to go and find.
    return load.needsMagazine ? null : load.capacity;
  }

  /// §4.2: a filling or emptying under way, a round at a time.
  ///
  /// ⚠️ The rounds move *while the bar moves*, not in one lump at the end.
  /// Half a minute of a bar creeping across with nothing changing anywhere
  /// else reads as the game having stopped — and the one thing a player is
  /// watching during it is the number this action exists to change.
  FillPlan? _filling;

  /// §4.7: the meal under way, so the tin empties as it is eaten.
  MealPlan? _meal;

  /// §11.1: finishes whatever the app was killed in the middle of.
  ///
  /// ⚠️ **The reported bug lives here.** Closing the game while eating used to
  /// give the sandwich back untouched: the action existed only in a notifier
  /// inside this widget, so killing the process undid it. Now it is a row, and
  /// coming back applies exactly what §4.7 already applies to a meal
  /// interrupted on screen — the mouthfuls that were swallowed, and no more.
  ///
  /// Nothing is resumed. A meal is not picked up an hour later; it is a meal
  /// that was interrupted, and the tin is open.
  Future<void> _restoreInterruptedAction() async {
    final runner = _actions;
    if (runner == null) return;

    final found = await runner.restore();
    if (found == null) return;

    final subject = found.subjectUid;
    if (subject != null) {
      final line = _inventory.value.carried
          .where((entry) => entry.uid == subject)
          .firstOrNull;

      if (line != null) await _swallow(line, found.progress);
    }

    await runner.finish();
  }

  /// §4.7, §2.2: moves the meal on to where the bar is.
  ///
  /// ⚠️ Called on every tick, and idempotent by construction: it works out
  /// what should have been swallowed by this fraction and applies the
  /// difference. A tick that arrives late, or twice in one frame, cannot feed
  /// somebody twice.
  ///
  /// The tin empties as it is eaten, so there is no moment at which the pack
  /// is lying about what is in it — which is the whole of the bug this
  /// replaces. Killing the app halfway leaves a half-eaten tin because it
  /// *is* half eaten, not because anything reconstructed one.
  Future<void> _advanceMeal(double progress) async {
    final plan = _meal;
    final loop = _loop;
    final line = _usingLine.value;
    if (plan == null || loop == null || line == null) return;

    final share = progress.clamp(0.0, 1.0);
    final step = share - plan.applied;
    if (step <= 0) return;

    // ⚠️ The first mouthful, then a heartbeat that replaces itself. A hang
    // during a meal is a trail ending at "~meal:0.42" — which says both that
    // it got there and how far in it stopped.
    if (plan.applied <= 0) {
      CrashLog.note('meal.first:${line.itemId}');
    } else {
      CrashLog.beat('meal:${share.toStringAsFixed(2)}');
    }

    // §2.2: the body gets it as it goes down, not in a lump at the end.
    final swallowed = step * plan.portionAtStart;
    loop.applyUse(
      kcal: plan.kcal * swallowed,
      waterMl: plan.waterMl * swallowed,
    );

    final left = plan.portionAt(share);
    _meal = plan.appliedTo(share);

    // The line is rebuilt by every change, so the handle goes with it — the
    // same rule §11.1's uid exists for.
    final next = _inventory.value.setPortion(line, left);
    _inventory.value = next.inventory;
    _usingLine.value = next.line;

    // ⚠️ **One column, not the whole pack.**
    //
    // This runs once a second for the length of a meal, and [_saveInventory]
    // deletes every row the profile owns and inserts them all back inside a
    // transaction. A full pack is thirty-odd rows through the write queue per
    // second, ahead of everything §11.1 and §3.2 are trying to save — reported
    // from the field as the game freezing the moment food is started.
    //
    // The last mouthful is the exception: the row is gone rather than changed,
    // and that is a write only the wholesale one knows how to do.
    if (next.line == null) CrashLog.note('meal.gone');

    final uid = next.line?.uid;
    if (next.line != null && uid != null) {
      await _pack.savePortion(uid, left);
    } else {
      await _saveInventory();
    }
  }

  /// §4.7: applies the part of a use that actually happened.
  ///
  /// One place, because it is now reached from two: an interruption on screen
  /// and an interruption by the operating system. Those are the same event as
  /// far as the character is concerned, and they gave different answers for as
  /// long as only the first one existed.
  Future<void> _swallow(CarriedItem line, double progress) async {
    final loop = _loop;
    final catalogue = _catalogue;
    if (loop == null || catalogue == null) return;

    final definition = catalogue[line.itemId];
    final use = definition == null
        ? null
        // §7: Medicine shortens a dressing, and nothing else.
        : useOf(definition, medicine: _learned.medicine);

    // Only what is swallowed comes in mouthfuls. A tourniquet half tied is not
    // half a tourniquet — it is a tourniquet still in the pack.
    if (use == null || !use.consumesItem) return;
    if (use.kcal == 0 && use.waterMl == 0) return;

    final share = progress.clamp(0.0, 1.0);
    final swallowed = share * line.portion;
    if (swallowed <= 0) return;

    loop.applyUse(kcal: use.kcal * swallowed, waterMl: use.waterMl * swallowed);
    _inventory.value = _inventory.value.consumePortion(line, share);
    await _saveInventory();
  }

  /// §4.2: thumbs loose rounds into a magazine.
  ///
  /// ⚠️ An action with a clock on it, not a button that changes a number.
  /// About a second a round is half a minute for a rifle magazine, and that is
  /// the whole reason a second full magazine is worth its two hundred grams —
  /// filling one is a thing done somewhere quiet, ahead of time.
  Future<void> _fillMagazine(CarriedItem line) async {
    final catalogue = _catalogue;
    if (catalogue == null) return;

    if (_refuseIfBusy()) return;

    final item = catalogue[line.itemId];
    if (item == null) return;

    final magazine = Magazine.of(item, rounds: line.rounds ?? 0);
    if (magazine == null) return;

    // Asked before the time is spent, so an empty pack is a sentence rather
    // than half a minute of standing still.
    final dry = fillMagazine(_inventory.value, line, catalogue);
    if (!dry.isDone) {
      _say(_loadRefusal(dry.refusal!));
      return;
    }

    _usingLine.value = line;
    _filling = FillPlan(
      itemId: line.itemId,
      from: magazine.rounds,
      to: magazine.rounds + dry.moved,
    );

    setState(() {
      _search.value = Search.using(
        at: _standingAt.value ?? const GeoPoint(0, 0),
        now: DateTime.now().toUtc(),
        itemId: line.itemId,
        duration: fillTime(dry.moved),
        label: L10n.of(context).actionLoading(_nameOfId(line.itemId)),
      );
    });
    _startSearchTimer();
  }

  /// §4.2: tips the rounds out of a magazine and back into the pack.
  ///
  /// The same clock as filling. A magazine is emptied to put its rounds into a
  /// different one, or to leave the weight behind — and both are decisions
  /// somebody makes standing still, which is what the seconds are for.
  Future<void> _emptyMagazine(CarriedItem line) async {
    final catalogue = _catalogue;
    if (catalogue == null) return;

    if (_refuseIfBusy()) return;

    final item = catalogue[line.itemId];
    if (item == null) return;

    final magazine = Magazine.of(item, rounds: line.rounds ?? 0);
    if (magazine == null || magazine.isEmpty) return;

    _usingLine.value = line;
    _filling = FillPlan(itemId: line.itemId, from: magazine.rounds, to: 0);

    setState(() {
      _search.value = Search.using(
        at: _standingAt.value ?? const GeoPoint(0, 0),
        now: DateTime.now().toUtc(),
        itemId: line.itemId,
        duration: fillTime(magazine.rounds),
        label: L10n.of(context).actionUnloading(_nameOfId(line.itemId)),
      );
    });
    _startSearchTimer();
  }

  /// §4.2: moves the rounds the bar has already earned.
  ///
  /// Called on every tick of a fill or an empty. Idempotent by construction:
  /// it works out where the magazine *should* be at this fraction and moves it
  /// there, so a tick that arrives late or twice cannot double-count.
  void _advanceFilling(Search running) =>
      _moveRoundsTo(_filling?.roundsAt(running.progress));

  /// §4.2: moves the magazine to [wanted] rounds, however many that takes.
  ///
  /// Idempotent by construction: it is told where the magazine *should* be and
  /// moves it there, rather than counting ticks. A tick that arrives late, or
  /// twice in one frame, cannot double-count.
  void _moveRoundsTo(int? wanted) {
    final line = _usingLine.value;
    final catalogue = _catalogue;
    if (wanted == null || line == null || catalogue == null) return;

    final now = line.rounds ?? 0;
    if (wanted == now) return;

    final out = wanted > now
        ? fillMagazine(_inventory.value, line, catalogue, limit: wanted - now)
        : emptyMagazine(_inventory.value, line, catalogue, limit: now - wanted);
    if (!out.isDone) return;

    _inventory.value = out.inventory;

    // ⚠️ The handle is replaced along with the line, and it comes back from
    // the move rather than being looked up by item id — two magazines are two
    // lines, and looking one up finds whichever comes first. Without this the
    // rounds stop moving half way, or move in the wrong magazine.
    _usingLine.value = out.line;
  }

  /// §5.3: what is in the weapon, as opposed to in the pack.
  ///
  /// ⚠️ Read off the weapon rather than held here, and it was a plain field
  /// for months. Nothing wrote it down: reloading took thirty rounds out of
  /// the pack, put them in this integer, and closing the app destroyed them.
  /// A player lost a magazine on every restart, which is the worst kind of
  /// bug — it costs them something real and it looks like nothing happened.
  int get _loaded => _weaponLine?.rounds ?? 0;

  /// The line the weapon in hand is, so its rounds can be written back.
  ///
  /// §5.6.3 already made this distinction for attachments: the weapon in the
  /// hand is a *line* in `worn`, not an id, because two rifles are two rifles.
  /// What is in one of them belongs to the same place.
  CarriedItem? get _weaponLine {
    final catalogue = _catalogue;
    if (catalogue == null) return null;

    for (final line in _inventory.value.worn) {
      final item = catalogue[line.itemId];
      if (item != null && item.kind == ItemKind.firearm) return line;
    }
    return null;
  }

  /// Puts [rounds] in the weapon in hand and writes it down.
  ///
  /// Every path that changes what is in the gun goes through here, so there is
  /// one place that can forget to save and it does not.
  void _setLoaded(int rounds) {
    final line = _weaponLine;
    if (line == null) return;

    _inventory.value = _inventory.value.withLine(
      line,
      line.copyWith(rounds: rounds < 0 ? 0 : rounds),
    );
    unawaited(_saveInventory());
  }

  /// §5.5.4: a magazine change in progress, and the thing that can end it.
  /// §18.4, §18.6: everything that can be made, as shipped.
  RecipeBook _recipes = RecipeBook.empty;

  /// §2.1a.3: what is on the bench, or null. Reloaded whenever the shelter is.
  ValueNotifier<CraftJob?> get _craftJob => _bench2.job;

  /// §18.6: which piece is currently under the multitool.
  ///
  /// ⚠️ The lines, not the item ids. Two rifles in one pack are two rifles,
  /// and the bar belongs under the one being taken apart — the same rule
  /// §4.7's half-eaten tin already lives by.
  ///
  /// ⚠️ **A list, and the order is the order it happens in (§18.6).** The
  /// first is the one actually under the multitool and the only one with a
  /// bar; the rest are locked and waiting their turn. Everything in here is
  /// unusable — a rifle in a sitting cannot be worn, fired, dropped or
  /// shelved, which is the whole reason the pieces stay visible instead of
  /// vanishing for a quarter of an hour.
  ValueNotifier<List<CarriedItem>> get _dismantling => _bench2.sitting;

  /// Whether this piece is spoken for by the sitting on the bench.
  bool _inSitting(CarriedItem line) => _bench2.inSitting(line);

  Reload? _reload;

  /// ⚠️ A reload has its own clock.
  ///
  /// It used to be advanced only when a GPS fix arrived. Indoors, in a shelter,
  /// or anywhere the signal had gone — which is most of where a player stops
  /// to reload — the seconds never passed: the magazine was never seated, no
  /// bar moved, and pressing the button appeared to do nothing at all.

  /// What the last reconnaissance revealed, for §10.2.1's ten minutes.
  AreaKnowledge? _knowledge;

  /// What the player has put down and could come back for (§4.8).
  ///
  /// A notifier because the ground list is a pushed route: handed a copy, it
  /// would keep offering things already in the pack.
  ValueNotifier<List<DroppedItem>> get _dropped => _loot.dropped;

  /// §3.2, §3.6: where the player is, and what the phone says.
  ///
  /// ⚠️ Behind one object rather than beside each other as two fields. Seven
  /// bugs in this file were a line reading `displayFix` where it meant the
  /// sticky position — see [PositionController] for the list. Two names on one
  /// object is a great deal harder to confuse than two fields ten lines apart.
  final PositionController _position = PositionController();

  /// §2.1a, §11.1: the one clock, and the row that survives a kill.
  ///
  /// ⚠️ Null until a character is loaded, because it is keyed on the profile.
  /// Everything with a duration is written here the moment it starts — an
  /// action that lived only in a notifier was an action a killed process
  /// undid, which is how closing the app during a meal handed the sandwich
  /// back whole.
  ActionRunner? _actions;

  ValueNotifier<GeoPoint?> get _standingAt => _position.standingAt;

  GameSnapshot? get _snapshot => _position.snapshot.value;

  /// Procedural places the player has actually looked for (§10.2.3). A
  /// pharmacy is a building and is visible from the street; a wrecked car in a
  /// side road is not, until somebody stops and looks.
  Set<String> get _revealed => _loot.revealed;

  /// Both HUD bars read these. Zero without a catalogue, which only happens if
  /// every bundled data file failed to parse — a broken build, not a state the
  /// player can reach.
  double get _carriedKg =>
      _catalogue == null ? 0 : _inventory.value.massKg(_catalogue!);

  double get _carriedVolumeL =>
      _catalogue == null ? 0 : _inventory.value.volumeL(_catalogue!);

  double _capacityL(BodyProfile body) => _catalogue == null
      ? kPocketCapacityL
      : _inventory.value.limits(body, _catalogue!).capacityL;

  /// The real GPS, when that is what is driving the game. Held so the location
  /// gate can send the player to the right settings page and ask again.
  DevicePositionSource? _device;

  /// True until a language has been chosen. Nothing at all runs first.
  bool _needsLanguage = false;

  /// True until §3.5 has been read and accepted.
  bool _needsBriefing = false;

  /// The map layer. Built once, on the first boot after the briefing.
  PackManager? _packs;

  /// Watches downloads for as long as the game runs, not for as long as the
  /// region screen is open (§16.6). A pack that finishes while the player is
  /// back on the map has to put itself on the map.
  StreamSubscription<DownloadState>? _downloadWatch;

  /// Where the tiles are read from, or null while there is no map at all — the
  /// region screen is then what the player sees (§16.6).
  MapSource? _mapSource;

  /// So the region screen opens itself on a first run and never again.
  bool _askedForMap = false;

  /// The middle of the installed pack, from its own header. Where the camera
  /// points until the first fix arrives (§16.6).
  GeoPoint? _packCentre;

  /// Where the previous session ended, read once at boot. What the first
  /// trusted fix is compared against (§16.6).
  GeoPoint? _lastKnown;

  /// Told once per session, not once per fix.
  bool _relocationTold = false;

  /// What the system allows (§3.3, §16.1). Re-read whenever the app comes back,
  /// because the player may have just changed it.
  SystemPermissions? _permissions;

  /// The startup prompt is offered once a session and never nags.
  bool _permissionsOffered = false;

  /// True only in a developer build where the simulator has been switched on
  /// (§11.2). Everything else walks on real ground.
  bool _useSimulator = false;

  /// The region the player chose to stream rather than download (§16.6).
  ///
  /// Held separately from [_mapSource] because resolving the map again — after
  /// the region screen closes, say — asks what is *installed*, and would
  /// otherwise throw the choice away and leave the player on a blank screen.
  RegionPack? _streamedChoice;

  /// Set when the operating system will not give us a position (§16.1). The
  /// game stops at the gate rather than running a simulation on movement that
  /// will never arrive.
  LocationAccess? _blocked;

  /// Where the simulated clock stood when the loop started, so the developer
  /// overlay can report how much game time this session has consumed.
  DateTime? _sessionStart;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // ⚠️ The strip under the stats reads the bench, and the bench is written
    // from outside setState — by a job finishing on the way into the app, by a
    // stop, by a pause. Without this the bar for a dismantling appeared only
    // when something else happened to rebuild the tree.
    _putClocksOn();
    _craftJob.addListener(_onBenchChanged);
    // The HUD bars and the search panel read the inventory too, so this tree
    // follows the same notifier the screen does.
    _inventory.addListener(_onInventoryChanged);
    // The map's own panel reads the action from this tree, so it follows the
    // same notifier the inventory screen does.
    _search.addListener(_onInventoryChanged);

    // ⚠️ **The places and the bodies used to be plain fields.**
    //
    // They changed inside a `setState` on this widget, which is how the map
    // and the panel found out. Now they belong to [LootController], so this
    // tree has to listen for itself — one listener, one `setState`, the same
    // frame as before.
    //
    // Narrowing that down to the widgets that actually care is a later change
    // and a separate one: a move that also changed which frames redraw would
    // be impossible to tell apart from a regression.
    _places.shelters.addListener(_onInventoryChanged);
    _loot.boxes.addListener(_onInventoryChanged);
    _loot.remains.addListener(_onInventoryChanged);
    _loot.dropped.addListener(_onInventoryChanged);

    // §2.1a.2: the loop owns sleep and this tree owns actions, so the one has
    // to tell the other. Somebody halfway through a bandage is not somebody
    // who has been sitting in a chair doing nothing.
    _search.addListener(_tellLoopWhatWeAreDoing);
    unawaited(_boot());
  }

  void _onInventoryChanged() {
    if (mounted) setState(() {});
  }

  /// §8, §2.5.1: the loop measures the zone from the same position as the map.
  ///
  /// ⚠️ Two answers to "where am I" is the failure this codebase keeps
  /// finding. The loop kept its own last *gated* reading, and §2.1a.4 turns
  /// the receiver off under a roof — so the zone could say open while the map,
  /// the search and the no-fire rule all said shelter, and sleep never began.
  void _tellLoopWhereWeAre() {
    final at = _standingAt.value;
    if (at != null) _loop?.setStandingAt(at);
  }

  void _tellLoopWhatWeAreDoing() {
    final action = _search.value;
    _loop?.setActing(acting: action != null && action.isRunning);
  }

  Future<void> _boot() async {
    // Language before the rules. §3.5 is about traffic and strangers, and a
    // player who cannot read it has not been briefed.
    if (!widget.settings.languageChosen) {
      setState(() {
        _needsLanguage = true;
        _loading = false;
      });
      return;
    }

    // §3.5 is read before anything happens, including before a character
    // exists. The rules are about the person holding the phone, not the one in
    // the game.
    final accepted = briefingAccepted(
      await widget.session.db.readSetting(kSafetyBriefingKey),
    );
    if (!mounted) return;

    if (!accepted) {
      setState(() {
        _needsBriefing = true;
        _loading = false;
      });
      return;
    }

    _useSimulator = simulatorEnabled(
      await widget.session.db.readSetting(kSimulatorSettingKey),
    );
    if (!mounted) return;

    // Read once. A problem here is a shipped data file being wrong, which the
    // build should already have caught — so it is logged for the developer
    // overlay and the game runs on whatever parsed (§4.1).
    _catalogue = await loadItemCatalogue();
    _names = await loadItemNames();

    // §18.4: what this player can make. Checked against the catalogue at load
    // rather than at every tap — a recipe naming an item a removed content
    // pack took with it should cost that recipe and nothing else.
    _recipes = checkedAgainst(
      RecipeBook.parse(await rootBundle.loadString(kRecipesAsset)),
      _catalogue!,
    );
    _notes = NoteSet.parse(
      await rootBundle.loadString('assets/data/notes.json'),
    );
    final tables = LootTableSet.parse(
      await rootBundle.loadString('assets/data/loot_tables.json'),
    );
    _world = LootWorld(tables: tables);

    // ⚠️ The tables, not the world. §10.2's radius and §10.2.1's hidden places
    // are read off them, and that is all the loot needs to know — the world
    // itself plans, downloads and decodes map packs, none of which is a
    // question about what is on the map right now.
    _loot.tables = tables;
    if (!mounted) return;

    await _readPermissions();
    if (!mounted) return;

    // The position is not a feature of this game, it is the input (§3). Asking
    // before a character exists means a player who will not grant it finds out
    // in one screen rather than after filling in a character sheet.
    //
    // Skipped only when the simulator is actually driving: it needs no
    // permission, and a prompt nothing will use is noise (§11.2).
    if (!_useSimulator) {
      final access = await requestLocationAccess();
      if (!mounted) return;

      if (!access.canPlay) {
        setState(() {
          _blocked = access;
          _loading = false;
        });
        return;
      }
    }

    final existing = await _factory.loadActive();
    if (!mounted) return;

    if (existing == null) {
      setState(() => _loading = false);
      return;
    }
    await _enter(existing);
  }

  Future<void> _chooseLanguage(Locale locale) async {
    await widget.settings.setLocale(locale);
    if (!mounted) return;

    setState(() {
      _needsLanguage = false;
      _loading = true;
    });
    await _boot();
  }

  /// Asks the system what it currently allows.
  ///
  /// Cheap and worth repeating: the player can change any of the three from
  /// outside the app, and the game has no way to be told.
  Future<void> _readPermissions() async {
    if (_useSimulator) return;

    final permissions = await _currentPermissions();
    if (!mounted) return;
    setState(() => _permissions = permissions);
  }

  /// Asks the system, without touching any state.
  ///
  /// Handed to the settings screen so it can re-read for itself: a pushed
  /// route given a value keeps showing the value it was built with, which is
  /// stale exactly when the player is looking at it — right after they walked
  /// to the system settings and changed something.
  Future<SystemPermissions> _currentPermissions() => widget.probe.read();

  /// Offered once, after the map is up, and dismissible.
  ///
  /// Not a gate: §16.1 says foreground-only is a supported way to play, so this
  /// explains what is missing and what it costs rather than demanding it. The
  /// battery half is the part no system dialog ever mentions.
  Future<void> _offerPermissions() async {
    if (_permissionsOffered || _useSimulator) return;
    final permissions = _permissions;
    if (permissions == null || permissions.backgroundWorks) return;

    _permissionsOffered = true;
    final l10n = L10n.of(context);
    final fix = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.permStartupTitle),
        content: Text(l10n.permStartupBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.permStartupLater),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.permStartupFix),
          ),
        ],
      ),
    );

    if (fix == true && mounted) await _openSettings();
  }

  Future<void> _acceptBriefing() async {
    await widget.session.db.writeSetting(
      kSafetyBriefingKey,
      '$kSafetyBriefingVersion',
    );
    if (!mounted) return;

    setState(() {
      _needsBriefing = false;
      _loading = true;
    });
    await _boot();
  }

  /// Starts the simulation for [character] and shows the HUD.
  Future<void> _enter(ActiveCharacter character) async {
    // Read before the loop starts writing over it: this is the only moment the
    // *previous* session's position is still on disk (§16.6).
    final previous = await _factory.lastKnownPosition(character.profile.id);
    _lastKnown = previous == null
        ? null
        : GeoPoint(previous.latitude, previous.longitude);
    if (!mounted) return;

    // What the character was carrying when the app last closed. Rows naming an
    // item nothing defines are dropped rather than guessed at (§4.1) — that
    // happens when a content pack is uninstalled, and the pack going away is
    // what took the item with it.
    final catalogue = _catalogue;
    if (catalogue != null) {
      // ⚠️ Said once, here, and never again. The controllers exist from the
      // first frame so their notifiers can be handed to screens before
      // anything is loaded; this is the moment they learn whose things they
      // are holding.
      _pack.bind(
        profileId: character.profile.id,
        catalogue: catalogue,
        body: character.body,
      );
      _shelf.bind(profileId: character.profile.id);

      // ⚠️ The tables, not the world. §10.2's radius and §10.2.1's hidden
      // places are read off them, and that is all the loot needs to know —
      // the world itself plans, downloads and decodes, none of which is a
      // question about what is on the map right now.
      _loot.bind(profileId: character.profile.id);
      _places.bind(profileId: character.profile.id);
      _bench2.bind(profileId: character.profile.id);

      // §7: what this character has learned, before anything can ask.
      await _learned.load(character.profile.id);

      await _pack.load(catalogue);
      if (!mounted) return;
    }

    _stats = await PlayerStatsStore(
      widget.session.db,
    ).load(character.profile.id);
    if (!mounted) return;

    if (kDevTools && _useSimulator) {
      _dev = DevSession.attach(constants: character.constants);
    }

    final l10n = L10n.of(context);
    final source = buildPositionSource(
      notice: ForegroundNotice(
        title: l10n.locationNotificationTitle,
        body: l10n.locationNotificationBody,
      ),
      dev: _dev,
      useSimulator: _useSimulator,
    );

    if (source is DevicePositionSource) {
      _device = source;

      // Ask before the loop starts. Starting a loop that will never receive a
      // fix leaves the player watching a HUD that never changes, with nothing
      // saying why.
      final access = await source.requestAccess();
      if (!mounted) {
        await source.dispose();
        return;
      }
      if (!access.canPlay) {
        setState(() {
          _character = character;
          _blocked = access;
          _loading = false;
        });
        return;
      }
    }

    // ⚠️ Read before the loop starts, and handed to it.
    //
    // start() replays the whole gap since the save was written (§11.1.2), and
    // what a night in a shelter is credited as depends on the loop knowing
    // there is a shelter and where the character is standing. This used to
    // happen two awaits later, and a night indoors came back as a night
    // outdoors: the sleep debt grew instead of falling.
    final built = await ShelterStore(
      widget.session.db,
    ).load(character.profile.id, DateTime.now().toUtc());
    if (!mounted) return;

    final loop = await _factory.startLoop(
      character: character,
      source: source,
      clock: _dev?.gameClock,
      power: DevicePowerSource(),
      shelters: built,
      standingAt: _standingAt.value ?? _lastKnown,
    );
    loop.snapshots.listen((snapshot) {
      if (!mounted) return;
      _sessionStart ??= snapshot.state.lastUpdate;

      // Both the snapshot and the sticky rule, in one call. The rule itself
      // lives in [PositionController.accept] now.
      setState(() => _position.accept(snapshot));

      // §17.2, §12: the sky, reported once — the same figure §10.2.2 and
      // §17.4 are already using, so the map and the search radius can never
      // disagree about whether it is dark.
      widget.settings.setDarkOutside(snapshot.darkness >= kDarkPaletteAt);
      // §3.3: the same moment animations stop is the moment smoothness does.
      unawaited(_refresh.want(economy: snapshot.economy));

      unawaited(_checkRelocation(snapshot));
      unawaited(_settleShelters(snapshot));

      // ⚠️ Also from the tick, not only from the interface's own timer. Found
      // on a phone at night: a meal started and the screen went off, the timer
      // stopped firing, and the action never finished — so the character was
      // "eating" for ever, which meant they never went back to sleep either.
      // The loop keeps ticking in the background; this rides on it.
      unawaited(_advanceSearch());
      _tellLoopWhatWeAreDoing();
      _tellLoopWhereWeAre();
      unawaited(_settleDown(snapshot));
      unawaited(_spawnLoot(snapshot));
      _advanceCombat(snapshot);
    });

    if (!mounted) {
      await loop.dispose();
      return;
    }
    setState(() {
      _character = character;
      _loop = loop;

      // §7, §2.6: kept in step rather than read once — a level earned
      // tonight has to reach tonight's regeneration, not tomorrow's boot.
      loop.medicine = _learned.medicine;
      _learned.skills.addListener(() => loop.medicine = _learned.medicine);
      _blocked = null;
      _loading = false;
    });

    // ⚠️ Seeded from the save, before any fix arrives. Everything that asks
    // "am I at my shelter" measures from this, and a shelter is a building —
    // which is exactly where §3.2's gate has nothing to hand over. Without
    // this a player who opened the app indoors was, as far as the game could
    // tell, nowhere at all, and the build they left running never moved.
    if (_standingAt.value == null) {
      final last = await _factory.lastKnownPosition(character.profile.id);
      if (last != null) {
        _position.seed(GeoPoint(last.latitude, last.longitude));
      }
    }

    // §2.1a: the clock, before anything that might want to start something.
    _actions = ActionRunner(
      db: widget.session.db,
      profileId: character.profile.id,
    );
    await _restoreInterruptedAction();

    await _reloadShelters();

    // §2.1a.3: a job that finished while the app was closed is paid out on
    // the way in. It is the whole reason making runs on a clock rather than a
    // bar — a forty-five minute pack is something to come back to.
    await _reloadCraftJob();

    await _reloadRemains();
    _resumeHunt(character);
    await _resolveMap();
    if (mounted) await _offerPermissions();
  }

  /// Finds a map for where the player is standing (§16.6).
  ///
  /// Runs after the loop has started, so the first fix — if there is one — can
  /// pick the right region. With no fix yet it falls back to whatever is
  /// installed, which on a second run is the right answer anyway.
  Future<void> _resolveMap() async {
    final packs = _packs ??= await bootMapPacks();
    _downloadWatch ??= packs.downloads.listen((state) {
      if (state.outcome == InstallOutcome.installed) {
        unawaited(_resolveMap());
      }
    });
    final near = await _bestKnownPosition();

    final active = await packs.activePack(
      nearLatitude: near?.latitude,
      nearLongitude: near?.longitude,
    );

    // An installed pack always wins; a chosen stream is the fallback, and only
    // then is there genuinely no map.
    final streamed = _streamedChoice;
    final source =
        packs.sourceFor(active) ??
        (streamed == null ? null : StreamedPack(streamed.url));

    final header = active?.header;
    final centre = header == null
        ? null
        : GeoPoint(header.centre.latitude, header.centre.longitude);

    if (!mounted) return;
    setState(() {
      _mapSource = source;
      _packCentre = centre;
    });

    // The loot layer reads the same file the renderer draws (§10). A streamed
    // pack gives it nothing: it is read over the network, and a POI query
    // across it would be hundreds of range requests every time somebody walks.
    await _world?.useSource(source);
    await _loadLootBoxes();

    // §16.6 calls this the first-run screen, and it is: with no map there is
    // nothing to draw, nowhere to put a marker and no §10 to run. Opening it
    // unasked is right exactly once, which is what [_askedForMap] guards.
    if (source == null && !_askedForMap) {
      _askedForMap = true;
      await _openRegionPicker();
    }
  }

  /// The live fix if there is one, otherwise the last position on disk.
  ///
  /// A GPS lock takes seconds and the region screen is the first thing a player
  /// sees. Falling back to the save is what makes "near you" mean anything on
  /// the second run, and on the first it is honestly unknown.
  Future<({double latitude, double longitude})?> _bestKnownPosition() async {
    final fix = _snapshot?.fix;
    if (fix != null) {
      return (latitude: fix.latitude, longitude: fix.longitude);
    }

    final character = _character;
    if (character == null) return null;
    return _factory.lastKnownPosition(character.profile.id);
  }

  /// Did this session open somewhere else? (§16.6)
  ///
  /// Only the first trusted fix is asked. A fix that failed the accuracy gate
  /// or came from a mock provider is not a journey, and the filter has already
  /// dropped those — what reaches a snapshot has passed both (§3.2, §3.4).
  Future<void> _checkRelocation(GameSnapshot snapshot) async {
    if (_relocationTold) return;

    final fix = snapshot.fix;
    if (fix == null || snapshot.signal != PositionSignal.good) return;

    _relocationTold = true;
    final here = GeoPoint(fix.latitude, fix.longitude);

    final covered =
        _mapSource != null &&
        (await _packs?.activePack(
              nearLatitude: here.latitude,
              nearLongitude: here.longitude,
            )) !=
            null;

    final moved = detectRelocation(
      lastKnown: _lastKnown,
      trusted: here,
      mapCoversHere: covered,
    );
    if (!moved.happened || !mounted) return;

    final l10n = L10n.of(context);
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.relocationTitle),
        content: Text(
          moved.verdict == RelocationVerdict.covered
              ? l10n.relocationBody(moved.kilometres)
              : l10n.relocationNoMapBody(moved.kilometres),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.relocationDismiss),
          ),
        ],
      ),
    );

    // Nothing to draw and nowhere for §10 to put anything: the region screen
    // is the only useful next step.
    if (moved.verdict == RelocationVerdict.uncovered && mounted) {
      await _openRegionPicker();
    }
  }

  /// The player chose the network map rather than waiting for a download.
  void _playStreamed(RegionPack pack) {
    setState(() {
      _streamedChoice = pack;
      _mapSource = StreamedPack(pack.url);
    });
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> _openSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SettingsScreen(
          settings: widget.settings,
          onOpenMaps: () => unawaited(_openRegionPicker()),
          readPermissions: _currentPermissions,
          onFixLocation: _fixLocation,
          onFixBattery: const SystemSettings().openBatterySettings,
          simulatorEnabled: _useSimulator,
          onSimulatorChanged: (value) => unawaited(_setSimulator(value)),
        ),
      ),
    );
  }

  Future<void> _openInventory() async {
    final character = _character;
    final catalogue = _catalogue;
    if (character == null || catalogue == null) return;

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => InventoryScreen(
          inventory: _inventory,
          order: _packOrder,
          catalogue: catalogue,
          names: _names ?? ItemNames.empty,
          body: character.body,
          onDrop: (line, count) => unawaited(_drop(line, count)),
          onWear: (line) => unawaited(_wear(line)),
          onTakeOff: (line) => unawaited(_takeOff(line)),
          onUse: (line) => unawaited(_use(line)),
          onFill: (line) => unawaited(_fillMagazine(line)),
          onEmpty: (line) => unawaited(_emptyMagazine(line)),
          onDismantle: (line) => unawaited(_dismantle(line)),
          onStopDismantle: () => unawaited(_pauseDismantle()),
          refusalOf: _packRefusal,
          onStash: _shelvesInReach()
              ? (line) => unawaited(_quickShelve(line))
              : null,
          craftJob: _craftJob,
          craftLines: _dismantling,
          // ⚠️ What actually comes out, not what the thing is made of.
          //
          // Two different questions, and the difference is most of the
          // catalogue: an axe holds 0.86 units of metal and wood, which at
          // §18.6's forty per cent rounds to nothing. Lighting the glyph on
          // everything with a material content lit it on axes, knives and
          // magazines and then refused every one of them on the tap.
          canDismantle: _worthTakingApart,
          onRead: _readNote,
          onDetails: (line) => unawaited(_showItemDetails(line)),
          action: _search,
          // Which piece, not which item: a half-eaten tin beside three whole
          // ones is one row being used and three that are not.
          usingLine: _usingLine,
          onCancelAction: _cancelSearch,
          onDevFill: kDevTools ? () => unawaited(_devFillPack()) : null,
        ),
      ),
    );
  }

  /// §4.2: one item's readings, and the one it would replace beside them.
  ///
  /// The choice a player actually faces is not "is this vest good" but "is it
  /// better than mine", and that question is unanswerable while the two numbers
  /// live on separate screens.
  Future<void> _showItemDetails(CarriedItem line) async {
    final catalogue = _catalogue;
    final item = catalogue?[line.itemId];
    if (catalogue == null || item == null) return;

    final wearable =
        BodySlot.fromWire(wearSlotOf(item)) != null ||
        item.kind == ItemKind.backpack;
    // This copy, not any copy with that id: the one already on the body is not
    // put on again, but its twin in the pack still can be.
    final worn = _inventory.value.worn.any((other) => other.isSame(line));

    await showItemDetails(
      context,
      line: line,
      inventory: _inventory,
      catalogue: catalogue,
      names: _names ?? ItemNames.empty,
      // §18.6: nothing that has been opened up goes on. Half a coat does not
      // keep the rain off, and the row hides the glyph for the same reason —
      // this is the sheet saying the same thing.
      onWear: wearable && !worn && !line.isPartlyDismantled
          ? () => unawaited(_wear(line))
          : null,
      wearLabel: L10n.of(context).inventoryWear,
      // The piece the sheet is showing now, not the one it was opened with:
      // each fit rebuilds the line, and the sheet stays open across them.
      onAttach: (current, part) => unawaited(_attach(current, part)),
      onDetach: (current, id) => unawaited(_detach(current, id)),

      // §18.6, §18.2, §4.8: the three decisions this sheet exists to
      // inform, offered where the reading is. Only for a piece in the pack:
      // something on the pavement or in a body's pockets is not the player's
      // to take apart or shelve, and ⚠️ nothing that is worn is offered
      // either — a rifle in the hands is the one that must not be dismantled
      // while it can still be fired.
      onDismantle:
          !worn &&
              _recipes.recipes.isNotEmpty &&
              materialContent(item, _recipes).isNotEmpty
          ? (current) => unawaited(_dismantle(current))
          : null,
      onStash: !worn && _shelvesInReach()
          ? (current) => unawaited(_quickShelve(current))
          : null,
      onDrop: worn ? null : (current) => unawaited(_drop(current, 1)),
    );
  }

  /// §5.6.3: bolts something onto this very weapon.
  Future<void> _attach(CarriedItem line, CarriedItem part) async {
    final catalogue = _catalogue;
    if (catalogue == null) return;

    final before = _inventory.value;
    final after = before.attach(line, part, catalogue);

    // A refusal that looks exactly like a working button is the worst thing
    // this screen can do, and it is what the last two reports were about. If
    // nothing moved, say which rule said no.
    if (identical(after, before)) {
      final weapon = catalogue[line.itemId];
      final fitting = catalogue[part.itemId];
      if (!mounted) return;

      _say(
        weapon == null || fitting == null
            ? L10n.of(context).attachmentRefused
            : !fitsWeapon(fitting, weapon)
            ? L10n.of(context).attachmentWrongWeapon
            : line.attachments.contains(fitting.id)
            ? L10n.of(context).attachmentAlreadyOn
            : line.attachments.length >= attachmentSlots(weapon)
            ? L10n.of(context).attachmentNoRail
            : L10n.of(context).attachmentRefused,
      );
      return;
    }

    _inventory.value = after;
    await _saveInventory();
  }

  /// And takes it off again, back into the pack.
  Future<void> _detach(CarriedItem line, String attachmentId) async {
    final catalogue = _catalogue;
    final character = _character;
    if (catalogue == null || character == null) return;

    _inventory.value = _inventory.value.detach(
      line,
      attachmentId,
      catalogue,
      body: character.body,
    );
    await _saveInventory();
  }

  /// Developer builds only. Puts a plausible kit in the pack so the screen can
  /// be looked at on a phone before §10 gives the game a way to find anything.
  Future<void> _devFillPack() async {
    final character = _character;
    final catalogue = _catalogue;
    if (character == null || catalogue == null) return;

    var next = _inventory.value.packId == null
        ? _inventory.value.withPack('pack_daypack')
        : _inventory.value;
    for (final id in const [
      'cloth_winter_jacket',
      'cloth_boots',
      'armor_vest_soft',
    ]) {
      next = next.wear(id, catalogue);
    }
    for (final line in const [
      // Something to fire and something to fire from it: §5 cannot be tried
      // on a phone without both.
      ('weapon_rifle_545', 1),
      ('ammo_545x39', 60),
      ('att_red_dot', 1),

      // §4.2: and something to put the rounds in. A magazine-fed rifle with
      // no magazine cannot be fired at all, and §10 only drops these on
      // military ground — which is not somewhere every tester has to hand.
      ('mag_rifle_545', 2),

      // §18.3: the tool every shelter module asks for. Same reason: a walk
      // that has to find a hammer before any of §8.4 can be looked at is a
      // walk, not a test.
      ('melee_hammer', 1),
      ('tool_multitool', 1),
      ('food_canned_meat', 2),
      ('drink_water_bottle_500', 2),
      ('med_bandage', 3),
      ('melee_knife', 1),
      ('mat_wood', 4),
      ('tool_flashlight', 1),
    ]) {
      next = next
          .add(line.$1, catalogue, body: character.body, count: line.$2)
          .inventory;
    }
    next = next
        .add(
          'lit_guide_survival',
          catalogue,
          body: character.body,
          pagesTotal: 160,
        )
        .inventory;

    _inventory.value = next;
    await _saveInventory();
  }

  /// §4.8: what leaves the pack lands on the ground and stays for a day.
  ///
  /// Which is the whole reason the two carry limits are a decision. If leaving
  /// something behind destroyed it, "this is too heavy" would always be
  /// answered by throwing it away, and nobody deliberates over that.
  Future<void> _drop(CarriedItem line, int count) async {
    final character = _character;
    // ⚠️ Sticky, and the order matters more than the source did.
    //
    // This took the line out of the pack, saved, and *then* returned without
    // putting anything on the ground when there was no position — so dropping
    // something in a shelter destroyed it. Nothing leaves the pack now until
    // there is somewhere for it to land.
    final at = _standingAt.value;
    if (character == null || at == null) return;

    // The copy that was pointed at, not any copy with that id: two knives at
    // different conditions are two different things to own.
    final next = _inventory.value.removeLine(line, count: count);
    if (next == null) return;

    _inventory.value = next;
    await _saveInventory();

    final store = DroppedStore(widget.session.db);
    await store.drop(
      character.profile.id,
      DroppedItem(
        id: 0,
        itemId: line.itemId,
        count: count,
        condition: line.condition,
        pagesTotal: line.pagesTotal,
        pagesRead: line.pagesRead,
        // §5.6.3: the sights go down with the rifle, and come back up with it.
        attachments: line.attachments,
        // §5.3, §18.6: so does what is in it, and how far it has been opened.
        rounds: line.rounds,
        salvageSeconds: line.salvageSeconds,
        // §11.1: the name goes down with it and comes back up with it.
        uid: line.uid,
        position: at,
        droppedAt: DateTime.now().toUtc(),
      ),
    );
    await _reloadDropped();
  }

  /// §4.4: puts something on, and what was in that slot comes off.
  ///
  /// A backpack is worn too (§4.5), and swapping one for another is the same
  /// gesture — so it goes through here rather than through a separate control
  /// nobody would look for.
  Future<void> _wear(CarriedItem line) async {
    final catalogue = _catalogue;
    if (catalogue == null) return;

    // ⚠️ §18.6: a piece somebody has already opened up does not work any
    // more. The row and the sheet both hide the control, and this is the
    // floor under both of them — the one place a stale handle or an old save
    // cannot get round.
    if (line.isPartlyDismantled) {
      _say(L10n.of(context).craftPartlyApart);
      return;
    }

    final definition = catalogue[line.itemId];
    if (definition == null) return;

    // The old pack goes into the new one, which is what actually happens when
    // somebody changes bags in a street — and it goes in whether or not it
    // fits, since the alternative is losing it.
    final next = definition.kind == ItemKind.backpack
        ? _inventory.value.wearPack(line)
        : _inventory.value.removeLine(line)?.wearLine(line, catalogue);
    if (next == null) return;

    _inventory.value = next;
    await _saveInventory();
  }

  /// §4.7: eats, drinks or dresses a wound, for as long as the data says.
  ///
  /// The time is the point. §2.1a calls these actions rather than occupations
  /// because they are short, but a player who wants to drink half a litre
  /// stands still for twenty-five seconds to do it, and that is a decision
  /// when something is walking towards them.
  Future<void> _use(CarriedItem line) async {
    final catalogue = _catalogue;
    final character = _character;
    final loop = _loop;
    if (catalogue == null || character == null || loop == null) return;

    // §2.1a: one pair of hands.
    if (_refuseIfBusy()) return;

    // ⚠️ §18.6: a piece somebody has already opened up does not work any
    // more. The row and the sheet both hide the control, and this is the
    // floor under both of them — the one place a stale handle or an old save
    // cannot get round.
    if (line.isPartlyDismantled) {
      _say(L10n.of(context).craftPartlyApart);
      return;
    }

    CrashLog.note('use:${line.itemId}');

    final definition = catalogue[line.itemId];
    final use = definition == null
        ? null
        // §7: Medicine shortens a dressing, and nothing else.
        : useOf(definition, medicine: _learned.medicine);
    if (definition == null || use == null) return;

    // §2.6: a dressing with nothing open to close is a dressing spent for
    // nothing, and there is no getting it back. Refused, and told why — the
    // way out of a low blood volume with nothing bleeding is food, water and
    // time, not another bandage.
    if (use.stopsBleedingTo != null && use.kcal == 0 && use.waterMl == 0) {
      if (loop.bleeding == BleedTier.none) {
        _say(L10n.of(context).inventoryNoWound);
        return;
      }
      // §2.6: down to the grade it can handle, not to nothing. A pressure
      // dressing on an arterial bleed is not a tourniquet.
      if (use.stopsBleedingTo!.index >= loop.bleeding.index) {
        _say(L10n.of(context).inventoryWrongDressing);
        return;
      }
    }

    // ⚠️ Sticky, and never the null island. A meal begun with no position
    // anchored itself at 0°N 0°E, which is several thousand kilometres from
    // wherever the player is standing — so the stillness test saw them move
    // that far on the next fix and cancelled the meal.
    final at = _standingAt.value;

    // Half a bottle takes half as long to finish, which is what makes putting
    // it down and coming back to it a real option rather than a punishment.
    final seconds = (use.duration.inSeconds * line.portion).round();

    _usingLine.value = line;

    // §11.1: on disk before the first second passes. [_restoreInterruptedAction]
    // is what reads it back, and it only works if this happened.
    final takes = Duration(seconds: seconds < 1 ? 1 : seconds);

    // ⚠️ §4.7: the tin is opened now. Only what is swallowed comes in
    // mouthfuls, so a tourniquet is not a meal and gets no plan — half a
    // tourniquet is a tourniquet still in the pack.
    var piece = line;
    if (use.consumesItem && (use.kcal > 0 || use.waterMl > 0)) {
      final opened = _inventory.value.openOne(line);
      piece = opened.line;

      _inventory.value = opened.inventory;
      _usingLine.value = piece;
      await _saveInventory();

      CrashLog.note('use.opened:${piece.uid}:${piece.portion}');

      _meal = MealPlan(
        uid: piece.uid,
        portionAtStart: piece.portion,
        kcal: use.kcal,
        waterMl: use.waterMl,
      );
    } else {
      _meal = null;
    }

    CrashLog.note('use.row:${use.action.name}:${takes.inSeconds}s');

    await _actions?.start(
      TimedAction(
        kind: use.action.name,
        subjectUid: piece.uid,
        startedAt: DateTime.now().toUtc(),
        total: takes,
      ),
    );
    if (!mounted) return;

    setState(() {
      _search.value = Search.using(
        at: at ?? const GeoPoint(0, 0),
        now: DateTime.now().toUtc(),
        itemId: line.itemId,
        duration: takes,
        // §12: what is being swallowed, by name. "Jedzenie" says what kind
        // of action it is; "Jesz: Kanapka" says what the player is doing with
        // the thing they just tapped, which is the question the strip exists
        // to answer.
        label: _useLabel(use.action, catalogue[line.itemId]),
      );
    });

    CrashLog.note('use.bar');
    _startSearchTimer();
  }

  /// §2.1a: the row goes when the action does, whichever way it ended.
  ///
  /// ⚠️ Every exit from a use passes through here. One that did not would
  /// leave a row behind, and the next boot would apply a meal the player
  /// finished half an hour ago.
  Future<void> _endTimedAction() async {
    await _actions?.finish();
  }

  /// The label for a stored action, by its wire name (§12).
  String _useLabelFor(String kind, CarriedItem line) => useLabelFor(
    L10n.of(context),
    kind,
    _catalogue?[line.itemId],
    nameOf: _nameOfItem,
  );

  String _useLabel(ActionKind kind, ItemDefinition? item) =>
      useLabel(L10n.of(context), kind, item, nameOf: _nameOfItem);

  /// The action finished: the item is gone and the body has it.
  Future<void> _finishUse(Search action) async {
    CrashLog.note('use.finish:${action.usingItemId}');

    // The row goes first: whatever happens below, this use is over.
    await _endTimedAction();

    final catalogue = _catalogue;
    final loop = _loop;
    final itemId = action.usingItemId;
    if (catalogue == null || loop == null || itemId == null) return;

    // §4.2: a magazine being filled is an action with a clock, not a use —
    // nothing is swallowed and §2.2's absorption has no opinion about it.
    final plan = _filling;
    final filling = _usingLine.value;
    if (plan != null && filling != null) {
      // ⚠️ To where the plan was going, not to the brim.
      //
      // The rounds have been moving all the way across the bar, so almost all
      // of them are already where they belong; this only settles the rounding.
      // Topping the magazine up here instead would undo an emptying entirely —
      // it would fill the magazine the player asked to unload.
      _moveRoundsTo(plan.to);
      _filling = null;
      _usingLine.value = null;
      await _saveInventory();
      return;
    }

    final definition = catalogue[itemId];
    final use = definition == null
        ? null
        // §7: Medicine shortens a dressing, and nothing else.
        : useOf(definition, medicine: _learned.medicine);
    if (definition == null || use == null) return;

    // ⚠️ A meal has been emptying itself all along (§4.7), so finishing is
    // one last step to the end of the bar rather than a lump at the end.
    // Swallowing it twice here would feed somebody two tins for one.
    final wasMeal = _meal != null;
    if (wasMeal) {
      await _advanceMeal(1);
      _meal = null;
    }

    // What was left of the piece, which is all that is left to swallow.
    final line = _usingLine.value;
    final portion = line?.portion ?? 1;
    _usingLine.value = null;

    if (!wasMeal) {
      if (use.consumesItem) {
        // The very piece that was in hand: a half bottle beside a full one is
        // two different things to own.
        final next = line == null
            ? _inventory.value.remove(itemId, count: 1)
            : _inventory.value.removeLine(line);
        if (next != null) {
          _inventory.value = next;
          await _saveInventory();
        }
      }

      loop.applyUse(kcal: use.kcal * portion, waterMl: use.waterMl * portion);
    }

    // §2.6: what the dressing was for. After the item is gone, so an
    // interrupted one neither heals nor is consumed.
    final treats = use.stopsBleedingTo;
    if (treats != null) loop.treatBleeding(treats);

    if (!mounted) return;

    final language = Localizations.localeOf(context).languageCode;
    _say(
      L10n.of(context).inventoryUsed(
        definition.name.resolve(
          language: language,
          lookup: (_names ?? ItemNames.empty).forLanguage(language),
        ),
      ),
    );
  }

  /// §4.4: a worn piece comes off into the pack, never onto the ground.
  ///
  /// Taking a coat off and throwing it away are different decisions, and only
  /// one of them should be one tap away from a screen read in the dark.
  Future<void> _takeOff(CarriedItem line) async {
    _inventory.value = _inventory.value.takeOff(line.itemId);
    await _saveInventory();
  }

  /// Opens a note the player is carrying (§19.1).
  void _readNote(CarriedItem line) {
    final note = line.noteId == null ? null : _notes?[line.noteId!];
    if (note == null) return;

    unawaited(showNote(context, note: note, names: _placeNames));
  }

  /// What the panel says is underfoot: the nearest pile, and how much else
  /// there is behind it.
  /// §4.8: what is underfoot, named.
  String? _groundLabel() =>
      groundLabel(_pilesInReach(), nameOf: (pile) => _nameOfId(pile.itemId));

  /// A tap on the map (§3.6): what the player wants to know about that dot.
  ///
  /// A yellow dot that says only "something is here" makes every dot worth the
  /// same walk, which makes none of them a decision.
  void _showMarker(MapMarker? marker) {
    final catalogue = _catalogue;
    // Sticky: tapping a dot from indoors did nothing at all.
    final at = _standingAt.value;
    if (catalogue == null || at == null) return;

    // §5.5.1: a tap on empty street lets the target go. Aiming is where the
    // player's attention is, and pointing somewhere else is how a person says
    // they have stopped looking at something.
    if (marker == null) {
      if (_aim.hasTarget) setState(() => _aim = _aim.released);
      return;
    }

    if (marker.kind == MarkerKind.loot) {
      final box = _boxes.where((b) => b.poiId == marker.id).firstOrNull;
      if (box == null) return;

      unawaited(
        showPlaceDetails(
          context,
          box: box,
          table: _world?.tables[box.tableId],
          standingAt: _standingAt,
          catalogue: catalogue,
          now: _snapshot?.state.lastUpdate ?? DateTime.now().toUtc(),
        ),
      );
      return;
    }

    if (marker.kind == MarkerKind.enemy) {
      // §5.5.1: one tap, one target, and it costs the sight picture. The rest
      // of them carry on running — aiming is where attention goes, not a
      // pause button.
      setState(() {
        _aim = _aim.at(
          marker.id,
          now: DateTime.now(),
          // §7: −30% on the time it takes to pick a new target up.
          weaponSkill: _learned.weapons,
          settle: settleTime(
            heartRate: _snapshot?.state.heartRateBpm ?? 70,
            rest: _character?.constants.restingHeartRate ?? 70,
            max: _character?.constants.maxHeartRate ?? 190,
            // §7: the sights come back faster.
            weapons: _learned.weapons,
          ),
        );
      });
      return;
    }

    if (marker.kind == MarkerKind.remains) {
      final id = marker.id.substring('remains.'.length);
      final body = _remains.where((b) => b.id == id).firstOrNull;
      if (body == null) return;

      unawaited(
        showRemains(
          context,
          kindName: enemyKindName(L10n.of(context), body.kind),
          distanceM: body.position.distanceTo(at),
          searched: body.searched,
          onSearch: body.searched || body.position.distanceTo(at) > kStillnessM
              ? null
              : () => unawaited(_searchRemains(body)),
        ),
      );
      return;
    }

    if (marker.kind == MarkerKind.dropped) {
      // ⚠️ The list, not one item. §4.8 gathers a dozen things dropped on one
      // corner into a single dot with a number on it, and tapping that dot
      // used to open the details of whichever row happened to be first —
      // so a pile of fourteen answered a question about one of them, and
      // never said what the other thirteen were.
      unawaited(_showPileAt(marker.at));
      return;
    }
  }

  /// §4.8: everything standing on one dot, as a list.
  ///
  /// Around the marker rather than around the player, because this is reached
  /// by tapping the map: the pile is wherever the dot is, and the player may
  /// be looking at it from across the street.
  Future<void> _showPileAt(GeoPoint where) async {
    final catalogue = _catalogue;
    if (catalogue == null) return;

    final here = ValueNotifier(where);
    try {
      await showGroundItems(
        context,
        dropped: _dropped,
        at: here,
        // The same radius §4.8 gathers a dot from, so the list holds exactly
        // what the dot stands for.
        reachM: kClusterM,
        catalogue: catalogue,
        names: _names ?? ItemNames.empty,
        onTake: (pile) => unawaited(_takePileFrom(pile, where)),
        onDetails: (pile) => unawaited(
          showItemDetails(
            context,
            line: CarriedItem(
              itemId: pile.itemId,
              count: pile.count,
              condition: pile.condition,
              pagesTotal: pile.pagesTotal,
              pagesRead: pile.pagesRead,
              attachments: pile.attachments,
            ),
            inventory: _inventory,
            catalogue: catalogue,
            names: _names ?? ItemNames.empty,
            fromPack: false,
          ),
        ),
      );
    } finally {
      here.dispose();
    }
  }

  /// §4.8: picking it up still needs an arm's length.
  ///
  /// Looking at a pile from across the street is free; reaching into it is
  /// not, and a button that quietly teleports things into a pack would undo
  /// the walking this whole game is made of.
  Future<void> _takePileFrom(GroundPile pile, GeoPoint where) async {
    final at = _standingAt.value;
    if (at == null || at.distanceTo(where) > kStillnessM) {
      if (mounted) _say(L10n.of(context).droppedTooFar);
      return;
    }
    await _takePile(pile);
  }

  /// Everything at the player's feet, gathered into piles (§4.8).
  List<GroundPile> _pilesInReach() {
    final at = _standingAt.value;
    if (at == null) return const [];

    // ⚠️ A pile is picked up from as far as its *place* is searched from.
    //
    // §10.2 gives a shop fifty metres because its door is not where the map
    // puts its dot — and a search drops what it found at that dot. With one
    // fifteen-metre rule for picking up, a player could turn a shop over from
    // the pavement and then not be able to reach what they had just found.
    //
    // What the player dropped themselves, and what a body left, keep the
    // arm's length of §4.8: those really are at their feet.
    return _loot.pilesInReach(at);
  }

  /// Opens the heap at the player's feet.
  ///
  /// Always the list, even for one pile. The panel no longer names what is
  /// down there — a glyph and the map are worth more than a line of text — so
  /// taking it on the strength of the icon alone would be picking something up
  /// without being told what it is.
  void _openGround() {
    if (_pilesInReach().isEmpty) return;

    unawaited(
      showGroundItems(
        context,
        dropped: _dropped,
        at: _standingAt,
        // ⚠️ The same reach [_pilesInReach] used to decide the button was
        // worth drawing. These disagreed: the hand appeared because a pile
        // was within the school's fifty metres, and then opened a list that
        // only gathered from fifteen — so a player who had just searched a
        // school from the pavement was shown an empty floor.
        reachM: _reachForPilesAt(_standingAt.value ?? const GeoPoint(0, 0)),
        catalogue: _catalogue!,
        names: _names ?? ItemNames.empty,
        onTake: (pile) => unawaited(_takePile(pile)),
        onDetails: (pile) => unawaited(
          showItemDetails(
            context,
            line: CarriedItem(
              itemId: pile.itemId,
              count: pile.count,
              condition: pile.condition,
              pagesTotal: pile.pagesTotal,
              pagesRead: pile.pagesRead,
              attachments: pile.attachments,
            ),
            inventory: _inventory,
            catalogue: _catalogue!,
            names: _names ?? ItemNames.empty,
            // A pile at the player's feet, same as a tap on the map: not
            // theirs until they pick it up.
            fromPack: false,
          ),
        ),
      ),
    );
  }

  /// Picks up a whole pile, nearest row first.
  ///
  /// It stops at the first row that will not fit rather than skipping past it
  /// to something smaller: a player who is out of room should be told, not
  /// quietly given the lighter half of what they asked for.
  Future<void> _takePile(GroundPile pile) async {
    for (final part in pile.parts) {
      final before = _inventory.value;
      await _takeDropped(part);
      if (identical(_inventory.value, before)) return;
    }
  }

  /// Picks a pile back up, if it fits (§18.1a).
  Future<void> _takeDropped(DroppedItem item) async {
    final character = _character;
    final catalogue = _catalogue;
    if (character == null || catalogue == null) return;

    final result = _inventory.value.add(
      item.itemId,
      catalogue,
      body: character.body,
      count: item.count,
      condition: item.condition,
      pagesTotal: item.pagesTotal,
      attachments: item.attachments,
      rounds: item.rounds,
      salvageSeconds: item.salvageSeconds,
      uid: item.uid,
    );
    if (!result.isAccepted && (result.acceptedCount ?? 0) == 0) {
      if (mounted) _say(L10n.of(context).droppedNoRoom);
      return;
    }

    _inventory.value = result.inventory;
    await _saveInventory();

    // Removed only once it is in the pack, and only as much of it as went in.
    // Deleting first and finding it did not fit — or deleting the whole pile
    // when two of five pieces fitted — would be the game destroying something
    // on the player's behalf.
    final taken = result.acceptedCount ?? item.count;
    await DroppedStore(
      widget.session.db,
    ).takeSome(item.id, left: item.count - taken);
    if (taken < item.count && mounted) _say(L10n.of(context).droppedNoRoom);
    await _reloadDropped();
  }

  /// What was on the map when the app last closed.
  ///
  /// Read before anything is spawned, so a player who walked towards a marker
  /// and closed the app finds the same marker in the same place.
  Future<void> _loadLootBoxes() async {
    await _loot.loadBoxes();
    if (!mounted) return;

    await _reloadDropped();
  }

  /// Puts loot on the map around wherever the player now is (§10).
  ///
  /// Driven off the fix rather than a timer: the thing that makes new loot
  /// worth spawning is the player having walked somewhere, and nothing else.
  Future<void> _spawnLoot(GameSnapshot snapshot) async {
    final world = _world;
    final character = _character;
    final fix = snapshot.fix;
    if (world == null || character == null || fix == null) return;
    if (!world.isReady) return;

    final at = GeoPoint(fix.latitude, fix.longitude);
    if (!world.shouldReplan(at)) return;

    final plan = await world.plan(
      centre: at,
      existing: _boxes,
      now: snapshot.state.lastUpdate,
      seed: character.profile.rngSeed,
    );
    if (plan == null || !mounted) return;

    await LootStore(widget.session.db).save(character.profile.id, plan);
    if (!mounted) return;

    _loot.adopt(plan);
  }

  /// §6.1a: one step of the fight, driven by the same tick as everything else.
  ///
  /// §11 already decides how much time has passed and hands it over; a fight
  /// with a timer of its own would keep running with the app closed, which is
  /// exactly what §2.1a says an occupation must not do.
  void _advanceCombat(GameSnapshot snapshot) {
    final character = _character;
    final fix = snapshot.displayFix;
    if (character == null || fix == null) return;

    final now = snapshot.state.lastUpdate;
    final since = _combatAt;
    _combatAt = now;

    final elapsed = since == null ? Duration.zero : now.difference(since);

    // ⚠️ No time passed is not the same as a gap. Found on a phone: the
    // enemies kept vanishing, because a snapshot can be published without the
    // simulation clock having moved — a position update does it — and the two
    // cases were treated alike. Emptying the street on those wiped everything
    // out from under the player every few seconds.
    if (elapsed <= Duration.zero) {
      if (since != null) return;

      // A first tick: nothing to walk through, but the street is whatever it
      // already was rather than nothing.
      setState(() {
        _combat = CombatSession(
          seed: character.profile.rngSeed,
          enemies: _combat.enemies,
          open: _combat.open,
        );
      });
      return;
    }

    // One after the app was away. §11.1.2 replays a gap for the body, because
    // a body keeps burning calories in a pocket; a street does not. What a
    // Walker did during eight hours of sleep is not knowable, so the street is
    // emptied and made again rather than guessed at.
    if (elapsed > kCombatGapForgotten) {
      setState(() {
        // ⚠️ Settle what was already bleeding before throwing the street away.
        //
        // §11.1.2 is right that what a Walker *did* over a gap is not
        // knowable — but a wound is not a walk. Reported three times as "the
        // skull does not always appear when it bleeds out", and this was the
        // last of it: shoot something, watch it run, put the phone in a
        // pocket, and five minutes later the session was discarded with the
        // death still pending. No body, no kill, no evidence it happened.
        for (final dying in _combat.bledOutOver(elapsed)) {
          _remember(dying);
        }

        _combat = CombatSession(seed: character.profile.rngSeed);
        _aim = const Aim();
      });
      return;
    }

    // §9.2: they took you for dead. Nothing swings at somebody on the ground,
    // and nothing swings for ten minutes after they get up — which is the
    // valve against waking inside a hotspot and going straight back down.
    if ((_loop?.down ?? DownState.none) == DownState.none) {
      _takeBlows(GeoPoint(fix.latitude, fix.longitude), now);
    }
    _advanceReload(GeoPoint(fix.latitude, fix.longitude));

    setState(() {
      // §10.3: bodies nobody came back for stop being worth drawing.
      _loot.sweep(now);

      // ⚠️ The safety net, and it is here because a death can be missed. The
      // session reports the ones it kills during a tick, and the shot reports
      // the one under the sights — but a thing can also leave the list because
      // the tick that killed it ran while the fix was stale, or because two
      // paths both thought the other had it. Anything that was standing here a
      // moment ago and is gone now, without having walked out of range, died.
      final before = {
        for (final enemy in _combat.enemies)
          if (!enemy.isDead) enemy.id: enemy,
      };

      // §5.6.2: while anything is actually after the player, the fight is
      // written down — not the fighters, just the fact, the place and the
      // number. Closing the app in the middle of one used to be a perfect
      // escape, and nothing in §5 costs anything if the way out is free.
      final engaged = [
        for (final enemy in _combat.near(GeoPoint(fix.latitude, fix.longitude)))
          if (!enemy.isDead &&
              enemy.state != EnemyState.idle &&
              enemy.state != EnemyState.returning)
            enemy,
      ].length;

      if (engaged > 0) {
        _loop?.setPursuit(
          stirredUp(
            at: GeoPoint(fix.latitude, fix.longitude),
            now: now,
            engaged: engaged,
          ),
        );
      } else if (_loop?.pursuit != null && !_loop!.pursuit!.isWarmAt(now)) {
        // Gone cold on its own: a walk round the block genuinely loses them.
        _loop?.setPursuit(null);
      }
      _combat = _combat.advance(
        playerAt: GeoPoint(fix.latitude, fix.longitude),
        elapsed: elapsed,
        now: now,
        // §10.3: whatever bled out on the way leaves a body, exactly as one
        // that went down under the sights does.
        onDeath: _remember,
        obstacles: _world?.obstacles ?? const [],
        // §8.1: they wait at the edge of what the player built.
        sanctuaries: _sanctuaries,
        shelterAt: _shelters.value
            .where((s) => s.kind == ShelterKind.main)
            .firstOrNull
            ?.position,
        // §5.6.1: walls that swallow a shot swallow a silhouette too.
        denseUrban: _world?.denseUrban ?? false,
        // §7: somebody who knows how to move is noticed later.
        scouting: _learned.scouting,
        // §17.4: and everybody is noticed sooner after dark.
        darkness: snapshot.darkness,
      );

      final here = GeoPoint(fix.latitude, fix.longitude);
      for (final gone in before.values) {
        if (_combat.enemies.any((enemy) => enemy.id == gone.id)) continue;
        if (gone.position.distanceTo(here) > kActiveRadiusM) continue;

        _remember(gone);
      }
    });
  }

  /// §5.5.1: the thing currently aimed at, if it is still out there.
  Enemy? get _target {
    final id = _aim.targetId;
    if (id == null) return null;

    for (final enemy in _combat.enemies) {
      if (enemy.id == id && !enemy.isDead) return enemy;
    }
    return null;
  }

  /// What is in the hand, if it is something that fires (§5.5.1).
  ItemDefinition? get _weapon {
    final catalogue = _catalogue;
    if (catalogue == null) return null;

    for (final line in _inventory.value.worn) {
      final item = catalogue[line.itemId];
      if (item != null && item.kind == ItemKind.firearm) return item;
    }
    return null;
  }

  /// §5.6.3: what is carried that fits the weapon in hand.
  ///
  /// ⚠️ Fitted because it fits. Which attachment is actually on which weapon
  /// is per-weapon state, and that is the schema change the magazine is
  /// already waiting for in stage 8.
  List<ItemDefinition> _attachmentsFor(ItemDefinition weapon) {
    final catalogue = _catalogue;
    if (catalogue == null) return const [];

    // What is on this weapon, not what is in the pack. Two rifles in one bag
    // are two rifles: the one with the suppressor is the one worth carrying
    // into a town (§5.6.3).
    final line = _wieldedLine;
    if (line == null) return const [];

    return [
      for (final id in line.attachments)
        if (catalogue[id] != null) catalogue[id]!,
    ];
  }

  /// The very piece in the hand, rather than its definition.
  CarriedItem? get _wieldedLine {
    final catalogue = _catalogue;
    if (catalogue == null) return null;

    for (final line in _inventory.value.worn) {
      if (catalogue[line.itemId]?.kind == ItemKind.firearm) return line;
    }
    return null;
  }

  /// A round that fits it, out of the pack (§10.3.3: the calibre string is the
  /// whole reason ammunition is a resource rather than a number).
  CarriedItem? _roundFor(ItemDefinition weapon) {
    final catalogue = _catalogue;
    final calibre = weapon.props['caliber'];
    if (catalogue == null || calibre == null) return null;

    for (final line in _inventory.value.carried) {
      final item = catalogue[line.itemId];
      if (item?.kind == ItemKind.ammo && item?.props['caliber'] == calibre) {
        return line;
      }
    }
    return null;
  }

  /// Which round is in the weapon, for §5.1.5's wound channel.
  ///
  /// Whatever of that calibre is nearest to hand. A player carrying buckshot
  /// and slugs is carrying one kind of shotgun ammunition as far as this is
  /// concerned, which is a simplification worth revisiting when there is a
  /// reason to choose.
  ItemDefinition? _loadedRound(ItemDefinition weapon) {
    final catalogue = _catalogue;
    final line = _roundFor(weapon);
    if (catalogue == null || line == null) return null;

    return catalogue[line.itemId];
  }

  /// §5.1.4: the odds, worked out exactly once and shown before they are used.
  ShotError? _aimError(Enemy target) {
    final character = _character;
    final weapon = _weapon;
    final snapshot = _snapshot;
    if (character == null || weapon == null || snapshot == null) return null;

    return aimError(
      weapon: weapon,
      attachments: _attachmentsFor(weapon),
      // §7: 25 MOA at no skill, 4 at full mastery (§5.1.1). §5.1.2's
      // calibration table is the first row of that scale, not the whole of it.
      skill: _learned.weapons,
      heartRate: snapshot.state.heartRateBpm,
      restingHr: character.constants.restingHeartRate,
      maxHr: character.constants.maxHeartRate,
      playerSpeedKmh: (snapshot.fix?.speedMps ?? 0) * 3.6,
      targetSpeedKmh: target.speedKmh,
      // ⚠️ §5.1.1: the body's own contribution, and it was missing. The
      // parameter had a default of nought and nobody ever passed it, so
      // §2.5.4's three minutes of arc for a day without sleep and §2.6's for
      // blood loss were worked out, drawn on the profile screen, and thrown
      // away before any shot was resolved. The penalty existed as a caption.
      conditionMoa: snapshot.status.totalExtraMoa,
      spreadMultiplier: _aim.spreadMultiplierAt(DateTime.now()),
    );
  }

  /// One round, one roll, and everything it costs (§5.1, §5.1.5, §5.6).
  Future<void> _fire() async {
    final character = _character;
    final catalogue = _catalogue;
    final target = _target;
    final weapon = _weapon;
    final fix = _snapshot?.displayFix;
    if (character == null ||
        catalogue == null ||
        target == null ||
        weapon == null ||
        fix == null) {
      return;
    }

    final error = _aimError(target);
    if (_loaded <= 0 || error == null) return;

    final at = GeoPoint(fix.latitude, fix.longitude);
    final outcome = fireAt(
      weapon: weapon,
      ammo: _loadedRound(weapon),
      attachments: _attachmentsFor(weapon),
      target: target,
      distanceM: target.position.distanceTo(at),
      error: error,
      random: Random(),
      // §5.6.1: a built-up street in daylight takes a third off what is heard.
      denseUrban: _world?.denseUrban ?? false,
      // ⚠️ This read `false` outright, so a shot fired at midnight pulled
      // enemies from a *daytime* radius while the ring drawn on the map used
      // the real one — the picture and the consequence disagreed.
      night: _snapshot?.isNight ?? false,
    );

    // The round is gone whatever happened to the shot.
    setState(() => _setLoaded(_loaded - 1));
    if (!mounted) return;

    final l10n = L10n.of(context);
    setState(() {
      var session = _combat;
      if (outcome.hit) {
        session = session.wound(
          target.id,
          outcome.bloodLossMl,
          bleeding: outcome.bleedMlPerSecond,
          // §6.1a: it has been told where the player is, in the most direct
          // way there is.
          from: at,
        );
      }

      // §10.3: a body, not a heap. What it was carrying stays in its pockets
      // until somebody walks over and puts a hand in them — dropping it on
      // the ground would answer, from two hundred metres off, the one
      // question worth walking over to answer.
      final down = session.enemies.where((e) => e.id == target.id).firstOrNull;
      if (down != null && down.isDead) _remember(down);

      // §5.6: heard whether or not it hit, from where it was fired.
      session = session.heard(
        NoiseEvent(
          at: at,
          radiusM: outcome.noiseM,
          startedAt: DateTime.now().toUtc(),
        ),
        playerAt: at,
      );
      _combat = session;

      // §5.5.1: nothing takes the place of a target that has gone down.
      final still = session.enemies.where((e) => e.id == target.id).firstOrNull;
      if (still == null || still.isDead) _aim = _aim.released;
    });

    // ⚠️ Counted from the outcome rather than from the log line, so a shot
    // fired while the app is being closed still lands in the tally.
    _note(
      (stats) => stats.fired(
        where: outcome.hit ? outcome.location : null,
        bloodMl: outcome.hit ? outcome.bloodLossMl : 0,
      ),
    );

    // §2.6: where it landed and what it opened. A head shot that ends it is
    // worth saying as an execution; a leg that keeps bleeding is worth saying
    // because it changes whether to run or to stay.
    final down = _combat.enemies.where((e) => e.id == target.id).firstOrNull;
    _say(
      !outcome.hit
          ? l10n.combatMiss
          : down == null || down.isDead
          ? (outcome.location == HitLocation.head
                ? l10n.combatExecution
                : l10n.combatDown)
          : l10n.combatHitAt(
              hitLocationName(l10n, outcome.location!),
              outcome.bloodLossMl.round(),
            ),
      remember: true,
    );
  }

  /// §13.1: adds to the tally and puts it on disk.
  ///
  /// No [setState]: nothing on the HUD shows any of this. The profile screen
  /// reads the tally when it opens, so a rebuild of the map for every trigger
  /// pull would buy nothing at all.
  void _note(PlayerStats Function(PlayerStats) change) {
    _stats = change(_stats);

    final character = _character;
    if (character == null) return;
    unawaited(
      PlayerStatsStore(widget.session.db).save(character.profile.id, _stats),
    );
  }

  /// §5.6.2: a round into the air, with nothing in the sights.
  ///
  /// Not a wasted bullet — the only deliberate use of the noise system the
  /// player has. Everything that hears it walks to *where the sound was*, so a
  /// shot fired from a corner and then left behind moves a street off the
  /// route somebody wants to take. It costs a round and it costs the noise,
  /// which is exactly the trade §5.6.3 is built around.
  Future<void> _fireAway() async {
    final weapon = _weapon;
    final at = _standingAt.value;
    if (weapon == null || at == null) return;

    // §9.2: nothing happens while flat on your back, and nothing for the ten
    // minutes after getting up.
    if (_loop?.down != DownState.none) return;

    if (_reload != null) {
      if (mounted) _say(L10n.of(context).combatReloadBroken);
      return;
    }

    // §8.1: not from inside your own zone. The one refusal a player is most
    // likely to meet, and the one they are most likely to think is a bug.
    if (_inOwnZone()) {
      if (mounted) _say(L10n.of(context).fireAwayInShelter);
      return;
    }

    if (_loaded <= 0) {
      if (mounted) _say(L10n.of(context).fireAwayUnloaded);
      return;
    }

    setState(() {
      _setLoaded(_loaded - 1);

      _combat = _combat.heard(
        NoiseEvent(
          at: at,
          radiusM: noiseRadiusM(
            FittedWeapon(
              weapon: weapon,
              attachments: _attachmentsFor(weapon),
            ).noiseRangeM,
            denseUrban: _world?.denseUrban ?? false,
            night: _snapshot?.isNight ?? false,
          ),
          startedAt: DateTime.now().toUtc(),
        ),
        playerAt: at,
      );
    });

    if (!mounted) return;
    _say(L10n.of(context).combatFiredAway, remember: true);
  }

  /// §5.2, §5.5.3: everything in reach swings, and being surrounded hurts.
  ///
  /// Below twenty metres §5.2 stops pretending GPS knows where anybody is
  /// standing and settles it abstractly, which is what this is: no positions,
  /// no facing, just how many of them are on you and how often each can swing.
  void _takeBlows(GeoPoint at, DateTime now) {
    final loop = _loop;
    final catalogue = _catalogue;
    if (loop == null || catalogue == null) return;

    final inReach = [
      for (final enemy in _combat.enemies)
        if (!enemy.isDead && enemy.position.distanceTo(at) <= kMeleeM) enemy,
    ];
    if (inReach.isEmpty) {
      _lastBlow.clear();
      return;
    }

    // §5.5.3: the player answers one of them and the rest swing freely, which
    // is why letting a group close is very nearly a sentence.
    final crowding = flankingMultiplier(inReach.length);
    var taken = 0.0;
    HitLocation? worst;

    for (final enemy in inReach) {
      final last = _lastBlow[enemy.id];
      if (last != null && now.difference(last) < enemy.kind.attackInterval) {
        continue;
      }
      _lastBlow[enemy.id] = now;

      // §2.6: teeth and hands land where they land. A bite to the arm the
      // player put up is not the bite that takes them down, and the log is
      // where the difference gets said.
      final where = rollHitLocation(Random().nextDouble());
      if (worst == null || where.multiplier > worst.multiplier) worst = where;

      // §4.4: armour reduces a blow only where it covers, and a bite is blunt.
      final protection = _inventory.value.protectionAgainst(
        catalogue: catalogue,
        slot: 'torso_armor',
        hitRoll: Random().nextDouble(),
        blunt: true,
      );

      taken +=
          enemy.kind.damageMl *
          crowding *
          where.multiplier *
          (1 - protection.clamp(0, 1) / 5);
    }

    if (taken <= 0 || worst == null) return;

    // §2.6: teeth and nails leave something open. A moderate bleed is what a
    // pressure dressing answers — which is the whole reason to carry one, and
    // the reason walking away from a clinch is not the end of the fight.
    loop.applyWound(
      taken,
      bleeding: worst == HitLocation.head || worst == HitLocation.torso
          ? BleedTier.moderate
          : BleedTier.superficial,
    );
    _note((stats) => stats.hurt(taken));
    _say(
      L10n.of(
        context,
      ).combatHurtAt(hitLocationName(L10n.of(context), worst), taken.round()),
    );
  }

  /// §5.5.4: the magazine goes in, unless something gets to the player first.
  void _advanceReload(GeoPoint at) {
    final reload = _reload;
    final weapon = _weapon;
    final catalogue = _catalogue;
    if (reload == null || weapon == null || catalogue == null) return;

    // ⚠️ Whatever it is doing. Hands stop when a body is that close, and the
    // game is not going to argue about intent.
    final tooClose = reloadBrokenBy([
      for (final enemy in _combat.enemies)
        if (!enemy.isDead) enemy.position.distanceTo(at),
    ]);

    if (tooClose) {
      _endReload();
      _say(L10n.of(context).combatReloadBroken, remember: true);
      return;
    }

    if (!reload.isDoneAt(DateTime.now())) return;

    final line = _weaponLine;
    if (line == null) {
      _endReload();
      return;
    }

    // §4.2: a magazine is swapped as a unit, and a revolver is fed a round at
    // a time. Both are the same three and a half seconds to the player and
    // completely different bookkeeping underneath.
    final outcome = Feed.of(weapon) == Feed.magazine
        ? swapMagazine(_inventory.value, line, catalogue)
        : loadLoose(_inventory.value, line, catalogue);

    if (!outcome.isDone) {
      _endReload();
      _say(_loadRefusal(outcome.refusal!));
      return;
    }

    setState(() => _inventory.value = outcome.inventory);
    _endReload();
    unawaited(_saveInventory());
  }

  /// Puts the reload down, whichever way it ended.
  void _endReload() {
    _stopReloadTimer();
    if (mounted) {
      setState(() => _reload = null);
    } else {
      _reload = null;
    }
  }

  /// Starts a magazine change (§5.3).
  void _startReload() {
    final weapon = _weapon;
    final line = _weaponLine;
    final catalogue = _catalogue;
    if (weapon == null || line == null || catalogue == null) return;

    // §2.1a: one pair of hands. §5.5.4's seconds are hands doing something,
    // and hands that are already eating are not free to change a magazine.
    if (_refuseIfBusy()) return;

    // ⚠️ Asked before the seconds are spent, not after.
    //
    // §5.5.4's three and a half seconds are the most expensive thing in a
    // fight, and standing through them to be told there was nothing to load is
    // the worst outcome the interface can produce. So the same function that
    // will do the work is asked whether it can, and its refusal is said out
    // loud now.
    final dry = Feed.of(weapon) == Feed.magazine
        ? swapMagazine(_inventory.value, line, catalogue)
        : loadLoose(_inventory.value, line, catalogue);

    if (!dry.isDone) {
      _say(_loadRefusal(dry.refusal!));
      return;
    }

    final total = reloadTime(
      weapon,
      attachments: _attachmentsFor(weapon),
      // §7: −30% at full mastery.
      weapons: _learned.weapons,
    );

    setState(() {
      _reload = Reload(
        weaponId: weapon.id,
        readyAt: DateTime.now().add(total),
        total: total,
      );
    });
    _startReloadTimer();
  }

  /// Ten beats a second, so the bar moves and the seconds pass indoors.
  void _startReloadTimer() => _clock.restart(_kReload);

  /// ⚠️ Nothing to stop. The ticker asks `_reload != null` on every beat, so a
  /// reload that ended has already stopped itself — and the clock drops back
  /// from ten beats a second to one the moment it does.
  void _stopReloadTimer() => _clock.retime();

  /// What to say when a weapon will not take anything (§4.2, §5.5.4).
  String _loadRefusal(LoadRefusal refusal) {
    final l10n = L10n.of(context);
    return switch (refusal) {
      LoadRefusal.noMagazine => l10n.reloadNoMagazine,
      LoadRefusal.nothingFuller => l10n.reloadNothingFuller,
      LoadRefusal.noRounds => l10n.combatNoAmmo,
      LoadRefusal.full => l10n.reloadAlreadyFull,
      LoadRefusal.notAWeapon => l10n.combatNoAmmo,
      // Nothing a player did. Something moved under the action, and the
      // honest thing to say is that it did not happen.
      LoadRefusal.gone => l10n.combatReloadBroken,
    };
  }

  /// §5.4: hands, or whatever is in them.
  ///
  /// Computational rather than a test of thumbs (§5.4's own recommendation for
  /// the MVP): the decision was made when the player let something get within
  /// twenty metres, not in the tap that follows.
  Future<void> _strike() async {
    final character = _character;
    final catalogue = _catalogue;
    final target = _target;
    final fix = _snapshot?.displayFix;
    if (character == null ||
        catalogue == null ||
        target == null ||
        fix == null) {
      return;
    }

    final blade = _meleeInHand;
    final swing = Duration(
      milliseconds:
          (((blade?.props['swing_seconds'] as num?)?.toDouble() ?? 1.4) * 1000)
              .round(),
    );

    final now = DateTime.now();
    final last = _lastSwing;
    if (last != null && now.difference(last) < swing) return;
    _lastSwing = now;

    final limits = _inventory.value.limits(character.body, catalogue);
    final chance = meleeHitChance(
      // §7: §5.4's budget is `0.65 + 0.30 × skill − …`. Weapons covers the
      // blade as well as the rifle — §7 gives four skills, not five, and a
      // separate Melee would be a fifth nobody asked for.
      skill: _learned.weapons,
      carriedKg: _carriedKg,
      maxCarryKg: limits.maxKg,
      fatigue:
          character.constants.maxHeartRate <=
              character.constants.restingHeartRate
          ? 0
          : ((_snapshot?.state.heartRateBpm ?? 70) -
                    character.constants.restingHeartRate) /
                (character.constants.maxHeartRate -
                    character.constants.restingHeartRate),
    );

    final landed = Random().nextDouble() < chance;
    final where = rollHitLocation(Random().nextDouble());
    final damage =
        ((blade?.props['blood_ml_per_hit'] as num?)?.toDouble() ?? 40) *
        where.multiplier;

    setState(() {
      // §2.6: a blade opens what it lands in, and a throat opened is a fight
      // that finishes itself.
      if (landed) {
        _combat = _combat.wound(
          target.id,
          damage,
          bleeding: switch (where) {
            HitLocation.head => 5,
            HitLocation.torso => 3,
            _ => 1,
          },
          from: GeoPoint(fix.latitude, fix.longitude),
        );
      }

      // §5.6.1: hands and a blade are twenty-five metres of noise, which is
      // the whole reason to use them.
      _combat = _combat.heard(
        NoiseEvent(
          at: GeoPoint(fix.latitude, fix.longitude),
          radiusM: NoiseKind.melee.baseM,
          startedAt: DateTime.now().toUtc(),
        ),
        playerAt: GeoPoint(fix.latitude, fix.longitude),
      );

      final still = _combat.enemies.where((e) => e.id == target.id).firstOrNull;
      if (still == null || still.isDead) {
        if (still != null) _remember(still);
        _aim = _aim.released;
      }
    });

    _note(
      (stats) => stats.swung(
        where: landed ? where : null,
        bloodMl: landed ? damage : 0,
      ),
    );

    if (!mounted) return;
    final left = _combat.enemies.where((e) => e.id == target.id).firstOrNull;
    _say(
      !landed
          ? L10n.of(context).combatMiss
          : left == null || left.isDead
          ? (where == HitLocation.head
                ? L10n.of(context).combatExecution
                : L10n.of(context).combatDown)
          : L10n.of(context).combatHitAt(
              hitLocationName(L10n.of(context), where),
              damage.round(),
            ),
      remember: true,
    );
  }

  /// What is in the hand, if it is something to swing (§5.4).
  ItemDefinition? get _meleeInHand {
    final catalogue = _catalogue;
    if (catalogue == null) return null;

    for (final line in _inventory.value.worn) {
      final item = catalogue[line.itemId];
      if (item != null && item.kind == ItemKind.melee) return item;
    }
    return null;
  }

  /// §10.3: marks where something went down.
  /// Everything the player can do standing exactly here (§10.2, §19.3, §4.8).
  ///
  /// Built in one place because it is drawn in two: on its own when nothing is
  /// in the sights, and stacked over the combat panel when something is.
  Widget _actionPanel(BuildContext context) {
    final box = _boxInReach();

    return ValueListenableBuilder<Search?>(
      valueListenable: _search,
      builder: (context, searchVal, _) {
        return SearchPanel(
          search: searchVal,
          targetName: box?.name,
          canSearchHere: box != null,
          // §10.3.5: how much of this place is left to turn over, so the panel can
          // grey out a pass there is no longer room for.
          searchUnitsLeft: box?.searchUnitsLeft ?? 0,
          // §10.3.5: what each depth costs in seconds, here. A bin is not a
          // supermarket, and the caption is where the player finds that out.
          searchTimes: _searchTimesAt(box),
          barrier: _barrierOn(box),
          carried: _carriedIds(),
          onSearchArea: _startAreaSearch,
          onSearchHere: _startObjectSearch,
          onBreach: _startBreach,
          droppedLabel: _groundLabel(),
          // Only with something actually underfoot. Found on a walk: the glyph
          // stayed on the panel from anywhere, so "can I pick that up from here"
          // was answered by pressing it and finding out.
          onTakeDropped: _catalogue == null || _pilesInReach().isEmpty
              ? null
              : _openGround,
          // §5.6.2: a round into the air.
          //
          // ⚠️ Offered whenever anything is in hand, and refused *out loud*. It
          // used to vanish on any of four conditions, which read on a walk as "the
          // button does not work" — the commonest cause being an unloaded weapon
          // after a restart, since §8.4's magazines are not saved yet. A control
          // that disappears cannot explain itself.
          onFireAway: _weapon == null ? null : () => unawaited(_fireAway()),

          // §5.3, §4.2: what is in hand and what is in it, on the panel that is
          // always there. Preparing a weapon is something done before anything is
          // in front of you, and until now there was nowhere to do it.
          weapon: _weapon == null ? null : _nameOfItem(_weapon!),
          rounds: _loaded,
          capacity: _weaponCapacity,
          onReload: _weapon == null ? null : _startReload,
          fittings: _weaponFittings(),
          reload: _reloadProgress(),
          onCancel: _cancelSearch,
        );
      },
    );
  }

  /// §5.6.2: a fight the player walked out of is a fight that was still going
  /// on when they came back.
  ///
  /// ⚠️ Closing the app used to be a perfect escape: fire into a crowd, kill
  /// the process, come back to an empty street. Nothing in §5 costs anything
  /// if the way out is free. The enemies themselves are still not written down
  /// — §6.4 remakes them — but the fight is, so a few of them are put back
  /// *looking* for the player rather than on top of them. That is a warning
  /// and a chance to leave, which is more than they had when they fired.
  void _resumeHunt(ActiveCharacter character) {
    final hunt = character.pursuit;
    final at = _standingAt.value;
    final now = DateTime.now().toUtc();
    if (hunt == null || at == null) return;

    final coming = hunt.resumedAt(at, now);
    if (coming <= 0) {
      _loop?.setPursuit(null);
      return;
    }

    final random = Random(character.profile.rngSeed ^ hunt.until.hashCode);
    final back = <Enemy>[];

    for (var i = 0; i < coming; i++) {
      // Out at the edge of the fight rather than in the player's lap: they
      // spread out looking while the app was shut.
      final where = at.offsetBy(
        metres: kSpawnMinM + random.nextDouble() * 120,
        bearingDeg: random.nextDouble() * 360,
      );

      back.add(
        Enemy.spawn(
          id: 'hunt.${hunt.until.millisecondsSinceEpoch}.$i',
          kind: EnemyKind.walker,
          at: where,
          home: where,
          random: random,
          sightFactor: _world?.denseUrban ?? false ? 0.7 : 1,
        ).hears(hunt.at),
      );
    }

    setState(
      () => _combat = CombatSession(
        seed: _combat.seed,
        enemies: [..._combat.enemies, ...back],
        open: _combat.open,
      ),
    );
    _say(L10n.of(context).combatStillHunted, remember: true);
  }

  // --------------------------------------------------------------- death ---

  /// §9: everything that happens once, at the moment the body gives out.
  ///
  /// The loop decides *when* — it is the only thing that knows whether the
  /// phone is asleep or has lost the sky, and §9.1 makes both of those reasons
  /// a character may not die. This is the rest of it: what the character
  /// leaves behind, and what the save has to remember.
  Future<void> _settleDown(GameSnapshot snapshot) async {
    final loop = _loop;
    final character = _character;
    if (loop == null || character == null) return;

    if (loop.takeWentDown()) {
      _note((stats) => stats.wentDown());

      // §5.5.1: nothing is aimed at any more, and nothing is being searched.
      setState(() {
        _aim = _aim.released;
        _search.value = null;
        _usingLine.value = null;
        _filling = null;
      });

      _logCombat('— ${causeName(L10n.of(context), loop.deathCause)} —');

      if (loop.down == DownState.dead) {
        await _factory.recordDeath(
          character: character,
          cause: (loop.deathCause ?? DeathCause.bloodLoss).wire,
          now: snapshot.state.lastUpdate,
        );
      } else {
        await _scatterKit(snapshot);
      }
    }

    if (loop.takeJustWoke()) {
      await _saveInventory();
      if (mounted) _say(L10n.of(context).downCaches);
    }
  }

  /// §9.2: the weapon in the hands is gone, and half of the rest is on the
  /// ground where the character fell.
  ///
  /// Caches rather than a wipe, and they stay where the body fell rather than
  /// following the player: §9.2.1 makes that the whole balance of the mode —
  /// the penalty grows with how far the player has moved since, and no rule
  /// had to be written to make it do that.
  Future<void> _scatterKit(GameSnapshot snapshot) async {
    final character = _character;
    final catalogue = _catalogue;
    final fix = snapshot.displayFix;
    if (character == null || catalogue == null || fix == null) return;

    final at = GeoPoint(fix.latitude, fix.longitude);
    final random = Random(
      character.profile.rngSeed ^ snapshot.state.lastUpdate.hashCode,
    );
    final store = DroppedStore(widget.session.db);

    var pack = _inventory.value;

    // Whatever was in the hands is simply gone, and it does not turn up in a
    // cache either. §9.2 is explicit, and it is what stops a deliberate death
    // from being a cheap way home.
    for (final line in [...pack.worn]) {
      final item = catalogue[line.itemId];
      if (item == null) continue;
      if (item.kind == ItemKind.firearm || item.kind == ItemKind.melee) {
        pack = pack.removeLine(line, count: line.count) ?? pack;
      }
    }

    // ⚠️ Worn as well as carried. §9.2 says "the rest of the kit worn", and
    // taking only what was in the pack meant a character woke up in the same
    // boots, coat and vest they went down in — the entire cost of a blackout
    // fell on whatever happened to be loose.
    //
    // Half of it, by the piece: losing three of five bandages and keeping two
    // is what §9.2 describes, and a stack is one piece.
    for (final line in [...pack.worn, ...pack.carried]) {
      if (random.nextDouble() >= kWakeLossFraction) continue;

      pack = pack.removeLine(line, count: line.count) ?? pack;
      await store.drop(
        character.profile.id,
        DroppedItem(
          id: 0,
          itemId: line.itemId,
          count: line.count,
          condition: line.condition,
          attachments: line.attachments,
          // Two or three caches in thirty to a hundred metres, so getting it
          // back is a walk rather than a button.
          position: at.offsetBy(
            metres: 30 + random.nextDouble() * 70,
            bearingDeg: random.nextDouble() * 360,
          ),
          droppedAt: DateTime.now().toUtc(),
        ),
      );
    }

    _inventory.value = pack;
    await _saveInventory();
    await _reloadDropped();
  }

  /// §9.1: a new character in the same body.
  Future<void> _startOver(ActiveCharacter dead) async {
    // The creator keeps height, weight, age and sex — it is still the player's
    // own body, and sitting through the measurements again would be theatre.
    setState(() {
      _character = null;
      _loop = null;
    });
    await _loop?.dispose();
    if (mounted) await _boot();
  }

  // ------------------------------------------------------------- shelter ---

  /// §8.3: how often the progress of a build reaches the disk.
  ///
  /// Often enough that a killed process costs a few seconds of nailing, rarely
  /// enough that a three-hour build is not ten thousand writes.
  static const Duration kBuildWriteEvery = Duration(seconds: 15);

  /// True while something is changing the shelters out from under the pass
  /// that credits work to them.
  bool _shelterBusy = false;

  /// §8.1: whether the player is standing on ground they built.
  ///
  /// ⚠️ From the sticky position, never straight off the snapshot. A shelter
  /// is a building and a building is where §3.2's gate has nothing to hand
  /// over — reading the fix directly meant the one place the rule exists to
  /// cover was the one place it did not apply, and a player could shoot out of
  /// their own doorway whenever the signal dropped.
  bool _inOwnZone() {
    final at = _standingAt.value;
    return at != null && inSanctuary(at, _sanctuaries);
  }

  /// §8.1: the circles the fight does not happen inside.
  List<Sanctuary> get _sanctuaries => [
    for (final place in _shelters.value)
      if (place.isReadyAt(DateTime.now().toUtc()))
        Sanctuary(at: place.position, radiusM: place.kind.safeRadiusM),
  ];

  /// §8: what has been built, from the save.
  Future<void> _reloadShelters() async {
    final places = await _places.reload(DateTime.now().toUtc());
    if (!mounted) return;

    _loop?.setShelters(places);
  }

  /// Re-reads them when something they depend on has moved on.
  ///
  /// Cheap and rare: only when a building finished, or when the player has
  /// walked into one — §8.5.2's clock on a camp restarts on a visit, and a
  /// visit is not an event the loop can raise on its own.
  Future<void> _settleShelters(GameSnapshot snapshot) async {
    if (_shelters.value.isEmpty || _shelterBusy) return;

    final now = snapshot.state.lastUpdate;

    // ⚠️ The smoothed, sticky position — never `snapshot.displayFix`. A night
    // at home is a night indoors, and indoors is where the accuracy gate has
    // nothing to hand over: reading the fix straight off the snapshot meant
    // the one place a shelter is ever built was the one place the game could
    // not tell you were standing.
    final at = _standingAt.value;

    // §2.1a.3, §8.3: work only happens on the site, and it is measured against
    // a timestamp on the row rather than one in memory. Held in memory it
    // started again at nothing every time the process did — so a shelter left
    // to build overnight, with the app closed exactly as §8.3 intends, was in
    // the same state in the morning as it had been at bedtime.
    //
    // With the app dead nobody can know whether the player stayed. Crediting
    // the gap to somebody standing on the site now is the generous reading of
    // an unanswerable question, and the alternative — losing a night's work
    // because a phone went to sleep — is the bug this exists to fix.
    if (at != null) {
      final places = [..._shelters.value];
      var wrote = false;

      for (var i = 0; i < places.length; i++) {
        final place = places[i];
        if (place.buildLeft == null && place.buildingLeft == null) continue;
        if ((place.buildLeft ?? Duration.zero) <= Duration.zero &&
            (place.buildingLeft ?? Duration.zero) <= Duration.zero) {
          continue;
        }

        // ⚠️ A row that has never been credited starts its clock, and does not
        // simply fall through. Found on a phone, twice over: a shelter carried
        // across the migration that added this column had no stamp, the gap
        // came out as nothing, and nothing was ever written — so the gap stayed
        // nothing and the build never moved again. A missing stamp is "start
        // counting", not "count nothing".
        final since = place.workedAt;
        if (since == null) {
          final started = place.worked(Duration.zero, at: now);
          places[i] = started;
          _shelters.value = [...places];
          await ShelterStore(widget.session.db).saveWork(started);
          continue;
        }

        final gap = now.isAfter(since) ? now.difference(since) : Duration.zero;
        final onSite = place.atSite(at);

        // In chunks rather than every tick: three hours of one-second writes
        // is ten thousand of them for a bar nobody is watching. The stamp only
        // moves when something is written, so nothing is lost by waiting.
        if (gap < kBuildWriteEvery) continue;

        // The stamp moves whether or not anything was earned. Without that, a
        // walk to the shops and back would bank the whole walk.
        final worked = place.worked(onSite ? gap : Duration.zero, at: now);
        places[i] = worked;
        _shelters.value = [...places];
        await ShelterStore(widget.session.db).saveWork(worked);

        // Only a finished job is worth re-reading the table for: that is when
        // a module turns into a level and the row has to be settled.
        wrote =
            wrote ||
            (place.isReadyAt(now) != worked.isReadyAt(now)) ||
            (place.building != null &&
                (worked.buildingLeft ?? Duration.zero) <= Duration.zero);
      }
      if (wrote) await _reloadShelters();
    }

    final finished = _shelters.value.any(
      (place) =>
          place.building != null &&
          (place.buildingLeft ?? Duration.zero) <= Duration.zero,
    );

    final inside = at == null ? null : shelterAt(at, _shelters.value, now: now);
    final stale =
        inside != null &&
        (inside.visitedAt == null ||
            now.difference(inside.visitedAt!) > const Duration(hours: 1));

    if (!finished && !stale) return;

    if (stale) {
      await ShelterStore(widget.session.db).visited(inside.id, now);
    }
    await _reloadShelters();
  }

  Future<void> _openShelter() async {
    final character = _character;
    final catalogue = _catalogue;
    if (character == null || catalogue == null) return;

    // §18.2: the shelves, before the screen rather than behind a tap. What is
    // on them decides whether a module can be started, so the screen that
    // offers the module has to know.
    await _loadShelvesOfMain();
    if (!mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ShelterScreen(
          shelters: _shelters,
          standingAt: _standingAt,
          carried: _carriedCounts(),
          shelved: _shelvedCounts(),
          shelvedMassKg: _stash.value.massKg(catalogue),
          shelvedVolumeL: _stash.value.volumeL(catalogue),
          itemNameOf: (id) {
            final definition = catalogue[id];
            if (definition == null) return id;

            final language = Localizations.localeOf(context).languageCode;
            return definition.name.resolve(
              language: language,
              lookup: (_names ?? ItemNames.empty).forLanguage(language),
            );
          },
          // §18.3: a tool on the shelf is a tool in the shelter. Making the
          // player pick their own hammer up off their own shelf before the
          // button lights is bookkeeping, not a decision.
          hasTools: _atHand(kHammerId) || _atHand(kAxeId),
          hasHammer: _atHand(kHammerId),
          hasMultitool: _atHand('tool_multitool'),
          onBuild: (kind) => unawaited(_buildShelter(kind)),
          onBuildModule: (module) => unawaited(_buildModule(module)),
          onDemolishModule: (module) => unawaited(_demolishModule(module)),
          onShelves: (place) => unawaited(_openStash(place)),
          onCraft: () => unawaited(_openCraft()),
          onDisassemble: () => unawaited(_openDisassemble()),
          craftJob: _craftJob,
          onCancelBuild: (place) => unawaited(_cancelBuild(place)),
          onPauseBuild: (place) => unawaited(_pauseBuild(place)),
        ),
      ),
    );
    await _reloadShelters();
  }

  /// §8.3: starts the work where the player is standing.
  ///
  /// ⚠️ That is, in practice, their home address (§8.2). It goes in the local
  /// save and nowhere else — `allowBackup` is off for the whole database.
  Future<void> _buildShelter(ShelterKind kind) async {
    final character = _character;
    final at = _standingAt.value;
    if (character == null || at == null) return;

    if (_refuseIfBusy()) return;

    if (kind == ShelterKind.camp) {
      final refusal = campRefusalAt(at, existing: _shelters.value);
      if (refusal != null) return;
      if (missingFor(kCampMaterials, _carriedCounts()).isNotEmpty) return;

      await _spendMaterials(kCampMaterials);
    }

    await ShelterStore(widget.session.db).begin(
      character.profile.id,
      kind: kind,
      at: at,
      now: DateTime.now().toUtc(),
      buildTime: buildTimeFor(
        kind,
        hasTools: _atHand(kHammerId) || _atHand(kAxeId),
      ),
    );

    await _reloadShelters();
    if (!mounted) return;
    _say(L10n.of(context).shelterBuildStarted);
  }

  /// §2.1a, §8.3: puts the work down, or picks it back up. Nothing is lost.
  ///
  /// ⚠️ **Asked in one direction only.** Putting work down must never be
  /// refused — it is the way *out* of an occupation. Picking it up is a start
  /// like any other and asks like any other: reported from a walk, eating and
  /// pressing "back to work" put a meal and a workshop on one pair of hands.
  Future<void> _pauseBuild(Shelter place) async {
    if (place.paused && _refuseIfBusy()) return;

    _shelterBusy = true;
    await _places.setPaused(place, DateTime.now().toUtc());
    _shelterBusy = false;

    await _reloadShelters();
    if (!mounted) return;

    final l10n = L10n.of(context);
    _say(place.paused ? l10n.shelterResumed : l10n.shelterPaused);
  }

  /// §8.3: gives up on whatever is going up here.
  ///
  /// The materials are gone — they went into the walls — and the work starts
  /// again from nothing. Both are said out loud before anything happens, and
  /// nothing here is reversible.
  Future<void> _cancelBuild(Shelter place) async {
    // ⚠️ Held against the crediting pass. That pass carries its own copy of
    // the list, and a copy taken a moment before a cancel would write the
    // abandoned work straight back over it.
    _shelterBusy = true;
    final store = ShelterStore(widget.session.db);

    // ⚠️ **The materials come back.** They did not, and §18.2 never said they
    // should not — that was my reading of "already in the walls", which turns
    // a change of mind into a punishment for a build somebody has not finished.
    // Reported plainly: stopping a module and starting it again should cost
    // the hours, not the timber.
    final module = place.building;
    final owed = module == null
        ? (place.kind == ShelterKind.camp ? kCampMaterials : null)
        : nextLevelOf(module, have: place.buildingLevel - 1)?.materials;

    if (place.building != null) {
      // Only the module: the shelter itself is still standing.
      await store.cancelModule(place.id);
    } else {
      await store.remove(place.id);
    }

    if (owed != null) await _refund(owed);

    _shelterBusy = false;
    await _reloadShelters();
    if (!mounted) return;
    _say(L10n.of(context).shelterCancelled);
  }

  /// §8.4: pulls a level off a module and gets half of it back.
  ///
  /// ⚠️ Half, rounded down, and the same figure §18.6 gives for a thing taken
  /// apart with a multitool — the ratio is the point, not the number. Pulling a
  /// workshop down to build a lounge should be possible and should hurt.
  Future<void> _demolishModule(ShelterModule module) async {
    final shelter = _shelters.value
        .where((place) => place.kind == ShelterKind.main)
        .firstOrNull;
    if (shelter == null || shelter.building != null) return;

    final level = shelter.levelOf(module);
    if (level <= 0) return;

    final recipe = nextLevelOf(module, have: level - 1);
    if (recipe == null) return;

    final back = {
      for (final entry in recipe.materials.entries)
        if ((entry.value / 2).ceil() > 0) entry.key: (entry.value / 2).ceil(),
    };

    final sure = await _confirmDemolish(module, level, back);
    if (!sure || !mounted) return;

    await ShelterStore(
      widget.session.db,
    ).setModule(shelter.id, module, level - 1, shelter.modules);
    await _refund(back);
    await _reloadShelters();

    if (!mounted) return;
    _say(L10n.of(context).shelterDemolished);
  }

  Future<bool> _confirmDemolish(
    ShelterModule module,
    int level,
    Map<String, int> back,
  ) async {
    final l10n = L10n.of(context);
    final gives = back.entries
        .map((entry) => '${_nameOfId(entry.key)} ×${entry.value}')
        .join(', ');

    final answer = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${moduleName(l10n, module)} L$level'),
        content: Text(l10n.shelterDemolishWhat(gives)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.shelterCancelKeep),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.shelterDemolish),
          ),
        ],
      ),
    );

    return answer ?? false;
  }

  /// §18.2: puts materials back where they came from.
  ///
  /// Onto the shelves first when the shelter is standing, because that is
  /// where they were spent from — and §18.1a's overflow is a state, not a
  /// reason to destroy anything.
  Future<void> _refund(Map<String, int> materials) async {
    final character = _character;
    final catalogue = _catalogue;
    if (character == null || catalogue == null) return;

    var pack = _inventory.value;
    final spill = <String, int>{};

    for (final entry in materials.entries) {
      final change = pack.add(
        entry.key,
        catalogue,
        body: character.body,
        count: entry.value,
      );
      pack = change.inventory;

      final took =
          change.acceptedCount ?? (change.isAccepted ? entry.value : 0);
      if (took < entry.value) spill[entry.key] = entry.value - took;
    }

    _inventory.value = pack;
    await _saveInventory();

    if (spill.isNotEmpty) await _shelveSpill(spill);
  }

  /// §8.4, §18.2: one level onto one module, against the clock.
  Future<void> _buildModule(ShelterModule module) async {
    final shelter = _shelters.value
        .where((place) => place.kind == ShelterKind.main)
        .firstOrNull;
    if (shelter == null || shelter.building != null) return;

    if (_refuseIfBusy()) return;

    final recipe = nextLevelOf(module, have: shelter.levelOf(module));
    if (recipe == null) return;

    // ⚠️ At hand, not carried: the shelves count, and [_spendMaterials] takes
    // from them first. Checking the pack alone lit the button on the screen
    // and then refused the build, which reads as the button being broken.
    final hammer = _atHand(kHammerId);
    final multitool = _atHand(kMultitoolId);
    if (!toolsAllow(recipe, hasHammer: hammer, hasMultitool: multitool)) return;

    final have = {..._carriedCounts()};
    for (final entry in _shelvedCounts().entries) {
      have[entry.key] = (have[entry.key] ?? 0) + entry.value;
    }
    if (missingFor(recipe.materials, have).isNotEmpty) return;

    // §2.1a.3: you have to be standing in it to build onto it.
    final at = _standingAt.value;
    if (at == null || !shelter.atSite(at)) {
      _say(L10n.of(context).shelterNotHere);
      return;
    }

    final work = moduleWork(
      recipe,
      hasHammer: hammer,
      hasMultitool: multitool,
      workshopLevel: shelter.levelOf(ShelterModule.workshop),
    );

    await _spendMaterials(recipe.materials);
    await ShelterStore(widget.session.db).beginModule(
      shelter.id,
      module: module,
      level: recipe.level,
      readyAt: DateTime.now().toUtc().add(work),
      work: work,
    );

    await _reloadShelters();
    if (!mounted) return;
    _say(L10n.of(context).shelterBuildStarted);
  }

  /// §18.4: opens the bench.
  Future<void> _openCraft() async {
    final catalogue = _catalogue;
    if (catalogue == null) return;

    await _reloadCraftJob();
    if (!mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ValueListenableBuilder<CraftJob?>(
          // ⚠️ The notifier, not a copy. The bench is a pushed route, and
          // this is the sixth time in this file that reading state into a
          // pushed screen once has meant the screen never changed again.
          valueListenable: _craftJob,
          builder: (_, job, _) => CraftScreen(
            book: _recipes,
            catalogue: catalogue,
            bench: _bench(),
            job: job,
            itemNameOf: _nameOfId,
            onCraft: (recipe) => unawaited(_craft(recipe)),
            onCancel: () => unawaited(_cancelCraft()),
          ),
        ),
      ),
    );
    await _reloadCraftJob();
  }

  /// §2.1a: whatever the character is already doing, or null.
  ///
  /// ⚠️ **One pair of hands.** §2.1a says an occupation excludes every other
  /// occupation, and the interface did not: a walk came back with a photograph
  /// of somebody eating a tin of meat *and* taking a pair of boots apart at the
  /// same time. Each half checked its own clock and neither asked about the
  /// other's.
  ///
  /// Everything with a duration goes through here before it starts.
  /// §2.1a: one pair of hands, asked and answered in one line.
  ///
  /// ⚠️ **The guard was written out ten times** — five lines each, and each
  /// copy an opportunity to forget the `return`. Every start in this file goes
  /// through here now, so adding an eleventh is one line rather than five, and
  /// the budget in `one_action_test` has one name to hold rather than a shape.
  bool _refuseIfBusy() {
    final busy = _alreadyBusy();
    if (busy == null) return false;

    _say(L10n.of(context).actionBusy(busy));
    return true;
  }

  String? _alreadyBusy() {
    final l10n = L10n.of(context);

    // §2.1a, §11.1: the row first, because it is the only one of these that
    // survives a restart. A use the operating system interrupted is still on
    // it until the boot has settled it, and starting something else on top
    // would be starting two things.
    final running = _actions?.current;
    if (running != null) {
      final subject = running.subjectUid;
      final line = subject == null
          ? null
          : _inventory.value.carried
                .where((entry) => entry.uid == subject)
                .firstOrNull;

      return line == null
          ? l10n.searchAreaRunning
          : _useLabelFor(running.kind, line);
    }

    if (_search.value != null) {
      return _search.value!.usingLabel ?? l10n.searchAreaRunning;
    }
    if (_reload != null) return l10n.combatReload;

    final job = _craftJob.value;
    if (job != null) return _jobLabel(job);

    // ⚠️ §2.1a, §8.3: work *put down* is not an occupation. A build blocks
    // everything else, and the only way out used to be cancelling — which
    // threw the hours away even though the timber came back.
    final now = DateTime.now().toUtc();
    for (final place in _shelters.value) {
      if (place.paused) continue;

      if (!place.isReadyAt(now)) {
        return place.kind == ShelterKind.main
            ? l10n.shelterTitle
            : l10n.campTitle;
      }
      if (place.building != null) {
        return moduleName(l10n, place.building!);
      }
    }

    return null;
  }

  /// §12: why one action would not work on one piece **right now**.
  ///
  /// ⚠️ Only for the second kind of "no". An action that does not apply to the
  /// thing at all — dismantling a tin, reloading a crowbar — shows no button,
  /// and is never asked about here. This answers for the ones that apply and
  /// cannot happen yet: the shelves are full, something is already on the
  /// bench, a search is running. Those are things a player can go and fix, and
  /// hiding them would leave somebody hunting for a control that was there a
  /// minute ago.
  ///
  /// Asked with the same figures that would do the work, never a proxy for
  /// them — the dismantle glyph spent a day lit on axes because it asked what
  /// a thing was made of instead of what would come out of it.
  String? _packRefusal(CarriedItem line, PackAction action) {
    final l10n = L10n.of(context);
    final catalogue = _catalogue;
    if (catalogue == null) return null;

    // §2.1a: anything at all rules out starting anything else.
    final busy = _alreadyBusy();

    switch (action) {
      case PackAction.use:
      case PackAction.read:
      case PackAction.fill:
      case PackAction.empty:
        return busy == null ? null : l10n.actionBusy(busy);

      case PackAction.wear:
        return null;

      case PackAction.stash:
        // §18.2: the one the player asked about. The shelves fill up, and
        // "full" is something they can answer by taking something off them.
        return _stash.value.fits(line, catalogue) ? null : l10n.stashFull;

      case PackAction.dismantle:
        final refusal = salvageRefusalFor(
          line.itemId,
          _bench(),
          catalogue: catalogue,
          book: _recipes,
          condition: line.condition ?? 100,
        );
        // `nothingBack` is the first kind of no: that glyph is not drawn at
        // all, so it never reaches here. Anything else is worth saying.
        return refusal == null || refusal == CraftRefusal.nothingBack
            ? null
            : _craftRefusal(refusal);
    }
  }

  /// §2.1a, §12: everything with a clock on it, in the one strip under the
  /// stats — and every line of it stoppable.
  ///
  /// Ordered by how urgent it is to the person holding the phone: a search or
  /// a reload is happening to them now, a bench job is happening to their
  /// afternoon.
  Widget? _running() {
    final search = _search.value;
    final reload = _reload;
    final job = _craftJob.value;
    final l10n = L10n.of(context);

    final lines = <RunningAction>[
      if (reload != null)
        RunningAction(
          icon: Icons.autorenew,
          label: _reloadProgress()?.label ?? l10n.combatReload,
          startedAt: reload.readyAt.subtract(reload.total),
          readyAt: reload.readyAt,
          // §5.5.4 already lets a body within five metres break a reload.
          // Somebody choosing to break their own is the same thing, and the
          // rounds have not moved yet — nothing is lost by stopping.
          onStop: _endReload,
        ),
      if (job != null)
        RunningAction(
          icon: Icons.handyman,
          label: _jobLabel(job),
          startedAt: job.startedAt,
          readyAt: job.readyAt,
          onStop: () => unawaited(_cancelCraft()),
          note: job.isSalvage
              ? l10n.craftStopKeepsWork
              : l10n.craftCancelWarning,
        ),
    ];

    final build = BuildProgress.of(
      _shelters.value,
      _standingAt.value,
      DateTime.now().toUtc(),
      onStop: (place) => unawaited(_confirmCancelBuild(place)),
      onPause: (place) => unawaited(_pauseBuild(place)),
    );

    if (search == null || !search.isRunning) {
      if (lines.isEmpty && build == null) return null;

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (lines.isNotEmpty) ActionStrip(actions: lines),
          ?build,
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ActionProgress(search: search, onCancel: _cancelSearch),
        if (lines.isNotEmpty) ActionStrip(actions: lines),
        ?build,
      ],
    );
  }

  void _onBenchChanged() {
    if (mounted) setState(() {});
  }

  /// §18.2: gives up on a build, having said what that costs.
  ///
  /// The same question the shelter screen asks, asked from the map — because
  /// the map is where the bar is, and a bar with a stop on it that quietly
  /// destroyed three hours of work and a pack of timber would be worse than
  /// no stop at all.
  Future<void> _confirmCancelBuild(Shelter place) async {
    if (await askCancelBuild(context, place)) await _cancelBuild(place);
  }

  /// What the bench is doing, in the player's words.
  String _jobLabel(CraftJob job) {
    final l10n = L10n.of(context);
    if (job.isSalvage) {
      final name = _nameOfId(job.salvageItemId!);

      // §12: a sitting says how much of itself is left. "Rozbiórka: Nóż" on a
      // bar with three quarters of an hour on it reads as broken.
      final rest = _sittingOf(job).length - 1;
      return rest > 0
          ? l10n.salvageBatchRunning(name, rest)
          : l10n.craftTakingApart(name);
    }

    final recipe = _recipes.recipes
        .where((entry) => entry.id == job.recipeId)
        .firstOrNull;
    return recipe == null
        ? l10n.craftTitle
        : l10n.craftMaking(_nameOfId(recipe.output));
  }

  /// §18.6: stops taking something apart, and remembers how far it got.
  ///
  /// ⚠️ The piece does **not** come back whole. It has been opened up, and
  /// that is the point: §18.6 is something you do to a thing you have already
  /// decided against, and half a rifle is not a rifle. What is kept is the
  /// work, so going back to it later is not starting again.
  Future<void> _pauseDismantle() async {
    final character = _character;
    final job = _craftJob.value;
    if (character == null || job == null || !job.isSalvage) return;

    final kept = job.creditedAt(DateTime.now().toUtc());

    // §18.6: a sitting stops in whole pieces. Everything that finished before
    // the stop is already apart and gets paid out; the one that was under the
    // multitool keeps its minutes; the rest were never touched.
    final batch = _sittingOf(job);
    final settled = batch.settledAt(kept);

    if (settled.done.isNotEmpty) await _paySalvage(settled.done);

    final head = settled.left.isEmpty ? null : settled.left.first;
    final piece = head == null ? null : _pieceOf(head);
    if (head != null && piece != null && !piece.fromShelf) {
      final into = batch.creditedOn(kept);

      // ⚠️ §11.1: one piece out of the stack first, and the progress goes on
      // that one.
      //
      // §18.6's partial progress is written on a *line*, and a line can stand
      // for three pieces. Writing it straight on would mark all three as
      // half undone when the multitool had only ever been on one of them —
      // three ruined vests for one interrupted sitting. §4.7 already settled
      // the same question about a stack of tins: opening one is what splits
      // it off.
      final split = _inventory.value.openOne(piece.line);
      final already = split.line.salvageSeconds ?? 0;

      _inventory.value = split.inventory.withLine(
        split.line,
        // Never nought: a piece that has been opened at all is a piece that
        // no longer works, and a zero here would read as untouched.
        split.line.copyWith(
          salvageSeconds: into.inSeconds + already < 1
              ? 1
              : into.inSeconds + already,
        ),
      );
      await _saveInventory();
    }

    await _bench2.clear();
    _craftJob.value = null;
    _dismantling.value = const [];

    if (!mounted) return;
    _say(L10n.of(context).craftStopped);
  }

  /// §11.1: the piece a step names, against the pack and shelves as they are.
  SalvagePiece? _pieceOf(SalvageStep step) => pieceOf(
    step,
    carried: _inventory.value.carried,
    shelved: _stash.value.lines,
  );

  /// §18.4: gives up on whatever is on the bench.
  ///
  /// Nothing comes back. §18 has no rule returning materials from abandoned
  /// work, and inventing one would make starting a job free — the shelter's
  /// own cancel says the same thing in the same words.
  Future<void> _cancelCraft() async {
    final character = _character;
    if (character == null) return;

    // A dismantling is stopped, not abandoned: §18.6 lets somebody come back
    // to it, and the work already done is the thing worth keeping.
    if (_craftJob.value?.isSalvage ?? false) {
      await _pauseDismantle();
      return;
    }

    await _bench2.clear();
    _craftJob.value = null;

    // §18.6: giving up hands the piece back whole. Nothing was taken out of
    // it — the minutes were the cost, and they are gone.
    _dismantling.value = const [];
    if (!mounted) return;
    _say(L10n.of(context).shelterCancelled);
  }

  /// §18.4, §18.6: what the bench knows about the player right now.
  ///
  /// ⚠️ Materials counted from the pack **and** the shelves, like §18.2's
  /// builds. Anything on a shelf is already where the work is happening, and
  /// making somebody pick their own wood up off their own shelf before the
  /// button lights is bookkeeping rather than a decision.
  ///
  /// ⚠️ **Cached, because this is on the hot path and used to be rebuilt every
  /// frame.** Every one of these calls walked the pack and the shelves to
  /// build two maps, and it is asked once per rebuild of the map screen — on
  /// every GPS fix, every tick of the action strip, every drag of the map —
  /// plus once per action per row of the pack, which at seven actions and
  /// thirty rows is two hundred walks in one frame.
  ///
  /// The inputs are all immutable and replaced wholesale, so comparing the
  /// references answers "has anything changed" exactly and in constant time.
  /// The one thing that is not a reference is the clock, and [_BenchInputs]
  /// says why that is safe.
  CraftBench _bench() {
    final now = DateTime.now().toUtc();
    final inputs = _BenchInputs(
      shelters: _shelters.value,
      standingAt: _standingAt.value,
      inventory: _inventory.value,
      stash: _stash.value,
      search: _search.value,
      reload: _reload,
      job: _craftJob.value,
    );

    final cached = _benchCache;
    if (cached != null && cached.inputs == inputs && cached.freshAt(now)) {
      return cached.bench;
    }

    final bench = _computeBench(now);
    _benchCache = (inputs: inputs, bench: bench, madeAt: now);
    return bench;
  }

  ({_BenchInputs inputs, CraftBench bench, DateTime madeAt})? _benchCache;

  CraftBench _computeBench(DateTime now) {
    final main = _shelters.value
        .where((place) => place.kind == ShelterKind.main)
        .firstOrNull;
    final at = _standingAt.value;

    final counts = {..._carriedCounts()};
    for (final entry in _shelvedCounts().entries) {
      counts[entry.key] = (counts[entry.key] ?? 0) + entry.value;
    }

    return CraftBench(
      // §2.1a: any shelter or camp will do. Making is something you do where
      // you keep your things, and a camp is one of those places (§8.5).
      atShelter:
          at != null && _shelters.value.any((place) => place.coversAt(at, now)),
      workshopLevel: main?.levelOf(ShelterModule.workshop) ?? 0,
      atHand: counts.keys.toSet(),
      materials: counts,
      // ⚠️ §2.1a: **the** busy check, not a hand-written second copy of it.
      // The old one missed the action row and every shelter build, so a
      // workshop could be started while a camp was going up. A private version
      // of a shared rule is a rule with holes in it.
      busy: _alreadyBusy() != null,
      // §7: −30% on building, making and taking apart at full mastery, and a
      // better share back from §18.6.
      engineering: _learned.engineering,
    );
  }

  /// §18.4: puts one thing on the bench.
  Future<void> _craft(ItemRecipe recipe) async {
    final character = _character;
    if (character == null) return;

    final bench = _bench();
    final refusal = refusalFor(recipe, bench);
    if (refusal != null) {
      _say(_craftRefusal(refusal));
      return;
    }

    // ⚠️ Paid now, not at the end. Charging on completion would let somebody
    // start a spear, spend the wood on a splint, and collect both.
    await _spendMaterials(recipe.materials);

    await _bench2.beginCraft(
      recipeId: recipe.id,
      now: DateTime.now().toUtc(),
      work: craftWork(
        recipe,
        engineering: bench.engineering,
        workshopLevel: bench.workshopLevel,
      ),
    );

    await _reloadCraftJob();
    if (!mounted) return;
    _say(L10n.of(context).shelterBuildStarted);
  }

  /// §18.6, §18.2: picks a sitting out of the pack and the shelves together.
  ///
  /// ⚠️ Both piles, because at a bench they are one pile. Making somebody
  /// carry their own scrap off their own shelf before it can be opened is
  /// bookkeeping rather than a decision — the same rule §18.2's builds and the
  /// bench's own materials already live by.
  Future<void> _openDisassemble() async {
    final catalogue = _catalogue;
    if (catalogue == null) return;

    // ⚠️ **Not refused while a sitting is running.**
    //
    // It used to be: §2.1a says one pair of hands, so the screen would not
    // open at all. The effect on a walk was that the only place a player could
    // watch their own dismantling was the *making* screen — a bar about taking
    // things apart, at the top of a list of recipes. Right information, wrong
    // list, and reported as exactly that.
    //
    // The screen now shows whichever of its two jobs applies. Starting a
    // second sitting is still refused, by [_startSitting], which is where the
    // refusal belongs — at the act, not at the door.
    final offers = offersFrom(
      carried: _inventory.value.carried,
      worn: _inventory.value.worn,
      shelved: _stash.value.lines,
      bench: _bench(),
      catalogue: catalogue,
      book: _recipes,
    );

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DisassembleScreen(
          offers: offers,
          catalogue: catalogue,
          nameOf: _nameOfId,
          // §12: the sitting is watched where it was started, and stopped from
          // the same place.
          job: _craftJob,
          onStop: () => unawaited(_cancelCraft()),
          // §18.6: at this player's share. Asked here because this is where
          // the bench is.
          yieldsOf: (step) => yieldOf(
            step,
            bench: _bench(),
            catalogue: catalogue,
            book: _recipes,
          ),
          onStart: (picked) {
            Navigator.of(context).pop();
            unawaited(_startSitting(picked));
          },
        ),
      ),
    );

    await _reloadCraftJob();
  }

  /// §18.6: puts a whole sitting on the bench, in the order it was agreed to.
  ///
  /// ⚠️ **Nothing leaves the pack or the shelf yet.** The pieces stay where
  /// they are, locked, and go one at a time as their turn finishes — which is
  /// what makes stopping half way honest: everything is either apart or
  /// exactly as it was.
  Future<void> _startSitting(List<SalvagePick> picked) async {
    final character = _character;
    if (character == null || picked.isEmpty) return;

    if (_refuseIfBusy()) return;

    // ⚠️ One step per **piece**, not per row. A stack of three that was asked
    // for whole is three steps sharing one uid — the pack holds one entry with
    // a count, and each step takes one off it as its turn finishes.
    final batch = batchOf(picked);
    if (batch.isEmpty) return;

    await _bench2.beginSalvage(batch, now: DateTime.now().toUtc());

    await _reloadCraftJob();

    if (!mounted) return;
    _say(L10n.of(context).shelterBuildStarted);
  }

  /// §18.6: takes something apart for what is in it.
  ///
  /// The item leaves the pack now, with the work. Leaving it there until the
  /// job finished would let a player dismantle a rifle and shoot it for the
  /// next quarter of an hour.
  Future<void> _dismantle(CarriedItem line) async {
    final character = _character;
    final catalogue = _catalogue;
    if (character == null || catalogue == null) return;

    // ⚠️ Out of the pack, never off the body. The piece stays where it is
    // while the work runs (that is what the bar is under), so a weapon still
    // in the hands would go on being fired through its own dismantling.
    if (!_inventory.value.carried.any((entry) => entry.isSame(line))) {
      _say(L10n.of(context).craftNotAtShelter);
      return;
    }

    final bench = _bench();
    final condition = line.condition ?? 100;
    final refusal = salvageRefusalFor(
      line.itemId,
      bench,
      catalogue: catalogue,
      book: _recipes,
      condition: condition,
    );
    if (refusal != null) {
      _say(_craftRefusal(refusal));
      return;
    }

    final back = salvagePreview(
      line.itemId,
      bench,
      catalogue: catalogue,
      book: _recipes,
      condition: condition,
    );

    final whole = salvageTime(
      materialContent(catalogue[line.itemId]!, _recipes),
    );

    // §18.6: what is left of it, for a piece somebody already started on.
    final done = Duration(seconds: line.salvageSeconds ?? 0);
    final work = whole - done;

    // ⚠️ Asked, because nothing here comes back. §18.6 destroys the item and
    // returns a fraction, and a player is entitled to read the price before
    // paying it rather than after.
    // Nothing to ask a second time: the piece is already ruined, and going
    // back to it is the only thing left to do with it.
    final go =
        line.isPartlyDismantled || await _confirmDismantle(line, back, work);
    if (!go || !mounted) return;

    // ⚠️ It stays in the pack, locked, rather than vanishing for a quarter of
    // an hour. A bar has to be under something, and an item that disappears
    // the moment the work starts leaves nowhere to put it. Locked is what
    // stops the other half of the problem: while this row is under the
    // multitool it cannot be worn, used, dropped or shelved, so a rifle being
    // taken apart still cannot be fired.
    _dismantling.value = [line];

    // ⚠️ Started in the past by however long it has already had, so the bar
    // picks up where it was left rather than beginning again at nothing.
    final now = DateTime.now().toUtc();
    await _bench2.beginSalvageOne(
      itemId: line.itemId,
      condition: condition,
      now: now.subtract(done),
      work: whole,
    );

    await _reloadCraftJob();
  }

  Future<bool> _confirmDismantle(
    CarriedItem line,
    Map<String, int> back,
    Duration work,
  ) async {
    final catalogue = _catalogue;
    if (catalogue == null) return false;

    return askDismantle(
      context,
      name: _nameOfItem(catalogue[line.itemId]!),
      gives: back.entries
          .map((entry) => '${_nameOfId(entry.key)} ×${entry.value}')
          .join(', '),
      work: work,
      inStack: line.count,
    );
  }

  String _nameOfId(String itemId) {
    final definition = _catalogue?[itemId];
    return definition == null ? itemId : _nameOfItem(definition);
  }

  String _craftRefusal(CraftRefusal refusal) =>
      craftRefusalText(L10n.of(context), refusal);

  /// §2.1a.3: reads the bench, and pays out anything that finished while the
  /// app was closed.
  /// Watches the bench while something is on it.
  void _startBenchTimer() => _clock.restart(_kBench);

  void _stopBenchTimer() => _clock.retime();

  Future<void> _reloadCraftJob() async {
    final character = _character;
    if (character == null) return;

    final job = await _bench2.load();

    if (job == null || !job.isDoneAt(DateTime.now().toUtc())) {
      _craftJob.value = job;
      if (job == null) {
        _stopBenchTimer();
      } else {
        _startBenchTimer();
      }

      // ⚠️ Found again after a restart, because object identity does not
      // survive the process — by uid where the row has one (§11.1), and by
      // item id for rows written before uids existed.
      //
      // Only the pack, deliberately. A piece waiting its turn on a shelf is
      // locked by [_takeOffShelf] refusing to hand it over; putting it in this
      // list would draw a bar under a row on a screen it does not belong to.
      _dismantling.value = job == null || !job.isSalvage
          ? const []
          : lockedByBatch(
              _sittingOf(job),
              carried: _inventory.value.carried,
              shelved: _stash.value.lines,
            );
      return;
    }

    _stopBenchTimer();
    _craftJob.value = null;
    await _finishCraftJob(job);
  }

  /// What a finished job hands over (§18.4, §18.6).
  Future<void> _finishCraftJob(CraftJob job) async {
    final character = _character;
    final catalogue = _catalogue;
    if (character == null || catalogue == null) return;

    await _bench2.clear();

    if (job.isSalvage) {
      // §18.6: every piece of the sitting, in order. The whole job ran, so
      // every one of them is apart.
      await _paySalvage(_sittingOf(job).steps);
      _dismantling.value = const [];

      if (!mounted) return;
      _say(L10n.of(context).craftDone);
      return;
    }

    final recipe = _recipes.recipes
        .where((entry) => entry.id == job.recipeId)
        .firstOrNull;
    if (recipe == null) return;

    await _grant({recipe.output: recipe.count});

    if (!mounted) return;
    _say(L10n.of(context).craftDone);
  }

  /// §18.6: destroys the pieces [steps] names and hands over what was in them.
  ///
  /// ⚠️ **Worked out at the end, not at the start.** The return is scaled by
  /// the workshop and by skill (§18.6), and a player who finished a Workshop
  /// while the sitting ran should get the better share — the same way the
  /// single-item path has always read the bench at the moment it paid out.
  ///
  /// Both piles, because §18.2 makes them one pile at a bench: a piece that
  /// went into the sitting from a shelf leaves from the shelf.
  Future<void> _paySalvage(List<SalvageStep> steps) async {
    final character = _character;
    final catalogue = _catalogue;
    if (character == null || catalogue == null || steps.isEmpty) return;

    final bench = _bench();
    final made = <String, int>{};

    var shelf = _stash.value;
    var pack = _inventory.value;
    var movedShelf = false;

    for (final step in steps) {
      for (final entry in salvagePreview(
        step.itemId,
        bench,
        catalogue: catalogue,
        book: _recipes,
        condition: step.condition,
      ).entries) {
        made[entry.key] = (made[entry.key] ?? 0) + entry.value;
      }

      // Now it goes. Whatever came out of it is what is left of it.
      final piece = _pieceOf(step);
      if (piece == null) continue;

      if (piece.fromShelf) {
        // ⚠️ Looked up again against the shelf as it stands now: taking one
        // line off it moves every index after it, and a list of indices
        // worked out before the loop would take the wrong things out.
        final index = shelf.lines.indexWhere((line) => line.isSame(piece.line));
        if (index < 0) continue;

        shelf = shelf.take(index).stash;
        movedShelf = true;
      } else {
        pack = pack.removeLine(piece.line) ?? pack;
      }
    }

    _inventory.value = pack;
    await _saveInventory();

    if (movedShelf) {
      _stash.value = shelf;
      await _saveShelf();
    }

    await _grant(made);
  }

  /// Hands [made] over, and puts on the shelves whatever will not fit.
  ///
  /// ⚠️ Onto the shelves when the pack will not take it, never nowhere.
  ///
  /// §18.1a's overflow is a state, not a reason to destroy something: a
  /// forty-five minute pack that vanishes because the bag was full is the
  /// worst possible reading of a carry limit.
  Future<void> _grant(Map<String, int> made) async {
    final character = _character;
    final catalogue = _catalogue;
    if (character == null || catalogue == null || made.isEmpty) return;

    var pack = _inventory.value;
    final overflow = <String, int>{};

    for (final entry in made.entries) {
      final change = pack.add(
        entry.key,
        catalogue,
        body: character.body,
        count: entry.value,
      );
      pack = change.inventory;

      final took =
          change.acceptedCount ?? (change.isAccepted ? entry.value : 0);
      if (took < entry.value) overflow[entry.key] = entry.value - took;
    }

    _inventory.value = pack;
    await _saveInventory();

    if (overflow.isNotEmpty) await _shelveSpill(overflow);
  }

  /// Takes what a build costs out of the pack (§18.2).
  Future<void> _spendMaterials(Map<String, int> materials) async {
    // ⚠️ The shelves first, the pack second.
    //
    // Everything on a shelf is already where the work is happening, and
    // spending it first sends the player away carrying as little as possible —
    // which is most of the reason §18.2 gives a shelter storage at all.
    final owed = {...materials};

    var shelf = _stash.value;
    for (final itemId in owed.keys.toList()) {
      var left = owed[itemId]!;

      while (left > 0) {
        final index = shelf.lines.indexWhere((line) => line.itemId == itemId);
        if (index < 0) break;

        final took = shelf.take(index, count: left);
        final taken = took.taken;
        if (taken == null) break;

        shelf = took.stash;
        left -= taken.count;
      }

      owed[itemId] = left;
    }

    if (!identical(shelf, _stash.value)) {
      _stash.value = shelf;
      await _saveShelf();
    }

    var pack = _inventory.value;
    for (final entry in owed.entries) {
      var left = entry.value;

      while (left > 0) {
        final line = pack.carried
            .where((piece) => piece.itemId == entry.key)
            .firstOrNull;
        if (line == null) break;

        final taken = line.count < left ? line.count : left;
        pack = pack.removeLine(line, count: taken) ?? pack;
        left -= taken;
      }
    }

    _inventory.value = pack;
    await _saveInventory();
  }

  /// Carried or on the shelf — the two places a thing can be within reach of
  /// somebody standing in their own shelter.
  bool _atHand(String itemId) =>
      _carries(itemId) || (_shelvedCounts()[itemId] ?? 0) > 0;

  /// §18.2: reads the shelves of the main shelter in.
  Future<void> _loadShelvesOfMain() async {
    final catalogue = _catalogue;
    final main = _shelters.value
        .where((place) => place.kind == ShelterKind.main)
        .firstOrNull;

    if (catalogue == null || main == null) {
      // ⚠️ Closed rather than emptied. With no shelter open there is nothing
      // to write to, and shelves that saved themselves against no shelter
      // would put one shelter's things into another's.
      _shelf.close();
      return;
    }

    await _shelf.open(main, catalogue);
  }

  bool _carries(String itemId) => _carriedIds().contains(itemId);

  /// An item's name in the player's language.
  String _nameOfItem(ItemDefinition item) {
    final language = Localizations.localeOf(context).languageCode;
    return item.name.resolve(
      language: language,
      lookup: (_names ?? ItemNames.empty).forLanguage(language),
    );
  }

  /// §10.3: marks where something went down, for as long as it is worth
  /// coming back to.
  void _remember(Enemy enemy) {
    final body = Remains(
      id: enemy.id,
      kind: enemy.kind,
      position: enemy.position,
      diedAt: DateTime.now().toUtc(),
    );

    final before = _remains;
    _loot.addBody(body);

    // §10.3: and onto the disk, because the player put it there. §6.4 remakes
    // the living every run and that is right — a Walker is not a place — but a
    // body is, and losing it to a restart takes away their own work.
    if (!identical(_remains, before)) {
      // ⚠️ Here rather than at the trigger, because a death is noticed from
      // three places — the shot, the swing, and the sweep that finds an enemy
      // gone. [addRemains] is what settles which of them was first, so it is
      // also the only place a kill can be counted exactly once.
      _note((stats) => stats.killed());

      final character = _character;
      if (character != null) {
        unawaited(
          RemainsStore(widget.session.db).add(character.profile.id, body),
        );
      }
    }
  }

  /// §18.2: the shelves of [place], and the pack beside them.
  Future<void> _openStash(Shelter place) async {
    final character = _character;
    final catalogue = _catalogue;
    if (character == null || catalogue == null) return;

    await _shelf.open(place, catalogue);
    if (!mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => StashScreen(
          title: L10n.of(context).shelterShelves,
          stash: _stash,
          pack: _inventory,
          catalogue: catalogue,
          // The catalogue is what the screen has; a name is what a
          // player can read.
          nameOf: (itemId) {
            final item = catalogue[itemId];
            return item == null ? itemId : _nameOfItem(item);
          },
          onStore: (line) => unawaited(_leaveOnShelf(line)),
          onTake: (index) => unawaited(_takeOffShelf(index)),
          // One order for the pack and the shelves: they are one decision
          // seen twice.
          order: _packOrder,
          onAct: (index, action) => unawaited(_shelfAct(index, action)),
          onDetails: (index) => unawaited(_shelfDetails(index)),
          canDismantle: _worthTakingApart,
          refusalOf: _shelfRefusal,
          // §18.4: what the bench is doing, said where the player is standing.
          // They came in to put things away while a spear is being made.
          job: _craftJob,
          jobLabel: _jobLabel,
          onStopJob: () => unawaited(_cancelCraft()),
        ),
      ),
    );

    _shelf.close();
  }

  /// §18.2: onto the shelf without opening it first.
  ///
  /// The same move [_leaveOnShelf] makes, from the pack screen. Walking into
  /// the shelter to put four things away meant four trips through the shelves
  /// screen, and the shelves screen exists to *take things out*.
  Future<void> _quickShelve(CarriedItem line) async {
    final character = _character;
    final catalogue = _catalogue;
    final main = _shelters.value
        .where((place) => place.kind == ShelterKind.main)
        .firstOrNull;
    if (character == null || catalogue == null || main == null) return;

    final at = _standingAt.value;
    if (at == null || !main.atSite(at)) {
      _say(L10n.of(context).shelterNotHere);
      return;
    }

    final moved = _stash.value.put(line, catalogue);
    if (!moved.moved) {
      _say(L10n.of(context).stashFull);
      return;
    }

    final left = _inventory.value.removeLine(line, count: line.count);
    if (left == null) return;

    // Off the pack only once it is on the shelf: a half-applied move is an
    // item that exists twice or not at all.
    _stash.value = moved.stash;
    _inventory.value = left;

    // ⚠️ Against the main shelter rather than [StashController.openAt]: this
    // is reached from the pack screen, where the shelves themselves were
    // never opened.
    await _shelf.saveTo(main);
    await _saveInventory();
  }

  /// Whether the shelves are within arm's reach right now (§18.2).
  bool _shelvesInReach() {
    final at = _standingAt.value;
    if (at == null) return false;

    return _shelters.value.any(
      (place) => place.kind == ShelterKind.main && place.atSite(at),
    );
  }

  /// §18.2: out of the pack and onto the shelf.
  Future<void> _leaveOnShelf(CarriedItem line) async {
    final catalogue = _catalogue;
    final place = _openShelves;
    if (catalogue == null || place == null) return;

    final moved = _stash.value.put(line, catalogue);
    if (!moved.moved) {
      if (mounted) _say(L10n.of(context).stashFull);
      return;
    }

    // ⚠️ The copy that was pointed at, not any copy with that id — two knives
    // at different conditions are two different things to own, exactly as
    // §4.8's dropping already treats them.
    final left = _inventory.value.removeLine(line, count: line.count);
    if (left == null) return;

    // ⚠️ Off the shelf only once it is on it. The two lists are one decision,
    // and a half-applied move is an item that exists twice or not at all.
    _stash.value = moved.stash;
    _inventory.value = left;

    await _saveShelf();
    await _saveInventory();
  }

  /// §18.2: off the shelf and into the pack, if it will go.
  Future<CarriedItem?> _takeOffShelf(int index) async {
    final character = _character;
    final catalogue = _catalogue;
    final place = _openShelves;
    if (character == null || catalogue == null || place == null) return null;

    final held = _stash.value.lines.elementAtOrNull(index);

    // §18.6: it is spoken for. Handing it over would put a piece that the
    // bench is counting on into the pack, where it could be worn, eaten or
    // dropped before its turn came round.
    if (held != null && _inSitting(held)) {
      if (mounted) _say(L10n.of(context).craftBenchBusy);
      return null;
    }

    final took = _stash.value.take(index);
    final line = took.taken;
    if (line == null) return null;

    // §18.1a: the pack has the same two limits the shelf does, and a shelf is
    // not a way round them.
    final added = _inventory.value.add(
      line.itemId,
      catalogue,
      body: character.body,
      count: line.count,
      condition: line.condition,
      pagesTotal: line.pagesTotal,
      pagesRead: line.pagesRead,
      noteId: line.noteId,
      portion: line.portion,
      attachments: line.attachments,
    );
    if (!added.isAccepted) {
      if (mounted) _say(L10n.of(context).stashNoRoomInPack);
      return null;
    }

    // ⚠️ Which piece it became, found before either list is replaced.
    //
    // Everything a player does to something on a shelf is done by picking it
    // up first, so the caller needs a handle on the very line that arrived —
    // and `add` builds a new one, or merges into a stack that was already
    // there. Identity against the old list answers both cases.
    final before = _inventory.value.carried;
    final arrived =
        added.inventory.carried
            .where((entry) => !before.any((old) => old.isSame(entry)))
            .firstOrNull ??
        added.inventory.carried
            .where((entry) => entry.itemId == line.itemId)
            .firstOrNull;

    _stash.value = took.stash;
    _inventory.value = added.inventory;

    await _saveShelf();
    await _saveInventory();

    return arrived;
  }

  /// §5.6.3: the numbers for a piece on a shelf, with its slots.
  ///
  /// ⚠️ **Looking at something does not move it.** This used to pick the piece
  /// up first — the same motion every other shelf action makes — and tapping
  /// the information glyph therefore dragged whatever it was into the pack.
  /// Reported from a shelter in one sentence. Reaching for a thing is an
  /// action; reading its weight is not.
  ///
  /// Parts still come out of the pack, and the weapon still stays where it is:
  /// nothing moves but the scope.
  Future<void> _shelfDetails(int index) async {
    final catalogue = _catalogue;
    final line = _stash.value.lines.elementAtOrNull(index);
    if (catalogue == null || line == null) return;

    await showItemDetails(
      context,
      line: line,
      inventory: _inventory,
      catalogue: catalogue,
      names: _names ?? ItemNames.empty,
      // ⚠️ Not from the pack. The sheet looks for the piece's counterpart in
      // the inventory to compare against, and a shelf line has none — the same
      // rule a pile on the pavement obeys, and for the same reason: it once
      // found the player's own rifle and pointed every control at it.
      fromPack: false,
      onAttach: (current, part) =>
          unawaited(_attachOnShelf(index, current, part)),
      onDetach: (current, id) => unawaited(_detachOnShelf(index, current, id)),
    );
  }

  /// §5.6.3: bolts something from the pack onto a weapon on a shelf.
  ///
  /// The part leaves the pack, the weapon stays on the shelf. Both lists are
  /// written together, because a half-applied move is a scope that exists
  /// twice or not at all.
  Future<void> _attachOnShelf(
    int index,
    CarriedItem line,
    CarriedItem part,
  ) async {
    final catalogue = _catalogue;
    final shelved = _stash.value.lines.elementAtOrNull(index);
    if (catalogue == null || shelved == null) return;

    final fitted = fittedWith(shelved, part, catalogue);
    if (fitted == null) {
      _say(L10n.of(context).attachmentRefused);
      return;
    }

    final without = _inventory.value.removeLine(part);
    if (without == null) return;

    _inventory.value = without;
    _stash.value = _stash.value.replace(index, fitted);

    await _saveShelf();
    await _saveInventory();
  }

  /// §5.6.3: takes one off a weapon on a shelf, back into the pack.
  Future<void> _detachOnShelf(int index, CarriedItem line, String id) async {
    final character = _character;
    final catalogue = _catalogue;
    final shelved = _stash.value.lines.elementAtOrNull(index);
    if (character == null || catalogue == null || shelved == null) return;
    if (!shelved.attachments.contains(id)) return;

    final part = catalogue[id];
    final magazine = part == null ? null : Magazine.of(part);

    // §5.3: what was in it goes with it, exactly as [Inventory.detach] does.
    final added = _inventory.value.add(
      id,
      catalogue,
      body: character.body,
      rounds: magazine == null ? null : (shelved.rounds ?? 0),
    );
    if (!added.isAccepted) {
      _say(L10n.of(context).stashNoRoomInPack);
      return;
    }

    _inventory.value = added.inventory;
    _stash.value = _stash.value.replace(
      index,
      shelved.copyWith(
        attachments: [
          for (final other in shelved.attachments)
            if (other != id) other,
        ],
        rounds: magazine == null ? null : 0,
      ),
    );

    await _saveShelf();
    await _saveInventory();
  }

  /// §12: why a shelf action would not work right now.
  ///
  /// Everything here needs the piece in hand first, so §18.1a's two limits are
  /// the first question — and after that it is the same set of answers the
  /// pack gives, asked about the same piece.
  String? _shelfRefusal(CarriedItem line, PackAction action) {
    final character = _character;
    final catalogue = _catalogue;
    if (character == null || catalogue == null) return null;

    final definition = catalogue[line.itemId];
    if (definition == null) return null;

    // ⚠️ Asked, not attempted. This used to call `add` and throw the result
    // away, which walked the whole pack twice and cloned its line list — once
    // per row, per action, per frame. Thirty things on a shelf and seven
    // actions each is two hundred clones of the inventory in one frame.
    if (!_packRoom().holds(line, definition, catalogue: catalogue)) {
      return L10n.of(context).stashNoRoomInPack;
    }

    return _packRefusal(line, action);
  }

  /// §18.2: does something to a piece that is on a shelf.
  ///
  /// ⚠️ By picking it up first, always. Eating off a shelf, putting on a coat
  /// that is on a shelf and taking a rifle apart on a shelf are all the same
  /// motion in the world — you reach for it — and making them one motion in
  /// the code means every rule they already obey goes on being obeyed: the
  /// carry limits, the dismantling lock, the attachment slots.
  ///
  /// The one refusal it adds is §18.1a's: a pack with no room in it cannot
  /// pick anything up, and that is said rather than swallowed.
  Future<void> _shelfAct(int index, PackAction action) async {
    final line = await _takeOffShelf(index);
    if (line == null || !mounted) return;

    switch (action) {
      case PackAction.use:
      case PackAction.read:
        await _use(line);
      case PackAction.wear:
        await _wear(line);
      case PackAction.dismantle:
        await _dismantle(line);
      case PackAction.stash:
      case PackAction.fill:
      case PackAction.empty:
        break;
    }
  }

  /// §13.1: the character, and what they have done.
  /// §15.3: the developer overlay, built the same way in both places.
  ///
  /// ⚠️ It was written out twice — once over the map and once over the loading
  /// state — and the copy that gained §7's skill buttons would have been
  /// whichever one somebody happened to be editing.
  Widget _devOverlay(DevSession dev, GameSnapshot? snapshot) => DevOverlay(
    console: dev.console,
    // §7, §15.3: every effect of every skill is wired and nothing yet grants
    // meaningful experience, so without this the whole feature is untestable
    // in the field until reading lands.
    onSetSkill: (skill, level) => unawaited(_learned.setLevel(skill, level)),
    snapshot: DevSnapshot(
      state: snapshot?.state,
      fix: snapshot?.fix,
      signal: snapshot?.signal ?? PositionSignal.unavailable,
      ticksApplied: _simulatedSeconds(snapshot),
      lastFlushAt: snapshot?.lastFlushAt,
      clockRolledBack: snapshot?.clockRolledBack ?? false,
    ),
  );

  Future<void> _openProfile() async {
    final character = _character;
    final snapshot = _snapshot;
    if (character == null || snapshot == null) return;

    final weapon = _weapon;

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProfileScreen(
          name: character.profile.name,
          body: character.body,
          // §2: the raw figures, so the screen can account for a penalty.
          state: snapshot.state,
          status: snapshot.status,
          skills: _learned.set,
          stats: _stats,
          // §16.4: from the game's own clock, so a character created under
          // the simulator ages at the same rate as everything else about them.
          aliveFor: snapshot.state.lastUpdate.difference(
            character.profile.createdAt,
          ),
          weaponMoa: weapon == null
              ? null
              : FittedWeapon(
                  weapon: weapon,
                  attachments: _attachmentsFor(weapon),
                ).moa,
        ),
      ),
    );
  }

  /// §10.3: turns out the pockets of the body in reach.
  ///
  /// Only from arm's length, and only once. What comes out lands on the ground
  /// where it fell, which is the same pile machinery §4.8 already has — the
  /// difference is that nobody could see it from across the street.
  Future<void> _searchRemains(Remains body) async {
    final at = _standingAt.value;
    if (at == null || body.searched) return;
    if (body.position.distanceTo(at) > kStillnessM) return;

    _note((stats) => stats.searchedSomething());

    _loot.replaceBody(body.emptied);

    final character = _character;
    if (character != null) {
      await RemainsStore(
        widget.session.db,
      ).searched(character.profile.id, body.id);
    }

    await _leaveRemainsOf(body);
    if (!mounted) return;

    // The list, not a line of text: what came out of the pockets is a
    // decision about weight, and a notice that vanishes is no help with it.
    await _showPileAt(body.position);
  }

  /// §4.8, §10.3: what is left where something went down.
  ///
  /// Not a loot table of its own: a Walker was a person with pockets, so it is
  /// the scraps §18.2 already knows about plus, rarely, whatever it was
  /// carrying. Seeded from the enemy, so the same body always held the same
  /// thing however many times the app is restarted over it.
  Future<void> _leaveRemainsOf(Remains body) async {
    final character = _character;
    if (character == null) return;

    final random = Random(character.profile.rngSeed ^ body.id.hashCode);
    final drops = <String>[
      if (random.nextDouble() < 0.55) 'mat_fabric',
      if (random.nextDouble() < 0.30) 'mat_metal',
      if (random.nextDouble() < 0.18) 'med_bandage',
      // §10.3.3: ammunition on a body is a windfall, not an income.
      if (body.kind != EnemyKind.walker && random.nextDouble() < 0.12)
        'ammo_9x19',
    ];
    if (drops.isEmpty) return;

    final store = DroppedStore(widget.session.db);
    for (final itemId in drops) {
      await store.drop(
        character.profile.id,
        DroppedItem(
          id: 0,
          itemId: itemId,
          count: itemId == 'ammo_9x19' ? 3 + random.nextInt(8) : 1,
          position: body.position,
          droppedAt: DateTime.now().toUtc(),
        ),
      );
    }

    await _reloadDropped();
  }

  /// §5.5.2: what the HUD says about a fight, or null when there is none.
  ///
  /// Engaged rather than nearby: something wandering its own patch two hundred
  /// metres off is not a fight, and a warning that never goes out is a warning
  /// nobody reads.
  ThreatReading? _threat(GameSnapshot snapshot) {
    final fix = snapshot.displayFix;
    if (fix == null) return null;

    return _fight.threatAt(GeoPoint(fix.latitude, fix.longitude));
  }

  /// §3.6: loot is yellow. An emptied box is not drawn at all — a marker that
  /// stays after there is nothing behind it is a walk taken for nothing.
  ///
  /// §10.2.3 decides what is on the map before anybody looks: a pharmacy is a
  /// building and is visible from the street, so its marker is always there. A
  /// wrecked car in a side road is not, and appears only once the player has
  /// stopped and searched the area.
  /// The markers as the map wants them, worked out once per change.
  ///
  /// ⚠️ **This is on the hot path and used to be rebuilt on every `setState`.**
  ///
  /// [clusterMarkers] is O(n²) over everything on the map — places, bodies,
  /// piles, the fight — and [_lootMarkers] walks the places once per pile on
  /// top of that. Eating calls `setState` once a second for the length of a
  /// meal, so all of it ran once a second to produce, almost always, exactly
  /// the same list.
  ///
  /// Cached the way [_bench] is cached, and for the same reason: every input
  /// here is a value replaced wholesale when it changes, so comparing
  /// references is exact and costs nothing.
  List<MapMarker> _markers() {
    final inputs = MarkerInputs(
      boxes: _loot.boxes.value,
      dropped: _loot.dropped.value,
      remains: _loot.remains.value,
      shelters: _shelters.value,
      at: _standingAt.value,
      // §5.5.6: the fight moves every tick, so this is what actually decides
      // whether the answer can be reused.
      enemies: _combat.enemies,
      revealed: _loot.revealed.length,
      shot: _combat.open,
    );

    final cached = _markerCache;
    if (cached != null && cached.inputs == inputs) return cached.markers;

    final markers = clusterMarkers(_lootMarkers());
    _markerCache = (inputs: inputs, markers: markers);
    return markers;
  }

  ({MarkerInputs inputs, List<MapMarker> markers})? _markerCache;

  List<MapMarker> _lootMarkers() {
    final now = _snapshot?.state.lastUpdate ?? DateTime.now().toUtc();
    final here = _standingAt.value;

    /// §10.2: the reach ring, but only once the place is nearly underfoot.
    ///
    /// A circle per place is honest and, at any distance, a smear — fifteen
    /// of them overlapping say nothing. The question a ring answers is "can I
    /// open *this* one", and that is only asked about somewhere the player is
    /// nearly at.
    double? ringFor(GeoPoint at, double radiusM, double visibleWithinM) {
      if (here == null) return null;
      return at.distanceTo(here) <= visibleWithinM ? radiusM : null;
    }

    return [
      // §10.2.1: what is there, and what was there. A place the player
      // emptied keeps its dot in grey for a week — "I have been here" is the
      // difference between a street they have worked and one they have not,
      // and it costs nothing to say.
      for (final box in _boxes)
        if (box.isKnownAt(now) && _isVisible(box))
          MapMarker(
            id: box.poiId,
            kind: MarkerKind.loot,
            at: box.position,
            spent: !box.isActiveAt(now),
            // ⚠️ OSM's name where there is one, and what the place *is* where
            // there is not. Everything generated by §10.1 has no name at all,
            // so every car and every bin read "Skrzynia" — on a map whose
            // icons exist precisely so a player can tell them apart.
            label: box.name ?? placeName(L10n.of(context), box.tableId),
            // §10.2: how close is close enough to search *this* place.
            // Judging thirty or fifty metres by eye on a map that zooms is
            // guesswork, and the two are now different numbers.
            reachM: ringFor(
              box.position,
              searchReachFor(
                _world?.tables[box.tableId]?.size ?? PlaceSize.normal,
              ),
              kReachRingVisibleM,
            ),
            // §3.6: what kind of place it is. A dot that only says "something
            // to search" sends a player three hundred metres to a florist —
            // the decision they are making is which errand is worth the walk.
            icon: placeIconFor(box.tableId),
          ),

      // §3.6: red, and only what is near enough to be part of the fight
      // (§5.5.6). Seeing every Walker in the district would answer the one
      // question §7's Reconnaissance is there to ask.
      // ⚠️ The last place the player was, never a default of nought — an
      // island off Africa is further than the forget radius from everything,
      // so a single fix without a position wiped every enemy off the map.
      for (final enemy in _visibleEnemies())
        MapMarker(
          id: enemy.id,
          kind: MarkerKind.enemy,
          at: enemy.position,
          // §3.6: which way it is walking. Not a field of view — §6.2 gives
          // them a radius and nothing directional — but knowing that one of
          // them has turned towards you is the whole of the warning.
          headingDeg: enemy.headingDeg,
          // §6.2: what it can see, drawn only once it is near enough for that
          // to be a decision. The question is how close a player can get
          // before it notices, and it is answered well before they are on
          // top of it — so this ring shows twice as far out as a reach ring.
          reachM: ringFor(enemy.position, enemy.sightM, kSightRingVisibleM),
          alert: switch (enemy.state) {
            EnemyState.chase || EnemyState.spent => MarkerAlert.hunting,
            EnemyState.alert => MarkerAlert.searching,
            EnemyState.idle || EnemyState.returning => MarkerAlert.calm,
          },
        ),

      // §3.6: blue, and there is only ever one of them plus the camps.
      for (final place in _shelters.value)
        MapMarker(
          id: 'shelter.${place.id}',
          kind: MarkerKind.shelter,
          at: place.position,
          reachM: place.kind.safeRadiusM,
          icon: PlaceIcon.home,
        ),

      // §10.3: bone white, with a skull on it. Stays until it is not worth
      // walking back to.
      for (final body in _remains)
        MapMarker(
          id: 'remains.${body.id}',
          kind: MarkerKind.remains,
          at: body.position,
          reachM: kStillnessM,
        ),

      // §4.8: grey, and gone after a day.
      for (final item in _dropped.value)
        MapMarker(
          id: 'dropped.${item.id}',
          kind: MarkerKind.dropped,
          at: item.position,
          // §4.8: a pile the player dropped is picked up from arm's reach.
          //
          // ⚠️ But §10.2 gives a shop fifty metres *because its door is not
          // where the dot is*, and a search drops what it found at the dot.
          // Drawing a fifteen-metre ring round that pile drew a promise the
          // pickup rule does not make — reported from a school, where the
          // find could be taken but the ring said it could not.
          reachM: _reachForPilesAt(item.position),
        ),
    ];
  }

  /// §10.2.1: whether this place can be seen without going and looking.
  ///
  /// ⚠️ Not "was it invented". A car standing in the street is invented by
  /// §10.1 and is still perfectly visible from the pavement; a house that
  /// might or might not be abandoned is exactly what reconnaissance is for.
  /// Hiding everything invented meant a walk through a city showed no cars and
  /// no bins at all — they were there, and nothing said so.
  /// §5.5.6: what is close enough to be drawn, with a little hysteresis.
  ///
  /// ⚠️ Two different numbers were doing this job: the spawner makes things up
  /// to six hundred metres out and the map drew them at three hundred, so a
  /// walk down a street took one across that line and back and it read as
  /// flickering. Nothing was appearing or disappearing — it was the same
  /// Walker, in and out of a threshold.
  ///
  /// So a marker that is already drawn stays drawn a quarter further out.
  /// Coming into view still costs the full approach, which is the half of the
  /// rule §7's Reconnaissance is going to take over.
  List<Enemy> _visibleEnemies() => _fight.visible(_standingAt.value);

  /// §10.3.5: how long each depth takes at this place.
  /// §10.3.5, §7: what each depth costs *here*, at this character's hands.
  Map<SearchDepth, Duration> _searchTimesAt(LootBox? box) => searchTimesFor(
    sizeOf: box == null ? null : _world?.tables[box.tableId]?.size,
    scouting: _learned.scouting,
  );

  /// Advances whatever search is running, once a second.
  ///
  /// Its own timer rather than the snapshot stream: snapshots stop arriving
  /// with anything new to say when the player is standing still, which is
  /// precisely the whole duration of a search.
  Future<void> _advanceSearch() async {
    // ⚠️ **Re-entrant, and that is what hung the game on food.**
    //
    // This is reached from two places on purpose — its own one-second timer
    // and the loop's tick, so that a meal goes on finishing with the screen
    // off. Both are fine. What was not fine is that crediting a meal used to
    // publish a snapshot, which ran the listener, which arrived back here:
    //
    //     _advanceSearch → _advanceMeal → applyUse → publish → listener → …
    //
    // The old guard was "has any time passed at all", and between two turns
    // of that loop a microsecond had, so it went round as fast as the machine
    // allowed. [GameLoop.applyUse] no longer publishes, which closes that
    // particular circuit — these two guards close the shape of it, so that the
    // next thing to publish from inside a listener cannot reopen it.
    if (_clock.advancing) return;

    final search = _search.value;
    if (search == null || !search.isRunning) return;

    final now = DateTime.now().toUtc();
    final since = _searchTickedAt ?? now;
    final delta = now.difference(since);

    // A floor rather than "any time at all". Everything upstream of this runs
    // on a one-second clock, so a call a fifth of a second after the last one
    // is not a tick — it is a loop. Nothing is lost by refusing it: the credit
    // stays owed, because [_searchTickedAt] only moves when it is paid.
    if (delta < const Duration(milliseconds: 200)) return;
    _clock.tickedAt = now;
    _clock.advancing = true;

    try {
      await _advanceSearchStep(search, delta, now);
    } finally {
      _clock.advancing = false;
    }
  }

  /// ⚠️ Guards [_advanceSearch] against arriving inside itself. See there.

  Future<void> _advanceSearchStep(
    Search search,
    Duration delta,
    DateTime now,
  ) async {
    final snapshot = _snapshot;

    // ⚠️ The sticky position, and this is the seventh time this line has been
    // the bug. Reported from a shelter as "Przeszukanie przerwane: brak
    // pewnej pozycji" — the search started (that was the last fix) and was
    // then cancelled a second later by this.
    final at = _standingAt.value;

    // §2.1a.4 switches the receiver off under a roof, which reports as
    // `unavailable` — the same value as a refused permission. Both halves of
    // the old test therefore failed in a shelter and nowhere else.
    final sheltered = snapshot?.state.zone.isSheltered ?? false;

    final next = search.advance(
      delta,
      at: at,
      // §10.2: the place being searched decides how far "still here" reaches.
      //
      // ⚠️ Reported from a walk over a school: the search cancelled itself
      // while the player was still well inside the building they were
      // searching. [kStillnessM] is fifteen metres — an arm's length rule for
      // a wheelie bin — and it was being applied to a fifty-metre school
      // because this call never passed the radius the parameter exists for.
      //
      // Recon (§10.2.2) and forcing a door keep the tight rule: those really
      // are about standing in one spot.
      boundaryRadiusM: _boundaryForSearch(search),
      // §2.1a: a search counts only while the game can still say where the
      // player is — that is the one question a search asks, did they stand
      // still. Being under a roof answers it better than a fix does: the
      // receiver is off *because* the character is somewhere known and not
      // moving, so silence there is the game working, not the game blind.
      present:
          at != null &&
          (sheltered || snapshot?.signal != PositionSignal.unavailable),
      // §2.3, §2.5.4: how much of this second the body is actually worth.
      rate: snapshot?.status.workRate ?? 1,
    );

    if (next.isRunning) {
      _search.value = next;
      if (_filling != null) setState(() => _advanceFilling(next));
      if (_meal != null) await _advanceMeal(next.progress);
      return;
    }

    _stopSearchTimer();
    _search.value = null;

    if (next.state == SearchState.done) {
      final at = snapshot?.state.lastUpdate ?? now;
      await switch (next) {
        final s when s.isUse => _finishUse(s),
        final s when s.isBreach => _finishBreach(s, at),
        final s when s.isArea => _finishAreaSearch(s, at),
        final s => _finishObjectSearch(s, at),
      };
    } else {
      await _interruptUse(next);
      if (mounted) {
        _say(
          next.state == SearchState.cancelledByMovement
              ? L10n.of(context).searchMoved
              : L10n.of(context).searchLostSignal,
        );
      }
    }
  }

  /// §10.2: how far a running search lets the player drift.
  double _boundaryForSearch(Search search) => searchBoundaryM(
    place: _boxes
        .where((entry) => entry.poiId == search.targetPoiId)
        .firstOrNull,
    sizeOf: (box) => _world?.tables[box.tableId]?.size,
  );

  void _startSearchTimer() {
    _clock.tickedAt = DateTime.now().toUtc();
    _clock.restart(_kSearch);
  }

  void _stopSearchTimer() {
    _clock.tickedAt = null;
    _clock.retime();
  }

  /// §10.2.3: whether looking around again is worth the forty-five seconds.
  String? _scoutRefusal(GeoPoint at, DateTime now) => switch (scoutRefusal(
    at: at,
    now: now,
    lastAt: _scoutedAt,
    lastFrom: _scoutedFrom,
  )) {
    ScoutRefusal.tooSoon => L10n.of(context).searchTooSoon,
    ScoutRefusal.tooClose => L10n.of(context).searchTooClose,
    null => null,
  };

  void _startAreaSearch() {
    // ⚠️ The sticky position, not the snapshot's fix. Fifth time this exact
    // line has been the bug: in a shelter §2.1a.4 turns the receiver off, so
    // `displayFix` is null and searching the area silently did nothing — on
    // the one spot the player is most likely to be standing still.
    final at = _standingAt.value;
    if (at == null) return;

    // §2.1a: one pair of hands. A reload or a dismantling running is a
    // character with something in them.
    if (_refuseIfBusy()) return;

    final now = DateTime.now().toUtc();
    final refusal = _scoutRefusal(at, now);
    if (refusal != null) {
      _say(refusal);
      return;
    }

    setState(() {
      _search.value = Search.area(
        at: at,
        now: now,
        // §7: less of §10.2's forty-five seconds of standing still.
        scouting: _learned.scouting,
      );
    });
    _startSearchTimer();
  }

  void _startObjectSearch(SearchDepth depth) {
    // Sticky, for the same reason as the area search above.
    final at = _standingAt.value;
    final box = _boxInReach();
    if (at == null || box == null) return;

    if (_refuseIfBusy()) return;

    setState(() {
      _search.value = Search.object(
        at: at,
        now: DateTime.now().toUtc(),
        poiId: box.poiId,
        depth: depth,
        // §10.3.5: scaled by how much place there is. Three minutes over a
        // wheelie bin is the same three minutes as a supermarket, and reads
        // as exactly that.
        takes: _world?.tables[box.tableId]?.searchTime(depth),
        scouting: _learned.scouting,
      );
    });
    _startSearchTimer();
  }

  /// §19.3: what still shuts the place in reach, if anything.
  ///
  /// A box that has been opened once stays open — a forced door does not
  /// repair itself while the player walks home.
  Barrier? _barrierOn(LootBox? box) {
    if (box == null || box.isOpen) return null;
    return _world?.tables[box.tableId]?.barrier;
  }

  void _startBreach(BarrierBreach breach) {
    // ⚠️ Sticky. The car outside the shelter has a door on it, so opening it
    // goes through here rather than through the search — which is why "I
    // cannot search the car from my shelter" survived a fix to the search.
    final at = _standingAt.value;
    final box = _boxInReach();
    if (at == null || box == null) return;

    // ⚠️ §2.1a: one pair of hands, and this is the third place that had
    // to learn it. Both searches asked [_alreadyBusy] and this did not — it
    // asked only whether another *search* was running — so a dismantling at
    // the bench refused a quick search and waved a locked car straight
    // through. Reported from a walk as exactly that inconsistency, and the
    // inconsistency was the tell: forcing a door is not a lesser act than
    // looking in a bin, it is twenty seconds of both hands on a crowbar.
    if (_refuseIfBusy()) return;

    setState(() {
      _search.value = Search.breach(
        at: at,
        now: DateTime.now().toUtc(),
        poiId: box.poiId,
        breach: breach,
      );
    });
    _startSearchTimer();
  }

  /// §19.3: the way in is made, and it stays made.
  Future<void> _finishBreach(Search search, DateTime now) async {
    final character = _character;
    final poiId = search.targetPoiId;
    if (character == null || poiId == null) return;

    final box = _boxes.where((b) => b.poiId == poiId).firstOrNull;
    if (box == null) return;

    final opened = box.openedAtTime(now);
    _loot.replace(opened);

    await LootStore(widget.session.db).saveOne(character.profile.id, opened);
    if (mounted) _say(L10n.of(context).breachDone);
  }

  void _cancelSearch() {
    final running = _search.value;
    if (running == null) return;

    _stopSearchTimer();
    _search.value = null;
    unawaited(_interruptUse(running));
  }

  /// §4.7: half a bottle drunk is half a bottle gone, and half a bottle left.
  ///
  /// Anything else makes the choice a trap. Losing the whole bottle for
  /// stopping would teach a player never to start one near a corner they
  /// might have to run round; getting it all back for free would make the
  /// time it takes meaningless.
  Future<void> _interruptUse(Search action) async {
    await _endTimedAction();

    // §4.2: a fill stopped part way keeps the rounds it already moved — they
    // are in the magazine, and that is where they are.
    final interrupted = _filling != null;
    _filling = null;

    final line = _usingLine.value;
    final loop = _loop;
    final catalogue = _catalogue;
    _usingLine.value = null;

    if (interrupted) {
      await _saveInventory();
      return;
    }

    if (line == null || loop == null || catalogue == null || !action.isUse) {
      return;
    }

    // ⚠️ Nothing to settle for a meal: it has been emptying itself as it
    // went (§4.7), so the pack is already telling the truth. Only the things
    // that are *not* swallowed in mouthfuls — a tourniquet, a splint — reach
    // the older path, and for those an interruption leaves them in the pack.
    if (_meal != null) {
      _meal = null;
      return;
    }

    await _swallow(line, action.progress);
  }

  /// §10.2.3: reconnaissance reveals the places that cannot be seen from the
  /// street, and the state of the ones that can.
  Future<void> _finishAreaSearch(Search search, DateTime now) async {
    final previous = _knowledge;
    final radius = searchRadiusM(
      // ⚠️ §7's strongest single effect: at full mastery the radius doubles,
      // which is four times the area looked over. §10.2.2 warns about exactly
      // this, which is why nothing else on the list comes close.
      scouting: _learned.scouting,
      // §10.2.2: half the radius in the dark, and nobody was passing it.
      darkness: _snapshot?.darkness ?? 0,
      binoculars:
          _inventory.value.countOf('tool_binoculars') > 0 ||
          _inventory.value.worn.any((line) => line.itemId == 'tool_binoculars'),
    );

    final found = <String>{
      for (final box in _boxes)
        if (box.position.distanceTo(search.anchor) <= radius) box.poiId,
    };
    final fresh = found.difference(_revealed);

    setState(() {
      _revealed.addAll(found);
      _knowledge = AreaKnowledge(
        at: search.anchor,
        radiusM: radius,
        completedAt: now,
        revealedPoiIds: found,
      );
    });

    // §10.2.3: and sometimes a look around finds something worth walking to.
    final turnedUp = await _scoutForSomething(search.anchor, now);

    if (!mounted) return;
    final l10n = L10n.of(context);
    // §10.2.1: looking again at ground already searched is allowed and adds
    // nothing for ten minutes. Saying so plainly beats letting the player read
    // an empty result as a failed search.
    final knownAlready = previous?.covers(search.anchor, now) ?? false;
    _say(
      turnedUp != null
          ? l10n.searchFoundNearby(
              turnedUp == kCarSelector ? l10n.scoutCar : l10n.scoutWaste,
            )
          : fresh.isNotEmpty && !knownAlready
          ? l10n.searchRevealed(fresh.length)
          : l10n.searchNothingNew,
    );
  }

  /// §10.2.3: three looks in ten turn up something to search within 75 m.
  ///
  /// ⚠️ Beta, and not from the design document. §10.1 puts the world on real
  /// map features, which is right and which leaves a residential estate
  /// genuinely empty — measured on walks through Poznań. Reconnaissance
  /// already costs forty-five seconds of standing still and eighty metres of
  /// noise (§5.6); this is what that buys where there are no shops.
  ///
  /// Returns the selector of what was found, or null. Naming is the
  /// caller's job — this runs across an await and must not hold a context.
  Future<String?> _scoutForSomething(GeoPoint at, DateTime now) async {
    final character = _character;
    final world = _world;
    if (character == null || world == null) return null;

    // The valve is spent by *looking*, not by finding: [_startAreaSearch]
    // refuses a second look until the clock and the distance are both paid,
    // and this only has to roll the odds.
    _loot.scouted(at, now);

    // §11: seeded from the character and the minute, so the same look at the
    // same moment gives the same answer however many times it is replayed.
    final random = Random(
      character.profile.rngSeed ^ (now.millisecondsSinceEpoch ~/ 60000),
    );
    if (random.nextDouble() >= kScoutFindChance) return null;

    // What turns up is street furniture, never a shop: §10.1 decides where
    // shops are and this must not be a way round it.
    final selector = random.nextBool() ? kCarSelector : kWasteSelector;
    final table = world.tables.forTags([selector]).firstOrNull;
    if (table == null) return null;

    // Somewhere on the ring rather than underfoot — found by looking, so it
    // has to be a short walk away to have been out of sight.
    final bearing = random.nextDouble() * 360;
    final metres = kScoutFindRadiusM * (0.45 + 0.55 * random.nextDouble());
    final where = at.offsetBy(metres: metres, bearingDeg: bearing);

    // §3.5: not onto a carriageway, a railway or somebody's garden.
    if (SpawnFilter(_world?.obstacles ?? const []).refuse(where) != null) {
      return null;
    }

    final box = LootBox(
      poiId: 'scout.${now.millisecondsSinceEpoch}',
      position: where,
      tableId: table.id,
      spawnedAt: now,
    );

    _loot.reveal(box);

    await LootStore(widget.session.db).saveOne(character.profile.id, box);
    return selector;
  }

  /// §19.3: the table is rolled, what fits goes in the pack, and the box is
  /// empty until it refills (§10).
  Future<void> _finishObjectSearch(Search search, DateTime now) async {
    final character = _character;
    final catalogue = _catalogue;
    final world = _world;
    final poiId = search.targetPoiId;
    final depth = search.depth;
    if (character == null ||
        catalogue == null ||
        world == null ||
        poiId == null ||
        depth == null) {
      return;
    }

    final box = _boxes.where((b) => b.poiId == poiId).firstOrNull;
    final table = box == null ? null : world.tables[box.tableId];
    if (box == null || table == null) return;
    if (!box.canSearchAt(depth)) return;

    _note((stats) => stats.searchedSomething());

    // Seeded from the place, the character and how far into this place the
    // player already is, so the same search of the same shop gives the same
    // result however many times the app is restarted mid-search (§11) — and a
    // second pass over the same shelves is a different draw rather than the
    // first one again.
    final random = Random(
      character.profile.rngSeed ^
          poiId.hashCode ^
          (box.searchUnits * 2654435761),
    );
    final drop = table.roll(
      random,
      depth: depth,
      catalogue: catalogue,
      // §7, §10.3.5: a skilled searcher finds better, never more.
      scouting: _learned.scouting,
    );

    // ⚠️ Onto the floor of the place, not straight into the pack.
    //
    // §18.1a's two limits made the old way a mess to be on the wrong side of:
    // a search either fitted or half-fitted, and the half that did not fit was
    // announced in a line of text that vanished in four seconds. What a player
    // wants after three minutes over a shop is to *see what is there* and
    // decide. So the pass puts it down where it was found and opens the list.
    //
    // A note is the exception. Which note it is depends on where it was found
    // (§19.1) and the ground has nowhere to keep that, so it goes to the pack
    // as it always did.
    var inventory = _inventory.value;
    final store = DroppedStore(widget.session.db);
    final found = <String, int>{};

    for (final entry in drop.entries) {
      if (entry.key == 'lit_note') {
        final note = _notes?.forPlace(
          selectors: [table.match.isEmpty ? table.id : table.match.first],
          names: _placeNames,
          seed: character.profile.rngSeed ^ poiId.hashCode,
        );
        inventory = inventory
            .add(entry.key, catalogue, body: character.body, noteId: note?.id)
            .inventory;
        found[entry.key] = 1;
        continue;
      }

      await store.drop(
        character.profile.id,
        DroppedItem(
          id: 0,
          itemId: entry.key,
          count: entry.value,
          position: box.position,
          droppedAt: now,
        ),
      );
      found[entry.key] = entry.value;
    }

    // What the pass took out of the place, whether or not the player picks it
    // up. §19.3 spends the time on searching it, not on carrying the result —
    // shelves that stayed full because a pack was full would be a way to farm
    // one shop.
    final searched = box.searchedAt(depth, now, random);

    _inventory.value = inventory;
    _loot.replace(searched);

    await LootStore(widget.session.db).saveOne(character.profile.id, searched);
    await _saveInventory();
    await _reloadDropped();
    if (!mounted) return;

    if (found.isEmpty) {
      _say(L10n.of(context).searchFoundNothing);
      return;
    }

    // The list itself, rather than a sentence naming what is in it: a line of
    // text that vanishes in four seconds is not a way to decide anything.
    await _showPileAt(box.position);
  }

  /// One line, at the bottom, gone in a few seconds. The player is walking.
  /// §12: the game says something, under the HUD rather than over the menu.
  /// Says something, and — for anything that belongs to a fight — writes it
  /// down as well.
  ///
  /// A notice lasts seconds. A death is exactly the moment somebody wants the
  /// last minute back, which is why [remember] exists at all.
  void _say(String message, {bool remember = false}) {
    if (remember) _logCombat(message);
    if (!mounted) return;

    final notice = Notice(message, DateTime.now());
    _notices.value = [notice, ..._notices.value];

    Timer(kNoticeLifetime, () {
      if (!mounted) return;
      _notices.value = _notices.value
          .where((other) => !identical(other, notice))
          .toList();
    });
  }

  /// Sends the player wherever the current refusal can actually be changed.
  Future<void> _fixLocation() async {
    final access = _permissions?.location ?? LocationAccess.denied;
    if (access.isAskable) {
      await requestLocationAccess();
    } else {
      // Background location cannot be granted from a prompt on modern
      // Android: it is a trip to the app's own settings page, every time.
      await const SystemSettings().openAppSettings();
    }
    await _readPermissions();
  }

  /// Switching the source is a restart of the session, not a live swap: the
  /// filter, the loop and the map are all built around one of them (§11.2).
  Future<void> _setSimulator(bool value) async {
    await widget.session.db.writeSetting(
      kSimulatorSettingKey,
      value ? 'true' : 'false',
    );
    if (!mounted) return;

    setState(() => _useSimulator = value);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(L10n.of(context).settingsRestartNeeded)),
      );
    }
  }

  Future<void> _openRegionPicker() async {
    final packs = _packs ??= await bootMapPacks();
    if (!mounted) return;

    final near = await _bestKnownPosition();
    if (!mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RegionPickerScreen(
          manager: packs,
          nearLatitude: near?.latitude,
          nearLongitude: near?.longitude,
          onPlayStreamed: _playStreamed,

          // A finished download is the whole reason the screen was open.
          // Leaving it up and making the player find the back gesture reads
          // as the download not having worked.
          onDone: () => Navigator.of(context).popUntil((r) => r.isFirst),
        ),
      ),
    );
    if (mounted) await _resolveMap();
  }

  Future<void> _createCharacter(CharacterDraft draft) async {
    final created = await _factory.create(
      name: draft.name,
      spec: draft.spec,
      deathMode: draft.deathMode,
      now: DateTime.now().toUtc(),
    );
    if (!mounted) return;

    Navigator.of(context).pop();
    setState(() => _loading = true);
    await _enter(created);
  }

  /// The two moments the process is most likely to be killed (§11.1.5).
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // ⚠️ Outside the null check below, because going away cleanly is exactly
    // what has to be recorded — and a run that never got as far as a loop is
    // still a run that ended.
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      // §16.1: the trail is put away on purpose, so that finding one on the
      // next launch means the last session did *not* stop on purpose.
      unawaited(CrashLog.settled());
    }

    final loop = _loop;
    if (loop == null) return;

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        unawaited(loop.onPaused(DateTime.now().toUtc()));
        _sleepTickers();
      case AppLifecycleState.resumed:
        unawaited(loop.onResumed());
        unawaited(_readPermissions());
        unawaited(_wakeTickers());
      case AppLifecycleState.inactive:
        // Not a background: a dialog over the app, the recents view, a call
        // coming in. The screen is still the player's, and a bar that froze
        // behind a permission sheet would read as the game hanging.
        break;
    }
  }

  /// ⚠️ **Nothing ticks while the app is in the background.**
  ///
  /// Seven periodic timers ran at one second and a hundred milliseconds, none
  /// of them tied to the lifecycle. This game lives in a pocket for hours at a
  /// time — that is the whole design — so a timer nobody stops is a wake-up
  /// every second for as long as the phone is carried, rebuilding a widget
  /// tree that no one can see.
  ///
  /// Nothing is lost by stopping. Every one of these draws a **deadline**, not
  /// an accumulator: the search knows when it ends, the bench knows when it
  /// ends, the reload knows when it ends. Waking up settles them against the
  /// wall clock, exactly as opening the app after a night already does.
  void _sleepTickers() => _clock.sleep();

  /// Puts the clocks back, and pays out whatever finished while they were off.
  ///
  /// The order matters: settle first, restart second. Restarting a timer for
  /// an action that ended twenty minutes ago would draw a full bar for one
  /// frame before the next tick cleared it.
  Future<void> _wakeTickers() async {
    // ⚠️ Settle first, start second. Putting a beat back for an action that
    // ended twenty minutes ago would draw a full bar for one frame before the
    // next tick cleared it.
    if (_search.value != null) {
      _clock.tickedAt = DateTime.now().toUtc();
      await _advanceSearch();
    }
    if (_reload != null) {
      _advanceReload(_standingAt.value ?? const GeoPoint(0, 0));
    }

    // Reloads what is on the bench, and pays it out if its time came while
    // the phone was in a pocket.
    await _reloadCraftJob();

    _clock.wake();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_downloadWatch?.cancel());
    unawaited(_loop?.dispose());
    unawaited(_dev?.dispose());
    unawaited(_world?.dispose());

    _position.dispose();
    _actions?.dispose();
    _craftJob.removeListener(_onBenchChanged);
    _notices.dispose();
    _controllers.dispose();
    super.dispose();
  }

  /// §18.1a, §11.1: the pack, and everything that is only about the pack.
  ///
  /// ⚠️ Created here rather than at boot so the notifiers inside it exist
  /// before any screen can ask for one. The character arrives later and is
  /// handed over with [InventoryController.bind] — that is the only thing
  /// allowed to be late.
  late final InventoryController _pack = _controllers.adopt(
    InventoryController(widget.session.db),
  );

  /// §18.2: the shelves of whichever shelter is open.
  late final StashController _shelf = _controllers.adopt(
    StashController(widget.session.db),
  );

  /// §10, §4.8, §10.3: the places, the ground and the bodies.
  late final LootController _loot = _controllers.adopt(
    LootController(widget.session.db),
  );

  /// §8.3, §8.4: the places this character has built.
  late final ShelterController _places = _controllers.adopt(
    ShelterController(widget.session.db),
  );

  /// §18.4, §18.6: what is on the bench, and what is coming apart on it.
  late final CraftController _bench2 = _controllers.adopt(
    CraftController(widget.session.db),
  );

  /// §5.5, §6.1a: everything hostile that is out there.
  late final CombatController _fight = _controllers.adopt(CombatController());

  /// §7: what this character has learned.
  ///
  /// ⚠️ Owns no clock and never will. Skills are the one long axis in this
  /// game that owes nothing to time — they move when something happens and
  /// never on their own.
  late final SkillController _learned = _controllers.adopt(
    SkillController(widget.session.db),
  );

  /// §2.1a, §3.3: the one clock everything with a bar runs on.
  ///
  /// ⚠️ There were five, none of them knowing about the others, and the
  /// lifecycle stopped three of them by name. The sixth would have been the
  /// one somebody forgot to add to both lists.
  late final ActionController _clock = _controllers.adopt(ActionController());

  /// §2.1a.3: puts the three things with a beat on the one clock.
  ///
  /// ⚠️ Registration is not starting. Each ticker says how often it wants a
  /// beat and how to tell whether it is still running; the clock asks, and
  /// runs at the finest period anything actually needs. A reload wants ten
  /// beats a second so its bar looks smooth; a forty-five minute pack wants
  /// one, and waking the phone ten times a second for it would be §3.3's
  /// complaint made real.
  void _putClocksOn() {
    _clock.every(
      _kSearch,
      const Duration(seconds: 1),
      running: () => _search.value != null,
      onTick: () => unawaited(_advanceSearch()),
    );

    _clock.every(
      _kReload,
      const Duration(milliseconds: 100),
      running: () => _reload != null,
      onTick: () {
        // ⚠️ Not inside setState: this can finish the reload, and finishing it
        // calls setState itself. The repaint the bar needs comes after.
        _advanceReload(_standingAt.value ?? const GeoPoint(0, 0));
        if (mounted && _reload != null) setState(() {});
      },
    );

    _clock.every(
      _kBench,
      const Duration(seconds: 1),
      running: () => _craftJob.value != null,
      onTick: () {
        if (_craftJob.value!.isDoneAt(DateTime.now().toUtc())) {
          unawaited(_reloadCraftJob());
        }
      },
    );
  }

  static const _kSearch = 'search';
  static const _kReload = 'reload';
  static const _kBench = 'bench';

  SalvageBatch _sittingOf(CraftJob job) => CraftController.sittingOf(job);

  /// §18.6: whether anything would actually come out of this piece.
  ///
  /// ⚠️ What actually comes out, not what the thing is made of. Two different
  /// questions, and the difference is most of the catalogue: an axe holds 0.86
  /// units of metal and wood, which at §18.6's forty per cent rounds to
  /// nothing. Lighting the glyph on everything with a material content lit it
  /// on axes, knives and magazines and then refused every one of them on the
  /// tap.
  bool _worthTakingApart(CarriedItem line) {
    final catalogue = _catalogue;
    if (catalogue == null) return false;

    return _bench2.worthTakingApart(
      line,
      bench: _bench(),
      catalogue: catalogue,
      book: _recipes,
    );
  }

  Future<void> _reloadDropped() => _loot.reloadDropped(DateTime.now().toUtc());

  Future<void> _reloadRemains() => _loot.reloadRemains(DateTime.now().toUtc());

  double _reachForPilesAt(GeoPoint at) => _loot.reachForPilesAt(at);

  bool _isVisible(LootBox box) => _loot.isVisible(box);

  /// §19.3: the place the player is standing at, if any.
  ///
  /// ⚠️ The sticky position, and this line has now been the bug six times.
  /// §2.1a.4 switches the receiver off under a roof, so `displayFix` is null
  /// in a shelter — which left the search button dead there. Fixing the
  /// handler was not enough: nothing ever reached it, because this is what
  /// decides whether the button is offered at all.
  LootBox? _boxInReach() => _loot.boxInReach(
    _standingAt.value,
    _snapshot?.state.lastUpdate ?? DateTime.now().toUtc(),
  );

  Future<void> _saveInventory() => _pack.save();

  Future<void> _saveShelf() => _shelf.save();

  Map<String, int> _carriedCounts() => _pack.counts();

  Set<String> _carriedIds() => _pack.ids();

  Map<String, int> _shelvedCounts() => _shelf.counts();

  PackRoom _packRoom() => _pack.room();

  /// §18.1a: puts what would not fit onto the shelves of the main shelter.
  Future<void> _shelveSpill(Map<String, int> spill) async {
    final catalogue = _catalogue;
    final main = _shelters.value
        .where((place) => place.kind == ShelterKind.main)
        .firstOrNull;
    if (catalogue == null || main == null) return;

    await _shelf.spill(spill, main, catalogue);
  }

  @override
  Widget build(BuildContext context) => GameScope(
    // ⚠️ Empty for now, and above everything on purpose.
    //
    // This class owns forty fields and six and a half thousand lines. They
    // leave one owner at a time, and each one that leaves has to be reachable
    // from the widgets that used to read it off `this` — so the scope goes in
    // before the first of them does, rather than as part of the same change.
    controllers: _controllers,
    child: Builder(builder: _buildGame),
  );

  final GameControllers _controllers = GameControllers();

  Widget _buildGame(BuildContext context) {
    if (_needsLanguage) {
      return LanguagePickerScreen(
        onChosen: (locale) => unawaited(_chooseLanguage(locale)),
      );
    }

    if (_needsBriefing) {
      return SafetyBriefingScreen(onAccept: () => unawaited(_acceptBriefing()));
    }

    final l10n = L10n.of(context);
    final recovery = widget.session.recovery;
    final dev = _dev;
    final snapshot = _snapshot;
    final character = _character;
    final blocked = _blocked;

    final source = _mapSource;
    // Deliberately not waiting for a snapshot. The first one arrives with the
    // first fix, and a lock takes seconds — showing the region in the meantime
    // beats a title screen the player has already left.
    // §9: nothing else is drawn while the character is not on their feet. The
    // bug this exists to close: a character with no blood left went on looting
    // shops while something chewed on them, because nothing had ever asked.
    final down = _loop?.down ?? DownState.none;
    if (character != null &&
        (down == DownState.dead || down == DownState.unconscious)) {
      return DownScreen(
        state: down,
        cause: _loop?.deathCause,
        until: _loop?.downUntil,
        log: _combatLog,
        onNewCharacter: down == DownState.dead
            ? () => unawaited(_startOver(character))
            : null,
      );
    }

    if (source != null && character != null) {
      return Stack(
        children: [
          MapScreen(
            tileBuilder:
                (
                  context, {
                  required centre,
                  required markers,
                  required economy,
                  onMarkerTap,
                  noise,
                }) => MapLibreSurface(
                  source: source,
                  centre: centre,
                  markers: markers,
                  economy: economy,
                  onMarkerTap: onMarkerTap,
                  noise: noise,
                  fallbackCentre: _packCentre,
                ),
            fix: snapshot?.displayFix,
            // §4.8: a pack emptied on a corner is fourteen rows in one place,
            // and fourteen overlapping circles is a smear rather than a map.
            markers: _markers(),
            onMarkerTap: _showMarker,
            // §5.6.5: what the last shot woke up, drawn at the radius it
            // actually carried.
            noise: _combat.open == null
                ? null
                : NoiseWave(
                    at: _combat.open!.at,
                    radiusM: _combat.open!.radiusM,
                    startedAt: _combat.open!.startedAt.toLocal(),
                  ),
            // §4.6, §10.2, §8.3: the bar for whatever is running, at the top.
            // Eating and building are the same thing from the player's side —
            // something they are waiting on — so they share the one slot.
            // ⚠️ Everything running, stacked, and every line with a way out.
            //
            // It used to be one slot showing whichever of two things it liked
            // best. A magazine change had its bar at the bottom of the screen
            // and a dismantling had one on a screen the player was not looking
            // at — which is the same failure three field reports have already
            // described as "it does not work": it was working, and there was
            // no way to tell.
            progress: _running(),
            searchPanel: snapshot == null
                ? null
                : Builder(
                    builder: (context) {
                      // §5.1.4: while something is being aimed at, the panel
                      // is the odds and the trigger. Searching a shop with a
                      // Walker in the sights is not a thing to offer.
                      // ⚠️ Whenever something is aimed at, weapon or no
                      // weapon. Found on a phone: tapping an enemy with
                      // nothing in hand looked like the tap had missed,
                      // because the panel only appeared when a shot could be
                      // worked out — so the one case where a player most
                      // needs to be told what they are looking at showed them
                      // nothing at all.
                      final target = _target;
                      final error = target == null ? null : _aimError(target);
                      if (target != null) {
                        // §5.5.1 and §10.2 at once: what can be done standing
                        // here sits *above* the fight, not behind it. Found on
                        // a phone: taking a target buried the search and
                        // pick-up glyphs under the combat panel, so a body at
                        // the player's feet could not be gone through until
                        // the fight was over.
                        final weapon = _weapon;
                        final round = weapon == null ? null : _roundFor(weapon);

                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _actionPanel(context),
                            CombatPanel(
                              targetName: enemyKindName(
                                L10n.of(context),
                                target.kind,
                              ),
                              state: target.state,
                              weaponName: weapon == null
                                  ? null
                                  : _nameOfItem(weapon),
                              distanceM: target.position.distanceTo(
                                GeoPoint(
                                  snapshot.displayFix?.latitude ?? 0,
                                  snapshot.displayFix?.longitude ?? 0,
                                ),
                              ),
                              chance: error == null
                                  ? null
                                  : hitChance(
                                      moa: error.total,
                                      distanceM: target.position.distanceTo(
                                        GeoPoint(
                                          snapshot.displayFix?.latitude ?? 0,
                                          snapshot.displayFix?.longitude ?? 0,
                                        ),
                                      ),
                                    ),
                              dominant: error?.dominant,
                              settling:
                                  _aim.spreadMultiplierAt(DateTime.now()) >
                                  1.02,
                              condition: target.condition,
                              sprintLeft: target.sprintLeftFraction,
                              bloodLeft: target.bloodLeft,
                              bleeding: target.isBleeding,
                              loaded: _loaded,
                              magazine: weapon == null
                                  ? 0
                                  : magazineSize(
                                      weapon,
                                      attachments: _attachmentsFor(weapon),
                                    ),
                              reloading: _reload != null,
                              // §8.1: the same fifty metres that keeps them
                              // out keeps the player's fire in. Two different
                              // numbers would make a ring nobody can win in.
                              refusal: _inOwnZone()
                                  ? L10n.of(context).shelterInside
                                  : _loop?.down == DownState.grace
                                  ? L10n.of(context).downGrace
                                  : weapon == null
                                  ? L10n.of(context).combatNoWeapon
                                  : _loaded <= 0 && round == null
                                  ? L10n.of(context).combatNoAmmo
                                  : null,
                              onReload:
                                  weapon == null ||
                                      round == null ||
                                      _reload != null ||
                                      // Nothing to do: §5.3's seconds are for
                                      // filling a magazine, and a full one has
                                      // no room to fill.
                                      _loaded >=
                                          magazineSize(
                                            weapon,
                                            attachments: _attachmentsFor(
                                              weapon,
                                            ),
                                          )
                                  ? null
                                  : _startReload,
                              onFire:
                                  weapon == null ||
                                      _loaded <= 0 ||
                                      _reload != null ||
                                      // §9.2: the grace window cuts both ways.
                                      _loop?.down == DownState.grace ||
                                      _inOwnZone()
                                  ? null
                                  : () => unawaited(_fire()),
                              // §5.2: below twenty metres the receiver has nothing
                              // useful to say about anybody's position, so the
                              // fight stops being about distance and becomes about
                              // what is in your hands.
                              onStrike:
                                  !_inOwnZone() &&
                                      _loop?.down != DownState.grace &&
                                      target.position.distanceTo(
                                            GeoPoint(
                                              snapshot.displayFix?.latitude ??
                                                  0,
                                              snapshot.displayFix?.longitude ??
                                                  0,
                                            ),
                                          ) <=
                                          kMeleeM
                                  ? () => unawaited(_strike())
                                  : null,
                            ),
                          ],
                        );
                      }

                      return _actionPanel(context);
                    },
                  ),
            headingDeg: snapshot?.fix?.headingDeg,
            economy: snapshot?.economy ?? false,
            // There is always a map here — this branch only runs with a
            // source. Whether the player has walked off its *edge* is the
            // coverage question of §16.6, and it arrives with 3.12.
            hasPack: true,
            hud: snapshot == null
                ? null
                : Hud(
                    state: snapshot.state,
                    status: snapshot.status,
                    constants: character.constants,
                    warnings: _warnings(l10n, snapshot),
                    twilight: snapshot.twilight,
                    bleeding: _loop?.bleeding ?? BleedTier.none,
                    carryComfortKg: character.body.carryComfortKg,
                    carryMaxKg: character.body.carryMaxKg,
                    carriedKg: _carriedKg,
                    carriedVolumeL: _carriedVolumeL,
                    capacityL: _capacityL(character.body),
                    threat: _threat(snapshot),
                  ),
            notices: NoticeStack(notices: _notices),
            onMenu: (entry) {
              switch (entry) {
                case MapMenuEntry.settings:
                  unawaited(_openSettings());
                case MapMenuEntry.inventory:
                  unawaited(_openInventory());
                case MapMenuEntry.shelter:
                  unawaited(_openShelter());
                case MapMenuEntry.profile:
                  unawaited(_openProfile());
              }
            },
          ),
          if (dev != null) _devOverlay(dev, snapshot),
        ],
      );
    }

    if (character != null && blocked == null) {
      // A character exists, so the game is running; the map is simply not
      // resolved yet. Showing the title screen here would put a logo over a
      // live simulation and read as something having gone wrong.
      return Scaffold(
        body: Stack(
          children: [
            const Center(child: CircularProgressIndicator()),
            if (snapshot != null)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Hud(
                    state: snapshot.state,
                    status: snapshot.status,
                    constants: character.constants,
                    warnings: _warnings(l10n, snapshot),
                    twilight: snapshot.twilight,
                    carryComfortKg: character.body.carryComfortKg,
                    carryMaxKg: character.body.carryMaxKg,
                    carriedKg: _carriedKg,
                    carriedVolumeL: _carriedVolumeL,
                    capacityL: _capacityL(character.body),
                  ),
                ),
              ),
          ],
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              if (snapshot != null && character != null)
                Hud(
                  state: snapshot.state,
                  status: snapshot.status,
                  constants: character.constants,
                  warnings: _warnings(l10n, snapshot),
                  // §12, §17.2: how long the light has left.
                  twilight: snapshot.twilight,
                  carryComfortKg: character.body.carryComfortKg,
                  carryMaxKg: character.body.carryMaxKg,
                  carriedKg: _carriedKg,
                  carriedVolumeL: _carriedVolumeL,
                  capacityL: _capacityL(character.body),
                ),
              Expanded(
                child: SafeArea(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: _loading
                          ? const CircularProgressIndicator()
                          : Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Image.asset('assets/icon.png', width: 120),
                                const SizedBox(height: 24),
                                Text(
                                  character?.profile.name ?? l10n.appTitle,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.headlineMedium,
                                ),
                                Text(
                                  l10n.appTagline,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                const SizedBox(height: 32),
                                if (recovery.health == SaveHealth.restored)
                                  BlockedPanel(
                                    title: l10n.saveRestoredTitle,
                                    body: l10n.saveRestoredBody(
                                      recovery.timeLost?.inMinutes ?? 0,
                                    ),
                                  ),
                                if (recovery.health == SaveHealth.lost)
                                  BlockedPanel(
                                    title: l10n.saveLostTitle,
                                    body: l10n.saveLostBody,
                                  ),
                                if (blocked != null)
                                  LocationGate(
                                    access: blocked,
                                    onRetry: _retryAccess,
                                  ),
                                if (character == null)
                                  FilledButton(
                                    onPressed: _openCreator,
                                    child: Text(l10n.newCharacter),
                                  ),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (dev != null) _devOverlay(dev, snapshot),
        ],
      ),
    );
  }

  /// The player has been to the settings, or wants to be asked again.
  Future<void> _retryAccess() async {
    final device = _device;
    final character = _character;

    // The gate can fire before there is a character at all — the permission is
    // now asked for during boot. Then the way back is simply to ask again.
    if (device == null || character == null) {
      final blocked = _blocked;
      if (blocked != null && blocked.needsSystemSettings) {
        await openSettingsFor(blocked);
        return;
      }

      final access = await requestLocationAccess();
      if (!mounted) return;

      if (access.canPlay) {
        setState(() {
          _blocked = null;
          _loading = true;
        });
        await _boot();
      } else {
        setState(() => _blocked = access);
      }
      return;
    }

    if (device.access.needsSystemSettings) {
      await device.openRelevantSettings();
      // Android gives us nothing to await here: the player may come back
      // having changed the setting, or not at all. The button stays, so the
      // next tap re-asks.
      return;
    }

    setState(() => _loading = true);
    await device.dispose();
    _device = null;
    await _enter(character);
  }

  void _openCreator() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CharacterCreatorScreen(onCreate: _createCharacter),
      ),
    );
  }

  /// Game seconds this session has consumed. In furious time scale a minute of
  /// wall clock is more than two days of it, which is exactly what the overlay
  /// exists to make visible.
  int _simulatedSeconds(GameSnapshot? snapshot) {
    final start = _sessionStart;
    if (snapshot == null || start == null) return 0;
    return snapshot.state.lastUpdate.difference(start).inSeconds;
  }

  /// Everything the systems layer wants said in words, in the order it matters.
  ///
  /// A suspended run comes first: while it holds, nothing else the HUD says is
  /// being applied anyway (§3.4).
  /// §12: what the strip under the bars is saying, if anything.
  List<String> _warnings(L10n l10n, GameSnapshot snapshot) =>
      hudWarnings(l10n, snapshot, location: _permissions?.location);
}

/// What the crafting bench is made of, for deciding whether to make it again.
///
/// Every field is an immutable value replaced wholesale when it changes, so
/// reference equality is exact: two of these are equal precisely when nothing
/// the bench reads has moved.
///
/// ⚠️ The clock is deliberately not in here. Only one thing the bench reads
/// depends on it — whether a shelter is finished (§8.3) — and that changes at
/// most once in three hours. A cache entry is held for a second so that a
/// build finishing is noticed promptly without making the clock an input, and
/// a second is far below anything a player can act on.
class _BenchInputs {
  const _BenchInputs({
    required this.shelters,
    required this.standingAt,
    required this.inventory,
    required this.stash,
    required this.search,
    required this.reload,
    required this.job,
  });

  final List<Shelter> shelters;
  final GeoPoint? standingAt;
  final Inventory inventory;
  final Stash stash;
  final Search? search;
  final Reload? reload;
  final CraftJob? job;

  @override
  bool operator ==(Object other) =>
      other is _BenchInputs &&
      identical(other.shelters, shelters) &&
      identical(other.standingAt, standingAt) &&
      identical(other.inventory, inventory) &&
      identical(other.stash, stash) &&
      identical(other.search, search) &&
      identical(other.reload, reload) &&
      identical(other.job, job);

  @override
  int get hashCode => Object.hash(
    identityHashCode(shelters),
    identityHashCode(standingAt),
    identityHashCode(inventory),
    identityHashCode(stash),
    identityHashCode(search),
    identityHashCode(reload),
    identityHashCode(job),
  );
}

extension on ({_BenchInputs inputs, CraftBench bench, DateTime madeAt}) {
  /// Whether this entry is young enough to trust. See [_BenchInputs].
  bool freshAt(DateTime now) =>
      now.difference(madeAt) < const Duration(seconds: 1);
}
