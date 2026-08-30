import 'dart:io';

import 'package:arls_za/inventory/inventory.dart';
import 'package:arls_za/items/item_catalogue.dart';
import 'package:arls_za/sim/body.dart';
import 'package:test/test.dart';

/// NARZĘDZIE SIĘ ZUŻYWA (§19.3, §4.1).
///
/// ⚠️ **`condition_decay_per_use` leżało w danych i nic go nie czytało.** Dwa
/// procent na użycie przy wytrychach — najwyższa wartość w całym katalogu,
/// wpisana po to, żeby komplet starczał na pięćdziesiąt zamków — było polem
/// parsowanym w `item_parser.dart` i nigdzie więcej. Cicha droga przez każde
/// drzwi w grze kosztowała jednorazowo dwa kawałki złomu i dwanaście minut.
///
/// Jedenasty przypadek tej samej klasy usterki: pole poprawne, przetestowane i
/// nieosiągalne z gry.
void main() {
  final catalogue = ItemCatalogue.load([
    for (final asset in kBundledItemAssets)
      ItemSource(asset, File(asset).readAsStringSync()),
  ]);

  final body = BodyProfile.from(
    const BodySpec(sex: Sex.male, ageYears: 30, heightCm: 180, weightKg: 80),
  );

  Inventory withPicks(int howMany) {
    var pack = const Inventory().withPack('pack_daypack');
    for (var i = 0; i < howMany; i++) {
      pack = pack.add('tool_lockpicks', catalogue, body: body).inventory;
    }
    return pack;
  }

  double? conditionOf(Inventory pack, {int at = 0}) =>
      pack.carried.where((line) => line.itemId == 'tool_lockpicks').isEmpty
      ? null
      : pack.carried
            .where((line) => line.itemId == 'tool_lockpicks')
            .elementAt(at)
            .condition;

  group('§19.3: jedno otwarcie kosztuje kawałek narzędzia', () {
    test('wytrych schodzi o swoje dwa procent', () {
      final after = withPicks(1).usedTool('tool_lockpicks', catalogue);

      expect(conditionOf(after), 98);
    });

    test('i po pięćdziesięciu otwarciach zostaje po nim nic', () {
      // Pięćdziesiąt zamków na komplet — liczba wpisana w dane od dawna, i to
      // jest pierwszy raz, kiedy cokolwiek ją czyta.
      var pack = withPicks(1);
      for (var lock = 0; lock < 50; lock++) {
        pack = pack.usedTool('tool_lockpicks', catalogue);
      }

      expect(pack.carried.where((l) => l.itemId == 'tool_lockpicks'), isEmpty);
    });

    test('a przedmiot bez zużycia nie zużywa się wcale', () {
      // Złom nie ma `condition_decay_per_use` — i nie ma go dostać przez to,
      // że raz przeszedł tą samą funkcją.
      final pack = const Inventory()
          .withPack('pack_daypack')
          .add('mat_metal', catalogue, body: body)
          .inventory;

      expect(pack.usedTool('mat_metal', catalogue), pack);
    });

    test('czego nie ma, tego się nie zużywa', () {
      final pack = withPicks(0);

      expect(pack.usedTool('tool_lockpicks', catalogue), pack);
    });
  });

  group('§4.1: który egzemplarz schodzi', () {
    test('najbardziej zużyty, nie pierwszy z brzegu', () {
      // ⚠️ Kto nosi dwa komplety, dorabia się jednego całego i jednego na
      // wykończeniu, a nie dwóch po połowie. Tak robi każdy, kto ma w kieszeni
      // dwa scyzoryki.
      var pack = withPicks(2);

      for (var use = 0; use < 3; use++) {
        pack = pack.usedTool('tool_lockpicks', catalogue);
      }

      final left = [
        for (final line in pack.carried)
          if (line.itemId == 'tool_lockpicks') line.condition ?? 100,
      ]..sort();

      expect(left, [94, 100], reason: 'jeden zjechał, drugi jest nietknięty');
    });

    test('i dopiero kiedy padnie, bierze się następny', () {
      var pack = withPicks(2);
      for (var lock = 0; lock < 50; lock++) {
        pack = pack.usedTool('tool_lockpicks', catalogue);
      }

      final left = pack.carried.where((l) => l.itemId == 'tool_lockpicks');

      expect(left, hasLength(1));
      expect(left.single.condition ?? 100, 100);
    });

    test('a narzędzie trzymane w ręce zużywa się tak samo', () {
      // ⚠️ **Broń w ręce stoi w obu listach naraz** i to o mało nie zepsuło
      // tej funkcji: prawdziwy egzemplarz z uid zostaje w plecaku, a lista
      // noszonych trzyma sam znacznik slotu — bez uid i bez kondycji. Zużycie
      // znacznika byłoby zużyciem niczego, a gracz dalej trzymałby całe.
      final pack = const Inventory()
          .withPack('pack_daypack')
          .add('melee_crowbar', catalogue, body: body)
          .inventory
          .wear('melee_crowbar', catalogue);

      expect(pack.worn.single.itemId, 'melee_crowbar');

      final after = pack.usedTool('melee_crowbar', catalogue);
      final bar = after.carried.where((l) => l.itemId == 'melee_crowbar');

      expect(bar, hasLength(1));
      expect(bar.single.condition ?? 100, lessThan(100));
    });
  });

  test('§19.3: i wyłamanie naprawdę je zużywa', () {
    // ⚠️ Test źródłowy: funkcja może być doskonała i niewołana — dokładnie to
    // było z `condition_decay_per_use` przez jedenaście wersji schematu.
    final main = File('lib/main.dart').readAsStringSync();
    final pack = File(
      'lib/game/controllers/inventory_controller.dart',
    ).readAsStringSync();

    expect(pack.contains('.usedTool('), isTrue);
    expect(
      main.contains('_pack.useTool(search.breach?.toolIds'),
      isTrue,
      reason: 'zużyć ma się to narzędzie, którym otwarto',
    );
  });
}
